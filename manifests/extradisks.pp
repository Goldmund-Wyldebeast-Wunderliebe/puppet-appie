class appie::extradisks ($mounts={}) {
    $mounts.each |String $device, String $mountpoint| {
        notice("${device} -> ${mountpoint}");
        file { $mountpoint: ensure => directory }
        mount { $mountpoint:
            require => File[$mountpoint],
            device => $device,
            fstype => 'ext4',
            ensure => 'mounted',
            options => 'rw,noexec,nosuid,nodev,noatime,errors=remount-ro',
            atboot => true,
        }
    }
}
