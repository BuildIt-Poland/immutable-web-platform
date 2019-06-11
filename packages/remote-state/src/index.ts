import * as yargs from 'yargs'
import * as shell from 'shelljs'
import * as inquirer from 'inquirer'
import { basename } from 'path'
import { diffString as prettyDiff } from 'json-diff'

import { isStateDiffers, diffState, readStateFile, reconcileState, ChangeDescriptor, escapeResources } from './reconciler'
import { aws } from './provisioner'

const remoteStateFileName = "localstate.nixops.json"
const defaultRemote = {
  remote: {
    default: remoteStateFileName
  }
}

const readFromStdin = (): Promise<string> =>
  new Promise((res, rej) => {
    const chunks = []
    process.stdin.on('data', (data) => chunks.push(data))
    process.stdin.on('end', () => res(chunks.join('').toString().trim()))
    process.stdin.on('error', rej)
  })

const getLocalStateFile =
  (fileName: string, stdin: boolean = false): Promise<string> =>
    stdin
      ? readFromStdin()
      : Promise.resolve(readStateFile(fileName))

const notifyAboutChanges =
  (remoteState: string, localState: string) => {
    console.log('Changes to be aplied\n', prettyDiff(JSON.parse(remoteState), JSON.parse(localState)))
  }

const askAboutReconciliation = () =>
  inquirer.prompt<{ proceed: boolean }>([
    {
      type: 'confirm',
      name: 'proceed',
      message: 'Remote state differs, should changes above should be applied to remote state?',
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
        console.log('State seems to be the same - skipping upload')
        return null
      })

const shouldApplyTransformation =
  (beforeUploadScript: string, data: string): Promise<string> =>
    new Promise((res) => {
      const transformed =
        beforeUploadScript && shell
          .echo(JSON.stringify(data))
          .exec(beforeUploadScript as string)

      transformed.stdout
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
// TODO add reason why lock / unlock
yargs
  .command('lock', 'Lock state', { reason: { default: 'CLI force change' } }, ({ reason }) => aws.setLock(true, reason))
  .command('unlock', 'Unlock state', { reason: { default: 'CLI force change' } }, ({ reason }) => aws.setLock(false, reason))

  .command('status', 'Get status of locker', { dump: { type: 'boolean' } },
    ({ dump }) =>
      (dump
        ? aws.getLockState()
        : aws.getLockState().then(d => d.locked))
        .then(console.log)
  )
  // TODO provide auto run - in case of CI or accept-all
  .command('upload-state', 'Upload state', {
    local: {},
    remoteFileName: { default: basename(remoteStateFileName) },
    force: { default: false },
    stdin: {},
    beforeUpload: {
      defaultDescription: "Extra command before uploading - data are passed thru stdin, to be used i.e for encryption before send",
    },
    ...defaultRemote,
  },
    ({ local, remote, force, stdin, beforeUpload, remoteFileName }) =>
      aws.setLock(true, "State upload lock.")
        .then(_ =>
          getLocalStateFile(local as string, stdin as boolean)
            .then(localState =>
              force
                ? aws.uploadState(localState, remoteFileName)
                : aws.getStateFromBucket(remote as string)
                  .then(remoteState =>
                    diffStateWithNotification(localState, remoteState)
                      .then(diff =>
                        diff &&
                        askAboutReconciliation()
                          .then(answers =>
                            !answers.proceed
                              ? console.log('Aborting action') as any
                              : runUploadCommand(beforeUpload as string, diff, remoteFileName))

                      ))
                  .catch(e =>
                    aws.uploadState(localState, remoteFileName) // INFO: key does not exists
                      .then(() => console.log('State update complete.'))
                  ))
        )
        .then(() => aws.setLock(false, "State upload lock finish."))
        .catch((e) => aws.setLock(false, `State upload lock error with message: ${e.message}`))
  )

  .command('reconcile-state', 'Merge local state with remote state', {}, () => {
    console.log('@@ todo')
  })
  .command('rewrite-arguments', 'Escape arguments for nixops', { input: { type: 'string' } },
    ({ input }) =>
      console.log(escapeResources(input.trim()))
  )
  .command('download-state', 'Download state', { file: {} },
    ({ file }) =>
      aws.getStateFromBucket(file as string).then(console.log))

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