class appie::users (
) {
    $make_users = (
        unique($appie::users + $appie::root_users) -
        $appie::gone_users)
    $remove_users = (
        unique($appie::gone_users + keys($appie::accountinfo)) -
        $make_users)
    $make_root_users = ($appie::root_users - $remove_users)
    $make_nonroot_users = ($make_users - $make_root_users)

    each ($remove_users) |$user| {
        user { $user: ensure => absent; }
        group { $user: ensure => absent; }
        file { "/etc/sudoers.d/$user": ensure => absent; }
    }

    each ($make_nonroot_users) |$user| {
        file { "/etc/sudoers.d/$user": ensure => absent; }
    }

    each ($make_users) |$user| {
        $home_base = "/home"
        $home_dir = "$home_base/$user"
        $ssh_dir = "$home_dir/.ssh"
        $allowed_users = [$user]
        $uid = $appie::accountinfo[$user]['uid']

        group { $user:
            ensure  => 'present',
            gid     => $uid,
        }
        user { $user:
            ensure  => 'present',
            require => Group[$user],
            uid     => $uid,
            gid     => $uid,
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

    each ($make_root_users) |$user| {
        file {
            "/etc/sudoers.d/$user":
                content => "$user ALL=(ALL:ALL) NOPASSWD: ALL\n",
                require => [User[$user], Package['sudo']],
                owner => root,
                group => root,
                mode => '0440';
        }
    }
}
