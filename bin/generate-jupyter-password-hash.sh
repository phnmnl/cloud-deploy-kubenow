#!/bin/bash

password="$1"
salt=$(openssl rand -hex 6)
hashed_passw=$(echo -n "$password$salt" | openssl dgst -sha1 | sed 's/^.* //')
jupyter_format_hash="sha1:$salt:$hashed_passw"
echo $jupyter_format_hash
