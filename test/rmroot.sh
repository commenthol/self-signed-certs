#!/bin/bash
#
# run with sudo
#

TARGET=/usr/local/share/ca-certificates/aa.crt

rm -f "$TARGET"

# remove broken symlinks
find /etc/ssl/certs -xtype l -exec rm {} \;

update-ca-certificates
