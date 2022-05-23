#!/bin/bash
 
echo "###########################################"
echo "   Import CA Cert to client Truststrore"
echo "###########################################"
 
CA_CERT="keys/ca.crt"
CA_ALIAS="kafka-ca"
 
echo "# create truststore"
keytool -keystore keys/client.truststore.jks \
        -alias $CA_ALIAS \
        -import \
        -file $CA_CERT \
        -storepass clientsecret \
        -storetype pkcs12 \
        -noprompt