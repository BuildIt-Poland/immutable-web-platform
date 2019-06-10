import * as cdk from '@aws-cdk/cdk'
import * as s3 from '@aws-cdk/aws-s3'
import { Table, AttributeType, StreamViewType, BillingMode } from '@aws-cdk/aws-dynamodb'
import { BlockPublicAccess } from '@aws-cdk/aws-s3'

import { bucketName, tableName } from 'config'

export class AwsStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);


    const siteBucket = new s3.Bucket(this, `${bucketName}-bucket`, {
      bucketName,
      versioned: true,
      publicReadAccess: false,
      blockPublicAccess: BlockPublicAccess.BlockAll,
    })

    new cdk.CfnOutput(this, 'Bucket', { value: siteBucket.bucketName })

    const itemsTable = new Table(this, `${tableName}-dynamodb`, {
      tableName: tableName,
      partitionKey: {
        name: `id`, // changing this id makes aws-cdk very unhappy
        type: AttributeType.String
      },
      billingMode: BillingMode.PayPerRequest,
      streamSpecification: StreamViewType.NewImage
    })

  }
}
