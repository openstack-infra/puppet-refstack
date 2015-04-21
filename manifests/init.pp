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

# == Class: refstack
#
# This class installs and updates refstack in a continuous-deployment fashion
# directly from its git repositories.
#
class refstack (
  $mysql_database      = 'refstack',
  $mysql_user          = 'refstack',
  $mysql_user_password,
) {

  # Configure the entire refstack instance. This does not install anything,
  # but ensures that variables are consistent across all modules.
  class { '::refstack::params':
    mysql_database         => $mysql_database,
    mysql_user             => $mysql_user,
    mysql_user_password    => $mysql_user_password,
  }

  include ::refstack::mysql
  include ::refstack::api
}
