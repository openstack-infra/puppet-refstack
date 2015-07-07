node default {
  class { 'refstack':
    hostname            => '192.168.99.88',
    mysql_user_password => 'refstack',
  }
}
