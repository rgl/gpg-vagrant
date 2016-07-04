#!/bin/bash
set -eux

config_domain=$(hostname --domain)
EMAIL="$USER@$config_domain"
TRUSTEE_EMAIL=$1
TRUST=$2
TRUSTEE_KEY_PATH=/tmp/$TRUSTEE_EMAIL.pem

gpg2 --list-packets $TRUSTEE_KEY_PATH

gpg2 --import $TRUSTEE_KEY_PATH

# NB on a real-world scenario you would verify whether the
#    imported fingerprint matches what you exchanged in
#    real-live. 
expect<<EOF
spawn gpg2 --edit-key $EMAIL trust
expect timeout {exit 1} "  1 = I don't know or won't say"
expect timeout {exit 1} "  2 = I do NOT trust"
expect timeout {exit 1} "  3 = I trust marginally"
expect timeout {exit 1} "  4 = I trust fully"
expect timeout {exit 1} "  5 = I trust ultimately"
expect timeout {exit 1} "Your decision? "; send "$TRUST\\r"
if {$TRUST=="5"} {
    expect timeout {exit 1} "Do you really want to set this key to ultimate trust? (y/N) "; send "y\\r"
}
expect timeout {exit 1} "gpg> "; send "quit\\r"
wait
EOF
