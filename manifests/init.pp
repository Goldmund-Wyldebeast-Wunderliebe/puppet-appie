class appie (
    Hash $accountinfo  = {},
    Hash $appenvs      = {},
    Hash $backupserver = {},
    Hash $backupclient = {},
    Hash $monitoring   = {},
    Hash $mailconfig   = {},
    Array $users       = [],
    Array $root_users  = [],
    Array $gone_users  = [],
    Array $packages    = [],
) {
    $config = {
        backupserver => $backupserver,
        backupclient => $backupclient,
        mailconfig   => $mailconfig,
        accountinfo  => $accountinfo,
        root_users   => $root_users,
        gone_users   => $gone_users,
        users        => $users,
    }
    include ::ssh
    include '::appie::base_firewall'
    include '::appie::backupclient'
    include '::appie::postfix'
    include '::appie::monitoring::node'
    include '::appie::users'
    include '::appie::webserver'
    include '::appie::extradisks'

    create_resources(appie::appenv, $appenvs)
    package { $packages: ensure => installed }
}
