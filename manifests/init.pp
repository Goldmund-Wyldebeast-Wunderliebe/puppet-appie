class appie {

    package { [
            'python-virtualenv', 'python-pip', 'python-dev',
            'python-psycopg2', 'python-sqlite', 'git', 'libxslt-dev',
            'sqlite3', 'gettext',
            'sudo',
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
            home => $home_dir,
            managehome => true,
            shell => '/bin/bash',
        }

    }
}
