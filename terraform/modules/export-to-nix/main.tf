# to generate this file run 
resource "null_resource" "vars" {
  provisioner "local-exec" {
    command = <<EXEC
      echo '${jsonencode(var.data)}' | jq . > ${var.file-output}
    EXEC
  }
}
