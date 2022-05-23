resource "null_resource" "shell" {
  provisioner "remote-exec" {
    inline = [
      # install postgresql
      "sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm",
      "sudo yum install -y postgresql10-server",
      "sudo /usr/pgsql-10/bin/postgresql-10-setup initdb",
      # start postgresql
      "sudo systemctl enable postgresql-10",
      "sudo systemctl start postgresql-10",
      # config postgresql.conf
      "echo \"listen_addresses = '*'\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      "echo \"wal_level = hot_standby\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      "echo \"synchronous_commit = local\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      "echo \"archive_mode = on\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      "echo \"archive_command = 'cp %p /var/lib/pgsql/10/archive/%f'\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      "echo \"max_wal_senders = 2\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      "echo \"wal_keep_segments = 10\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      "echo \"synchronous_standby_names = 'pgslave001'\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      # create archive directory
      "sudo mkdir -p /var/lib/pgsql/10/archive",
      "sudo chmod 700 /var/lib/pgsql/10/archive",
      "sudo chown -R postgres:postgres /var/lib/pgsql/10/archive",
      # config pg_hba.conf
      "cat <<EOF > /$HOME/pg_hba.conf",
      "# TYPE  DATABASE        USER            ADDRESS                 METHOD",
      "# \"local\" is for Unix domain socket connections only",
      "local   all             all                                     trust",
      "# IPv4 local connections:",
      "host    all             all             all                     md5",
      "# IPv6 local connections:",
      "host    all             all             ::1/128                 md5",
      "# Allow replication connections from localhost, by a user with the",
      "# replication privilege.",
      "local   replication     all                                     peer",
      "host    replication     all             all                     md5",
      "host    replication     all             ::1/128                 md5",
      "# Localhost",
      "host    replication     replica         all                     md5",
      "# PostgreSQL Master IP address",
      "host    replication     replica         all                     md5",
      "# PostgreSQL SLave IP address",
      "host    replication     replica         all                     md5",
      "EOF",
      "sudo cp /var/lib/pgsql/10/data/pg_hba.conf /var/lib/pgsql/10/data/pg_hba_backup.conf",
      "sudo cp /$HOME/pg_hba.conf /var/lib/pgsql/10/data/pg_hba.conf",
      "sudo systemctl restart postgresql-10",
      # create user replica
      "sudo su - postgres -c \"psql <<EOF",
      "create user replica replication login encrypted with password 'Passw0rd';",
      "EOF\"",
      # test
      # psql -c "select application_name, state, sync_priority, sync_state from pg_stat_replication;"
      # psql -x -c "select * from pg_stat_replication;"
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