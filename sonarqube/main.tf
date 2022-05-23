resource "null_resource" "shell" {
  provisioner "remote-exec" {
    inline = [
      # install wget and unzip
      "sudo yum install wget unzip -y",
      # install java
      "sudo yum install java-11-openjdk-devel -y",
      # set environment variables
      "sudo cp /etc/profile /etc/profile_backup",
      "echo 'export JAVA_HOME=/usr/lib/jvm/jre-11-openjdk' | sudo tee -a /etc/profile",
      "echo 'export JRE_HOME=/usr/lib/jvm/jre' | sudo tee -a /etc/profile",
      "source /etc/profile",
      # configure selinux as permissive
      "sudo setenforce 0",
      "sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config",
      # tweak max_map_count and fs.file-max
      "echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf",
      "echo 'fs.file-max=65536' | sudo tee -a /etc/sysctl.conf",
      # create user sonarqube
      "sudo useradd --system --no-create-home sonarqube",
      # install and configure postgresql
      "sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm",
      "sudo yum install -y postgresql14-server postgresql14",
      "sudo /usr/pgsql-14/bin/postgresql-14-setup initdb",
      # start postgresql
      "sudo systemctl start postgresql-14",
      "sudo systemctl enable postgresql-14",
      # config postgresql
      "cat <<EOF > /$HOME/pg_hba.conf",
      "# TYPE  DATABASE        USER            ADDRESS                 METHOD",
      "# \"local\" is for Unix domain socket connections only",
      "local   all             all                                     trust",
      "# IPv4 local connections:",
      "host    all             all             127.0.0.1/32            md5",
      "# IPv6 local connections:",
      "host    all             all             ::1/128                 md5",
      "# Allow replication connections from localhost, by a user with the",
      "# replication privilege.",
      "local   replication     all                                     peer",
      "host    replication     all             127.0.0.1/32            md5",
      "host    replication     all             ::1/128                 md5",
      "EOF",
      "sudo cp /var/lib/pgsql/14/data/pg_hba.conf /var/lib/pgsql/14/data/pg_hba_backup.conf",
      "sudo cp /$HOME/pg_hba.conf /var/lib/pgsql/14/data/pg_hba.conf",
      "sudo systemctl restart postgresql-14",
      # create user and database sonarqube
      "sudo su - postgres -c \"psql <<EOF",
      "create user sonarqube;",
      "create database sonarqube_db owner sonarqube;",
      "grant all privileges on database sonarqube_db to sonarqube;",
      "alter user sonarqube with password 'Passw0rd';",
      "EOF\"",
      # download sonarqube
      "cd /opt",
      "sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.2.1.49989.zip -O sonarqube.zip",
      "sudo unzip sonarqube.zip",
      "sudo mv sonarqube-* sonarqube",
      "sudo rm sonarqube.zip",
      # config sonarqube
      "sudo cp /opt/sonarqube/conf/sonar.properties /opt/sonarqube/conf/sonar_backup.properties",
      "sudo sed -i 's+#sonar.jdbc.username=+sonar.jdbc.username=sonarqube+' /opt/sonarqube/conf/sonar.properties",
      "sudo sed -i 's+#sonar.jdbc.password=+sonar.jdbc.password=Passw0rd+' /opt/sonarqube/conf/sonar.properties",
      "sudo sed -i 's+#sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube?currentSchema=my_schema+sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube_db+' /opt/sonarqube/conf/sonar.properties",
      "sudo sed -i 's+#sonar.web.host=0.0.0.0+sonar.web.host=0.0.0.0+' /opt/sonarqube/conf/sonar.properties",
      "sudo sed -i 's+#sonar.web.port=9000+sonar.web.port=9000+' /opt/sonarqube/conf/sonar.properties",
      "sudo sed -i 's/^#sonar.web.javaOpts=-Xmx512m -Xms128m -XX:+HeapDumpOnOutOfMemoryError$/sonar.web.javaOpts=-server -Xms512m -Xmx512m -XX:+HeapDumpOnOutOfMemoryError/' /opt/sonarqube/conf/sonar.properties",
      "sudo sed -i 's/^#sonar.search.javaOpts=-Xmx512m -Xms512m -XX:MaxDirectMemorySize=256m -XX:+HeapDumpOnOutOfMemoryError$/sonar.search.javaOpts=-server -Xms512m -Xmx512m -XX:+HeapDumpOnOutOfMemoryError/' /opt/sonarqube/conf/sonar.properties",
      "sudo sed -i 's+#sonar.path.data=data+sonar.path.data=/var/sonarqube/data+' /opt/sonarqube/conf/sonar.properties",
      "sudo sed -i 's+#sonar.path.temp=temp+sonar.path.temp=/var/sonarqube/temp+' /opt/sonarqube/conf/sonar.properties",
      "sudo cp /opt/sonarqube/conf/wrapper.conf /opt/sonarqube/conf/wrapper_backup.conf",
      "sudo sed -i 's+wrapper.java.command=java+wrapper.java.command=/usr/lib/jvm/jre-11-openjdk/bin/java+' /opt/sonarqube/conf/wrapper.conf",
      # change ownership to sonarqube
      "sudo chown -R sonarqube:sonarqube /opt/sonarqube",
      "sudo mkdir -p /var/sonarqube/data",
      "sudo mkdir -p /var/sonarqube/temp",
      "sudo chown -R sonarqube:sonarqube /var/sonarqube",
      # create sonarqube service
      "cat <<EOF > /$HOME/sonarqube.service",
      "[Unit]",
      "Description=SonarQube service",
      "After=syslog.target network.target",
      "[Service]",
      "Type=forking",
      "ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start",
      "ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop",
      "LimitNOFILE=65536",
      "LimitNPROC=4096",
      "User=sonarqube",
      "Group=sonarqube",
      "Restart=on-failure",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      "sudo cp /$HOME/sonarqube.service /etc/systemd/system/sonarqube.service",
      # start sonarqube
      "sudo systemctl start sonarqube",
      "sudo systemctl enable sonarqube",
      "sudo reboot"
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