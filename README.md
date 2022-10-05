moodle-toolbox
==============

This is a small Bash script collection which makes handling of multiple Moodle instances and working with Moodle code quite handy.


Requirements
------------

This toolbox requires an up-to-date Bash installation and, for running Moodle CLI scripts, and installed PHP-CLI interpreter.


Installation
------------

Clone the toolbox into a directory on your webserver, for example:
/opt/moodle-toolbox

Then, have a look at the configuration files
/_config/localconfig.dist.sh,
/_config/localcredentials.dist.sh,
copy the files to
/_config/localconfig.sh,
/_config/localcredentials.sh,
and adapt these configuration files to your local needs. All configuration settings should be commented well in the configuration dist files.

Futhermore, have a look at the template files below
/_template/
and adapt the config.php template files for new installations to your local needs.


Usage
-----

### /commands/run

In this folder, you will find scripts which can be used on all kinds of Moodle instances (prod / test / dev).

#### mtb-site-init.php

This script is used to initialize a Moodle instance. It needs just some basic parameters about the site and will setup the instance structure on disk.

```
Usage:
mtb-site-init.sh -s <site> -i <instance> [-a] [-d <distro>] [-r <release>]

Mandatory parameters:
  -s <site>
     The Moodle site which is to be used by this script
     This parameter expects the folder name of the Moodle site below the basedir.
     When running the script, a list of possible values can be requested with the -h parameter.
  -i <instance>
     The instance of the Moodle site which is to be used by this script
     This parameter expects the instance name of the instance of the Moodle site.
     When running the script, a list of possible values can be requested with the -h parameter.

Optional parameters:
  -a
     Auto mode
     If this flag is set, the script will not ask for any confirmations
  -d <distro>
     The Moodle distribution which is to be used by the scripts
     This parameter expects the distribution name of the instance of the Moodle site.
     When running the script, a list of possible values can be requested with the -h parameter.
     If not given, this parameter value is taken from the Moodle toolbox configuration file.
  -r <release>
     The Moodle release which is to be used by the scripts
     This parameter expects the release number of the instance of the Moodle site.
     When running the script, a list of possible values can be requested with the -h parameter.
     If not given, this parameter value is taken from the Moodle toolbox configuration file.
```

#### mtb-site-install.php

This script is used to install a Moodle instance. It needs some additional parameters about the database and the site and will install the site / initialize the database.

```
Usage:
mtb-site-install.sh -s <site> -i <instance> -f <fullname> -t <shortname> -n <dbname> -u <dbuser> -p <dbpass> [-a] [-d <distro>] [-r <release>] [-m <maxbytes>] [-l <language>] [-j]

Mandatory parameters:
  -s <site>
     The Moodle site which is to be used by this script
     This parameter expects the folder name of the Moodle site below the basedir.
     When running the script, a list of possible values can be requested with the -h parameter.
  -i <instance>
     The instance of the Moodle site which is to be used by this script
     This parameter expects the instance name of the instance of the Moodle site.
     When running the script, a list of possible values can be requested with the -h parameter.
  -f <fullname>
     The full name to be set for the Moodle site
  -t <shortname>
     The short name to be set for the Moodle site
  -n <dbname>
     The database name to be set for the Moodle site
  -u <dbuser>
     The database user to be set for the Moodle site
  -p <dbpass>
     The database password to be set for the Moodle site

Optional parameters:
  -a
     Auto mode
     If this flag is set, the script will not ask for any confirmations
  -d <distro>
     The Moodle distribution which is to be used by the scripts
     This parameter expects the distribution name of the instance of the Moodle site.
     When running the script, a list of possible values can be requested with the -h parameter.
     If not given, this parameter value is taken from the Moodle toolbox configuration file.
  -r <release>
     The Moodle release which is to be used by the scripts
     This parameter expects the release number of the instance of the Moodle site.
     When running the script, a list of possible values can be requested with the -h parameter.
     If not given, this parameter value is taken from the Moodle toolbox configuration file.
  -m <maxbytes>
     The Moodle maxbytes setting to be set for the Moodle site
     If not given, this parameter value is taken from the Moodle toolbox configuration file.
  -l <language>
     The language pack to be set for the Moodle site
     If not given, this parameter value is taken from the Moodle toolbox configuration file.
  -j
     Initialize H5P content types
     If this flag is set, the script will download the H5P content types to the Moodle instance initially
```

