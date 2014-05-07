class appie {

    package { [
            'python-virtualenv', 'python-pip', 'python-dev',
            'python-psycopg2', 'python-sqlite', 'git', 'libxslt1-dev',
            'sqlite3', 'gettext',
            'sudo', 'nginx',
        ]:
        ensure => installed,
    }

    file { "/etc/sudoers.d/appie_applications":
        source => "puppet:///modules/appie/appie_applications",
        owner => root,
        group => root,
    }

    file { "/opt/APPS":
        ensure => directory,
        owner => root,
        group => root,
        mode => '0755',
    }

    group { "appadmin":
        ensure => 'present',
    }

    define app($envs) {
        file { "/opt/APPS/$name":
            ensure => directory,
            owner => root,
            group => root,
            mode => '0755',
        }
        appie::appenv { $envs: app => $name }
    }

    define appenv($app) {
        $home_dir = "/opt/APPS/$app/$name"
        $ssh_dir = "$home_dir/.ssh"
        $user = "app-$app-$name"

        group { $user:
            ensure => 'present',
        }
        user { $user:
            require => Group[$user],
            ensure => 'present',
            gid => $user,
            groups => ["appadmin"],
            home => $home_dir,
            managehome => true,
            shell => '/bin/bash',
        }

        file { $ssh_dir:
            require => User[$user],
            ensure => directory,
            owner => $user,
            group => $user,
            mode => '0700',
        }
        file { "${ssh_dir}/known_hosts":
            require => File[$ssh_dir],
            owner => $user,
            group => $user,
            mode => 600,
            source => "puppet:///modules/appie/ssh/known_hosts"
        }
        file { "${ssh_dir}/authorized_keys":
            require => File[$ssh_dir],
            owner => $user,
            group => $user,
            mode => 600,
            source => "puppet:///modules/appie/ssh/authorized_keys"
        }

        file { "$home_dir/sites-enabled":
            ensure => directory,
            owner => $user,
            group => $user,
            mode => '0755',
        }
        file { "/etc/nginx/conf.d/$user.conf":
            content => "include $home_dir/sites-enabled/*;",
            owner => root,
            group => root,
            mode => '0444',
        }
    }
}
