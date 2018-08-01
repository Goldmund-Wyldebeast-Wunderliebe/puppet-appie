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

    class { '::icinga2': manage_repo => true }
    class { '::icingaweb2': }

#   class { '::apache::mod::fcgid':
#       options => {
#           'FcgidIPCDir'  => '/var/run/fcgidsock',
#           'SharememPath' => '/var/run/fcgid_shm',
#           'AddHandler'   => 'fcgid-script .fcgi',
#       },
#   }
    ::apache::mod { ['dir', 'env', 'proxy_fcgi']: }

    class { 'phpfpm':
        poold_purge => true,
#       log_level   => 'debug',
#       error_log   => '/var/log/phpfpm-icinga.log',
    }
    phpfpm::pool { 'icinga':
        listen                 => '127.0.0.1:9000',
        listen_allowed_clients => '127.0.0.1',
        chdir                  => '/usr/share/icingaweb2/public',
        env                    => {
            'ICINGAWEB_CONFIGDIR' => '/etc/icingaweb2',
        },
    }

    exec { "check-letsencript-$::fqdn":
        path    => '/bin:/usr/bin',
        command => 'false',
        unless  => "test -f /etc/letsencrypt/live/$::fqdn/fullchain.pem";
    }
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
