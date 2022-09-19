#!/bin/bash
#
# generates a root ca certificate
# @see https://jamielinux.com/docs/openssl-certificate-authority/create-the-root-pair.html
# @see https://access.redhat.com/documentation/en-us/red_hat_update_infrastructure/2.1/html/administration_guide/chap-red_hat_update_infrastructure-administration_guide-certification_revocation_list_crl
#

set -e
#set -x

# certification domain
CA_DOMAIN=ca.aa
# cert validity in days (20 years)
DAYS=7320
# base directory
DIR="."

# ----

INI="$DIR/private/root_ca.ini"

ROOT_PASS="$DIR/private/root_ca.pass"
ROOT_KEY="$DIR/private/root_ca.key"
ROOT_CRT="$DIR/certs/root_ca.crt"

CRL="$DIR/crl/root_ca.crl"
CRL_DATABASE="$DIR/crl/root_ca.index.txt"
CRL_NUMBER="$DIR/crl/number"

RANDFILE="$DIR/private/randfile"
SERIAL="$DIR/private/serial"

# ----

_mkdir () {
  test -d "$1" && rm -rf "$1"
  mkdir -p "$1"
}

_mkdir "$DIR/certs"
_mkdir "$DIR/crl"
_mkdir "$DIR/csr"
_mkdir "$DIR/private"
chmod 700 "$DIR/private"

# clean start
touch "$CRL_DATABASE"
echo 00 > "$CRL_NUMBER"
openssl rand -hex 12 > "$SERIAL"

# ---

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
x509_extensions   = v3_ca
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
# default_bits        = 4096
default_days        = 375
default_md          = sha256
string_mask         = utf8only
distinguished_name  = req_distinguished_name
# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca

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
CN = AA Certification
# Email Address
emailAddress = info@$CA_DOMAIN

[ v3_ca ]
# Extensions for a typical CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, keyEncipherment, cRLSign, keyCertSign

[ crl_ext ]
# Extension for CRLs (man x509v3_config).
authorityKeyIdentifier = keyid:always,issuer:always

EOS
) > "$INI"

openssl rand -base64 100 > "$RANDFILE"

# generate password
openssl rand -base64 100 | tr -dc "[:print:]" | head -c 80 > "$ROOT_PASS"

# generate key
openssl genrsa -aes256 \
  -passout "file:$ROOT_PASS" \
  -out "$ROOT_KEY" 4096

# create certificate
openssl req -x509 \
  -config "$INI" \
  -new -nodes \
  -days $DAYS \
  -passin "file:$ROOT_PASS" \
  -key "$ROOT_KEY" \
  -out "$ROOT_CRT"

# show certificate
openssl x509 -text -noout -in "$ROOT_CRT"