#### mtb-site-configure.php

This script is used to configure a Moodle instance. It needs just some basic parameters about the site and will apply the basic configuration as it is defined in the configuration templates.

```
Usage:
mtb-site-configure.sh -s <site> -i <instance> [-a] [-d <distro>] [-r <release>]

Mandatory parameters:
  -s <site>
     The Moodle site which is to be used by this script
     This parameter expects the folder name of the Moodle site below the basedir.
     When running the script, a list of possible values can be requested with the -h parameter.
  -i <instance>
     The instance of the Moodle site which is to be used by this script
     This parameter expects the instance name of the instance of the Moodle site.
     When running the script, a list of possible values can be requested with the -h parameter.

Optional parameters:
  -a
     Auto mode
     If this flag is set, the script will not ask for any confirmations
  -d <distro>
     The Moodle distribution which is to be used by the scripts
     This parameter expects the distribution name of the instance of the Moodle site.
     When running the script, a list of possible values can be requested with the -h parameter.
     If not given, this parameter value is taken from the Moodle toolbox configuration file.
  -r <release>
     The Moodle release which is to be used by the scripts
     This parameter expects the release number of the instance of the Moodle site.
     When running the script, a list of possible values can be requested with the -h parameter.
     If not given, this parameter value is taken from the Moodle toolbox configuration file.
```

#### mtb-site-brand.php

This script is used to brand a Moodle instance. It expects additional parameters about the details which should be branded.

```
Usage:
mtb-site-brand.sh -s <site> -i <instance> [-a] [-d <distro>] [-k <customerdomain>] [-b <bbbuser> -c <bbbtoken>] [[-x <smtpserver>] -y <smtpuser> -z <smtppass>]

Mandatory parameters:
  -s <site>
     The Moodle site which is to be used by this script
  -i <instance>
     The instance of the Moodle site which is to be used by this script

Optional parameters:
  -a
     Auto mode
     If this flag is set, the script will not ask for any confirmations
  -d <distro>
     The Moodle distribution which is to be used by the scripts
     When running the script, a list of possible values can be requested with the -h parameter.
     If not given, this parameter value is taken from the Moodle toolbox configuration file.

  Customer domain:
    -k <customerdomain>
       The customer domain to be set for the Moodle site

  BBB token (all or none of these optional parameters have to be given):
    -b <bbbuser>
       The BBB user to be set for the Moodle site
    -c <bbbtoken>
       The BBB token to be set for the Moodle site

  SMTP server (at least the user and pass parameters or none of these optional parameters have to be given):
    -x <smtpserver>
       The SMTP mail server which is used for outgoing mail
    -y <smtpuser>
       The SMTP mail user which is used for outgoing mail
    -z <smtppass>
       The SMTP mail password which is used for outgoing mail
```

#### mtb-site-downgrade.php

This script is used to downgrade the core and plugin versions stored in the Moodle database to the versions stored in the version.php files on disk.
It does not do any rollback of upgrade steps. Please use it only for development or emergency purposes.

```
Usage:
mtb-site-downgrade.sh -s <site> -i <instance> [-d <distro>]

Mandatory parameters:
  -s <site>
     The Moodle site which is to be used by this script
     This parameter expects the folder name of the Moodle site below the basedir.
     When running the script, a list of possible values can be requested with the -h parameter.
  -i <instance>
     The instance of the Moodle site which is to be used by this script
     This parameter expects the instance name of the instance of the Moodle site.
     When running the script, a list of possible values can be requested with the -h parameter.

Optional parameters:
  -d <distro>
     The Moodle distribution which is to be used by the scripts
     This parameter expects the distribution name of the instance of the Moodle site.
     When running the script, a list of possible values can be requested with the -h parameter.
```

#### mtb-site-permissions.php

This script is used to fix the permissions on disk.
Normally, all site scripts which deal with files should fix permissions at the end anyway. However, after manual modifications and to fix issues, this script can be useful.

