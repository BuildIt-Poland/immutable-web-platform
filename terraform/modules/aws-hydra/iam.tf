# FIXME use data "aws_iam_policy_document" "worker-role-policy" {

resource "aws_iam_role" "instance_role" {
  name = "instance_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY

  tags = var.common_tags
}

resource "aws_iam_role_policy" "full_access_to_s3" {
  name = "full_access_to_s3"
  role = aws_iam_role.instance_role.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_iam_instance_profile" "hydra-profile" {
  name = "hydra-profile"
  role = aws_iam_role.instance_role.name
}