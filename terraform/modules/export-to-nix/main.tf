# to generate this file run 
# Handly to avoid coupling modules with remote_state
resource "null_resource" "vars" {
  provisioner "local-exec" {
    command = <<EXEC
      echo '${jsonencode(var.data)}' | jq . > ${var.file-output}
    EXEC
  }
}
