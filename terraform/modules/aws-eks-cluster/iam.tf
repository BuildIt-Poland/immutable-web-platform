AmazonEC2ContainerRegistryReadOnly

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
}

resource "aws_iam_policy" "worker-policy" {
  name        = "${var.cluster_name}_policy"
  path        = "/${var.cluster_name}/"
  description = "Enabling ECR for Kubernetes"
  policy      = data.aws_iam_policy_document.worker-role-policy.json
}
