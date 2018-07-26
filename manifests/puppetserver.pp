class appie::puppetserver () {
    include ::puppetdb
    include ::puppetdb::master::config
    firewall {
        '100 puppetserver':
            dport => [8140],
            proto => tcp,
            action => accept;
    }
}
