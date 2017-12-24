#!/bin/bash
#
# generates a root ca certificate
#

# read password from file
CA_PASS=$(cat root_ca.pass)
# cert validity in days
DAYS=9999

# remove old keys
test -f root_ca.key && rm root_ca.key root_ca.pem

# generate key
openssl genrsa -des3 \
  -passout "pass:$CA_PASS" \
  -out root_ca.key 4096

# create certificate
openssl req -x509 -new -nodes \
  -days $DAYS \
  -config root_ca.ini \
  -passin "pass:$CA_PASS" \
  -key root_ca.key -out root_ca.pem

# show certificate
openssl x509 -text -noout -in root_ca.pem
