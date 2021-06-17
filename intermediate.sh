#!/bin/bash
#
# generates an intermediate certificate
# see https://jamielinux.com/docs/openssl-certificate-authority/create-the-intermediate-pair.html
#

set -x

# cert validity in days (10 years)
DAYS=3655
# certificate directory
CERTS="./certs"
# certificate revocation list dir
CRLS="./certs/crl"
# certificate name
NAME="intermediate"

# ----

INI="$NAME.ini"

# ----

ROOT_PASS="$CERTS/root_ca.pass"
ROOT_KEY="$CERTS/root_ca.key"
ROOT_CRT="$CERTS/root_ca.crt"
ROOT_SRL="$CERTS/root_ca.srl"

KEY="$CERTS/$NAME.key"
CSR="$CERTS/$NAME.csr"
CRT="$CERTS/$NAME.crt"
PASS="$CERTS/$NAME.pass"
CRL="$CRLS/$NAME.crl"

ROOT_CRL="$CRLS/root_ca.crl"
CRL_DATABASE="$CRLS/index.txt"
CRL_NUMBER="$CRLS/number"

(cat << EOS
[ca]
default_ca = ca_default

[ca_default]
default_md        = sha256
# For certificate revocation lists.
database          = $CRL_DATABASE
crlnumber         = $CRL_NUMBER
crl_extensions    = crl_ext
default_crl_days  = 30

[crl_ext]
# Extension for CRLs (man x509v3_config).
authorityKeyIdentifier = keyid:always,issuer:always

[req]
prompt = no
default_bits = 2048
distinguished_name = req_distinguished_name
string_mask = utf8only
# SHA-1 is deprecated, so use SHA-2 instead.
default_md = sha256
# Extension to add when the -x509 option is used.
x509_extensions = v3_intermediate_ca

[req_distinguished_name]
# Country Name (2 letter code)
C = AA
# State or Province Name
ST = Andromeda
# Locality Name
L = Island
# Organization Name
O = AA Certification
# Organizational Unit Name
OU = Certification Unit
# Common Name
CN = AA Certification Intermediate
# Email Address
emailAddress = info@ca.aa

[v3_intermediate_ca]
# Extensions for a typical intermediate CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

EOS
) > $INI

# ----

test ! -f "$ROOT_CRT" && ./root_ca.sh

CA_SERIAL="-CAcreateserial"
if [ -f "$ROOT_SRL" ]; then
  CA_SERIAL="-CAserial $ROOT_SRL"
fi

# remove old keys
test -f $KEY && rm $KEY $CSR $CRT $CHAIN $PFX $PFX_PASS

# generate password
openssl rand -base64 100 | tr -dc "[:print:]" | head -c 80 > "$PASS"

# generate key
openssl genrsa -aes256 \
  -passout "file:$PASS" \
  -out "$KEY" 4096

# create certificate signing request
openssl req -new \
  -passin "file:$PASS" \
  -config $INI \
  -key $KEY -out $CSR

# sign certificate
openssl x509 -req \
  -extensions v3_intermediate_ca \
  -days $DAYS \
  -CA $ROOT_CRT -CAkey $ROOT_KEY \
  $CA_SERIAL \
  -sha256 \
  -passin "file:$ROOT_PASS" \
  -extfile $INI \
  -in $CSR -out $CRT

# show certificate
openssl x509 -text -noout -in $CRT

# generate cert revocation list
openssl ca \
  -gencrl \
  -config $INI \
  -keyfile $KEY \
  -cert $CRT \
  -passin "file:$PASS" \
  -out "$CRL"

