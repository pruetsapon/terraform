resource "null_resource" "shell" {
  provisioner "remote-exec" {
    inline = [
      # create mongodb repo
      "cat <<EOF > /$HOME/mongodb.repo",
      "[mongodb-org-4.4]",
      "name=MongoDB Repository",
      "baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.4/x86_64/",
      "gpgcheck=1",
      "enabled=1",
      "gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc",
      "EOF",
      "sudo cp /$HOME/mongodb.repo /etc/yum.repos.d/mongodb.repo",
      # install mongodb
      "sudo yum install -y mongodb-org",
      # start mongodb
      "systemctl enable mongod",
      "systemctl start mongod",
    ]
    connection {
      type = "ssh"
      host = var.host
      user = var.username
      password = var.password
      #private_key = file("private_key.pem")
    }
  }
}