class appie::monitoring::master (
        $admins = {
            admin => "root@$::fqdn",
        },
        $hosts = ['zz01.gw20e.com'],
        $services = {
            load => '
                service_description Load
                max_check_attempts 2',
            users => '
                service_description Logged-in Users',
            disks => '
                service_description Disk Usage
                max_check_attempts 2',
            total_procs => '
                service_description Processes',
            zombie_procs => '
                service_description Zombie Processes',
        },
) {

    $db = {
        ido => {
            'dbname' => 'icinga2',
            'username' => 'icinga2',
            'password' => 'YnunVNhbf6Ec4Vilt4blOLB2rvg',
        },
        web => {
            'dbname' => 'icingaweb2',
            'username' => 'icingaweb2',
            'password' => 'vaUUmMEFk8ZApzIdYbgCh4gdU5A',
        },
    }

    include ::postgresql::server
    postgresql::server::db {
        $db['ido']['dbname']:
            user     => $db['ido']['username'],
            password => postgresql_password($db['ido']['username'], $db['ido']['password']);
        $db['web']['dbname']:
            user     => $db['web']['username'],
            password => postgresql_password($db['web']['username'], $db['web']['password']);
    }
    package { 'php7.0-pgsql': ensure => installed }

    class { '::icinga2': manage_repo => true }
    class{ '::icinga2::feature::idopgsql':
        user          => $db['ido']['username'],
        password      => $db['ido']['password'],
        database      => $db['ido']['dbname'],
        import_schema => true,
        require       => Postgresql::Server::Db[$db['ido']['dbname']],
    }

    class {'icingaweb2':
        manage_repo   => false,
        import_schema => true,
        db_type       => 'pgsql',
        db_host       => 'localhost',
        db_port       => 5432,
        db_name       => $db['web']['dbname'],
        db_username   => $db['web']['username'],
        db_password   => $db['web']['password'],
        require       => Postgresql::Server::Db[$db['web']['dbname']],
    }

    class {'icingaweb2::module::monitoring':
        ido_host        => 'localhost',
        ido_db_name     => $db['ido']['dbname'],
        ido_db_username => $db['ido']['username'],
        ido_db_password => $db['ido']['password'],
        commandtransports => {
            icinga2 => {
                transport => 'api',
                username  => 'root',
                password  => 'icinga',
            }
        }
    }

  # icingaweb2::config::resource{'my-sql':
  #     type        => 'db',
  #     db_type     => 'pgsql',
  #     host        => 'localhost',
  #     port        => 5432,
  #     db_name     => $db['web']['dbname'],
  #     db_username => $db['web']['username'],
  #     db_password => $db['web']['password'],
  # }
    icingaweb2::config::authmethod{'localdb':
        backend  => 'db',
        resource => 'pgsql-icingaweb2',
        order    => '01',
    }

    ::apache::mod { ['dir', 'env', 'proxy_fcgi']: }

    class { 'phpfpm': poold_purge => true, }
    phpfpm::pool { 'icinga':
        listen                 => '127.0.0.1:9000',
        listen_allowed_clients => '127.0.0.1',
        chdir                  => '/usr/share/icingaweb2/public',
        env                    => {
            'ICINGAWEB_CONFIGDIR' => '/etc/icingaweb2',
        },
    }

  # exec { "check-letsencript-$::fqdn":
  #     path    => '/bin:/usr/bin',
  #     command => 'false',
  #     unless  => "test -f /etc/letsencrypt/live/$::fqdn/fullchain.pem";
  # }

    apache::vhost {
        $::fqdn:
            require => Exec["check-letsencript-$::fqdn"],
            port => 443,
            ssl => true,
            ssl_cert => "/etc/letsencrypt/live/$::fqdn/fullchain.pem",
            ssl_key => "/etc/letsencrypt/live/$::fqdn/privkey.pem",
            docroot => '/var/www/html/localhost',

            aliases => [
                {
                    alias => '/icingaweb2',
                    path => '/usr/share/icingaweb2/public',
                },
            ],
            directories => [
                {
                    path => '/usr/share/icingaweb2/public',
                    custom_fragment => '

    Options SymLinksIfOwnerMatch
    AllowOverride None

    DirectoryIndex index.php

    <IfModule mod_authz_core.c>
        # Apache 2.4
        <RequireAll>
            Require all granted
        </RequireAll>
    </IfModule>

    <IfModule !mod_authz_core.c>
        # Apache 2.2
        Order allow,deny
        Allow from all
    </IfModule>

    SetEnv ICINGAWEB_CONFIGDIR "/etc/icingaweb2"

    EnableSendfile Off

    <IfModule mod_rewrite.c>
        RewriteEngine on
        RewriteBase /icingaweb2/
        RewriteCond %{REQUEST_FILENAME} -s [OR]
        RewriteCond %{REQUEST_FILENAME} -l [OR]
        RewriteCond %{REQUEST_FILENAME} -d
        RewriteRule ^.*$ - [NC,L]
        RewriteRule ^.*$ index.php [NC,L]
    </IfModule>

    <IfModule !mod_rewrite.c>
        DirectoryIndex error_norewrite.html
        ErrorDocument 404 /icingaweb2/error_norewrite.html
    </IfModule>
    
    <FilesMatch "\.php$">
        SetHandler "proxy:fcgi://127.0.0.1:9000"
        ErrorDocument 503 /icingaweb2/error_unavailable.html
    </FilesMatch>


                    ',
                },
            ],

    }

}



#    package { ['nagios', 'nagios-plugins-nrpe', 'php-cli']:
#        ensure => installed;
#    }
#    service { 'nagios':
#        ensure => running,
#        enable => true,
#        require => File['/etc/nagios/conf.d/config.cfg'],
#    }
#    file {
#        default:
#           require => Package['nagios'];
#        '/etc/nagios/conf.d/config.cfg':
#            content => template("appie/nagios/config.cfg.erb"),
#            notify => Service['nagios'];
#        '/etc/munin/passwd':
#            content => 'muninadmin:$apr1$sfogXy3t$5O/Llhbk/TBwtUaw.cWJg0';
#        '/etc/nagios/passwd':
#            content => 'nagiosadmin:$apr1$Hj4n5NSt$GhxxTWkWDFUwBNi6d1.pu.';
#    }
