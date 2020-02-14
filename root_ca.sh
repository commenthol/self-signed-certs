#!/bin/bash
#
# generates a root ca certificate
#

# cert validity in days
DAYS=9999
CERTS='./certs'

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
  -config root_ca.ini \
  -passin "file:$ROOT_PASS" \
  -key $ROOT_KEY -out $ROOT_CRT

# show certificate
# openssl x509 -text -noout -in $ROOT_CRT
