#!/bin/bash
# see https://wiki.debian.org/Keysigning
set -eux

config_domain=$(hostname --domain)
EMAIL="$USER@$config_domain"
TRUSTEE_EMAIL=$1
TRUSTEE_KEY_PATH=/tmp/$TRUSTEE_EMAIL.pem
SIGNED_KEY_PATH=/tmp/$TRUSTEE_EMAIL-signed-by-$EMAIL.pem

# NB on a real-world scenario you would verify whether the
#    imported fingerprint matches what you exchanged in
#    real-live, and only then would you sign it.
expect<<EOF
spawn gpg2 --sign-key $TRUSTEE_EMAIL
expect timeout {exit 1} "Really sign? (y/N) "; send "y\\r"
wait
EOF

gpg2 --list-sigs

# export the signed key.
gpg2 --armor --output $SIGNED_KEY_PATH --export $TRUSTEE_EMAIL
