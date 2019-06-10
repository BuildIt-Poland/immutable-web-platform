
import { createReadStream } from 'fs'
import { basename, resolve } from 'path'

import * as AWS from 'aws-sdk'
import { DocumentClient } from 'aws-sdk/clients/dynamodb'
import { S3 } from 'aws-sdk'

import { tableName, awsRegion, bucketName } from '../../infra/config' // TODO make aliases instead of this ugly dots

const lockerId = 'locker'

// make a refactor of it
export const updateCredentials = () => {
  var credentials = new AWS.SharedIniFileCredentials({ profile: 'default' })

  AWS.config.update({
    ...credentials,
    region: awsRegion
  })

  return credentials
}

export const setLock = (locked: boolean) => {
  const credentials = updateCredentials()
  const docClient = new AWS.DynamoDB.DocumentClient()

  const params: DocumentClient.PutItemInput = {
    TableName: tableName,
    Item: {
      id: lockerId,
      locked: locked,
      time: new Date().toISOString(),
      who: credentials.accessKeyId,
    }
  }

  return docClient
    .put(params)
    .promise()
}

export const getLockState = () => {

  updateCredentials()

  const docClient = new AWS.DynamoDB.DocumentClient()
  const params: DocumentClient.GetItemInput = {
    TableName: tableName,
    Key: {
      'id': lockerId
    },
  }

  return docClient
    .get(params)
    .promise()
    .then(d => d.Item)
}

export const uploadState = (file: string) => {
  updateCredentials()

  const s3 = new AWS.S3()
  const fileStream = createReadStream(resolve(file))
  const params: S3.PutObjectRequest = {
    Bucket: bucketName,
    Key: basename(file),
    Body: fileStream
  }

  return s3.upload(params).promise()
}

export const getStateFromBucket = (fileName: string) => {
  updateCredentials()

  const s3 = new AWS.S3()
  const params = {
    Bucket: bucketName,
    Key: fileName
  }

  return s3
    .getObject(params)
    .promise()
    .then(d => d.Body.toString())
}