```
Usage:
mtb-site-permissions.sh -s <site> -i <instance> [-d <distro>] [-a]

Mandatory parameters:
  -s <site>
     The Moodle site which is to be used by this script
     This parameter expects the folder name of the Moodle site below the basedir.
     When running the script, a list of possible values can be requested with the -h parameter.
  -i <instance>
     The instance of the Moodle site which is to be used by this script
     This parameter expects the instance name of the instance of the Moodle site.
     When running the script, a list of possible values can be requested with the -h parameter.

Optional parameters:
  -a
     Auto mode
     If this flag is set, the script will not ask for any confirmations
  -d <distro>
     The Moodle distribution which is to be used by the scripts
     This parameter expects the distribution name of the instance of the Moodle site.
     When running the script, a list of possible values can be requested with the -h parameter.
```

### /commands/dev

In this folder, you will find scripts which can be used to do various Moodle dev tasks.

#### mtb-plugin-upgrade-prepare.php

This script is used to prepare a plugin upgrade.
It is used as the first of three scripts which must be used in combination to easily publish new plugin major versions.

```
Usage:
mtb-plugin-upgrade-prepare.sh -p <path> -m <machinerelease> -r <release> -d <date> -c <coreversion> [-a <path>]

Mandatory parameters:
  -p <path>
     The (full) path to the plugin directory where the plugin to be upgraded is located.
     This path does not necessarily have to be located within a runnning Moodle site.
  -m <machinerelease>
     The (machine readable) target release of the plugin.
  -r <release>
     The (human readable) target release of the plugin.
  -d <date>
     The date of the upgrade.
     This is just needed for the CHANGELOG entry.
  -v <version>
     The version of the release of the plugin.
     Ideally, this matches the date in the CHANGELOG entry. Don't forget the two trailing zeros which are required for Moodle versions.
  -c <coreversion>
     The version of the Moodle core which is required for the new release of the plugin.
     You can find the Moodle core releases on https://docs.moodle.org/dev/Releases.

Optional parameters:
  -a <path>
     The (full) path to a shell script which will be sourced after the basic plugin modifications and before committing the results. It can be used to apply additional, release-specific changes to the plugin.
     Please note that the script must be executable.
```

#### mtb-plugin-upgrade-finish.php

This script is used to finish a plugin upgrade.
It is used as the second of three scripts which must be used in combination to easily publish new plugin major versions.

```
Usage:
mtb-plugin-upgrade-finish.sh -p <path> -m <machinerelease> -r <release> -v <version>

Mandatory parameters:
  -p <path>
     The (full) path to the plugin directory where the plugin to be upgraded is located.
     This path does not necessarily have to be located within a runnning Moodle site.
  -m <machinerelease>
     The (machine readable) target release of the plugin.
  -r <release>
     The (human readable) target release of the plugin.
  -v <version>
     The version of the release of the plugin.
     Ideally, this matches the date in the CHANGELOG entry. Don't forget the two trailing zeros which are required for Moodle versions.
```

#### mtb-plugin-upgrade-release.php

This script is used to release a plugin upgrade.
It is used as the third of three scripts which must be used in combination to easily publish new plugin major versions.

```
Usage:
mtb-plugin-upgrade-release.sh -p <path> -m <machinerelease> -r <release>

Mandatory parameters:
  -p <path>
     The (full) path to the plugin directory where the plugin to be upgraded is located.
     This path does not necessarily have to be located within a runnning Moodle site.
  -m <machinerelease>
     The (machine readable) target release of the plugin.
  -r <release>
     The (human readable) target release of the plugin.
```

#### mtb-plugin-patch-commit.php

This script is used to commit a patch to a plugin.
It is normally used to commit a patch to the master branch, but can be used to patch other branches as well.

