class appie {

    class background() {
        package { [
                'ssh', 'sudo',
                'python-virtualenv', 'python-pip', 'python-dev',
                'python-psycopg2', 'libpq-dev',
                'python-sqlite', 'sqlite3',
                'git', 'mercurial', 'subversion',
                'libxslt1-dev',
                'gettext', 'build-essential', 'pkg-config',
                'libpcre3-dev',
                'less', 'vim-nox',
                'libbz2-dev',
                # 'apache2' or 'nginx',
            ]:
            ensure => installed,
        }

        file { "/opt/APPS":
            ensure => directory,
            owner => root,
            group => root,
            mode => '0755',
        }
    }

    define app(
            $envs,
            $accountinfo,
            $accounts = [],
            $secret = '',
            $makedb = False,
            $webserver = 'apache2',
            ) {
        require appie::background
        file { "/opt/APPS/$name":
            ensure => directory,
            owner => root,
            group => root,
            mode => '0755',
            require => File["/opt/APPS"],
        }
        $env_keys = keys($envs)
        $users = split(
            inline_template(
                '<%= env_keys.map { |x| "app-"+name+"-"+x }.join(",") %>'),
            ',')
        if (size($accounts) > 0) {
            $allow = $accounts
        } else {
            $allow = keys($accountinfo)
        }
        appie::appenv { $users:
            app => $name,
            accountinfo => $accountinfo,
            accounts => $allow,
            secret => $secret,
            makedb => $makedb,
            webserver => $webserver,
            envs => $envs,
        }
    }

    define appenv(
            $app,
            $accountinfo,
            $accounts,
            $secret,
            $makedb,
            $webserver,
            $envs,
            ) {
        $words = split($name, '-')
        $env = $words[-1]
        $home_dir = "/opt/APPS/$app/$env"
        $ssh_dir = "$home_dir/.ssh"
        $user = "$name"
        $uid = $envs[$env][uid]

        group { $user:
            gid => $uid,
            ensure => 'present',
        }
        user { $user:
            require => [Group[$user], File["/opt/APPS/$app"]],
            ensure => 'present',
            uid => $uid,
            gid => $user,
            home => $home_dir,
            managehome => true,
            shell => '/bin/bash',
        }

        # SSH access to this account
        file { $ssh_dir:
            require => User[$user],
            ensure => directory,
            owner => $user,
            group => $user,
            mode => '0700',
        }
        file { "${ssh_dir}/known_hosts2":
            require => File[$ssh_dir],
            owner => $user,
            group => $user,
            mode => 600,
            source => "puppet:///modules/appie/ssh/known_hosts",
        }
        file { "${ssh_dir}/authorized_keys":
            require => File[$ssh_dir],
            owner => $user,
            group => $user,
            mode => 600,
            #source => "puppet:///modules/appie/ssh/authorized_keys",
            content => template("appie/authorized_keys.erb"),
        }

        # buildout defaults (eggs-directory)
        file { "${home_dir}/.buildout":
            require => User[$user],
            ensure => directory,
            owner => $user,
            group => $user,
            mode => '0700',
        }
        file { [
                "${home_dir}/.buildout/eggs",
                "${home_dir}/.buildout/download",
            ]:
            require => File["${home_dir}/.buildout"],
            ensure => directory,
            owner => $user,
            group => $user,
            mode => '0700',
        }
        file { "${home_dir}/.buildout/default.cfg":,
            require => File["${home_dir}/.buildout"],
            owner => $user,
            group => $user,
            mode => '0600',
            content => template("appie/buildout-default.erb"),
        }


        # APACHE/NGINX & SUDO config
        file { "$home_dir/sites-enabled":
            require => User[$user],
            ensure => directory,
            owner => $user,
            group => $user,
            mode => '0755',
        }
        if ($webserver == 'nginx') {
            file {
                "/etc/nginx/sites-enabled/zzz-$user":
                    require => Package['nginx'],
                    content => "include $home_dir/sites-enabled/*;\n",
                    owner => root,
                    group => root,
                    mode => '0444';
                "/etc/sudoers.d/$user":
                    content => "$name ALL=NOPASSWD: \
                            /etc/init.d/nginx reload\n",
                    require => Package['sudo'],
                    owner => root,
                    group => root,
                    mode => '0440';
            }
        } elsif ($webserver == 'apache2') {
            file {
                "/etc/apache2/sites-enabled/zzz-$user":
                    ensure => absent;
                "/etc/apache2/sites-enabled/zzz-$user.conf":
                    require => Package['apache2'],
                    content => "Include $home_dir/sites-enabled/\n",
                    owner => root,
                    group => root,
                    mode => '0444';
                "/etc/sudoers.d/$user":
                    content => "$name ALL=NOPASSWD: \
                            /etc/init.d/apache2 reload\n",
                    require => Package['sudo'],
                    owner => root,
                    group => root,
                    mode => '0440';
            }
        }

        if ($makedb and $secret) {
            # DB access.  For a better idea to manage DB user/password, see:
            # http://serverfault.com/questions/353153/managing-service-passwords-with-puppet
            $dbpassword = sha1("${fqdn}-${user}-$secret")
            file { "${home_dir}/.pgpass":
                content => "localhost:5432:$user:$user:$dbpassword\n",
                owner => $user,
                group => $user,
                mode => '0400',
            }
            require postgresql::server
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
