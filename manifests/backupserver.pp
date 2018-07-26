class appie::backupserver {
     $config = $::appie::config['backupserver']
     if (!$config) {
        fail("::appie::backupserver config missing for $::fqdn")
     }

    $device = $config['device']
    if ($device) {
        $mountpoint = '/var/lib/backuppc'
        exec { "mkdir $mountpoint":
            path => '/bin:/usr/bin',
	    unless => "test -d $mountpoint";
        }
        mount { $mountpoint:
            require => Exec["mkdir $mountpoint"],
            before => Package['backuppc'],
            device => $device,
            fstype => 'ext4',
            ensure => 'mounted',
            options => 'rw,noexec,nosuid,nodev,noatime,errors=remount-ro',
            atboot => true,
        }
    }

    class { 'backuppc::server':
        backuppc_password => $config['backuppc_password'],
        topdir            => $topdir,
    }

    package { 'libfile-rsyncp-perl': ensure => installed }
    apache::mod { ['dir', 'cgid']: }

    exec { "check-letsencript-$::fqdn":
        path => '/bin:/usr/bin',
        command => 'false',
        unless => "test -f /etc/letsencrypt/live/$::fqdn/fullchain.pem";
    }
    apache::vhost {
        $::fqdn:
            require => Exec["check-letsencript-$::fqdn"],
            port => 443,
            ssl => true,
            ssl_cert => "/etc/letsencrypt/live/$::fqdn/fullchain.pem",
            ssl_key => "/etc/letsencrypt/live/$::fqdn/privkey.pem",
            docroot => '/var/www/html/localhost';
    }
}
