resource "null_resource" "shell" {
  provisioner "remote-exec" {
    inline = [
      # install environment
      "sudo yum install -y gcc gcc-c++ pcre pcre-devel zlib zlib-devel openssl openssl-devel git",
      # setup number of open files limited in Linux
      "echo \"* hard nofile 4096\" | sudo tee --append /etc/security/limits.conf",
      "echo \"* soft nofile 4096\" | sudo tee --append /etc/security/limits.conf",
      # install postgresql
      "sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm",
      "sudo yum install -y postgresql10-server",
      "sudo /usr/pgsql-10/bin/postgresql-10-setup initdb",
      # start postgresql
      "sudo systemctl enable postgresql-10",
      "sudo systemctl start postgresql-10",
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
      "sudo cp /var/lib/pgsql/10/data/pg_hba.conf /var/lib/pgsql/10/data/pg_hba_backup.conf",
      "sudo cp /$HOME/pg_hba.conf /var/lib/pgsql/10/data/pg_hba.conf",
      "sudo systemctl restart postgresql-10",
      # create postgresql user kong and konga
      "sudo su - postgres -c \"psql <<EOF",
      "create user kong with password 'Passw0rd';",
      "create database kong owner kong;",
      "grant all privileges on database kong to kong;",
      "create user konga with password 'Passw0rd';",
      "create database konga owner konga;",
      "grant all privileges on database konga to konga;",
      "EOF\"",
      # install kong
      "curl -Lo kong-2.7.0.rpm $(rpm --eval \"https://download.konghq.com/gateway-2.x-centos-7/Packages/k/kong-2.7.0.el7.amd64.rpm\")",
      "sudo yum install -y kong-2.7.0.rpm",
      # config kong
      "sudo cp /etc/kong/kong.conf.default /etc/kong/kong.conf",
      "echo 'admin_listen = 0.0.0.0:8001' | sudo tee -a /etc/kong/kong.conf",
      "echo 'database = postgres' | sudo tee -a /etc/kong/kong.conf",
      "echo 'pg_host = 127.0.0.1' | sudo tee -a /etc/kong/kong.conf",
      "echo 'pg_port 5432' | sudo tee -a /etc/kong/kong.conf",
      "echo 'pg_user = kong' | sudo tee -a /etc/kong/kong.conf",
      "echo 'pg_password = Passw0rd' | sudo tee -a /etc/kong/kong.conf",
      "echo 'pg_database = kong' | sudo tee -a /etc/kong/kong.conf",
      "sudo /usr/local/bin/kong migrations bootstrap -c /etc/kong/kong.conf",
      "sudo chown -R kong:kong /usr/local/kong",
      # create kong service
      "cat <<EOF > /$HOME/kong.service",
      "[Unit]",
      "Description=kong service",
      "After=syslog.target network.target",
      "[Service]",
      "User=kong",
      "Group=kong",
      "Type=forking",
      "ExecStart=/usr/local/bin/kong start -c /etc/kong/kong.conf",
      "ExecReload=/usr/local/bin/kong reload",
      "ExecStop=/usr/local/bin/kong stop",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      "sudo cp /$HOME/kong.service /etc/systemd/system/kong.service",
      # start kong
      "sudo systemctl enable kong",
      "sudo systemctl start kong",
      # install nodejs
      "curl -sL https://rpm.nodesource.com/setup_12.x | sudo bash -",
      "sudo yum install -y nodejs",
      "sudo npm install npm@latest -g",
      "sudo npm install -g gulp bower sails",
      # install konga
      "git clone https://github.com/pantsel/konga.git",
      "cd konga",
      "npm i",
      "node ./bin/konga.js prepare --adapter postgres --uri postgresql://konga:Passw0rd@127.0.0.1:5432/konga",
      "cd",
      "sudo mv konga /opt",
      "sudo chown -R kong:kong /opt/konga",
      # config konga
      "cat <<EOF > .env",
      "HOST=0.0.0.0",
      "PORT=1337",
      "NODE_ENV=production",
      "KONGA_HOOK_TIMEOUT=120000",
      "DB_ADAPTER=postgres",
      "DB_USER=konga",
      "DB_PASSWORD=Passw0rd",
      "DB_PORT=5432",
      "DB_DATABASE=konga",
      "KONGA_LOG_LEVEL=warn",
      "TOKEN_SECRET=secret_token",
      "EOF",
      # create konga service
      "cat <<EOF > /$HOME/konga.service",
      "[Unit]",
      "Description=konga service",
      "After=network.target",
      "[Service]",
      "User=kong",
      "Group=kong",
      "Type=simple",
      "ExecStart=/usr/bin/node /opt/konga/app.js",
      "WorkingDirectory=/opt/konga",
      "Restart=on-failure",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      "sudo cp /$HOME/konga.service /etc/systemd/system/konga.service",
      # start konga
      "sudo systemctl enable konga",
      "sudo systemctl start konga",
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