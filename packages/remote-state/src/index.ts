import { aws } from './provisioner'
import * as yargs from 'yargs'
import { isStateDiffers, diffState, fileToJSON, reconcileState } from './reconciler'
import * as shell from 'shelljs'
import * as inquirer from 'inquirer'
import { basename } from 'path'
import { diffString as prettyDiff, diff } from 'json-diff'

const remoteStateFileName = "localstate.nixops.json"
const defaultRemote = {
  remote: {
    default: remoteStateFileName
  }
}

yargs
  .command('lock', 'Lock state', {}, () => aws.setLock(true))
  .command('unlock', 'Unlock state', {}, () => aws.setLock(false))

  .command('status', 'Get status of locker', { dump: {} },
    ({ dump }) =>
      (dump
        ? aws.getLockState()
        : aws.getLockState().then(d => d.locked))
        .then(console.log)
  )
  // usage:
  // locker upload-state ./test/remote-state-a.json --before-upload "cat" -> it is going to read stdout
  .command('upload-state <local>', 'Upload state', {
    local: {},
    remoteFileName: { default: basename(remoteStateFileName) },
    force: { default: false },
    beforeUpload: {
      defaultDescription: "Extra command before uploading - data are passed thru stdin, to be used i.e for encryption before send",
    },
    ...defaultRemote,
  },
    ({ local, remote, force, beforeUpload, remoteFileName }) =>
      force
        ? aws.uploadState(local as string, remoteFileName)
        : aws
          .getStateFromBucket(remote as string)
          .then(remoteState => {
            const localState = fileToJSON(local as string)
            const diff = diffState(remoteState as string, localState)

            if (!isStateDiffers(diff)) {
              console.log('State seems to be the same - skipping upload')
              return
            }

            console.log('Changes to be aplied\n', prettyDiff(JSON.parse(remoteState), JSON.parse(localState)))
            return inquirer.prompt<{ proceed: boolean }>([
              {
                type: 'confirm',
                name: 'proceed',
                message: 'remote state differs, should merge state as?',
                default: false
              }
            ]).then(answers => {
              if (!answers.proceed) {
                console.log('Aborting action')
                return
              }

              const a = beforeUpload && shell
                .echo(JSON.stringify(diff))
                .exec(beforeUpload as string)

              if (a && a.stdout) {
                return aws.uploadStateFromStdout(a.stdout, remoteFileName)
              } else {
                const reconciled = reconcileState(diff)
                return aws.uploadStateFromStdout(
                  JSON.stringify(reconciled, null, 2),
                  basename(remote as string)
                )
              }
            })
          })
          .catch(e =>
            aws.uploadState(local as string, remoteFileName) // INFO: key does not exists
              .then(() => console.log('State update complete.'))
          )
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