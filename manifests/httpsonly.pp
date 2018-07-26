define appie::httpsonly () {
    $sitename = $name
    apache::vhost::custom { $sitename:
        priority => 40,
        content => epp("appie/apache/vhost.conf.epp", {
            'sitename' => $sitename,
        });
    }
    include ::appie::httpsonly::docroot
    letsencrypt::certonly { $sitename:
        plugin => 'webroot',
        webroot_paths => ['/opt/httpsonly/documentroot'],
    }
}

class appie::httpsonly::docroot {
    file { ['/opt/httpsonly', '/opt/httpsonly/documentroot']:
	ensure => directory
    }
}
