variable "region" {}
variable "bucket" {}
variable "dynamo_db" {}
variable "state_path" {}
variable "common_tags" {}

resource "aws_s3_bucket" "tf-state" {
  bucket = var.bucket
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = merge(
    var.common_tags,
    map(
      "Name", "Terraform State Lock Bucket"
    )
  )
}

resource "aws_dynamodb_table" "dynamodb-tf-state-lock" {
  name           = var.dynamo_db
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    var.common_tags,
    map(
      "Name", "DynamoDB Terraform State Lock Table"
    )
  )
}
