class appie::users (
) {
    user {
        $appie::gone_users:
            ensure => absent;
    }

    each (unique($appie::root_users + $appie::users)) |$user| {
        $home_base = "/home"
        $home_dir = "$home_base/$user"
        $ssh_dir = "$home_dir/.ssh"
        $allowed_users = [$user]

        user { $user:
            ensure  => 'present',
            home    => $home_dir,
            shell   => '/bin/bash',
        }
        file {
            $home_dir:
                require => User[$user],
                ensure => directory,
                owner => $user,
                group => $user,
                mode => '0755';
            $ssh_dir:
                require => [User[$user], File[$home_dir]],
                ensure  => directory,
                owner   => $user,
                group   => $user,
                mode    => '0700';
            "${ssh_dir}/authorized_keys":
                require => File[$ssh_dir],
                owner   => $user,
                group   => $user,
                mode    => '0600',
                content => epp("appie/ssh/authorized_keys.epp", {
                    'accounts'    => $allowed_users,
                    'accountinfo' => $appie::accountinfo,
                });
        }
    }
    each ($appie::root_users) |$user| {
        file {
            "/etc/sudoers.d/$user":
                content => "$user ALL=(ALL:ALL) NOPASSWD: ALL\n",
                require => Package['sudo'],
                owner => root,
                group => root,
                mode => '0440';
        }
    }
}
