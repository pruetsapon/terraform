resource "null_resource" "shell" {
  provisioner "remote-exec" {
    inline = [
      # install filebeat
      "sudo rpm -ivh https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.10.1-x86_64.rpm",
      "sudo mkdir /etc/filebeat/certs",
      "sudo cp /$HOME/tmp/certs/ca/ca.crt /etc/filebeat/certs/",
      "sudo cp /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.bkp",
      "cat <<EOF > /$HOME/filebeat.yml",
      "filebeat.inputs:",
      "- type: log",
      "  enabled: true",
      "  paths:",
      "    - /var/log/*.log",
      "output.logstash:",
      "  hosts: [\"logstash.local:5044\"]",
      "  ssl.certificate_authorities:",
      "    - /etc/filebeat/certs/ca.crt",
      "EOF",
      "sudo cp /$HOME/filebeat.yml /etc/filebeat/filebeat.yml",
      "sudo systemctl start filebeat",
      "sudo systemctl enable filebeat",
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