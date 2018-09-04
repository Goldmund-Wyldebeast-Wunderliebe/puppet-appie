class appie::postfix {
     $config = $::appie::config['mailconfig']
     if (!$config) {
        fail("::appie::mailconfig config missing for $::fqdn")
     }
     $smarthost = $config['smarthost']
     $adminaddr = $config['adminaddr']

    package { 'postfix': ensure => present; }
    file {
        '/etc/mailname':
            content => "${::fqdn}\n";
        '/etc/postfix/main.cf':
            require => Package['postfix'],
            notify  => Service['postfix'],
            content => epp("appie/postfix/main.cf.epp", $config);
        '/etc/postfix/changerecipient':
            require => Package['postfix'],
            notify  => Service['postfix'],
            content => epp("appie/postfix/changerecipient.epp", $config);
    }
    service {
        'postfix':
            ensure => running,
            enable => true,
            require => Package['postfix'];
    }
}

