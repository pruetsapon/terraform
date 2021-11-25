resource "null_resource" "shell" {
  provisioner "local-exec" {
    command = "Get-Date > completed.txt"
    interpreter = ["PowerShell", "-Command"]

    environment = {
      FOO = "bar"
      BAR = 1
      BAZ = "true"
    }
  }
}