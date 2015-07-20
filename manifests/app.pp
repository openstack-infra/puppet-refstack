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
# This class installs the refstack JavaScript Webclient (or app).
#
# Much of this module is duplicated in ::refstack::api, however it's separated
# here so that any future project splits (api vs. client) can be treated
# similarly in the puppet module.
#
class refstack::app () {
  require ::refstack::params
  require ::refstack::user

  # Import parameters into local scope.
  $src_www_root           = $::refstack::params::src_www_root
  $install_www_root       = $::refstack::params::install_www_root
  $user                   = $::refstack::params::user
  $group                  = $::refstack::params::group

  # Ensure Git is present
  if !defined(Package['git']) {
    package { 'git':
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

  # Download the latest Refstack Source
  vcsrepo { $src_www_root:
    ensure   => latest,
    owner    => $user,
    group    => $group,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/stackforge/refstack/',
    require  => Package['git']
  }

  # Run NPM Install
  exec { 'npm install':
    command     => 'npm install',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    cwd         => $src_www_root,
    user        => $user,
    group       => $group,
    refreshonly => true,
    subscribe   => [
      Vcsrepo[$src_www_root],
    ],
    require     => [
      Package['npm'],
      Vcsrepo[$src_www_root],
    ],
    environment => [
      # This is not automatically set by exec.
      'HOME=/home/refstack'
    ]
  }

  # Create config.json file
  file { "${src_www_root}/refstack-ui/app/config.json":
    ensure  => file,
    content => '{"refstackApiUrl": "/api/v1"}',
    require => Vcsrepo[$src_www_root],
  }
}
