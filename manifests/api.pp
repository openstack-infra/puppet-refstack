# Copyright (c) 2015 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# == Class: refstack::api
#
# This class installs the RefStack API so that it may be run via wsgi.
#
class refstack::api () {
  require ::refstack::params
  require ::refstack::user

  # Import parameters into local scope.
  $src_api_root           = $::refstack::params::src_api_root
  $user                   = $::refstack::params::user
  $group                  = $::refstack::params::group

  # Ensure Git is present
  if !defined(Package['git']) {
    package { 'git':
      ensure => present
    }
  }

  # Ensure OpenSSL is present
  if !defined(Package['libssl-dev']) {
    package { 'libssl-dev':
      ensure => present
    }
  }

  # Ensure python-dev is present
  if !defined(Package['python-dev']) {
    package { 'python-dev':
      ensure => present
    }
  }

  # Create the RefStack configuration directory.
  file { '/etc/refstack':
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }

  # Configure the RefStack API
  file { '/etc/refstack/refstack.conf':
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => template('refstack/refstack.conf.erb'),
    require => [
      File['/etc/refstack']
    ]
  }

  # Download the latest RefStack Source
  vcsrepo { $src_api_root:
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/stackforge/refstack/',
    require  => Package['git']
  }

  # Install RefStack
  exec { 'install-refstack':
    command     => "pip install ${src_api_root}",
    path        => '/usr/local/bin:/usr/bin:/bin',
    refreshonly => true,
    require     => Vcsrepo[$src_api_root],
    subscribe   => Vcsrepo[$src_api_root],
  }

  # Migrate the database
  exec { 'migrate-refstack-db':
    command     => 'refstack-manage --config-file /etc/refstack/refstack.conf upgrade --revision head',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => [
      Exec['install-refstack'],
      File['/etc/refstack/refstack.conf'],
    ],
    require     => [
      Exec['install-refstack'],
      File['/etc/refstack/refstack.conf'],
    ],
  }
}
