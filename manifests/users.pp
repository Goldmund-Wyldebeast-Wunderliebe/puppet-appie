class appie::users (
) {
    user {
        $appie::gone_users:
            ensure => absent;
        unique($appie::root_users + $appie::users):
            ensure => 'present';
    }
}

