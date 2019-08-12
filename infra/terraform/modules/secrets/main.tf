
variable "common_tags" {
  type = "map"
}

variable "project_name" {
  default = ""
}

variable "env" {
  default = ""
}

resource "aws_kms_key" "key-for-secrets" {
  description             = "Key to decrypt secrets.json file"
  deletion_window_in_days = 10
  tags = "${merge(
    var.common_tags,
    map(
      "Name", "KMS key to decrypt secrets.json file"
    )
  )}"
}

output "secrets-kms-key" {
  value = aws_kms_key.key-for-secrets
}
