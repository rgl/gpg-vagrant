#!/bin/bash
set -eux
umask 0077

EMAIL=$1
DOCUMENT=$2

export GNUPGHOME=$PWD/gnupg-home-$EMAIL

gpg2 --detach-sign --armor --output "$DOCUMENT.gpg" $DOCUMENT 
