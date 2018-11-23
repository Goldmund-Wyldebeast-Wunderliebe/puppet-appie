class appie::webserver (
    String $catchall_redirect  = 'http://example.com',
    Boolean $default_server = false,
) {

    include '::apache'
    include '::apache::mod::event'
    include '::apache::mod::ssl'

    apache::vhost {
        'catchall':
            priority       => '00',
            port           => '80',
            redirect_dest  => $catchall_redirect,
            docroot        => '/var/www/html';
        'localhost':
            serveraliases  => ['127.0.0.1'],
            port           => '80',
            docroot        => '/var/www/html/localhost',
            manage_docroot => false;
    }
    apache::vhost::custom {
        'http2':
            content => "Protocols h2 http/1.1\n",
            priority => '00';
    }
    if ($default_server) {
        apache::vhost {
            $::fqdn:
                require  => Exec["check-letsencrypt-$::fqdn"],
                port     => 443,
                ssl      => true,
                ssl_cert => "/etc/letsencrypt/live/$::fqdn/fullchain.pem",
                ssl_key  => "/etc/letsencrypt/live/$::fqdn/privkey.pem",
                docroot  => '/var/www/html/localhost';
        }
    }

    firewall {
        '100 webserver':
            dport => [80, 443],
            proto => tcp,
            action => accept;
    }
}
