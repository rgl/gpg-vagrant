# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu-16.04-amd64"

  config.vm.hostname = "gpg.example.com"

  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.memory = "1024"
  end

  config.vm.provision "shell", path: "provision.sh"
end
