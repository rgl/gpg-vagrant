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

# create Alice and Bob keychains.
sudo -sHu vagrant bash /vagrant/gnupg-recreate-keychains.sh "alice.doe@$config_domain" 'Alice Doe'
sudo -sHu vagrant bash /vagrant/gnupg-recreate-keychains.sh "bob.doe@$config_domain" 'Bob Doe'

# make Alice sign a document.
ALICE_DOCUMENT=alice-document.txt
echo 'Hello World' >$ALICE_DOCUMENT
sudo -sHu vagrant bash /vagrant/gnupg-sign.sh "alice.doe@$config_domain" $ALICE_DOCUMENT

# Bob should not trust Alice signed document because he didn't yet trust her.
sudo -sHu vagrant bash /vagrant/gnupg-verify.sh "bob.doe@$config_domain" $ALICE_DOCUMENT || true

# make Bob ultimately trust Alice.
sudo -sHu vagrant bash /vagrant/gnupg-trust-key.sh "bob.doe@$config_domain" "alice.doe@$config_domain" 5

# Bob should now trust Alice signed document because he ultimately trusts her.
# BUT you'll still see a warning telling Bob that the Alice key does
# not have any certified signature, which we'll do next.
sudo -sHu vagrant bash /vagrant/gnupg-verify.sh "bob.doe@$config_domain" $ALICE_DOCUMENT

# make Bob sign the Alice key and recheck the document signature.
sudo -sHu vagrant bash /vagrant/gnupg-sign-key.sh "bob.doe@$config_domain" "alice.doe@$config_domain"
sudo -sHu vagrant bash /vagrant/gnupg-verify.sh "bob.doe@$config_domain" $ALICE_DOCUMENT

echo 'SUCCESS!'
