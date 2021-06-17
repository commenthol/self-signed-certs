#!/bin/bash
#
# generates a wildcard (multi-domain) server certificate
#

# certification domain
CA_DOMAIN=ca.aa
# cert validity in days
DAYS=375
# certificate directory
CERTS="./certs"
# certificate name
NAME="star"
# domain
CN=aa.aa

# ----

INI="$NAME.ini"

if [ ! -z "$1" ]; then 
  NAME=$1
  CN=$1
fi

TYPE="root_ca"
CRLDP="https://$CA_DOMAIN/root_ca.crl"

if [ -f "$CERTS/intermediate.crt" ]; then
  TYPE="intermediate"
  # change the distribution 
  CRLDP="https://$CA_DOMAIN/intermediate.crl"
fi

(cat << EOS
[req]
prompt = no
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]
# Country Name (2 letter code)
C = AA
# State or Province Name
ST = Frogstar
# Locality Name
L = City
# Organization Name
O = AA Server
# Organizational Unit Name
#OU = Certification Unit
# Common Name
CN = $CN
# Email Address
emailAddress = info@$CN

[v3_req]
nsCertType = server
#nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
crlDistributionPoints = URI:$CRLDP

[alt_names]
DNS.1 = *.$CN
DNS.2 = $CN
DNS.3 = *.test.aa
DNS.4 = localhost

EOS
) > $INI

# ----

ROOT_PASS="$CERTS/$TYPE.pass"
ROOT_KEY="$CERTS/$TYPE.key"
ROOT_CRT="$CERTS/$TYPE.crt"
ROOT_SRL="$CERTS/$TYPE.srl"

KEY="$CERTS/$NAME.key"
CSR="$CERTS/$NAME.csr"
CRT="$CERTS/$NAME.crt"
PFX="$CERTS/$NAME.pfx"
PFX_PASS="$CERTS/$NAME.pfx.pass"
CRTKEY="$CERTS/${NAME}.crt.key"

PASSWORD=$(openssl rand -base64 50 | tr -dc "[:print:]" | head -c 40)

# ----

test ! -f $ROOT_CRT && ./root_ca.sh

CA_SERIAL="-CAcreateserial"
if [ -f "$ROOT_SRL" ]; then
  CA_SERIAL="-CAserial $ROOT_SRL"
fi

# remove old keys
test -f $KEY && rm $KEY $CSR $CRT $CRTKEY $PFX $PFX_PASS

# generate key
openssl genrsa -out $KEY 4096

# create certificate
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

# chain certs with key (e.g. for HAProxy)
cat $CRT $KEY > $CRTKEY

# generate PKCS12
echo $PASSWORD > $PFX_PASS
openssl pkcs12 -export \
  -passout "file:$PFX_PASS" \
  -in $CRT -inkey $KEY \
  -certfile $ROOT_CRT \
  -out $PFX

# show certificate
openssl x509 -text -noout -in $CRT
