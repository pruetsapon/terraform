resource "null_resource" "shell" {
  provisioner "remote-exec" {
    inline = [
      # install wget
      "sudo yum install wget -y",
      # install postgres
      "sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm",
      "sudo yum install -y postgresql10 postgresql10-server postgresql10-contrib postgresql-devel postgresql10-plperl",
      "sudo /usr/pgsql-10/bin/postgresql-10-setup initdb",
      # start postgres
      "sudo systemctl enable postgresql-10",
      "sudo systemctl start postgresql-10",
      # install dependencies
      "sudo yum install -y perl-DBI perl-DBD-Pg perl-CGI perl-version perl-ExtUtils-MakeMaker perl-DBD-Pg perl-Encode-Locale perl-Sys-Syslog perl-Test-Simple perl-Pod-Parser perl-Time-HiRes perl-Readonly",
      "wget https://bucardo.org/downloads/DBIx-Safe-1.2.5.tar.gz -O DBIx-Safe.tar.gz",
      "tar -xvf DBIx-Safe.tar.gz",
      "mv DBIx-Safe-* DBIx-Safe",
      "cd DBIx-Safe",
      "perl Makefile.PL",
      "make",
      "make test",
      "sudo make install",
      # install bucardo
      "cd",
      "wget https://bucardo.org/downloads/Bucardo-5.6.0.tar.gz -O Bucardo.tar.gz",
      "tar -xvf Bucardo.tar.gz",
      "mv Bucardo-* Bucardo",
      "cd Bucardo",
      "perl Makefile.PL",
      "make",
      "sudo make install",
      # config tmpfiles
      "cat <<EOF > /$HOME/bucardo.conf",
      "d /run/bucardo 0755 root root",
      "EOF",
      "sudo cp /$HOME/bucardo.conf /usr/lib/tmpfiles.d/bucardo.conf",
      # create directory
      "sudo mkdir /var/run/bucardo",
      "sudo chmod 600 /var/run/bucardo",
      "sudo mkdir /var/log/bucardo",
      "sudo chmod 600 /var/log/bucardo",
      # create user and database bucardo
      "sudo su - postgres -c \"psql <<EOF",
      "create user bucardo superuser;",
      "create database bucardo;",
      "alter database bucardo owner to bucardo;",
      "EOF\"",
      # config postgresql
      "echo \"listen_addresses = '*'\" | sudo tee -a /var/lib/pgsql/10/data/postgresql.conf",
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