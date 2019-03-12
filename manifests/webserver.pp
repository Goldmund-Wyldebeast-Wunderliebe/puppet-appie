class appie::webserver (
    Array $sitenames = [],
    Hash $redirects = {},
    Boolean $default_server = false,
) {
    include '::apache'
    include '::apache::mod::event'
    include '::apache::mod::ssl'
    include '::apache::mod::alias'

    firewall {
        '100 webserver':
            dport => [80, 443],
            proto => tcp,
            action => accept;
    }

    apache::vhost::custom { 'http2':
        priority => '00',
        content  => "Protocols h2 http/1.1\n",
    }
    apache::vhost::custom { 'catchall':
        priority => '01',
        content => epp("appie/apache/vhost.conf.epp", {
            'sitename' => $::fqdn,
        });
    }
    apache::vhost { 'localhost':
        priority            => '02',
        serveraliases       => ['127.0.0.1'],
        port                => '80',
        docroot             => '/var/www/html/localhost',
        manage_docroot      => false,
        error_log_file      => 'error.log',
        access_log_file     => 'access.log',
    }
    if ($default_server) {
        appie::httpsonly { $::fqdn:
            priority => '03',
        }
    }
    appie::httpsonly { $sitenames: }
    $redirects.each |$sitename, $redirect_dest| {
        appie::httpsonly { $sitename:
            redirect_dest => $redirect_dest,
        }
    }

    file { '/var/www/html/localhost/index.html':
        content => "hello\n";
    }
}
