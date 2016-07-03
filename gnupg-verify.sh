#!/bin/bash
set -eux
umask 0077

EMAIL=$1
DOCUMENT=$2

export GNUPGHOME=$PWD/gnupg-home-$EMAIL

gpg2 --list-packets "$DOCUMENT.gpg"
gpg2 --verify "$DOCUMENT.gpg" $DOCUMENT
