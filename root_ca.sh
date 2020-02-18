#!/bin/bash
#
# generates a root ca certificate
#

# cert validity in days
DAYS=9999
# certificate directory
CERTS='./certs'

# ----

INI="root_ca.ini"

(cat << EOS
[req]
prompt = no
distinguished_name = req_distinguished_name

[req_distinguished_name]
C = AA
ST = Andromeda
L = Island
O = AA Certification
OU = ca.aa
CN = AA Certification
emailAddress = info@ca.aa

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
openssl genrsa -des3 \
  -passout "file:$ROOT_PASS" \
  -out $ROOT_KEY 4096

# create certificate
openssl req -x509 -new -nodes \
  -days $DAYS \
  -config $INI \
  -passin "file:$ROOT_PASS" \
  -key $ROOT_KEY -out $ROOT_CRT

# show certificate
# openssl x509 -text -noout -in $ROOT_CRT
