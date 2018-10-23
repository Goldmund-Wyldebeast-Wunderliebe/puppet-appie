define appie::appenv (
        $uid,
        $allow=[],
        $webserver='apache2',
        $makedb=false,
        $dbpassword='',
        $dbhost='localhost',
	$elasticsearch_port=0,
        ) {

    $user = $name
    $home_base = "/opt"
    $home_dir = "$home_base/$user"
    $ssh_dir = "$home_dir/.ssh"
    if (size($allow) > 0) {
        $allowed_users = $allow
    } else {
        $allowed_users = keys($appie::accountinfo)
    }

    group { $user: gid => $uid, ensure => 'present' }
    user { $user:
        require => Group[$user],
        ensure  => 'present',
        uid     => $uid,
        gid     => $user,
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
            ensure => directory,
            owner => $user,
            group => $user,
            mode => '0700';
        "${ssh_dir}/authorized_keys":
            require => File[$ssh_dir],
            owner => $user,
            group => $user,
            mode => '0600',
            content => epp("appie/ssh/authorized_keys.epp", {
                'accounts'    => $allowed_users,
                'accountinfo' => $appie::accountinfo,
            });
    }

    if ($webserver != '') {
        if ($webserver == 'httpd' or $webserver == 'apache2') {
            $configcontent = "IncludeOptional $home_dir/sites-enabled/*.conf\n"
        } elsif ($webserver == 'nginx') {
            $configcontent = "include $home_dir/sites-enabled/*.conf;\n"
        }

        apache::vhost::custom { $user:
            content => $configcontent,
            priority => 50;
        }

        file {
            "$home_dir/sites-enabled":
                require => [User[$user], File[$home_dir]],
                ensure => directory,
                owner => $user,
                group => $user,
                mode => '0755';
            "/etc/sudoers.d/$user":
                content => "$user ALL=(ALL:ALL) NOPASSWD: \
                    /bin/systemctl reload $webserver\n",
                    #apachectl configtest
                require => Package['sudo'],
                owner => root,
                group => root,
                mode => '0440';
        }
    }

    appie::database { $user:
        dbpassword => $dbpassword,
        pgpass_file => "${home_dir}/.pgpass",
	makedb => $makedb,
        dbhost => $dbhost;
    }

    if ($elasticsearch_port > 0) {
	include ::java
	include ::elasticsearch
	elasticsearch::instance {
            $name:
                config => {
                    'cluster.name' => $name,
                    'http.bind_host' => '127.0.0.1',
                    'http.port' => $elasticsearch_port,
                    'transport.tcp.port' => $elasticsearch_port+100,
                };
	}
    }
}

