class appie {

    package { [
            'python-virtualenv', 'python-pip', 'python-dev',
            'python-psycopg2', 'python-sqlite', 'git', 'libxslt-dev',
            'sqlite3', 'gettext',
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

    define parent_dir() {
        file { "/opt/APPS/$name":
            ensure => directory,
            owner => root,
            group => root,
            mode => '0755',
        }
    }

    define app($app, $source) {
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

        file { $ssh_dir:
            require => User[$user],
            ensure => directory,
            owner => $user,
            group => $user,
            mode => '0700',
        }

        # Store SSH keys so we can pull from git.gw20e.com
        # TODO: this probably isn't secure..
        file { "${ssh_dir}/id_rsa":
            require => File[$ssh_dir],
            owner => $user,
            group => $user,
            mode => 600,
            source => "puppet:///modules/appie/ssh/id_rsa"
        }
        file { "${ssh_dir}/id_rsa.pub":
            require => File[$ssh_dir],
            owner => $user,
            group => $user,
            mode => 600,
            source => "puppet:///modules/appie/ssh/id_rsa.pub"
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

        vcsrepo { "${home_dir}/project":
            require => [
                User[$user],
                File["${ssh_dir}/known_hosts"],
                File["${ssh_dir}/id_rsa"],
            ],
            ensure => present,
            user => $user,
            provider => git,
            source => $source,
            #revision => $buildout_rev,
        }
    }
}
