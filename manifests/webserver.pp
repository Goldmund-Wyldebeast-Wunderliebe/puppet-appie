class appie::webserver (
    String $catchall_redirect,
) {

    class { 'apache':
        default_vhost => false,
        default_mods => [
            'ssl', 'mime', 'rewrite', 'setenvif', 'headers',
            'access_compat', 'auth_basic', 'authn_core', 'authn_file',
            'authz_user', 'status',
            'proxy', 'proxy_http',
            'expires', 'deflate',
        ],
        mpm_module => false,
    }

    class { 'apache::mod::event':
        serverlimit => 25,
        startservers => 4,
        minsparethreads => 50,
        maxsparethreads => 200,
        threadsperchild => 50,
        threadlimit => 100,
    }

    class { 'apache::mod::ssl':
        ssl_compression => false,
        ssl_protocol => ['all', '-SSLv2', '-SSLv3', '-TLSv1', '-TLSv1.1'],
        ssl_cipher => 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS',
        ssl_honorcipherorder => true,
    }

    apache::vhost {
        'catchall':
            port => '80',
            redirect_dest => $catchall_redirect,
            docroot => '/var/www/html';
        'localhost':
            serveraliases => ['127.0.0.1'],
            port => '80',
            docroot => '/var/www/html/localhost',
            manage_docroot => false;
        $::fqdn:
            require => Exec["check-letsencript-$::fqdn"],
            port => 443,
            ssl => true,
            ssl_cert => "/etc/letsencrypt/live/$::fqdn/fullchain.pem",
            ssl_key => "/etc/letsencrypt/live/$::fqdn/privkey.pem",
            docroot => '/var/www/html/localhost';
    }

    firewall {
        '100 webserver':
            dport => [80, 443],
            proto => tcp,
            action => accept;
    }
}
