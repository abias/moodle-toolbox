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
mtb-plugin-update-finish-latest.sh -p <path> -m <machinerelease> -r <release> [-v] [-g]

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

Optional parameters:
  -v
     Raise version.
     If this switch is set, the plugin version in version.php is raised within the update.

  -g
     Push to Github.
     If this switch is set, the branches are pushed to Github after the commit.
EOU
}

# Process parameters
while getopts 'hp:m:r:vg' OPTION; do
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
            pluginraiseversion=1
            ;;
        g)
            pluginpush=1
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
echo -e "You requested to finish the plugin update of \033[1;35m$pluginpath\033[0m for release \033[1;35m$pluginrelease\033[0m!"
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
git checkout $config_github_mainbranch \
    && success || failure
changes=$(grep "### Unreleased" $pluginpath/CHANGES.md)
if [[ $? -ne 0 ]]; then
    echo -e "The CHANGES.md file does not contain an 'Unreleased' section. It seems as if the update is not prepared yet."
    echo "I can't continue."
    exit 1
else
    success
fi
unset changes


###################################
### git
###################################

now "Prepare git commits"

git_init_commits


###################################
### action
###################################

now "Check out $config_github_mainbranch branch"

cd $pluginpath \
    && success || failure
git checkout $config_github_mainbranch \
    && success || failure


if [[ $pluginraiseversion -eq 1 ]]; then
    now "Raise plugin version"

    cd $pluginpath \
        && success || failure
    version=$(grep "plugin->version" $pluginpath/version.php | tr -dc '0-9')
    nextversion=$((version + 1))
    sed -i "/plugin->version/s/$version/$nextversion/g" $pluginpath/version.php \
        && success || failure
    unset version
    unset nextversion
fi


now "Raise plugin release"

cd $pluginpath \
    && success || failure
release=$(grep "plugin->release" $pluginpath/version.php | sed 's/.*-r//' | tr -dc '0-9')
nextrelease=$((release + 1))
sed -i "/plugin->release/s/-r${release}/-r${nextrelease}/g" $pluginpath/version.php \
    && success || failure
unset release


now "Amend CHANGES.md"

cd $pluginpath \
    && success || failure
sed -i "s/### Unreleased/### v$pluginrelease-r$nextrelease/" $pluginpath/CHANGES.md \
    && success || failure


now "Commit changes"

cd $pluginpath \
    && success || failure
git commit -a -m "Release v$pluginrelease-r$nextrelease" \
    && success || failure
unset nextrelease


if [[ $pluginpush -eq 1 ]]; then
    now "Push branch to Github"

    cd $pluginpath \
        && success || failure
    git push $config_github_remoterepo \
        && success || failure
fi


now "Port commit to release branch"

cd $pluginpath \
    && success || failure
git checkout $config_github_mainbranch \
    && success || failure
commithash=$(git rev-parse HEAD)
git checkout MOODLE_${pluginmrelease}_STABLE \
    && success || failure
git cherry-pick $commithash \
    && success || failure


if [[ $pluginpush -eq 1 ]]; then
    now "Push branch to Github"

    cd $pluginpath \
        && success || failure
    git push $config_github_remoterepo \
        && success || failure
fi


now "Checkout $config_github_mainbranch branch again (just for cleanup)"

cd $pluginpath \
    && success || failure
git checkout $config_github_mainbranch \
    && success || failure


###################################
### inform admin
###################################

now "Finish"

echo -e "The \033[1;35m$pluginpath\033[0m plugin update for release \033[1;35m$pluginrelease\033[0m has been finished."
if [[ $pluginpush -eq 1 ]]; then
    echo -e "The branch was pushed to Github as well."
fi
echo -e "Please review the Git log and use then mtb-plugin-update-release-latest.sh"
