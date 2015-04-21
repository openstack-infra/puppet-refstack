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
# Centralized configuration management for the refstack module.
#
class refstack::params (
  $python_version = '2.7',

  # Source and install directories.
  $src_api_root   = '/opt/refstack-api',

  # The user under which refstack will run.
  $user           = 'refstack',
  $group          = 'refstack',

  # [database] refstack.conf
  $mysql_user             = 'refstack',
  $mysql_user_password,
  $mysql_host             = localhost,
  $mysql_port             = 3306,
  $mysql_database         = 'refstack',
) {

  # Resolve a few parameters based on the install environment.
  if $::operatingsystem != 'Ubuntu' or $::operatingsystemrelease < 13.10 {
    fail("${::operatingsystem} ${::operatingsystemrelease} is not supported.")
  }

  # Create our install directory with a python-versioned name (because venv).
  $install_api_root       = "/var/lib/refstack-py${python_version}"

  # Build the connection string from individual parameters
  $mysql_connection_string = "mysql://${mysql_user}:${mysql_user_password}@${mysql_host}:${mysql_port}/${mysql_database}"

}
