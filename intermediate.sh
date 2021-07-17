#!/bin/bash
#
# generates an intermediate certificate
# see https://jamielinux.com/docs/openssl-certificate-authority/create-the-intermediate-pair.html
#

set -e
#set -x

# certification domain
CA_DOMAIN=ca.aa
# cert validity in days (10 years)
DAYS=3655
# certificate name
NAME="intermediate"
# base directory
DIR="."

# ----

INI="$DIR/private/$NAME.ini"

ROOT_PASS="$DIR/private/root_ca.pass"
ROOT_KEY="$DIR/private/root_ca.key"
ROOT_CRT="$DIR/certs/root_ca.crt"

CRL="$DIR/crl/root_ca.crl"
CRL_DATABASE="$DIR/crl/root_ca.index.txt"
CRL_NUMBER="$DIR/crl/number"
CRL_DP="https://$CA_DOMAIN/root_ca.crl"

KEY="$DIR/private/$NAME.key"
CSR="$DIR/csr/$NAME.csr"
CRT="$DIR/certs/$NAME.crt"
PASS="$DIR/private/$NAME.pass"

RANDFILE="$DIR/private/randfile"
SERIAL="$DIR/private/serial"

_config () {
(cat << EOS
[ ca ]
default_ca        = CA_default

[ CA_default ]
dir               = $DIR          
database          = $CRL_DATABASE
new_certs_dir     = $DIR/certs   
certificate       = $ROOT_CRT    
serial            = $SERIAL
rand_serial       = yes
private_key       = $ROOT_KEY
RANDFILE          = $RANDFILE
default_days      = $DAYS
default_crl_days  = 30 
default_md        = sha256
policy            = policy_any
email_in_dn       = no
name_opt          = ca_default
cert_opt          = ca_default
unique_subject    = no
copy_extensions   = copyall
x509_extensions   = v3_intermediate_ca
crl_extensions    = crl_ext

[ policy_strict ]
countryName            = match
stateOrProvinceName    = match
organizationName       = match
organizationalUnitName = optional
commonName             = supplied
emailAddress           = optional

[ policy_any ]
countryName            = supplied
stateOrProvinceName    = optional
organizationName       = optional
organizationalUnitName = optional
commonName             = supplied
emailAddress           = optional

[ req ]
prompt              = no
default_bits        = 4096
default_days        = 375
default_md          = sha256
string_mask         = utf8only
distinguished_name  = req_distinguished_name
# Extension to add when the -x509 option is used.
x509_extensions     = v3_intermediate_ca

[ req_distinguished_name ]
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
emailAddress = info@$CA_DOMAIN

[ v3_intermediate_ca ]
# Extensions for a typical intermediate CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
crlDistributionPoints = URI:$CRL_DP

[ crl_ext ]
# Extension for CRLs (man x509v3_config).
authorityKeyIdentifier = keyid:always,issuer:always

EOS
) > "$INI"
}

_config

# ----

test ! -f "$ROOT_CRT" && ./root_ca.sh

# remove old keys
test -f "$KEY" && rm "$PASS" "$KEY" "$CSR" "$CRT"

# generate password
openssl rand -base64 100 | tr -dc "[:print:]" | head -c 80 > "$PASS"

# generate key
openssl genrsa -aes256 \
  -passout "file:$PASS" \
  -out "$KEY" 4096

# create certificate signing request
openssl req -new \
  -passin "file:$PASS" \
  -config "$INI" \
  -key "$KEY" -out "$CSR"

# sign certificate
openssl ca \
  -batch \
  -notext \
  -config "$INI" \
  -days $DAYS \
  -passin "file:$ROOT_PASS" \
  -in "$CSR" \
  -out "$CRT"

# show certificate
openssl x509 -text -noout -in "$CRT"

# initialize crl database for correct key revocation if using with 
# openssl ca -config private/intermediate.ini -passin file:private/intermediate.pass -revoke certs/xxx.pem
CRL_DATABASE="$DIR/crl/$NAME.index.txt"
ROOT_CRT="$CRT"
ROOT_KEY="$KEY"
_config
touch "$CRL_DATABASE"
