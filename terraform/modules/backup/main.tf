variable "bucket_name" {}

variable "common_tags" {
  type = "map"
}

resource "aws_s3_bucket" "backup-bucket" {
  bucket = "${var.bucket_name}"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = "${var.common_tags}"
}
