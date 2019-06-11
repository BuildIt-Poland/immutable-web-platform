
import { createReadStream } from 'fs'
import { basename, resolve } from 'path'
import * as uuidv1 from 'uuid/v1'

import * as AWS from 'aws-sdk'
import { DocumentClient } from 'aws-sdk/clients/dynamodb'
import { S3 } from 'aws-sdk'

// TODO make aliases instead of this ugly dots
// with aliases after build thru nix, alias is not resolved - investigate
import { tableName, awsRegion, bucketName } from '../../config'
import { stringify } from 'querystring';

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

// TODO this should append next state
export const setLock = (locked: boolean, reason: string) => {
  const credentials = updateCredentials()
  const docClient = new AWS.DynamoDB.DocumentClient()

  const params: DocumentClient.PutItemInput = {
    TableName: tableName,
    Item: {
      "change-id": uuidv1(),
      id: lockerId,
      locked: locked,
      time: new Date().toISOString(),
      timestamp: new Date().getTime(),
      reason,
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
  const params: DocumentClient.QueryInput = {
    TableName: tableName,
    ScanIndexForward: false,
    Limit: 1,
    KeyConditionExpression: "id = :id",
    ExpressionAttributeValues: {
      ":id": lockerId
    }
  }

  return docClient
    .query(params)
    .promise()
    .then(d => d.Items[0])
}

export const uploadState = (file: string, fileName?: string) => {
  updateCredentials()

  const s3 = new AWS.S3()
  const fileStream = createReadStream(resolve(file))
  const params: S3.PutObjectRequest = {
    Bucket: bucketName,
    Key: fileName || basename(file),
    Body: fileStream
  }

  return s3.upload(params).promise()
}

export const uploadStateFromStdout = (stdout: string, fileName: string) => {
  updateCredentials()

  const s3 = new AWS.S3()
  const params: S3.PutObjectRequest = {
    Bucket: bucketName,
    Key: fileName,
    Body: stdout
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
