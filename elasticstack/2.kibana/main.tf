resource "null_resource" "shell" {
  provisioner "remote-exec" {
    inline = [
      # install java
      "sudo yum -y update",
      "sudo yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel unzip",
      # install kibana
      "cat <<EOF > /$HOME/kibana.repo",
      "[kibana-7.x]",
      "name=Kibana repository for 7.x packages",
      "baseurl=https://artifacts.elastic.co/packages/7.x/yum",
      "gpgcheck=1",
      "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch",
      "enabled=1",
      "autorefresh=1",
      "type=rpm-md",
      "EOF",
      "sudo cp /$HOME/kibana.repo /etc/yum.repos.d/kibana.repo",
      "sudo yum install kibana -y",
      "sudo systemctl enable kibana.service",
      # copy certificate
      "sudo mkdir /etc/kibana/certs",
      "sudo cp /$HOME/tmp/certs/ca/ca.crt /etc/kibana/certs/",
      "sudo cp /$HOME/tmp/certs/kibana/* /etc/kibana/certs/",
      # config kibana
      "sudo cp /etc/kibana/kibana.yml /etc/kibana/kibana_backup.yml",
      "echo 'server.port: 5601' | sudo tee -a /etc/kibana/kibana.yml",
      "echo 'server.host: \"kibana.local\"' | sudo tee -a /etc/kibana/kibana.yml",
      "echo 'server.name: \"kibana.local\"' | sudo tee -a /etc/kibana/kibana.yml",
      "echo 'elasticsearch.hosts: [\"https://elastic.local:9200\"]' | sudo tee -a /etc/kibana/kibana.yml",
      "echo 'server.ssl.enabled: true' | sudo tee -a /etc/kibana/kibana.yml",
      "echo 'server.ssl.certificate: /etc/kibana/certs/kibana.crt' | sudo tee -a /etc/kibana/kibana.yml",
      "echo 'server.ssl.key: /etc/kibana/certs/kibana.key' | sudo tee -a /etc/kibana/kibana.yml",
      "echo 'xpack.fleet.enabled: true' | sudo tee -a /etc/kibana/kibana.yml",
      "echo 'xpack.fleet.agents.tlsCheckDisabled: true' | sudo tee -a /etc/kibana/kibana.yml",
      "echo 'xpack.encryptedSavedObjects.encryptionKey: \"j2Yb4X2a3PEHu0icpkg4Ry4oESvjuxPY\"' | sudo tee -a /etc/kibana/kibana.yml",
      "echo 'xpack.security.enabled: true' | sudo tee -a /etc/kibana/kibana.yml",
      "echo 'elasticsearch.username: \"kibana\"' | sudo tee -a /etc/kibana/kibana.yml",
      "echo 'elasticsearch.password: \"${var.kibana_password}\"' | sudo tee -a /etc/kibana/kibana.yml",
      "echo 'elasticsearch.ssl.certificateAuthorities: [ \"/etc/kibana/certs/ca.crt\" ]' | sudo tee -a /etc/kibana/kibana.yml",
      "sudo systemctl start kibana",
      # update ca certificates
      "sudo yum install ca-certificates -y",
      "sudo update-ca-trust force-enable",
      "sudo cp /$HOME/tmp/certs/ca/ca.crt /etc/pki/ca-trust/source/anchors/",
      "sudo update-ca-trust extract",
      # create role: logstash_write_role
      #  - cluster: monitor, manage_index_templates
      #  - indices: logstash-*
      #  - privileges: write, create_index
      # create user: logstash_writer
      #  - roles: logstash_write_role
      #  - password: same logstash_system
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