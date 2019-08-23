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
      "route53:ListResourceRecordSets"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "worker-policy" {
  name        = "${var.cluster_name}_policy"
  path        = "/${var.cluster_name}/"
  description = "Enabling ECR for Kubernetes"
  policy      = data.aws_iam_policy_document.worker-role-policy.json
}
