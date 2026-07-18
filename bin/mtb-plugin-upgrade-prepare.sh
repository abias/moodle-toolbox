#!/bin/bash

###################################
### includes
###################################

CURRENTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$CURRENTDIR/../_config/_localconfig.sh"
source "$CURRENTDIR/../_include/_functions.sh"


###################################
### check startup
###################################

usage ()
{
    cat <<EOU
Usage:
mtb-plugin-upgrade-prepare.sh -p <path> -m <machinerelease> -r <release> -d <date> -c <coreversion> [-a <path>]

Mandatory parameters:
  -p <path>
     The (full) path to the plugin directory where the plugin to be upgraded is located.
     This path does not necessarily have to be located within a runnning Moodle site.

     Example:
     /var/moodle-dev/mod/customcert

  -m <machinerelease>
     The (machine readable) target release of the plugin.

     Example:
     311

  -r <release>
     The (human readable) target release of the plugin.

     Example:
     3.11

  -d <date>
     The date of the upgrade.
     This is just needed for the CHANGELOG entry.

     Example:
     2022-11-01

  -c <coreversion>
     The version of the Moodle core which is required for the new release of the plugin.
     You can find the Moodle core releases on https://docs.moodle.org/dev/Releases.

     Example:
     2021051700

Optional parameters:
  -a <path>
     The (full) path to a shell script which will be sourced after the basic plugin modifications and before committing the results. It can be used to apply additional, release-specific changes to the plugin.
     Please note that the script must be executable.

     Example:
     /var/moodle-dev/release-311-changes.sh
EOU
}

# Process parameters
while getopts 'hp:m:r:d:c:a:' OPTION; do
    case "$OPTION" in
        p)
            pluginpath=$OPTARG
            ;;
        m)
            pluginmrelease=$OPTARG
            ;;
        r)
            pluginrelease=$OPTARG
            ;;
        d)
            plugindate=$OPTARG
            ;;
        c)
            plugincoreversion=$OPTARG
            ;;
        a)
            pluginadditions=$OPTARG
            ;;
        h)
            usage
            exit 0
            ;;
        :)
            usage
            exit 1
            ;;
        *)
            usage
            exit 1
            ;;
        ?)
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

# Verify that a path was given and that the path exists
if [[ -z "$pluginpath" ]] || [[ ! -d "$pluginpath" ]]; then
    usage
    exit 1
fi

# Verify that a machine release was given
if [[ -z "$pluginmrelease" ]]; then
    usage
    exit 1
fi

# Verify that a human readable release was given
if [[ -z "$pluginrelease" ]]; then
    usage
    exit 1
fi

# Verify that a date was given
if [[ -z "$plugindate" ]]; then
    usage
    exit 1
fi

# Verify that a coreversion was given
if [[ -z "$plugincoreversion" ]]; then
    usage
    exit 1
fi

# If additional modifications were set, verify that the path exists
if [[ ! -z "$pluginadditions" ]] && [[ ! -x "$pluginadditions" ]]; then
    usage
    exit 1
fi

# Confirmation
echo -e "You requested to prepare the plugin upgrade of \033[1;35m$pluginpath\033[0m to release \033[1;35m$pluginrelease\033[0m!"
confirm


###################################
### security net
###################################

now "Checking security nets"

cd $pluginpath \
    && success || failure
gitstatus=$(git status --porcelain)
if [[ -n "$gitstatus" ]]; then
    echo "The plugin git repo is not clean. This must be solved before the upgrade."
    echo "I can't continue."
    exit 1
else
    success
fi
unset gitstatus

cd $pluginpath \
    && success || failure
changes=$(grep "### Unreleased" $pluginpath/CHANGES.md)
if [[ $? -eq 0 ]]; then
    echo -e "The CHANGES.md file contains an 'Unreleased' section. Normally, a new release should be pushed out for the current latest version before upgrading to the next version."
    echo -e "However, if the unreleased changes do not have an effect on the running plugin (e.g. changes in Moodle-Plugin-CI), you can go ahead and prepare the new version."
    echo "Do you really want to continue?"
    confirm
else
    success
fi
unset changes

cd $pluginpath \
    && success || failure
gitbranch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$gitbranch" != $config_github_mainbranch ]]; then
    echo -e "The plugin git repo does not have the $config_github_mainbranch branch checked out. Instead, $gitbranch is checkout out."
    echo "I can't continue."
    exit 1
else
    success
fi
unset gitbranch

cd $pluginpath \
    && success || failure
gitupgradebranch=$(git show-ref --heads upgrade-$pluginmrelease)
if [[ $? -eq 0 ]]; then
    echo -e "The upgrade-$pluginmrelease branch already exists."
    echo "I can't continue."
    exit 1
else
    success
fi
unset gitupgradebranch

cd $pluginpath \
    && success || failure
gitcommit=$(git log --oneline | grep "Prepare compatibility for Moodle $pluginrelease")
if [[ $? -eq 0 ]]; then
    echo -e "The git history already contains a commit message for preparing this upgrade."
    echo "I can't continue."
    exit 1
else
    success
fi
unset gitcommit


###################################
### git
###################################

now "Prepare git commits"

git_init_commits


###################################
### action
###################################

now "Creating and checking out upgrade-$pluginmrelease branch"

cd $pluginpath \
    && success || failure
git branch upgrade-$pluginmrelease \
    && success || failure
git checkout upgrade-$pluginmrelease \
    && success || failure


now "Modify README.md"

cd $pluginpath \
    && success || failure
sed -i "s/This plugin requires Moodle.*/This plugin requires Moodle ${pluginrelease}\+/" $pluginpath/README.md \
    && success || failure
sed -i "s/This theme requires Moodle.*/This theme requires Moodle ${pluginrelease}\+/" $pluginpath/README.md \
    && success || failure


now "Modify version.php"

cd $pluginpath \
    && success || failure
sed -i "s/\$plugin->requires.*/\$plugin->requires = $plugincoreversion;/" $pluginpath/version.php \
    && success || failure
sed -i "s/\$plugin->supported.*/\$plugin->supported = \[$pluginmrelease, $pluginmrelease\];/" $pluginpath/version.php \
    && success || failure


now "Amend CHANGES.md"

cd $pluginpath \
    && success || failure
changes=$(grep "### Unreleased" $pluginpath/CHANGES.md)
if [[ $? -ne 0 ]]; then
    sed -i "7i ### Unreleased\n\n* $plugindate - Prepare compatibility for Moodle $pluginrelease.\n" $pluginpath/CHANGES.md \
        && success || failure
else
    sed -i "9i * $plugindate - Prepare compatibility for Moodle $pluginrelease." $pluginpath/CHANGES.md \
        && success || failure
fi
unset changes

if [[ ! -z "$pluginadditions" ]]; then
    now "Apply additional changes through the modification script"

    cd $pluginpath \
        && success || failure
    source $pluginadditions
fi


now "Commit changes"

cd $pluginpath \
    && success || failure
git commit -a -m "Prepare compatibility for Moodle $pluginrelease." \
    && success || failure



###################################
### inform admin
###################################

now "Finish"

echo -e "The \033[1;35m$pluginpath\033[0m plugin upgrade for release \033[1;35m$pluginrelease\033[0m has been prepared."
echo -e "Please continue your preparation work and use then mtb-plugin-upgrade-finish.sh"
