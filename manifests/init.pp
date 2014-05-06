class appie {
    file { "/tmp/appie-1.8.1.deb":
        ensure => file,
        source => "puppet:///modules/appie/appie-1.8.1.deb",
    }

    exec { "dpkg -i /tmp/appie-1.8.1.deb":
        alias => "install appie",
        path => [ "/bin/", "/usr/bin/", "/usr/local/sbin", "/usr/sbin", "/sbin" ],
        require => File["/tmp/appie-1.8.1.deb"]
    }

    file { "/etc/sudoers.d/appie_applications":
        source => "puppet:///modules/appie/appie_applications",
	owner => root,
	group => root,
    }
}
