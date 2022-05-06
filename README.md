moodle-toolbox
==============

This is a small Bash script collection which makes handling of multiple Moodle instances quite handy.


Requirements
------------

This toolbox requires an up-to-date Bash installation and, for running Moodle CLI scripts, and installed PHP-CLI interpreter.


Installation
------------

Clone the toolbox into a directory on your webserver, for example:
/opt/moodle-toolbox

Then, have a look at the configuration file
/_config/localconfig.sh
and adapt the configuration settings to your local needs. All configuration settings should be commented well in the configuration file.

Futhermore, have a look at the template file
/_template/config.sh
and adapt the default config.php file for new installations to your local needs.


Usage
-----

### /commands/all

In this folder, you will find scripts which can be used on all kinds of Moodle instances (prod / test / dev).

#### mtb-downgrade.php

This script is used to downgrade the core and plugin versions stored in the Moodle database to the versions stored in the version.php files on disk.
It does not do any rollback of upgrade steps. Please use it only for development or emergency purposes.

```
Usage:
mtb-downgrade.sh -s <site> -i <instance> [-d <distro>] [-r <release>]

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
  -r <release>
     The Moodle release which is to be used by the scripts
     This parameter expects the release number of the instance of the Moodle site.
     When running the script, a list of possible values can be requested with the -h parameter.
```


#### mtb-init.php

This script is used to initialize a Moodle instance. It needs some additional parameters about the database and the site and will setup the site, starting from the creation of the filestructure and ending at the initialization of the database.

```
Usage:
mtb-init.sh -s <site> -i <instance> -f <fullname> -t <shortname> -n <dbname> -u <dbuser> -p <dbpass> [-d <distro>] [-r <release>]

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
  -d <distro>
     The Moodle distribution which is to be used by the scripts
     This parameter expects the distribution name of the instance of the Moodle site.
     When running the script, a list of possible values can be requested with the -h parameter.
  -r <release>
     The Moodle release which is to be used by the scripts
     This parameter expects the release number of the instance of the Moodle site.
     When running the script, a list of possible values can be requested with the -h parameter.
```


Maintainers
-----------

lern.link GmbH\
Alexander Bias


Copyright
---------

lern.link GmbH\
Alexander Bias
