import { aws } from './provisioner'
import * as yargs from 'yargs'

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

  .command('upload-state', 'Upload state', { file: {} },
    ({ file }) =>
      aws.uploadState(file as string))

  .command('download-state', 'Download state', { file: {} },
    ({ file }) =>
      aws.getStateFromBucket(file as string))

  .demandCommand()
  .help()
  .argv