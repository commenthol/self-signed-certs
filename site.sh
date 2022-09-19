#!/usr/bin/env bash
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

set -e
#set -x

# certification domain
CA_DOMAIN=ca.aa
# cert validity in days
DAYS=375
# certificate name
NAME="site"
# domain
CN=aa.aa
# base directory
DIR="."

# ----

if [ ! -z "$1" ]; then 
  NAME=$1
  CN=$1
fi

INI="$DIR/csr/$NAME.ini"

TYPE="root_ca"
FILES=()
if [ -f "$DIR/certs/intermediate.crt" ]; then
  FILES+=("$DIR/certs/$TYPE.crt")
  TYPE="intermediate"
fi

ROOT_PASS="$DIR/private/$TYPE.pass"
ROOT_KEY="$DIR/private/$TYPE.key"
ROOT_CRT="$DIR/certs/$TYPE.crt"

CRL="$DIR/crl/$TYPE.crl"
CRL_DATABASE="$DIR/crl/$TYPE.index.txt"
CRL_NUMBER="$DIR/crl/number"
CRL_DP="https://$CA_DOMAIN/$TYPE.crl"

TAR="$DIR/certs/$NAME.tgz"
KEY="$DIR/certs/$NAME.key"
CSR="$DIR/csr/$NAME.csr"
CRT="$DIR/certs/$NAME.crt"
PFX="$DIR/certs/$NAME.pfx"
PFX_PASS="$DIR/certs/$NAME.pfx.pass"
CRTKEY="$DIR/certs/$NAME.crt.key"

RANDFILE="$DIR/private/randfile"
SERIAL="$DIR/private/serial"

FILES+=($ROOT_CRT)
FILES+=($KEY)
FILES+=($CRT)
FILES+=($PFX)
FILES+=($PFX_PASS)
FILES+=($CRTKEY)

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
# default_bits        = 2048
default_days        = 375
default_md          = sha256
string_mask         = utf8only
distinguished_name  = req_distinguished_name
req_extensions      = v3_req

[ crl_ext ]
# Extension for CRLs (man x509v3_config).
issuerAltName          = issuer:copy
authorityKeyIdentifier = keyid:always

[ req_distinguished_name ]
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

[ v3_req ]
#nsCertType = server
#nsComment = "OpenSSL Generated Server Certificate"
# authorityKeyIdentifier = keyid,issuer
subjectKeyIdentifier = hash
basicConstraints = critical, CA:FALSE
#keyUsage = nonRepudiation, digitalSignature, keyEncipherment
keyUsage = critical, digitalSignature, keyEncipherment
#extendedKeyUsage = serverAuth, clientAuth, timeStamping
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = DNS:$CN
crlDistributionPoints = URI:$CRL_DP

EOS
) > $INI

# ----

PASSWORD=$(openssl rand -base64 50 | tr -dc "[:print:]" | head -c 40)

# ----

test ! -f $ROOT_CRT && ./root_ca.sh

# remove old keys
test -f "$KEY" && rm "$KEY" "$CSR" "$CRT" "$CRTKEY" "$PFX" "$PFX_PASS"

# generate key
openssl genrsa -out $KEY 4096

# create certificate signing request
openssl req -new \
  -config $INI \
  -key $KEY -out $CSR

# sign certificate
openssl ca \
  -batch \
  -notext \
  -config "$INI" \
  -days $DAYS \
  -passin "file:$ROOT_PASS" \
  -in "$CSR" \
  -out "$CRT"

# chain crt with key (e.g. for HAProxy)
cat "$CRT" "$KEY" > "$CRTKEY"

# generate PKCS12
echo $PASSWORD > $PFX_PASS
openssl pkcs12 -export \
  -passout "file:$PFX_PASS" \
  -in "$CRT" -inkey "$KEY" \
  -certfile "$ROOT_CRT" \
  -out "$PFX"

# tar all
tar czf "$TAR" "${FILES[@]}"

# show certificate
openssl x509 -text -noout -in "$CRT"
