#!/bin/bash

###################################
### includes
###################################

CURRENTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$CURRENTDIR/../../_config/localconfig.sh"
source "$CURRENTDIR/../../_config/localcredentials.sh"
source "$CURRENTDIR/../../_include/sh/functionslib.sh"


###################################
### check startup
###################################

usage ()
{
    cat <<EOU
Usage:
mtb-plugin-update-release-legacy.sh -p <path> -m <machinerelease> -r <release>

Mandatory parameters:
  -p <path>
     The (full) path to the plugin directory where the plugin to be updated is located.
     This path does not necessarily have to be located within a runnning Moodle site.

     Example:
     /var/moodle-dev/mod/customcert

  -m <machinerelease>
     The (machine readable) major version of the plugin update.

     Example:
     311

  -r <release>
     The (human readable) major version of the plugin update.

     Example:
     3.11
EOU
}

# Process parameters
while getopts 'hp:m:r:' OPTION; do
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

# Confirmation
echo -e "You requested to release the plugin update of \033[1;35m$pluginpath\033[0m with release \033[1;35m$pluginrelease\033[0m!"
confirm


###################################
### security net
###################################

now "Checking security nets"

cd $pluginpath \
    && success || failure
gitstatus=$(git status --porcelain)
if [[ -n "$gitstatus" ]]; then
    echo "The plugin git repo is not clean. This must be solved before the update."
    echo "I can't continue."
    exit 1
else
    success
fi
unset gitstatus

cd $pluginpath \
    && success || failure
git checkout MOODLE_${pluginmrelease}_STABLE \
    && success || failure
changes=$(grep "### Unreleased" $pluginpath/CHANGES.md)
if [[ $? -eq 0 ]]; then
    echo -e "The CHANGES.md file contains an 'Unreleased' section. It seems as if the update is not finished yet."
    echo "I can't continue."
    exit 1
else
    success
fi
unset changes


now "Github actions status"

echo -e "The plugin update must not be released if there are still any bugs or issues. Please confirm that Github actions was 'all green'."
confirm


###################################
### git
###################################

now "Prepare git commits"

git_init_commits


###################################
### action
###################################

now "Tag the update in the release branch"

cd $pluginpath \
    && success || failure
release=$(grep "plugin->release" $pluginpath/version.php | sed 's/.*-r//' | tr -dc '0-9')
git checkout MOODLE_${pluginmrelease}_STABLE \
    && success || failure
git tag v$pluginrelease-r$release \
    && success || failure


now "Push the release branch and the release tag to Github"

cd $pluginpath \
    && success || failure
git push $config_github_remoterepo MOODLE_${pluginmrelease}_STABLE \
    && success || failure
git push $config_github_remoterepo MOODLE_${pluginmrelease}_STABLE --tags \
    && success || failure


now "Checkout $config_github_mainbranch branch again (just for cleanup)" 

cd $pluginpath \
    && success || failure
git checkout $config_github_mainbranch \
    && success || failure


###################################
### inform admin
###################################

now "Finish"

echo -e "The \033[1;35m$pluginpath\033[0m plugin update for release \033[1;35m$pluginrelease\033[0m has been released and has been pushed to Github."
echo -e "Please review the results on Github and continue to publish the update on moodle.org"