```
Usage:
mtb-plugin-patch-commit.sh -p <path> -d <date> -m <message> [-v] [-g]

Mandatory parameters:
  -p <path>
     The (full) path to the plugin directory where the plugin which contains the patch is located.
     This path does not necessarily have to be located within a runnning Moodle site.
  -d <date>
     The date of the patch.
     This is just needed for the CHANGELOG entry.
  -m <message>
     The message of the patch.
     This is needed for the CHANGELOG entry and for the commit message

Optional parameters:
  -v
     Raise version.
     If this switch is set, the plugin version in version.php is raised within the commit.
  -g
     Push to Github.
     If this switch is set, the branch is pushed to Github after the commit.
```

#### mtb-plugin-patch-backport.php

This script is used to backport a commit to release branches.

```
Usage:
mtb-plugin-patch-backport.sh -p <path> -b <branches> [-s <shahash>] [-g]

Mandatory parameters:
  -p <path>
     The (full) path to the plugin directory where the plugin which contains the patch is located.
     This path does not necessarily have to be located within a runnning Moodle site.
  -b <branches>
     The branches which the patch should be backported to.
     This parameter expects a comma-separated list of existing branch names.

Optional parameters:
  -s <shahash>
     The SHA hash of the patch to be backported.
     If this parameter is not given, the script backports the HEAD commit in the master branch.
  -g
     Push to Github.
     If this switch is set, the given branches are pushed to Github after the backport.
```

#### mtb-plugin-update-finish-latest.php

This script is used to finish a plugin update for the latest supported release.
It is used as the first of two scripts which must be used in combination to easily publish new plugin minor versions.

```
Usage:
mtb-plugin-update-finish-latest.sh -p <path> -m <machinerelease> -r <release> [-v] [-g]

Mandatory parameters:
  -p <path>
     The (full) path to the plugin directory where the plugin to be updated is located.
     This path does not necessarily have to be located within a runnning Moodle site.
  -m <machinerelease>
     The (machine readable) major version of the plugin update.
  -r <release>
     The (human readable) major version of the plugin update.

Optional parameters:
  -v
     Raise version.
     If this switch is set, the plugin version in version.php is raised within the update.
  -g
     Push to Github.
     If this switch is set, the branches are pushed to Github after the commit.
```

#### mtb-plugin-update-release-latest.php

This script is used to release a plugin update for the latest supported release.
It is used as the second of two scripts which must be used in combination to easily publish new plugin minor versions.

```
Usage:
mtb-plugin-update-release-latest.sh -p <path> -m <machinerelease> -r <release>

Mandatory parameters:
  -p <path>
     The (full) path to the plugin directory where the plugin to be updated is located.
     This path does not necessarily have to be located within a runnning Moodle site.
  -m <machinerelease>
     The (machine readable) major version of the plugin update.
  -r <release>
     The (human readable) major version of the plugin update.
```

#### mtb-plugin-update-finish-legacy.php

This script is used to finish a plugin update for a legacy release.
It is used as the first of two scripts which must be used in combination to easily publish new plugin minor versions.

```
Usage:
mtb-plugin-update-finish-legacy.sh -p <path> -m <machinerelease> -r <release> [-v] [-g]

Mandatory parameters:
  -p <path>
     The (full) path to the plugin directory where the plugin to be updated is located.
     This path does not necessarily have to be located within a runnning Moodle site.
  -m <machinerelease>
     The (machine readable) major version of the plugin update.
  -r <release>
     The (human readable) major version of the plugin update.

Optional parameters:
  -v
     Raise version.
     If this switch is set, the plugin version in version.php is raised within the update.
  -g
     Push to Github.
     If this switch is set, the branches are pushed to Github after the commit.
```

#### mtb-plugin-update-release-legacy.php

This script is used to release a plugin update for a legacy release.
It is used as the second of two scripts which must be used in combination to easily publish new plugin minor versions.

```
Usage:
mtb-plugin-update-release-legacy.sh -p <path> -m <machinerelease> -r <release>

Mandatory parameters:
  -p <path>
     The (full) path to the plugin directory where the plugin to be updated is located.
     This path does not necessarily have to be located within a runnning Moodle site.
  -m <machinerelease>
     The (machine readable) major version of the plugin update.
  -r <release>
     The (human readable) major version of the plugin update.
```


Maintainers
-----------

lern.link GmbH\
Alexander Bias


Copyright
---------

lern.link GmbH\
Alexander Bias
