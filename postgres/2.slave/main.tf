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
      "sudo systemctl stop postgresql-10",
      "echo \"listen_addresses = '*'\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      "echo \"hot_standby = on\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      "echo \"wal_level = hot_standby\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      "echo \"synchronous_commit = local\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      "echo \"archive_mode = on\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      "echo \"archive_command = 'cp %p /var/lib/pgsql/10/archive/%f'\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      "echo \"max_wal_senders = 2\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      "echo \"wal_keep_segments = 10\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      "echo \"synchronous_standby_names = 'pgslave001'\" | sudo tee --append /var/lib/pgsql/10/data/postgresql.conf",
      # copy data from master
      "sudo su - postgres -c \"mv /var/lib/pgsql/10/data /var/lib/pgsql/10/data_backup\"",
      "sudo su - postgres -c \"mkdir /var/lib/pgsql/10/data\"",
      "sudo su - postgres -c \"chmod 700 /var/lib/pgsql/10/data\"",
      "sudo su - postgres -c \"pg_basebackup -h ${var.master_ip} -U replica -D /var/lib/pgsql/10/data -P Passw0rd\"",
      # config recovery.conf
      "cat <<EOF > /$HOME/recovery.conf",
      "standby_mode = 'on'",
      "primary_conninfo = 'host=${var.master_ip} port=5432 user=replica password=Passw0rd application_name=pgslave001'",
      "restore_command = 'cp /var/lib/pgsql/10/archive/%f %p'",
      "trigger_file = '/tmp/postgresql.trigger.5432'",
      "EOF",
      "sudo cp /$HOME/recovery.conf /var/lib/pgsql/10/data/recovery.conf",
      "sudo chown -R postgres:postgres /var/lib/pgsql/10/data/recovery.conf",
      "sudo chmod 600 /var/lib/pgsql/10/data/recovery.conf"
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