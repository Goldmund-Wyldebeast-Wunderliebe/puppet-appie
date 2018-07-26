class appie (
    Hash $accountinfo = {},
    Hash $appenvs = {},
    Array $sitenames = [],
    String $catchall_redirect = 'https://example.com/',
    Hash $backupserver = {},
    Hash $backupclient = {},
) {
    $config = {
	backupserver => $backupserver,
	backupclient => $backupclient,
    }
    include ::ssh
    include '::appie::base_firewall'
    include '::appie::packages'
    include '::appie::backupclient'
    class { '::appie::webserver': catchall_redirect => $catchall_redirect }
    include '::letsencrypt'
    appie::httpsonly { $sitenames: }

    create_resources(appie::appenv, $appenvs)
}
