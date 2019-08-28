data "aws_iam_policy_document" "worker-role-policy" {
  statement {
    actions = [
      "ecr:CreateRepository",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]

    effect    = "Allow"
    resources = ["*"]
  }

  # s3 for valero (https://velero.io/docs/v1.0.0/aws-config/)
  statement {
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:ListBucket"
    ]

    effect    = "Allow"
    resources = ["*"]
  }

  # https://github.com/kubernetes-incubator/external-dns/blob/master/docs/tutorials/aws.md#setting-up-externaldns-for-services-on-aws
  statement {
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    effect    = "Allow"
    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListHostedZonesByName"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  # cert manager
  statement {
    actions = [
      "route53:GetChange",
    ]
    effect    = "Allow"
    resources = ["arn:aws:route53:::change/*"]
  }
}

resource "aws_iam_policy" "worker-policy" {
  name        = "${var.cluster_name}_policy"
  path        = "/${var.cluster_name}/"
  description = "Enabling ECR for Kubernetes"
  policy      = data.aws_iam_policy_document.worker-role-policy.json
}
