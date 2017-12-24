#!/bin/bash
#
# generates a wildcard (multi-domain) server certificate
#

# read password from file
CA_PASS=$(cat root_ca.pass)
# cert validity in days
DAYS=9999

# ----

CA_SERIAL="-CAcreateserial"
if [ -f root_ca.srl ]; then
  CA_SERIAL="-CAserial root_ca.srl"
fi

# remove old keys
test -f star.key && rm star.key star.csr star.crt star_chained.crt

# generate key
openssl genrsa -out star.key 4096

# create certificate
openssl req -new \
  -config star.ini \
  -key star.key -out star.csr

# sign certificate
openssl x509 -req -days $DAYS \
  -CA root_ca.pem -CAkey root_ca.key \
  $CA_SERIAL \
  -passin "pass:$CA_PASS" \
  -extensions v3_req \
  -extfile star.ini \
  -in star.csr -out star.crt

# chain certs (e.g. for HAProxy)
cat root_ca.pem star.crt star.key > star_chained.crt

# show certificate
openssl x509 -text -noout -in star.crt
