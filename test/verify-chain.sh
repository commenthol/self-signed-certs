#!/bin/bash

CWD=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

openssl verify -CAfile ./certs/root_ca.crt -untrusted ./certs/intermediate.crt $1