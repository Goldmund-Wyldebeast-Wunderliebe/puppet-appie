class appie::packages (
) {
    package { [
            'apt-transport-https',
            'git', 'sudo', 'python-certbot-apache', 'httpie',
        ]: ensure => installed
    }
}
