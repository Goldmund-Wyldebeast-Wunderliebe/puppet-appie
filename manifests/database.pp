define appie::database (
    $dbpassword,
    $pgpass_file,
    $makedb,
    $dbhost,
) {
    $user = $name
    if ($dbpassword) {
        file { "${pgpass_file}":
            content => "$dbhost:5432:$user:$user:$dbpassword\n",
            owner => $user,
            group => $user,
            mode => '0400',
        }
        if ($makedb) {
            require appie::database::pgconfig
            postgresql::server::role { $user:
                createdb => true,
                password_hash => postgresql_password($user, $dbpassword),
            }
            postgresql::server::db { $user:
                user => $user,
                password => postgresql_password($user, $dbpassword),
            }
        }
    }
}

class appie::database::pgconfig {
    include '::postgresql::globals'
    include '::postgresql::server'
}

