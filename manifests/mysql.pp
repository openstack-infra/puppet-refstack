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

# == Class: refstack::mysql
#
# The RefStack MySQL manifest will install a standalone, localhost instance
# of mysql if mysql_host is set to 'localhost'.
#
class refstack::mysql () {

  require ::refstack::params

  # Import parameters.
  $mysql_host          = $refstack::params::mysql_host
  $mysql_database      = $refstack::params::mysql_database
  $mysql_user          = $refstack::params::mysql_user
  $mysql_user_password = $refstack::params::mysql_user_password

  # Install MySQL
  if $mysql_host == 'localhost' {
    include ::mysql::server

    # Add the refstack database.
    mysql::db { $mysql_database:
      user     => $mysql_user,
      password => $mysql_user_password,
      host     => $mysql_host,
      grant    => ['all'],
    }
  }

  mysql_backup::backup_remote { $mysql_database:
    database_host     => $mysql_host,
    database_user     => $mysql_user,
    database_password => $mysql_user_password,
  }
}
