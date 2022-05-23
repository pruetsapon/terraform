resource "null_resource" "shell" {
  provisioner "remote-exec" {
    inline = [
      # install java
      "sudo yum -y update",
      "sudo yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel unzip",
      # set environment hosts file
      "sudo cp /etc/hosts /etc/hosts_backup",
      "echo '${var.host} elastic.local kibana.local logstash.local' | sudo tee -a /etc/hosts",
      # install elasticsearch
      "rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch",
      "cat <<EOF > /$HOME/elasticsearch.repo",
      "[elasticsearch]",
      "name=Elasticsearch repository for 7.x packages",
      "baseurl=https://artifacts.elastic.co/packages/7.x/yum",
      "gpgcheck=1",
      "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch",
      "enabled=0",
      "autorefresh=1",
      "type=rpm-md",
      "EOF",
      "sudo cp /$HOME/elasticsearch.repo /etc/yum.repos.d/elasticsearch.repo",
      "sudo yum install --enablerepo=elasticsearch elasticsearch -y",
      "sudo systemctl enable elasticsearch.service",
      # generate certificate
      "mkdir /$HOME/tmp",
      "cd /$HOME/tmp",
      "cat <<EOF > /$HOME/tmp/instance.yml",
      "instances:",
      "  - name: 'elastic'",
      "    dns: [ 'elastic.local' ]",
      "  - name: 'kibana'",
      "    dns: [ 'kibana.local' ]",
      "  - name: 'logstash'",
      "    dns: [ 'logstash.local' ]",
      "EOF",
      "sudo /usr/share/elasticsearch/bin/elasticsearch-certutil cert --keep-ca-key --pem --in /$HOME/tmp/instance.yml --out /$HOME/tmp/certs.zip",
      "sudo unzip certs.zip -d ./certs",
      "sudo mkdir /etc/elasticsearch/certs",
      "sudo cp /$HOME/tmp/certs/ca/ca.crt /etc/elasticsearch/certs/",
      "sudo cp /$HOME/tmp/certs/elastic/* /etc/elasticsearch/certs/",
      # config elasticsearch
      "sudo cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch_backup.yml",
      "echo 'node.name: elastic' | sudo tee -a /etc/elasticsearch/elasticsearch.yml",
      "echo 'network.host: elastic.local' | sudo tee -a /etc/elasticsearch/elasticsearch.yml",
      "echo 'http.port: 9200' | sudo tee -a /etc/elasticsearch/elasticsearch.yml",
      "echo 'xpack.security.enabled: true' | sudo tee -a /etc/elasticsearch/elasticsearch.yml",
      "echo 'xpack.security.http.ssl.enabled: true' | sudo tee -a /etc/elasticsearch/elasticsearch.yml",
      "echo 'xpack.security.transport.ssl.enabled: true' | sudo tee -a /etc/elasticsearch/elasticsearch.yml",
      "echo 'xpack.security.http.ssl.key: certs/elastic.key' | sudo tee -a /etc/elasticsearch/elasticsearch.yml",
      "echo 'xpack.security.http.ssl.certificate: certs/elastic.crt' | sudo tee -a /etc/elasticsearch/elasticsearch.yml",
      "echo 'xpack.security.http.ssl.certificate_authorities: certs/ca.crt' | sudo tee -a /etc/elasticsearch/elasticsearch.yml",
      "echo 'xpack.security.transport.ssl.key: certs/elastic.key' | sudo tee -a /etc/elasticsearch/elasticsearch.yml",
      "echo 'xpack.security.transport.ssl.certificate: certs/elastic.crt' | sudo tee -a /etc/elasticsearch/elasticsearch.yml",
      "echo 'xpack.security.transport.ssl.certificate_authorities: certs/ca.crt' | sudo tee -a /etc/elasticsearch/elasticsearch.yml",
      "echo 'xpack.security.authc.api_key.enabled: true' | sudo tee -a /etc/elasticsearch/elasticsearch.yml",
      "echo 'discovery.seed_hosts: [ \"elastic.local\" ]' | sudo tee -a /etc/elasticsearch/elasticsearch.yml",
      "echo 'cluster.initial_master_nodes: [ \"elastic\" ]' | sudo tee -a /etc/elasticsearch/elasticsearch.yml",
      "sudo systemctl start elasticsearch",
      # generate password
      # sudo /usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto -u "https://elastic.local:9200"
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