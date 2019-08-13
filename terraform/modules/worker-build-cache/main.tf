resource "aws_s3_bucket" "worker-bucket" {
  bucket = "${var.bucket}"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = "${var.common_tags}"

  #   policy = <<POLICY
  # {
  #   "Id": "DirectReads",
  #   "Version": "2012-10-17",
  #   "Statement": [
  #       {
  #           "Sid": "AllowDirectReads",
  #           "Action": [
  #               "s3:GetObject",
  #               "s3:GetBucketLocation"
  #           ],
  #           "Effect": "Allow",
  #           "Resource": [
  #               "arn:aws:s3:::${var.bucket}",
  #               "arn:aws:s3:::${var.bucket}/*"
  #           ],
  #           "Principal": "*"
  #       }
  #   ]
  # }
  #   POLICY
}
