#!/bin/bash
#
# generates a wildcard (multi-domain) server certificate
#

# cert validity in days
DAYS=9999
CERTS="./certs"

ROOT_PASS="$CERTS/root_ca.pass"
ROOT_KEY="$CERTS/root_ca.key"
ROOT_CRT="$CERTS/root_ca.crt"
ROOT_SRL="$CERTS/root_ca.srl"

KEY="$CERTS/star.key"
CSR="$CERTS/star.csr"
CRT="$CERTS/star.crt"
PFX="$CERTS/star.pfx"
PFX_PASS="$CERTS/star.pfx.pass"
CHAIN="$CERTS/star_chained.crt"

PASSWORD="password"

# ----

CA_SERIAL="-CAcreateserial"
if [ -f "$ROOT_SRL" ]; then
  CA_SERIAL="-CAserial $ROOT_SRL"
fi

# remove old keys
test -f $KEY && rm $KEY $CSR $CRT $CHAIN $PFX $PFX_PASS

# generate key
openssl genrsa -out $KEY 4096

# create certificate
openssl req -new \
  -config star.ini \
  -key $KEY -out $CSR

# sign certificate
openssl x509 -req -days $DAYS \
  -CA $ROOT_CRT -CAkey $ROOT_KEY \
  $CA_SERIAL \
  -sha256 \
  -passin "file:$ROOT_PASS" \
  -extensions v3_req \
  -extfile star.ini \
  -in $CSR -out $CRT

# chain certs (e.g. for HAProxy)
cat $CRT $KEY > $CHAIN

# generate PKCS12
echo $PASSWORD > $PFX_PASS
openssl pkcs12 -export \
  -passout "file:$PFX_PASS" \
  -in $CRT -inkey $KEY \
  -certfile $ROOT_CRT \
  -out $PFX

# show certificate
# openssl x509 -text -noout -in $CRT
