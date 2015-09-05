# Copyright (c) 2015 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# == Class: refstack::apache::http
#
# This module installs RefStack onto the current host using an unencrypted http
# protocol.
#
class refstack::apache::http () {
  require ::refstack::params
  require ::refstack::api
  require ::refstack::app

  # Pull various variables into this module, for slightly saner templates.
  $install_www_root       = $::refstack::params::install_www_root
  $src_www_root           = $::refstack::params::src_www_root
  $hostname               = $::refstack::params::hostname
  $user                   = $::refstack::params::user
  $group                  = $::refstack::params::group
  $server_admin           = $::refstack::params::server_admin

  # Install apache
  include ::httpd
  include ::httpd::params
  include ::httpd::mod::wsgi

  # Create a copy of the wsgi file with apache user permissions.
  file { '/etc/refstack/app.wsgi':
    ensure  => present,
    owner   => $::httpd::params::user,
    group   => $::httpd::params::group,
    mode    => '0644',
    source  => "${src_www_root}/refstack/api/app.wsgi",
    require => [
      Class['refstack::api']
    ],
    notify  => Service['httpd'],
  }

  # Synchronize the app directory and the apache directory.
  file { $install_www_root:
    ensure  => directory,
    owner   => $::httpd::params::user,
    group   => $::httpd::params::group,
    source  => "${src_www_root}/refstack-ui/app",
    recurse => true,
    purge   => true,
    force   => true,
    notify  => Service['httpd'],
  }

  # Set up RefStack as HTTP.
  httpd::vhost { $hostname:
    port     => 80,
    docroot  => $install_www_root,
    priority => '50',
    template => 'refstack/refstack_http.vhost.erb',
    ssl      => false,
    notify   => Service['httpd'],
    require  => File['/etc/refstack/app.wsgi'],
  }
}
