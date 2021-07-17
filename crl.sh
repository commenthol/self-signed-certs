#!/bin/bash

## 
# update certificate revocation lists
#
# To revoke a certificate get the current timestamp in UTC
#    TZ=UTC date +%y%m%d%H%M%SZ
# Edit e.g. crl/intermediate.index.txt 
#    V	220619155302Z		60F913DDBB3F5F4AAE7C17424291D3641E942A7A	unknown	/C=AA/ST=Frogstar/O=AA Server/CN=aa.aa
# and change to
#    R	220619155302Z	210619160108Z	60F913DDBB3F5F4AAE7C17424291D3641E942A7A	unknown	/C=AA/ST=Frogstar/O=AA Server/CN=aa.aa
# Then rerun this script.


DIR="."
INTERMEDIATE="intermediate"

update_crl () {
  local TYPE=$1

  local INI="$DIR/private/$TYPE.ini" 
  local PASS="$DIR/private/$TYPE.pass" 
  local KEY="$DIR/private/$TYPE.key" 
  local CRT="$DIR/certs/$TYPE.crt" 
  local CRL="$DIR/crl/$TYPE.crl" 

  # update crl
  openssl ca \
    -config "$INI" \
    -gencrl \
    -passin "file:$PASS" \
    -keyfile "$KEY" \
    -cert "$CRT" \
    -out "$CRL"

  # show crl
  openssl crl -in "$CRL" -noout -text
}

update_crl root_ca

if [ -f "$DIR/certs/$INTERMEDIATE.crt" ]; then
  update_crl $INTERMEDIATE  
fi