import * as shell from 'shelljs'
import * as inquirer from 'inquirer'
import { diffString as prettyDiff } from 'json-diff'

import {
  isStateDiffers,
  diffState,
  readStateFile,
  reconcileState,
  ChangeDescriptor,
} from './reconciler'
import { aws } from './provisioner'

// TODO provide better logging -> these console.log are a bit crappy
// TODO make refactoring of this arrows - but first tests!
export const getLocalStateFile =
  (pathToFile: string, from: string): Promise<string> =>
    Promise
      .resolve(console.log('Current local state:'))
      .then(() =>
        !!from
          ? shell.exec(from).stdout
          : readStateFile(pathToFile)
      )

export const notifyAboutChanges =
  (remoteState: string, localState: string) => {
    console.log('Changes to be applied\n', prettyDiff(JSON.parse(remoteState), JSON.parse(localState)))
  }

export const askAboutReconciliation = (message?: string) =>
  inquirer.prompt<{ proceed: boolean }>([
    {
      type: 'confirm',
      name: 'proceed',
      message: message || 'Remote state differs, should changes above should be applied to remote state?',
      default: false
    }
  ])

export const diffStates =
  (localState: string, remoteState: string): Promise<ChangeDescriptor> =>
    new Promise((res, rej) => {
      const diff = diffState(remoteState as string, localState)

      isStateDiffers(diff)
        ? res(diff)
        : rej(false)
    })

export const diffStateWithNotification =
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

export const shouldApplyTransformation =
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

export const runUploadCommand =
  (beforeUploadScript: string, diff: ChangeDescriptor, remoteFileName: string) => {
    const reconciled = reconcileState(diff as ChangeDescriptor)
    return shouldApplyTransformation(beforeUploadScript, reconciled)
      .then(data =>
        aws.uploadStateFromStdout(data, remoteFileName)
      )
  }

export type UploadState = {
  local: string
  from: string
  remote: string
  force: boolean
  beforeUpload: string
  remoteFileName: string
}

export const uploadState =
  ({ local, from, remote, force, beforeUpload, remoteFileName }: UploadState) =>
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
      )

export type ImportState = {
  to: string
  from: string
  beforeTo: string
  remote: string
}

export const importState =
  ({ to, from, beforeTo, remote }: ImportState) =>
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