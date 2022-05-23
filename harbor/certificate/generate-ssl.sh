#!/bin/bash
openssl genrsa -out ca.key 4096

openssl req -x509 -new -nodes -sha512 -days 3650 -subj "/C=CN/ST=Harbor/L=Harbor/O=Harbor/OU=IT/CN=harbor.local" -key ca.key -out ca.crt

openssl genrsa -out harbor.local.key 4096

openssl req -sha512 -new -subj "/C=CN/ST=Harbor/L=Harbor/O=Harbor/OU=Personal/CN=harbor.local" -key harbor.local.key -out harbor.local.csr

cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=harbor.local
DNS.2=harbor.local
DNS.3=harbor.local
EOF

openssl x509 -req -sha512 -days 3650 -extfile v3.ext -CA ca.crt -CAkey ca.key -CAcreateserial -in harbor.local.csr -out harbor.local.crt

openssl x509 -inform PEM -in harbor.local.crt -out harbor.local.cert