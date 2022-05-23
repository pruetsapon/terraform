resource "null_resource" "shell" {
  provisioner "remote-exec" {
    inline = [
      # install wget
      "sudo yum install epel-release wget -y",
      # install java
      "sudo yum install java-11-openjdk-devel -y",
      # set environment variables
      "sudo cp /etc/profile /etc/profile_backup",
      "echo 'export JAVA_HOME=/usr/lib/jvm/jre-11-openjdk' | sudo tee -a /etc/profile",
      "echo 'export JRE_HOME=/usr/lib/jvm/jre' | sudo tee -a /etc/profile",
      "source /etc/profile",
      # install jenkin
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo --no-check-certificate",
      "sudo yum install jenkins -y",
      # start jenkin
      "sudo systemctl start jenkins",
      "sudo systemctl enable jenkins",
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