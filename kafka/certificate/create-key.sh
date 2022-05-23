#!/bin/bash
 
echo "##################################"
echo "            Generate KEY"
echo "##################################"
# Create CA
echo "# clear old key"
rm -rf gen-key
 
mkdir gen-key
 
echo 01 > gen-key/serial.txt
touch gen-key/index.txt
 
echo "##### 1) GEN CA KEY #####"
VALIDITY=3650
CA_KEY="gen-key/ca.key"
CA_CERT="gen-key/ca.crt"
CA_ALIAS="kafka-ca"
 
openssl req \
    -config openssl-ca.cnf \
    -new \
    -newkey rsa:4096 \
    -days $VALIDITY \
    -x509 -subj "/CN=Kafka-Security-CA" \
    -keyout $CA_KEY \
    -out $CA_CERT \
    -nodes
     
gen_key() {
    echo "##### 2) GEN KAFKA KEY #####"
    KAFKA_PWD="$1"
    KAFKA_KEYSTORE="gen-key/$2"
    KAFKA_TRUSTSTORE="gen-key/$3"
    KAFKA_CSR="gen-key/$4"
    KAFKA_SIGNED="gen-key/$5"
    KAFKA_ALIAS="$6"
     
    echo "# gen keystore"
    keytool -genkey \
            -keyalg RSA \
            -keysize 4096 \
            -alias $KAFKA_ALIAS \
            -keystore $KAFKA_KEYSTORE \
            -validity $VALIDITY \
            -storepass $KAFKA_PWD \
            -keypass $KAFKA_PWD \
            -dname "CN=$6" \
            -storetype pkcs12
 
    echo "# gen cert request"
    keytool -keystore $KAFKA_KEYSTORE \
            -certreq \
            -alias $KAFKA_ALIAS \
            -file $KAFKA_CSR \
            -storepass $KAFKA_PWD \
            -keypass $KAFKA_PWD \
            -ext SAN=DNS:localhost,IP:$6
 
    echo "# Sign"
    openssl ca -config openssl-ca.cnf \
            -policy signing_policy \
            -extensions signing_req \
            -out $KAFKA_SIGNED \
            -infiles $KAFKA_CSR
 
    echo "# create truststore"
    keytool -keystore $KAFKA_TRUSTSTORE \
            -alias $CA_ALIAS \
            -import \
            -file $CA_CERT \
            -storepass $KAFKA_PWD \
            -noprompt
 
    echo "# import signed cert"
    keytool -keystore $KAFKA_KEYSTORE \
            -alias $CA_ALIAS \
            -import \
            -file $CA_CERT \
            -storepass $KAFKA_PWD \
            -noprompt
    keytool -keystore $KAFKA_KEYSTORE \
            -alias $KAFKA_ALIAS \
            -import \
            -file $KAFKA_SIGNED \
            -storepass $KAFKA_PWD \
            -noprompt
}
 
gen_key "kkP@ssw0rd" "keystore.jks" "truststore.jks" "kafka-1-csr-file" "kafka-1-crt-file" "52.221.202.113"
#gen_key "kafkasecret" "kafka-2.keystore.jks" "kafka-2.truststore.jks" "kafka-2-csr-file" "kafka-2-crt-file" "159.89.198.249"
#gen_key "kafkasecret" "kafka-3.keystore.jks" "kafka-3.truststore.jks" "kafka-3-csr-file" "kafka-3-crt-file" "128.199.182.114"
