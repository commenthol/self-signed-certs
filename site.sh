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

# cert validity in days
DAYS=375
# certificate directory
CERTS="./certs"
# certificate name
NAME="site"
# domain
CN=aa.aa

# ----

INI="$NAME.ini"

(cat << EOS
[req]
prompt = no
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]
C = AA
ST = Frogstar
L = City
O = AA Server
CN = $CN
emailAddress = info@$CN

[v3_req]
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = DNS:$CN

EOS
) > $INI

# ----

ROOT_PASS="$CERTS/root_ca.pass"
ROOT_KEY="$CERTS/root_ca.key"
ROOT_CRT="$CERTS/root_ca.crt"
ROOT_SRL="$CERTS/root_ca.srl"

KEY="$CERTS/$NAME.key"
CSR="$CERTS/$NAME.csr"
CRT="$CERTS/$NAME.crt"
PFX="$CERTS/$NAME.pfx"
PFX_PASS="$CERTS/$NAME.pfx.pass"
CHAIN="$CERTS/${NAME}_chained.crt"

PASSWORD=$(openssl rand -base64 50 | tr -dc "[:print:]" | head -c 40)

# ----

test ! -f $ROOT_CRT && ./root_ca.sh

CA_SERIAL="-CAcreateserial"
if [ -f "$ROOT_SRL" ]; then
  CA_SERIAL="-CAserial $ROOT_SRL"
fi

# remove old keys
test -f $KEY && rm $KEY $CSR $CRT $CHAIN $PFX $PFX_PASS

# generate key
openssl genrsa -out $KEY 4096

# create certificate signing request
openssl req -new \
  -config $INI \
  -key $KEY -out $CSR

# sign certificate
openssl x509 -req \
  -days $DAYS \
  -CA $ROOT_CRT -CAkey $ROOT_KEY \
  $CA_SERIAL \
  -sha256 \
  -passin "file:$ROOT_PASS" \
  -extensions v3_req \
  -extfile $INI \
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
