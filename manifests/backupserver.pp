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

    create_resources('class', {'backuppc::server' => delete($config, 'device')})

    package { 'libfile-rsyncp-perl': ensure => installed }
    apache::mod { ['dir', 'cgid']: }
}
