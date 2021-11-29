resource "null_resource" "shell" {
  provisioner "remote-exec" {
    inline = [
      # set environment hosts file
      "sudo cp /etc/hosts /etc/hosts_backup",
      "echo '${var.host} host.local' | sudo tee -a /etc/hosts",
      # create file with data
      "cat <<EOF > /$HOME/test.txt",
      "test",
      "EOF",
      # configure selinux as permissive
      "sudo setenforce 0",
      "sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config",
      # use sudo su as psql
      "sudo su - postgres -c 'psql <<EOF",
      "create database test;",
      "drop database test;",
      "EOF'",
    ]
    connection {
      type = "ssh"
      host = var.host
      user = var.username
      password = var.password
      # private_key = file("private_key.pem")
    }
  }
}