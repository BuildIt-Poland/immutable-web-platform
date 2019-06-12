import * as yargs from 'yargs'
import { basename } from 'path'

import { diffState, escapeResources } from './reconciler'
import { aws } from './provisioner'
import { importState, ImportState, uploadState, UploadState } from './actions'
import { remoteStateFileName } from 'remote-state-config'

const defaultRemote = {
  remote: {
    default: remoteStateFileName
  }
}

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
  }, (args) => uploadState(args as UploadState))

  .command('has-remote-state', 'Checking existence of remote state on remote drive', defaultRemote,
    ({ remote }) =>
      aws.getStateFromBucket(remote)
        .then(result => Object.keys(result).length > 0)
        .then(console.log)
  )
  .command('rewrite-arguments', 'Escape arguments for nixops',
    { input: { type: 'string', required: true }, cwd: { type: 'string' } },
    ({ input, cwd }) =>
      console.log(escapeResources((input as string).trim(), cwd as string))
  )
  .command('download-state', 'Download state', { toFile: {} },
    ({ toFile }) =>
      aws
        .getStateFromBucket(toFile as string)
        .then(console.log)
  )
  .command('import-state', 'Import state',
    { from: { required: true }, beforeTo: {}, to: { required: true }, ...defaultRemote },
    (args) => importState(args as ImportState)
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