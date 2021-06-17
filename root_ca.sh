#!/bin/bash
#
# generates a root ca certificate
#

#set -x

# cert validity in days (20 years)
DAYS=7320
# certificate directory
CERTS='./certs'

# ----

INI="root_ca.ini"

(cat << EOS
[req]
prompt = no
default_bits = 2048
distinguished_name = req_distinguished_name
string_mask = utf8only
# SHA-1 is deprecated, so use SHA-2 instead.
default_md = sha256
# Extension to add when the -x509 option is used.
x509_extensions = v3_ca

[req_distinguished_name]
C = AA
ST = Andromeda
L = Island
O = AA Certification
OU = Certification Unit
CN = AA Certification
emailAddress = info@ca.aa

[ v3_ca ]
# Extensions for a typical CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

EOS
) > $INI

# ----

ROOT_PASS="$CERTS/root_ca.pass"
ROOT_KEY="$CERTS/root_ca.key"
ROOT_CRT="$CERTS/root_ca.crt"

test ! -d $CERTS && mkdir -p $CERTS
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
#openssl x509 -text -noout -in $ROOT_CRT
