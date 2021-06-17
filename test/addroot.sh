#!/bin/bash
#
# run with sudo
#

CWD=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

TARGET=/usr/local/share/ca-certificates/aa.crt

cp $CWD/../certs/root_ca.crt "$TARGET"
chmod 644 "$TARGET"

update-ca-certificates
