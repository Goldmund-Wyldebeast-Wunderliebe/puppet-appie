define appie::httpsonly () {
    $sitename = $name
    include ::appie::httpsonly::docroot

    apache::vhost::custom { $sitename:
        priority => 40,
        content => epp("appie/apache/vhost.conf.epp", {
            'sitename' => $sitename,
        });
    }
    letsencrypt::certonly { $sitename:
        plugin => 'webroot',
        webroot_paths => ['/opt/httpsonly/documentroot'],
    }

    exec { "check-letsencrypt-$sitename":
        path    => '/bin:/usr/bin',
        command => 'false',
        unless  => "test -f /etc/letsencrypt/live/$sitename/fullchain.pem";
    }
}

class appie::httpsonly::docroot {
    file { ['/opt/httpsonly', '/opt/httpsonly/documentroot']:
	ensure => directory
    }
}
