class appie (
    Hash $accountinfo  = {},
    Hash $appenvs      = {},
    Array $sitenames   = [],
    Hash $backupserver = {},
    Hash $backupclient = {},
    Hash $monitoring   = {},
    Hash $mailconfig   = {},
    Array $users       = [],
    Array $root_users  = [],
    Array $gone_users  = [],
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
    include '::appie::packages'
    include '::appie::backupclient'
    include '::appie::postfix'
    include '::appie::monitoring::node'
    include '::appie::users'
    include '::appie::webserver'
    include '::letsencrypt'
    appie::httpsonly { $sitenames: }
    appie::httpsonly { $fqdn: }

    create_resources(appie::appenv, $appenvs)
}
