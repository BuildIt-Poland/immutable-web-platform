import * as cdk from '@aws-cdk/cdk'
import * as s3 from '@aws-cdk/aws-s3'
import { Table, AttributeType, StreamViewType, BillingMode } from '@aws-cdk/aws-dynamodb'

export class AwsStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // TODO make this configurable
    const projectName = "future-is-comming"
    const bucketName = `${projectName}-remote-state`
    const tableName = `${projectName}-remote-state`

    const siteBucket = new s3.Bucket(this, `${bucketName}-bucket`, {
      bucketName,
    })

    new cdk.CfnOutput(this, 'Bucket', { value: siteBucket.bucketName })

    const itemsTable = new Table(this, `${tableName}-dynamodb`, {
      tableName: tableName,
      partitionKey: {
        name: `${tableName}Id`,
        type: AttributeType.String
      },
      billingMode: BillingMode.PayPerRequest,
      streamSpecification: StreamViewType.NewImage
    })

  }
}
