import * as yargs from 'yargs'
import * as shell from 'shelljs'
import * as inquirer from 'inquirer'
import { basename } from 'path'
import { diffString as prettyDiff } from 'json-diff'

import { isStateDiffers, diffState, readStateFile, reconcileState, ChangeDescriptor, escapeResources, escapeNixExpression } from './reconciler'
import { aws } from './provisioner'

const remoteStateFileName = "remotestate.nixops.json"
const defaultRemote = {
  remote: {
    default: remoteStateFileName
  }
}

const getLocalStateFile =
  (pathToFile: string, from: string): Promise<string> =>
    Promise
      .resolve(console.log('Current local state:'))
      .then(() =>
        !!from
          ? shell.exec(from).stdout
          : readStateFile(pathToFile)
      )

const notifyAboutChanges =
  (remoteState: string, localState: string) => {
    console.log('Changes to be applied\n', prettyDiff(JSON.parse(remoteState), JSON.parse(localState)))
  }

const askAboutReconciliation = (message?: string) =>
  inquirer.prompt<{ proceed: boolean }>([
    {
      type: 'confirm',
      name: 'proceed',
      message: message || 'Remote state differs, should changes above should be applied to remote state?',
      default: false
    }
  ])

const diffStates =
  (localState: string, remoteState: string): Promise<ChangeDescriptor> =>
    new Promise((res, rej) => {
      const diff = diffState(remoteState as string, localState)

      isStateDiffers(diff)
        ? res(diff)
        : rej(false)
    })

const diffStateWithNotification =
  (localState: string, remoteState: string): Promise<ChangeDescriptor> =>
    diffStates(localState, remoteState)
      .then(diff => {
        notifyAboutChanges(remoteState, localState)
        return diff
      })
      .catch(e => {
        console.log('State seems to be the same - skipping ...')
        return null
      })

const shouldApplyTransformation =
  (beforeUploadScript: string, data: JSON): Promise<string> =>
    new Promise((res) => {
      const transformed =
        beforeUploadScript && shell
          .echo(JSON.stringify(data))
          .exec(beforeUploadScript as string)

      transformed && transformed.stdout
        ? res(transformed.stdout)
        : res(JSON.stringify(data, null, 2))
    })

const runUploadCommand =
  (beforeUploadScript: string, diff: ChangeDescriptor, remoteFileName: string) => {
    const reconciled = reconcileState(diff as ChangeDescriptor)
    return shouldApplyTransformation(beforeUploadScript, reconciled)
      .then(data =>
        aws.uploadStateFromStdout(data, remoteFileName)
      )
  }

// TODO provide better logging -> these console.log are a bit crappy
// TODO make refactoring of this arrows - but first tests!
yargs
  .command('lock', 'Lock state', { reason: { default: 'CLI force change' } }, ({ reason }) => aws.setLock(true, reason))
  .command('unlock', 'Unlock state', { reason: { default: 'CLI force change' } }, ({ reason }) => aws.setLock(false, reason))

  .command('status', 'Get status of locker', { dump: { type: 'boolean' } },
    ({ dump }) =>
      (dump
        ? aws.getLockState().then(console.log)
        : aws.getLockState().then(d => d.locked).then(console.log))
  )
  // TODO provide auto run - in case of CI or accept-all
  .command('upload-state', 'Upload state', {
    local: {},
    remoteFileName: { default: basename(remoteStateFileName) },
    force: { default: false },
    stdin: {},
    from: {},
    beforeUpload: {
      defaultDescription: "Extra command before uploading - data are passed thru stdin, to be used i.e for encryption before send",
    },
    ...defaultRemote,
  },
    ({ local, from, remote, force, stdin, beforeUpload, remoteFileName }) =>
      aws.getLockState()
        .then(({ locked, ...details }) =>
          !locked
            ? aws
              .setLock(true, "State upload lock.")
              .then(_ =>
                getLocalStateFile(local as string, from as string)
                  .then(localState =>
                    force
                      ? aws.uploadState(localState, remoteFileName)
                      : aws
                        .getStateFromBucket(remote as string)
                        .then(remoteState =>
                          diffStateWithNotification(localState, remoteState)
                            .then(diff =>
                              diff &&
                              askAboutReconciliation()
                                .then(answers =>
                                  !answers.proceed
                                    ? console.log('Aborting action') as any
                                    : runUploadCommand(beforeUpload as string, diff, remoteFileName))),
                        )
                  )
              )
              .then(() => aws.setLock(false, "State upload lock finish."))
              .catch(e => aws.setLock(false, `State upload lock error with message: ${e.message}`))
            : console.log(`State is locked, details: ${JSON.stringify(details, null, 2)}`) as any
        ))
  .command('has-remote-state', 'Checking existence of remote state on remote drive', defaultRemote,
    ({ remote }) =>
      aws.getStateFromBucket(remote)
        .then(result => Object.keys(result).length > 0)
        .then(console.log)
  )
  .command('rewrite-arguments', 'Escape arguments for nixops', { input: { type: 'string' }, cwd: { type: 'string' } },
    ({ input, cwd }) =>
      console.log(escapeResources(input.trim(), cwd as string))
  )
  .command('download-state', 'Download state', { toFile: {} },
    ({ toFile }) =>
      aws
        .getStateFromBucket(toFile as string)
        .then(console.log)
  )
  .command('import-state', 'Import state', { from: { required: true }, beforeTo: {}, to: { required: true }, ...defaultRemote },
    ({ to, from, beforeTo, remote }) =>
      aws
        .getStateFromBucket(remote)
        .then(remoteState => {
          const localState = shell.exec(from as string).stdout
          return diffStateWithNotification(remoteState, localState)
            .then(diff => {
              diff &&
                askAboutReconciliation("Local state differs, final state would be as above.")
                  .then(answers => {
                    if (answers.proceed) {
                      shell.exec(beforeTo as string) // clean state
                      const reconciled = reconcileState(diff as ChangeDescriptor)
                      shell.echo(JSON.stringify(reconciled)).exec(to as string)
                    }
                  })
            })
        })
  )

  .command('diff-state <local>', 'Diff remote state with local state', {
    local: {},
    ...defaultRemote,
  },
    ({ remote, local }) =>
      aws.getStateFromBucket(remote as string).then(remoteState =>
        Promise.resolve(diffState(remoteState, local as string).changes)
          .then(console.log)))

  .demandCommand()
  .help()
  .argv