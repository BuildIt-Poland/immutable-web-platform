
variable "common_tags" {
  type = "map"
}

variable "project_name" {
  default = ""
}

variable "root_folder" {

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

resource "null_resource" "create-secret-file" {
  depends_on = [aws_kms_alias.key-alias]

  provisioner "local-exec" {
    command = <<BASH
      echo "creating sops ${aws_kms_alias.key-alias.arn} ${var.root_folder}"
    BASH
      # sops
  }
}

output "secrets-kms-key" {
  value = aws_kms_key.key-for-secrets
}