#!/bin/bash
set -eux

config_fqdn=$(hostname --fqdn)
config_domain=$(hostname --domain)

echo "127.0.0.1 $config_fqdn" >>/etc/hosts

apt-get install -y --no-install-recommends vim
cat >/etc/vim/vimrc.local <<'EOF'
syntax on
set background=dark
set esckeys
set ruler
set laststatus=2
set nobackup
autocmd BufNewFile,BufRead Vagrantfile set ft=ruby
EOF

# the VM does not produce enough entropy for running gpg in a timely maner, so
# we fake it by installing haveged.
# see https://wiki.archlinux.org/index.php/GnuPG#Not_enough_random_bytes_available
# see https://wiki.archlinux.org/index.php/Random_number_generation#Faster_alternatives
# see https://wiki.archlinux.org/index.php/Haveged
cat /proc/sys/kernel/random/entropy_avail
apt-get install -y --no-install-recommends haveged

apt-get install -y --no-install-recommends gnupg2
apt-get install -y --no-install-recommends psmisc expect

# create the users and their keychains.
USERS="alice bob"
for user in $USERS; do
    addgroup $user
    adduser --ingroup $user --gecos ${user^} --shell /bin/bash $user
    sudo -sHu $user bash /vagrant/gnupg-recreate-keychains.sh
done

# make Alice sign a document.
ALICE_DOCUMENT=/tmp/alice-document.txt
echo 'Hello World' >$ALICE_DOCUMENT
sudo -sHu alice gpg2 --detach-sign --armor --output "$ALICE_DOCUMENT.sig" $ALICE_DOCUMENT

# Bob should not trust Alice signed document because he didn't yet have her public key nor he trusts her yet.
sudo -sHu bob gpg2 --verify "$ALICE_DOCUMENT.sig" $ALICE_DOCUMENT || true

# make Bob ultimately trust Alice.
# this is made by importing Alice' public key into bob keychain
# and setting the trust level.
sudo -sHu bob /vagrant/gnupg-trust-key.sh "alice@$config_domain" 5

# Bob should now trust Alice signed document because he ultimately trusts her.
# BUT you'll still see a warning telling Bob that the Alice key does
# not have any certified signature, which we'll do next.
sudo -sHu bob gpg2 --verify "$ALICE_DOCUMENT.sig" $ALICE_DOCUMENT

# make Bob sign the Alice key and recheck the document signature,
# which should not show any warning. 
sudo -sHu bob /vagrant/gnupg-sign-key.sh "alice@$config_domain"
sudo -sHu bob gpg2 --verify "$ALICE_DOCUMENT.sig" $ALICE_DOCUMENT

echo 'SUCCESS!'
