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
# This class installs the refstack API so that it may be run via wsgi.
#
class refstack::api () {
  require ::refstack::params
  require ::refstack::user

  # Import parameters into local scope.
  $python_version         = $::refstack::params::python_version
  $src_api_root           = $::refstack::params::src_api_root
  $install_api_root       = $::refstack::params::install_api_root
  $user                   = $::refstack::params::user
  $group                  = $::refstack::params::group

  class { 'python':
    version    => $python_version,
    pip        => true,
    dev        => true,
    virtualenv => true,
  }
  include python::install

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

  # Ensure PyMysqldb is present
  if !defined(Package['python-mysqldb']) {
    package { 'python-mysqldb':
      ensure => present
    }
  }

  # Create the refstack configuration directory.
  file { '/etc/refstack':
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0700',
  }

  # Configure the refstack API
  file { '/etc/refstack/refstack.conf':
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0400',
    content => template('refstack/refstack.conf.erb'),
    require => [
      File['/etc/refstack']
    ]
  }

  # Download the latest Refstack Source
  vcsrepo { $src_api_root:
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/stackforge/refstack/',
    require  => Package['git']
  }

  # Create the install directory and virtual environment
  file { $install_api_root:
    ensure  => directory,
    owner   => $user,
    group   => $group,
  }
  python::virtualenv { $install_api_root:
    ensure       => present,
    version      => $python_version,
    owner        => $user,
    group        => $group,
    require      => [
      File[$install_api_root],
      Class['python::install'],
    ],
    systempkgs   => true,
  }

  # Run pip from the venv, install refstack.
  python::pip { 'refstack':
    pkgname    => 'refstack',
    ensure     => present,
    virtualenv => $install_api_root,
    url        => "file://${src_api_root}",
    owner      => $user,
    require    => Vcsrepo[$src_api_root],
    subscribe  => Vcsrepo[$src_api_root],
  }

  # Migrate the database
  exec { 'migrate-refstack-db':
    command     => 'refstack-manage --config-file /etc/refstack/refstack.conf upgrade --revision head',
    path        => "${install_api_root}/bin/:/usr/local/bin:/usr/bin:/bin/",
    refreshonly => true,
    subscribe   => [
      Python::Pip['refstack'],
      File['/etc/refstack/refstack.conf'],
    ],
    require     => [
      Package['python-mysqldb'],
      Python::Pip['refstack'],
      File['/etc/refstack/refstack.conf'],
    ],
  }
}
