resource "null_resource" "shell" {
  provisioner "remote-exec" {
    inline = [
      # install java
      "sudo yum -y update",
      "sudo yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel unzip",
      # install logstash
      "cat <<EOF > /$HOME/logstash.repo",
      "[logstash-7.x]",
      "name=Elastic repository for 7.x packages",
      "baseurl=https://artifacts.elastic.co/packages/7.x/yum",
      "gpgcheck=1",
      "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch",
      "enabled=1",
      "autorefresh=1",
      "type=rpm-md",
      "EOF",
      "sudo cp /$HOME/logstash.repo /etc/yum.repos.d/logstash.repo",
      "sudo yum install logstash -y",
      "sudo systemctl enable logstash.service",
      # copy certificate
      "sudo mkdir /etc/logstash/certs",
      "sudo cp /$HOME/tmp/certs/ca/ca.crt /etc/logstash/certs/",
      "sudo cp /$HOME/tmp/certs/logstash/* /etc/logstash/certs/",
      # config logstash
      "sudo openssl pkcs8 -in /etc/logstash/certs/logstash.key -topk8 -nocrypt -out /etc/logstash/certs/logstash.pkcs8.key",
      "sudo cp /etc/logstash/logstash.yml /etc/logstash/logstash_backup.yml",
      "echo 'node.name: logstash.local' | sudo tee -a /etc/logstash/logstash.yml",
      "echo 'path.config: /etc/logstash/conf.d/*.conf' | sudo tee -a /etc/logstash/logstash.yml",
      "echo 'xpack.monitoring.enabled: true' | sudo tee -a /etc/logstash/logstash.yml",
      "echo 'xpack.monitoring.elasticsearch.username: logstash_system' | sudo tee -a /etc/logstash/logstash.yml",
      "echo 'xpack.monitoring.elasticsearch.password: \"${var.logstash_password}\"' | sudo tee -a /etc/logstash/logstash.yml",
      "echo 'xpack.monitoring.elasticsearch.hosts: [ \"https://elastic.local:9200\" ]' | sudo tee -a /etc/logstash/logstash.yml",
      "echo 'xpack.monitoring.elasticsearch.ssl.certificate_authority: /etc/logstash/certs/ca.crt' | sudo tee -a /etc/logstash/logstash.yml",
      "cat <<EOF > /$HOME/https.conf",
      "input {",
      "  beats {",
      "    port => 5044",
      "    ssl => true",
      "    ssl_key => '/etc/logstash/certs/logstash.pkcs8.key'",
      "    ssl_certificate => '/etc/logstash/certs/logstash.crt'",
      "  }",
      "}",
      "output {",
      "  elasticsearch {",
      "    ilm_enabled => false",
      "    hosts => ['https://elastic.local:9200']",
      "    cacert => '/etc/logstash/certs/ca.crt'",
      "    user => 'logstash_writer'",
      "    password => '${var.logstash_password}'",
      "  }",
      "}",
      "EOF",
      "sudo cp /$HOME/https.conf /etc/logstash/conf.d/https.conf",
      "sudo systemctl start logstash",
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