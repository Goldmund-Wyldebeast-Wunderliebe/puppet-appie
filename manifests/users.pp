class appie::users (
    Hash $accountinfo,
    Array $root_users,
    Array $gone_users,
    Array $users,
) {
    user {
        $gone_users: ensure => absent;
        join($root_users, $users):
            ensure => 'present';
    }
}

