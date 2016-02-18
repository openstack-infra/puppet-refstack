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

# == Class: refstack::app
#
# This class installs the RefStack application (API and UI) so that it may be
# run via wsgi.
#
class refstack::app () {
  require ::refstack::params
  require ::refstack::user

  # Import parameters into local scope.
  $src_www_root           = $::refstack::params::src_www_root
  $src_root               = $::refstack::params::src_root
  $install_www_root       = $::refstack::params::install_www_root
  $user                   = $::refstack::params::user
  $group                  = $::refstack::params::group

  # Ensure python-dev is present
  if !defined(Package['python-dev']) {
    package { 'python-dev':
      ensure => present
    }
  }

  # Ensure OpenSSL is present
  if !defined(Package['libssl-dev']) {
    package { 'libssl-dev':
      ensure => present
    }
  }

  # Ensure NPM is present
  if !defined(Package['npm']) {
    package { 'npm':
      ensure => present
    }
  }

  if !defined(Package['nodejs']) {
    package { 'nodejs':
      ensure => present
    }
  }

  if !defined(Package['nodejs-legacy']) {
    package { 'nodejs-legacy':
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

  file { $src_root:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }

  # Configure the RefStack API.
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

  # Download the RefStack tar.gz source distribution from pypi only if a new
  # one is available.
  exec { 'download-refstack':
    command => 'pip install refstack -d /tmp --no-deps --no-binary :all:',
    path    => '/usr/local/bin:/usr/bin:/bin',
    user    => $user,
    group   => $group,
    onlyif  => 'pip list --outdated | grep -c refstack || test `pip freeze | grep -c refstack` -eq 0'
  }

  # Untar the source contents.
  exec { 'untar-refstack' :
    command     => "tar -xvzf /tmp/refstack-*.tar.gz -C ${src_root} --strip-components=1",
    path        => '/usr/local/bin:/usr/bin:/bin',
    refreshonly => true,
    user        => $user,
    group       => $group,
    subscribe   => Exec['download-refstack']
  }

  # Remove tar.gz file after extracting.
  exec { 'remove-tar':
    command     => 'rm -f /tmp/refstack-*.tar.gz',
    path        => '/usr/local/bin:/usr/bin:/bin',
    refreshonly => true,
    subscribe   => Exec['untar-refstack']
  }

  # Install RefStack using pip.
  exec { 'install-refstack':
    command     => "pip install -U ${src_root}",
    path        => '/usr/local/bin:/usr/bin:/bin',
    refreshonly => true,
    subscribe   => Exec['untar-refstack'],
    notify      => Service['httpd']
  }

  # Migrate the database.
  exec { 'migrate-refstack-db':
    command     => 'refstack-manage --config-file /etc/refstack/refstack.conf upgrade --revision head',
    path        => '/usr/local/bin:/usr/bin:/bin',
    refreshonly => true,
    subscribe   => [
      Exec['install-refstack'],
      File['/etc/refstack/refstack.conf'],
    ],
    require     => [
      Exec['install-refstack'],
      File['/etc/refstack/refstack.conf'],
    ]
  }

  # Run NPM Install.
  exec { 'npm install':
    command     => 'npm install',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    cwd         => $src_root,
    user        => $user,
    group       => $group,
    refreshonly => true,
    subscribe   => Exec['untar-refstack'],
    require     => [
      Package['npm'],
    ],
    environment => [
      # This is not automatically set by exec.
      'HOME=/home/refstack'
    ]
  }

  # Create config.json file.
  file { "${src_root}/refstack-ui/app/config.json":
    ensure  => file,
    content => '{"refstackApiUrl": "/api/v1"}',
    require => [
      File[$src_root],
      Exec['untar-refstack'],
    ]
  }
}
