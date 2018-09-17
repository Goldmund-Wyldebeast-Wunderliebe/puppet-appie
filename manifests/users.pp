class appie::users (
) {
    user {
        $appie::gone_users:
            ensure => absent;
        $appie::root_users:
            ensure => 'present';
        $appie::users:
            ensure => 'present';
    }
}

