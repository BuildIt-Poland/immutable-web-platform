import { aws } from './provisioner'
import * as yargs from 'yargs'
import { isStateDiffers, diffState, fileToJSON, reconcileState } from './reconciler'
import * as shell from 'shelljs'
import * as inquirer from 'inquirer'
import { basename } from 'path';

const defaultRemote = {
  remote: {
    default: "localstate.nixops.json"
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
    force: { default: false },
    beforeUpload: {},
    ...defaultRemote,
  },
    ({ local, remote, force, beforeUpload }) =>
      // TODO check if file exists
      force
        ? aws.uploadState(local as string)
        : aws.getStateFromBucket(remote as string)
          .then(remoteState => {
            const localState = fileToJSON(local as string)
            const diff = diffState(remoteState, localState)

            if (isStateDiffers(diff)) {
              console.log('you have changes', JSON.stringify(diff.changes, null, 2))
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
                  return aws.uploadStateFromStdout(a.stdout, basename(remote as string))
                } else {
                  const reconciled = reconcileState(diff)
                  return aws.uploadStateFromStdout(
                    JSON.stringify(reconciled, null, 2),
                    basename(remote as string)
                  )
                }
              })
            }
          })
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