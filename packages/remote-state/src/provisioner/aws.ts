import * as AWS from 'aws-sdk'
import { tableName, awsRegion } from '../../infra/config' // TODO make aliases instead of this ugly dots
import { DocumentClient } from 'aws-sdk/clients/dynamodb'

const lockerId = 'locker'

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

export const getState = () => {

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