#!/usr/bin/env sh 

# call from within alpine docker image
# sh /work/scripts/install.sh

apk update \
	&& apk add bash \
	&& apk add openssl

(cat << EOS

generate certificate with

	./star.sh <fqdn1> <fqdn2>
	# or
	./site.sh <fqdn>

EOS
)
