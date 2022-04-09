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

The, have a look at the configuration file
/_config/localconfig.sh
and adapt the configuration settings to your local needs. All configuration settings should be commented well in the configuration file.


Usage
-----

### /commands/all

In this folder, you will find scripts which can be used on all kinds of Moodle instances (prod / test / dev).

#### mtb-downgrade.php

```
Usage:
mtb-downgrade.sh -s <site> -i <instance> [-d <distro>]

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


Maintainers
-----------

lern.link GmbH\
Alexander Bias


Copyright
---------

lern.link GmbH\
Alexander Bias
