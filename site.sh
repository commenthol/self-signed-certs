#!/bin/bash
#
# generates a server certificate for a single site
#
# CN and subjectAltName in site.ini needs to match your domain e.g. `aa.aa`
# ```
# CN = aa.aa
# ...
# subjectAltName = DNS:aa.aa
# ```
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
test -f site.key && rm site.key site.csr site.crt

# generate key
openssl genrsa -out site.key 4096

# create certificate
openssl req -new \
  -config site.ini \
  -key site.key -out site.csr

# sign certificate
openssl x509 -req -days $DAYS \
  -CA root_ca.pem -CAkey root_ca.key \
  $CA_SERIAL \
  -passin "pass:$CA_PASS" \
  -extensions v3_req \
  -extfile site.ini \
  -in site.csr -out site.crt

# show certificate
openssl x509 -text -noout -in site.crt
