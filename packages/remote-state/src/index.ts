import { aws } from './provisioner'

// console.log(aws.setLock(true))
aws.setLock(true)
  .then(() => aws.getState())
  .then(console.log)
  .then(() => aws.setLock(false))
  .then(() => aws.getState())
  .then(console.log)