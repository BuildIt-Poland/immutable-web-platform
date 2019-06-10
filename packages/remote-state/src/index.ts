import { aws } from './provisioner'

// console.log(aws.setLock(true))
console.log('@@@', process.cwd())

aws.setLock(true)
  .then(() => aws.getLockState())
  .then(console.log)
  .then(() => aws.setLock(false))
  .then(() => aws.getLockState())
  .then(console.log)
  .then(() => aws.uploadState('./test.nixops'))
  .then(() => aws.getStateFromBucket('test.nixops'))
  .then(console.log)