#!/bin/bash

openssl s_client -showcerts -verify 5 -connect aa.aa:8443 < /dev/null
