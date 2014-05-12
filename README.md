puppet-appie
============

Easy setup of everything you need to deploy a new django site.
See https://github.com/Goldmund-Wyldebeast-Wunderliebe/templateproject for a quick start.

------------
Installation
------------

Install the package::

  git clone git@github.com:Goldmund-Wyldebeast-Wunderliebe/puppet-appie.git /etc/puppet/modules/appie

-----
Usage
-----

Add a section in your /etc/puppet/manifests/site.pp::

    # bobbies laptop
    node 'kiezel.gw20e.com' {
        class { 'ssh':
            server_options => {
                'PasswordAuthentication' => 'no',
                'PermitRootLogin' => 'no',
            },
        }
        appie::app { "mysite":
            envs => ["tst", "acc", "prd"],
            secret => "some-secret-change-this",
            accountinfo => $gw20e::user_accounts,
            accounts => ['ganzevoort', 'vandermeij'],
        }
    }

Change the secret! It's used (hashed with hostname and database name) to create the database password.

The account info should be a hash like::

  {
    ganzevoort => {
      sshkeytupe => 'ssh-rsa',
      sshkey => 'AAA.....',
      # other info
    },
    # other accounts
  }

It creates users app-mysite-tst, -acc, -prd with associated postgres databases and nginx configuration.
The homedirectory (/opt/APPS/mysite/tst etc) contains:

.pgpass with DB credentials,
.ssh/authorized_keys allowing users to login to this user/host,
.ssh/known_hosts for github.com's hostkey,
sites-enabled/ empty directory that's read by nginx.
