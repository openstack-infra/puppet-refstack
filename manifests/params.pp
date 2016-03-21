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

# == Class: refstack::params
#
# Centralized configuration management for the Refstack module.
#
class refstack::params (

  # Source and install directories.
  $install_www_root       = '/var/www/refstack-www',
  $src_root               = '/opt/refstack',

  # The user under which refstack will run.
  $group            = 'refstack',
  $hostname         = $::fqdn,
  $protocol         = 'http',
  $server_admin     = undef,
  $user             = 'refstack',

  # [database] refstack.conf
  $mysql_user_password,
  $mysql_database   = 'refstack',
  $mysql_host       = localhost,
  $mysql_port       = 3306,
  $mysql_user       = 'refstack',

  # Apache2 ssl configuration
  $ssl_ca           = undef, # '/etc/ssl/certs/ca.pem'
  $ssl_ca_content   = undef,
  $ssl_cert         = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  $ssl_cert_content = undef,
  $ssl_key          = '/etc/ssl/private/ssl-cert-snakeoil.key',
  $ssl_key_content  = undef,
) {

  # Resolve a few parameters based on the install environment.
  if $::operatingsystem != 'Ubuntu' or $::operatingsystemrelease < 13.10 {
    fail("${::operatingsystem} ${::operatingsystemrelease} is not supported.")
  }

  # Build the connection string from individual parameters
  $mysql_connection_string = "mysql+pymysql://${mysql_user}:${mysql_user_password}@${mysql_host}:${mysql_port}/${mysql_database}"

  # Construct website URL.
  $web_url = "${protocol}://${hostname}"

  $api_url = "${web_url}/api"

  # CA file needs special treatment, since we want the path variable
  # to be undef in some cases.
  if $ssl_ca == undef and $ssl_ca_content != undef {
    $resolved_ssl_ca = '/etc/ssl/certs/refstack.ca.pem'
  } else {
    $resolved_ssl_ca = $ssl_ca
  }
}
