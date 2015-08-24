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

# == Class: refstack::apache::https
#
# This module installs RefStack onto the current host using an the https
# protocol.
#
class refstack::apache::https () {
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

  $ssl_cert_content       = $::refstack::params::ssl_cert_content
  $ssl_cert               = $::refstack::params::ssl_cert
  $ssl_key_content        = $::refstack::params::ssl_key_content
  $ssl_key                = $::refstack::params::ssl_key
  $ssl_ca_content         = $::refstack::params::ssl_ca_content
  $resolved_ssl_ca        = $::refstack::params::resolved_ssl_ca

  # Install apache
  include ::apache
  include ::apache::params
  include ::apache::mod::wsgi

  # Create a copy of the wsgi file with apache user permissions.
  file { '/etc/refstack/app.wsgi':
    ensure  => present,
    owner   => $::apache::params::user,
    group   => $::apache::params::group,
    mode    => '0644',
    source  => "${src_www_root}/refstack/api/app.wsgi",
    require => [
      Class['refstack::api']
    ],
    notify  => Service['httpd'],
  }

  if $ssl_cert_content != undef {
    file { $ssl_cert:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_cert_content,
      notify  => Service['httpd'],
    }
  }

  if $ssl_key_content != undef {
    file { $ssl_key:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_key_content,
      notify  => Service['httpd'],
    }
  }

  if $ssl_ca_content != undef {
    file { $resolved_ssl_ca:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_ca_content,
      notify  => Service['httpd'],
    }
  }

  # Synchronize the app directory and the apache directory.
  file { $install_www_root:
    ensure  => directory,
    owner   => $::apache::params::user,
    group   => $::apache::params::group,
    source  => "${src_www_root}/refstack-ui/app",
    recurse => true,
    purge   => true,
    force   => true,
    notify  => Service['httpd'],
  }

  # Set up RefStack as HTTPS.
  apache::vhost { $hostname:
    port     => 443,
    docroot  => $install_www_root,
    priority => '50',
    template => 'refstack/refstack_https.vhost.erb',
    ssl      => true,
    notify   => Service['httpd'],
    require  => File['/etc/refstack/app.wsgi'],
  }
}
