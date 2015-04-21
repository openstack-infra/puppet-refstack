#!/bin/sh

# Install Puppet!
if [ ! -f /etc/apt/sources.list.d/puppetlabs.list ]; then
  lsbdistcodename=`lsb_release -c -s`
  wget https://apt.puppetlabs.com/puppetlabs-release-${lsbdistcodename}.deb
  sudo dpkg -i puppetlabs-release-${lsbdistcodename}.deb
  sudo apt-get update
  sudo apt-get dist-upgrade -y
fi

# Create a symlink to the vagrant directory, so puppet can find our module.
if [ ! -d /etc/puppet/modules/refstack ]; then
  sudo ln -s /vagrant /etc/puppet/modules/refstack
fi

# Install required puppet modules.
if [ ! -d /etc/puppet/modules/python ]; then
  puppet module install stankevich-python --version 1.6.6
fi