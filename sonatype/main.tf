resource "null_resource" "shell" {
  provisioner "remote-exec" {
    inline = [
      # install java and wget
      "sudo yum install wget -y",
      "sudo yum install java-1.8.0-openjdk.x86_64 -y",
      # create directory and download nexus
      "sudo mkdir -p /opt/nexus && cd /opt/nexus",
      "sudo wget -O nexus.tar.gz https://download.sonatype.com/nexus/3/latest-unix.tar.gz",
      "sudo tar -xvf nexus.tar.gz",
      "sudo rm -rf nexus.tar.gz",
      "sudo mv nexus-3* nexus",
      # create user nexus
      "sudo adduser nexus",
      "mkdir /$HOME/nexus",
      # set run_as_user parameter
      "echo 'run_as_user=\"nexus\"' | sudo tee -a /opt/nexus/nexus/bin/nexus.rc",
      # create and backup nexus configuration
      "sudo sed -i 's+-Dkaraf.data=../sonatype-work/nexus3+-Dkaraf.data=/opt/nexus/sonatype-work/nexus3+' /opt/nexus/nexus/bin/nexus.vmoptions",
      # change ownership to nexus
      "sudo chown -R nexus:nexus /opt/nexus",
      # create nexus service
      "cat <<EOF > /$HOME/nexus.service",
      "[Unit]",
      "Description=nexus service",
      "After=network.target",
      "[Service]",
      "Type=forking",
      "LimitNOFILE=65536",
      "User=nexus",
      "Group=nexus",
      "ExecStart=/opt/nexus/nexus/bin/nexus start",
      "ExecStop=/opt/nexus/nexus/bin/nexus stop",
      "User=nexus",
      "Restart=on-abort",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      "sudo cp /$HOME/nexus.service /etc/systemd/system/nexus.service",
      # start nexus
      "sudo systemctl start nexus",
      "sudo systemctl enable nexus"
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