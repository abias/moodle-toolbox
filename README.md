moodle-toolbox
==============

This is a small Bash script collection which makes working with Moodle plugins quite handy.


Requirements
------------

This toolbox requires an up-to-date Bash installation.


Installation
------------

Clone the toolbox into a directory on your webserver, for example:
/opt/moodle-toolbox

Then, have a look at the configuration file
/_config/_localconfig.dist.sh,
copy the file to
/_config/_localconfig.sh,
and adapt the configuration file to your local needs. All configuration settings should be commented well in the configuration dist file.

Finally, add the
/bin
folder to your PATH. This is not strictly necessary, but it allows you to call the scripts by their plain name from within any directory.


Usage
-----

### /bin

In this folder, you will find scripts which can be used to do various Moodle dev tasks.

#### mtb-plugin-upgrade-prepare.sh

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
  -c <coreversion>
     The version of the Moodle core which is required for the new release of the plugin.
     You can find the Moodle core releases on https://docs.moodle.org/dev/Releases.

Optional parameters:
  -a <path>
     The (full) path to a shell script which will be sourced after the basic plugin modifications and before committing the results. It can be used to apply additional, release-specific changes to the plugin.
     Please note that the script must be executable.
```

#### mtb-plugin-upgrade-finish.sh

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

#### mtb-plugin-upgrade-release.sh

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

#### mtb-plugin-patch-commit.sh

This script is used to commit a patch to a plugin.
It is normally used to commit a patch to the main branch, but can be used to patch other branches as well.

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

#### mtb-plugin-patch-backport.sh

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
     Instead of a full branch name, you can also use the plain Moodle release number as a shorthand.
     It is expanded to MOODLE_<number>_STABLE automatically.

Optional parameters:
  -s <shahash>
     The SHA hash of the patch to be backported.
     If this parameter is not given, the script backports the HEAD commit in the main branch.
  -g
     Push to Github.
     If this switch is set, the given branches are pushed to Github after the backport.
```

#### mtb-plugin-patch-rebase.sh

This script is used to rebase a feature branch onto the main branch.

Before the rebase, it checks if the local main branch is in sync with the remote repository and offers to pull it.

Conflicts in CHANGES.md are resolved by the script itself, all other conflicts have to be resolved manually while the script waits.

```
Usage:
mtb-plugin-patch-rebase.sh -p <path> -b <branch> [-g]

Mandatory parameters:
  -p <path>
     The (full) path to the plugin directory where the plugin which contains the feature branch is located.
     This path does not necessarily have to be located within a runnning Moodle site.
  -b <branch>
     The feature branch which should be rebased onto the main branch.

Optional parameters:
  -g
     Push to Github.
     If this switch is set, the feature branch is force-pushed to Github after the rebase.
```

#### mtb-plugin-update-finish-latest.sh

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

#### mtb-plugin-update-release-latest.sh

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

#### mtb-plugin-update-finish-legacy.sh

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

#### mtb-plugin-update-release-legacy.sh

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

Alexander Bias


Copyright
---------

Alexander Bias


Credits
-------

This script collection was started as internal management tool at lern.link GmbH.
