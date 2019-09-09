resource "aws_s3_bucket" "worker-bucket" {
  bucket = "${var.bucket}"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = "${var.common_tags}"
}
