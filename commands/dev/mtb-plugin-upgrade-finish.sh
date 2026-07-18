#!/bin/bash

###################################
### includes
###################################

CURRENTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$CURRENTDIR/../../_config/_localconfig.sh"
source "$CURRENTDIR/../../_include/sh/functionslib.sh"


###################################
### check startup
###################################

usage ()
{
    cat <<EOU
Usage:
mtb-plugin-upgrade-finish.sh -p <path> -m <machinerelease> -r <release> -v <version>

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

  -v <version>
     The version of the release of the plugin.
     Ideally, this matches the date in the CHANGELOG entry. Don't forget the two trailing zeros which are required for Moodle versions.

     Example:
     2022110100
EOU
}

# Process parameters
while getopts 'hp:m:r:v:' OPTION; do
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
        v)
            pluginversion=$OPTARG
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

# Verify that a version was given
if [[ -z "$pluginversion" ]]; then
    usage
    exit 1
fi

# Confirmation
echo -e "You requested to finish the plugin upgrade of \033[1;35m$pluginpath\033[0m to release \033[1;35m$pluginrelease\033[0m!"
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
if [[ $? -ne 0 ]]; then
    echo -e "The CHANGES.md file does not contain an 'Unreleased' section. It seems as if the upgrade is not prepared yet."
    echo "I can't continue."
    exit 1
else
    success
fi
unset changes

cd $pluginpath \
    && success || failure
gitbranch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$gitbranch" != upgrade-$pluginmrelease ]]; then
    echo -e "The plugin git repo does not have the upgrade-$pluginmrelease branch checked out. Instead, $gitbranch is checkout out."
    echo "I can't continue."
    exit 1
else
    success
fi
unset gitbranch

cd $pluginpath \
    && success || failure
gitupgradebranch=$(git show-ref --heads upgrade-$pluginmrelease)
if [[ $? -ne 0 ]]; then
    echo -e "The upgrade-$pluginmrelease branch does not exist."
    echo "I can't continue."
    exit 1
else
    success
fi
unset gitupgradebranch

cd $pluginpath \
    && success || failure
gitcommit=$(git log --oneline | grep "Prepare compatibility for Moodle $pluginrelease")
if [[ $? -ne 0 ]]; then
    echo -e "The git history does not contain a commit message for preparing this upgrade."
    echo "I can't continue."
    exit 1
else
    success
fi
unset gitcommit


now "Github issues status"

echo -e "The plugin upgrade should not be released if there are still any bugs or issues. Please confirm that you have checked the Github issues list for pending issues."
confirm


###################################
### git
###################################

now "Prepare git commits"

git_init_commits


###################################
### action
###################################

now "Modify version.php"

cd $pluginpath \
    && success || failure
sed -i "s/\$plugin->version.*/\$plugin->version = $pluginversion;/" $pluginpath/version.php \
    && success || failure
sed -i "s/\$plugin->release.*/\$plugin->release = 'v$pluginrelease-r1';/" $pluginpath/version.php \
    && success || failure


now "Amend CHANGES.md"

cd $pluginpath \
    && success || failure
sed -i "s/### Unreleased/### v$pluginrelease-r1/" $pluginpath/CHANGES.md \
    && success || failure


now "Commit changes"

cd $pluginpath \
    && success || failure
git commit -a -m "Release v$pluginrelease-r1" \
    && success || failure


now "Push to Github"

cd $pluginpath \
    && success || failure
git push $config_github_remoterepo upgrade-$pluginmrelease \
    && success || failure


###################################
### inform admin
###################################

now "Finish"

echo -e "The \033[1;35m$pluginpath\033[0m plugin upgrade for release \033[1;35m$pluginrelease\033[0m has been finished and has been pushed to Github."
echo -e "Please review the Github actions results and use then mtb-plugin-upgrade-release.sh"
