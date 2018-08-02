class appie::base_firewall () {

    resources { "firewall": purge => true }
    class { 'firewall': }
    firewall {
        '000 accept all icmp':
            proto => 'icmp',
            action => 'accept';
        '001 accept all to lo interface':
            proto => 'all',
            iniface => 'lo',
            action => 'accept';
        '002 accept related established rules':
            proto => 'all',
            state => ['RELATED', 'ESTABLISHED'],
            action => 'accept';
        '010 maintenance':
            dport => [22],  # ssh, backup
            proto => tcp,
            action => accept;
        '999 drop all':
            proto => 'all',
            action => 'drop';
    }
}
