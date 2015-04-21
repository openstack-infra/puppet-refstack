# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Define the box.
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = "puppet-refstack-trusty64"

  config.vm.provider :virtualbox do |vb|
    vb.customize ['modifyvm', :id,'--memory', '2048']
    vb.name = 'puppet-refstack-trusty64'
  end

  # Grant a private IP
  config.vm.network "private_network", ip: "192.168.99.88"

  # All VM's run the same provisioning
  config.vm.provision "shell", path: "vagrant.sh"
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = ['vm', "/vagrant"]
    puppet.manifest_file = "vagrant.pp"
  end
end
