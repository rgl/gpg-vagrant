#!/bin/bash
# see https://wiki.debian.org/Keysigning

set -eux
umask 0077

EMAIL=$1
TRUSTEE_EMAIL=$2

export GNUPGHOME=$PWD/gnupg-home-$EMAIL
TRUSTEE_GNUPGHOME=$PWD/gnupg-home-$TRUSTEE_EMAIL
TRUSTEE_KEY_PATH=$TRUSTEE_GNUPGHOME/$TRUSTEE_EMAIL-public.pem
SIGNED_KEY_PATH=$GNUPGHOME/$TRUSTEE_EMAIL-public-signed-by-$EMAIL.pem

# NB on a real-world scenario you would verify whether the
#    imported fingerprint matches what you exchanged in
#    real-live, and only then would you sign it.
expect<<EOF
spawn gpg2 --sign-key $TRUSTEE_EMAIL
expect timeout {exit 1} "Really sign? (y/N) "; send "y\\r"
wait
EOF

# export the signed key and our key too.
gpg2 --armor --output $SIGNED_KEY_PATH --export $TRUSTEE_EMAIL $EMAIL

# import them on the TRUSTEE keychain and dump it.
(
    set -eux
    source $TRUSTEE_GNUPGHOME/env.sh
    gpg2 --import $SIGNED_KEY_PATH
    gpg2 --list-sigs
)
