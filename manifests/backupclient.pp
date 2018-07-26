class appie::backupclient {
     $config = $::appie::config['backupclient']
     if (!$config) {
        warning("::appie::backupclient config missing for $::fqdn")
     } else {
        $server = $config['server']
        $shares = $config['shares']
        if (!$server) {
            warn("::appie::backupclient::server not set for $::fqdn")
        }
        if (!$shares) {
            warn("::appie::backupclient::shares not set for $::fqdn")
        }
        if ($server and $shares) {
            class { 'backuppc::client':
                backuppc_hostname => $server,
                rsync_share_name  => $shares,
            }
        }
    }
}
