define appie::httpsonly (
    $redirect_dest = undef,
    $priority      = '99',
) {
    $sitename = $name
    include ::appie::httpsonly::docroot

    include '::letsencrypt'
    letsencrypt::certonly { $sitename:
        plugin => 'webroot',
        webroot_paths => ['/opt/httpsonly/documentroot'],
    }

    exec { "check-letsencrypt-$sitename":
        path    => '/bin:/usr/bin',
        command => 'false',
        unless  => "test -f /etc/letsencrypt/live/$sitename/fullchain.pem";
    }

    apache::vhost { "${sitename}-default":
        require         => Exec["check-letsencrypt-${sitename}"],
        priority        => $priority,
        port            => 443,
        ssl             => true,
        ssl_cert        => "/etc/letsencrypt/live/${sitename}/fullchain.pem",
        ssl_key         => "/etc/letsencrypt/live/${sitename}/privkey.pem",
        servername      => $sitename,
        error_log_file  => 'error.log',
        access_log_file => 'access.log',
        docroot         => '/var/www/html/localhost',
        redirect_dest   => $redirect_dest,
   }
}

class appie::httpsonly::docroot {
    file { ['/opt/httpsonly', '/opt/httpsonly/documentroot']:
        ensure => directory
    }
}
