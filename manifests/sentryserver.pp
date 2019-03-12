class appie::sentryserver ($user='', $sitename='') {
    if (!$user) {
        fail("::appie::sentryserver::user missing for $::fqdn")
    }
    if (!$sitename) {
        fail("::appie::sentryserver::sitename missing for $::fqdn")
    }

    package { [
            'python-setuptools', 'python-dev', 'libxslt1-dev', 'gcc',
            'libffi-dev', 'libjpeg-dev', 'libxml2-dev',
            'libyaml-dev', 'libpq-dev',
            'virtualenv', 'supervisor', 'redis-server', 'postgresql-contrib',
        ]: ensure => installed
    }

    sysctl { 'vm.overcommit_memory':
        value  => "1",
        notify => Service["redis"]
    }

    service { 'redis': require => Package['redis-server'], ensure => 'running' }
    postgresql::server::extension {
        'citext': database => 'sentry', ensure => 'present';
    }

    $home = "/opt/$user"
    file {
        ["$home/.sentry", "$home/etc",
         "$home/var", "$home/var/log", "$home/var/run"]:
            ensure => 'directory',
            mode => '0700', owner => $user, group => $user;
        "$home/etc/supervisord.conf":
            require => File["$home/etc"],
            mode => '0400', owner => $user, group => $user,
            content => epp("appie/sentry/supervisord.conf.epp", {
                'home' => $home,
            });
        "$home/.sentry/INSTALL":
            require => File["$home/.sentry"],
            mode => '0500', owner => $user, group => $user,
            source => "puppet:///modules/appie/sentry/INSTALL";
    }

    apache::vhost {
        "$sitename":
            port => '443',
            ssl => true,
            ssl_cert => "/etc/letsencrypt/live/$sitename/fullchain.pem",
            ssl_key => "/etc/letsencrypt/live/$sitename/privkey.pem",
            proxy_dest => 'http://localhost:9001',
            docroot => '/var/www/html',
            priority => '30';
    }
}
