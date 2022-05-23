resource "null_resource" "shell" {
  provisioner "remote-exec" {
    inline = [
      # install wget
      "sudo yum install wget -y",
      # set environment hosts file
      "sudo cp /etc/hosts /etc/hosts_backup",
      "echo '${var.host} harbor.local' | sudo tee -a /etc/hosts",
      # install docker ce
      "sudo yum remove docker docker-common docker-selinux docker-engine -y",
      "sudo yum install -y yum-utils device-mapper-persistent-data lvm2 -y",
      "sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo",
      "sudo yum install docker-ce -y",
      # start docker
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      # install docker compose
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose",
      # download harbor
      "cd /opt",
      "sudo wget https://github.com/goharbor/harbor/releases/download/v2.3.4/harbor-online-installer-v2.3.4.tgz -O harbor.tgz",
      "sudo tar -xvf harbor.tgz",
      "sudo rm -rf harbor.tgz",
      # harbor certificate
      "sudo mkdir -p /opt/harbor/cert",
      "sudo cp /$HOME/cert/harbor.local.crt /opt/harbor/cert",
      "sudo cp /$HOME/cert/harbor.local.key /opt/harbor/cert",
      # add certificate to docker
      "sudo mkdir -p /etc/docker/certs.d/harbor.local",
      "sudo cp /$HOME/cert/harbor.local.cert /etc/docker/certs.d/harbor.local",
      "sudo cp /$HOME/cert/harbor.local.key /etc/docker/certs.d/harbor.local",
      "sudo cp /$HOME/cert/ca.crt /etc/docker/certs.d/harbor.local",
      "sudo systemctl restart docker",
      # config harbor
      "sudo cp /opt/harbor/harbor.yml.tmpl /opt/harbor/harbor.yml",
      "sudo sed -i 's+hostname: reg.mydomain.com+hostname: harbor.local+' /opt/harbor/harbor.yml",
      "sudo sed -i 's+certificate: /your/certificate/path+certificate: /opt/harbor/cert/harbor.local.crt+' /opt/harbor/harbor.yml",
      "sudo sed -i 's+private_key: /your/private/key/path+private_key: /opt/harbor/cert/harbor.local.key+' /opt/harbor/harbor.yml",
      "sudo sed -i 's+harbor_admin_password: Harbor12345+harbor_admin_password: P@ssw0rd+' /opt/harbor/harbor.yml",
      # install harbor
      "cd /opt/harbor",
      "sudo ./prepare --with-notary --with-trivy --with-chartmuseum",
      "sudo ./install.sh --with-notary --with-trivy --with-chartmuseum",
      # create harbor service
      "cat <<EOF > /$HOME/harbor.service",
      "[Unit]",
      "Description=Harbor Service",
      "Requires=docker.service",
      "After=docker.service",
      "[Service]",
      "Type=oneshot",
      "RemainAfterExit=yes",
      "WorkingDirectory=/opt/harbor",
      "ExecStart=/usr/local/bin/docker-compose up -d",
      "ExecStop=/usr/local/bin/docker-compose down",
      "TimeoutStartSec=0",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      "sudo cp /$HOME/harbor.service /etc/systemd/system/harbor.service",
      # start harbor
      "sudo systemctl start harbor",
      "sudo systemctl enable harbor"
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