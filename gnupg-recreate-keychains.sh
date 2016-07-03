#!/bin/bash
set -eux
umask 0077

EMAIL=$1
NAME=$2

export GNUPGHOME=$PWD/gnupg-home-$EMAIL

rm -rf $GNUPGHOME && install -d -m 700 $GNUPGHOME

cat<<EOF>$GNUPGHOME/env.sh
# source this into the current shell to use this GNUPGHOME:
# source env.sh
EMAIL='$EMAIL'
NAME='$NAME'
export GNUPGHOME='$GNUPGHOME'
config_fqdn=\$(hostname --fqdn)
config_domain=\$(hostname --domain)
EOF

cat <<EOF >$GNUPGHOME/gpg.conf
# enter the passwords on stdin.
pinentry-mode loopback

# use strict OpenPGP behavior.
openpgp

# use full 16-character key IDs, not short 8-character key IDs.
keyid-format long

# show key fingerprint by default.
with-fingerprint

# ignore the preferred keyserver embeded in keys.
# always use the keyserver defined in this configuration file.
keyserver-options no-honor-keyserver-url

# prefer strong hashes whenever possible.
personal-digest-preferences SHA256
cert-digest-algo SHA256

# prefer more modern ciphers over older ones.
# NB golang (as of v1.6.2) only supports:
#       3DES, CAST5, AES128, AES192 and AES256 
#    see https://github.com/golang/crypto/blob/master/openpgp/packet/packet.go#L441
personal-cipher-preferences AES256
EOF

cat <<EOF >$GNUPGHOME/gpg-agent.conf
# allow to enter the passwords on stdin.
allow-loopback-pinentry
EOF

killall gpg-agent || true

# create a certificate and signing key.
expect<<EOF
#set timeout 1
spawn gpg2 --full-gen-key
expect timeout {exit 1} "   (4) RSA (sign only)"
expect timeout {exit 1} "Your selection? "; send "4\\r"
expect timeout {exit 1} "What keysize do you want? "; send "4096\\r"
expect timeout {exit 1} "Key is valid for? (0) "; send "0\\r"
expect timeout {exit 1} "Is this correct? (y/N) "; send "y\\r"
expect timeout {exit 1} "Real name: "; send "$NAME\\r"
expect timeout {exit 1} "Email address: "; send "$EMAIL\\r"
expect timeout {exit 1} "Comment: "; send "\\r"
expect timeout {exit 1} "Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? "; send "O\\r"
expect timeout {exit 1} "Enter passphrase: "; send "\\r"
expect timeout {exit 1} "public and secret key created and signed."
wait
EOF

# create a signing subkey valid for an year.
# see https://wiki.debian.org/Subkeys
expect<<EOF
#set timeout 1
spawn gpg2 --edit-key $EMAIL addkey
expect timeout {exit 1} "   (4) RSA (sign only)"
expect timeout {exit 1} "Your selection? "; send "4\\r"
expect timeout {exit 1} "What keysize do you want? "; send "4096\\r"
expect timeout {exit 1} "Key is valid for? (0) "; send "1y\\r"
expect timeout {exit 1} "Is this correct? (y/N) "; send "y\\r"
expect timeout {exit 1} "Really create? (y/N) "; send "y\\r"
expect timeout {exit 1} "Enter passphrase: "; send "\\r"
expect timeout {exit 1} "gpg> "; send "save\\r"
wait
EOF

gpg2 --list-secret-keys
gpg2 --list-sigs

gpg2 --armor --export $EMAIL >$GNUPGHOME/$EMAIL-public.pem
gpg2 --list-packets $GNUPGHOME/$EMAIL-public.pem

killall gpg-agent || true
