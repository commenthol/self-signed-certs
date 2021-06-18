#!/bin/bash
#
# generates a root ca certificate
# @see https://jamielinux.com/docs/openssl-certificate-authority/create-the-root-pair.html
# @see https://access.redhat.com/documentation/en-us/red_hat_update_infrastructure/2.1/html/administration_guide/chap-red_hat_update_infrastructure-administration_guide-certification_revocation_list_crl
#

#set -x

# certification domain
CA_DOMAIN=ca.aa
# cert validity in days (20 years)
DAYS=7320
# certificate directory
CERTS="./certs"
# certificate revocation list dir
CRLS="./certs/crl"

# ----

INI="root_ca.ini"

ROOT_PASS="$CERTS/root_ca.pass"
ROOT_KEY="$CERTS/root_ca.key"
ROOT_CRT="$CERTS/root_ca.crt"

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
default_md = sha256
# Extension to add when the -x509 option is used.
x509_extensions = v3_ca

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
CN = AA Certification
# Email Address
emailAddress = info@$CA_DOMAIN

[v3_ca]
# Extensions for a typical CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

EOS
) > $INI

# ----

test ! -d $CERTS && mkdir -p $CERTS
test ! -d $CRLS && mkdir -p $CRLS

test ! -f "$CRL_DATABASE" && touch "$CRL_DATABASE"
echo 00 > "$CRL_NUMBER"

# remove old keys
test -f $ROOT_KEY && rm $ROOT_KEY $ROOT_PASS $ROOT_CRT

# generate password
openssl rand -base64 100 | tr -dc "[:print:]" | head -c 80 > $ROOT_PASS

# generate key
openssl genrsa -aes256 \
  -passout "file:$ROOT_PASS" \
  -out $ROOT_KEY 4096

# create certificate
openssl req -x509 -new -nodes \
  -days $DAYS \
  -config $INI \
  -passin "file:$ROOT_PASS" \
  -key $ROOT_KEY -out $ROOT_CRT

# show certificate
openssl x509 -text -noout -in $ROOT_CRT

# generate cert revocation list
openssl ca \
  -gencrl \
  -config $INI \
  -keyfile $ROOT_KEY \
  -cert $ROOT_CRT \
  -passin "file:$ROOT_PASS" \
  -out "$ROOT_CRL"

