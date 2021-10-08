#!/usr/bin/env sh

DIR="."

DHPARAM="$DIR/certs/dhparam-4096.pem"

openssl dhparam -dsaparam -out $DHPARAM 4096
