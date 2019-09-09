
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

resource "null_resource" "create-secret-file-on-root" {
  depends_on = [aws_kms_alias.key-alias]

  provisioner "local-exec" {
    command = <<BASH
      echo "Creating secrets file based on secret key kms"
      sops --kms ${aws_kms_alias.key-alias.arn} \
        -e ${var.root_folder}/secrets.template.json \
        > ${var.root_folder}/secrets.json
    BASH
  }
}

output "secrets-kms-key" {
  value = aws_kms_key.key-for-secrets
}