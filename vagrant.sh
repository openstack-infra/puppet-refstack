#!/bin/sh

# Install Puppet!
if [ ! -f /etc/apt/sources.list.d/puppetlabs.list ]; then
  lsbdistcodename=`lsb_release -c -s`
  wget https://apt.puppetlabs.com/puppetlabs-release-${lsbdistcodename}.deb
  sudo dpkg -i puppetlabs-release-${lsbdistcodename}.deb
  sudo apt-get update
  sudo apt-get dist-upgrade -y
fi

wget https://bootstrap.pypa.io/get-pip.py
sudo python get-pip.py

# Create a symlink to the vagrant directory, so puppet can find our module.
if [ ! -d /etc/puppet/modules/refstack ]; then
  sudo ln -s /vagrant /etc/puppet/modules/refstack
fi

# Install required puppet modules.
if [ ! -d /etc/puppet/modules/stdlib ]; then
  puppet module install puppetlabs-stdlib --version 3.2.0
fi
if [ ! -d /etc/puppet/modules/mysql ]; then
  puppet module install puppetlabs-mysql --version 0.6.1
fi
if [ ! -d /etc/puppet/modules/apache ]; then
  puppet module install puppetlabs-apache --version 0.0.4
fi
if [ ! -d /etc/puppet/modules/vcsrepo ]; then
  puppet module install openstackci-vcsrepo --version 0.0.8
fi
