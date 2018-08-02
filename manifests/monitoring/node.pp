class appie::monitoring::node {

    # munin
    class { 'munin::node':
        service_ensure => running,
        allow => $appie::monitoring['masters'],
    }

    # nagios
    package { [
            'nagios-nrpe-server', 'monitoring-plugins', 'nagios-plugins-contrib'
        ]: ensure => installed
    }
    file {
        '/etc/nagios/nrpe.cfg':
            require => Package['nagios-nrpe-server'],
            content => epp("appie/nagios/nrpe.cfg.epp", {
               allowed_hosts => $appie::monitoring['masters'],
            }),
            notify => Service['nagios-nrpe-server'];
    }
    service { 'nagios-nrpe-server':
        ensure => running,
        enable => true,
        require => [File['/etc/nagios/nrpe.cfg']];
    }

    $appie::monitoring['masters'].each |$host| {
        firewall { "020 monitoring ${host}":
            source => $host,
            dport => [4949,5666],  # munin, nagios
            proto => tcp,
            action => accept;
        }
    }

}
