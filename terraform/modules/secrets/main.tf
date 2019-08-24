
variable "common_tags" {
  type = "map"
}

variable "project_name" {
  default = ""
}

variable "env" {
  default = ""
}

variable "domain" {
  default = ""
}

resource "aws_kms_key" "key-for-secrets" {
  description         = "Key to decrypt secrets.json file, for ${var.project_name}-${var.env}"
  enable_key_rotation = true
  tags = merge(
    var.common_tags,
    map(
      "Name", "KMS key to decrypt secrets.json file"
    )
  )
}

resource "aws_kms_alias" "key-alias" {
  name          = "alias/${replace(var.domain, ".", "-")}"
  target_key_id = aws_kms_key.key-for-secrets.key_id
}

output "secrets-kms-key" {
  value = aws_kms_key.key-for-secrets
}
