#!/usr/bin/env sh 

CWD=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

cd "$CWD/.."

docker run -it --rm \
	-u root \
	-v $(pwd)":/work" \
	-p 8443:8443 \
	node:18-alpine \
	sh -c "sh /work/docker/install.sh && sh"
