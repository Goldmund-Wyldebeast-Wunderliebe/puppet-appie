class appie::packages (
) {
    package { [
            'apt-transport-https', 'unattended-upgrades', 'apt-listchanges',
            'git', 'sudo', 'python-certbot-apache', 'httpie',
        ]: ensure => installed
    }
}
