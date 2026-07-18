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
mtb-plugin-patch-commit.sh -p <path> -d <date> -m <message> [-v] [-g]

Mandatory parameters:
  -p <path>
     The (full) path to the plugin directory where the plugin which contains the patch is located.
     This path does not necessarily have to be located within a runnning Moodle site.

     Example:
     /var/moodle-dev/mod/customcert

  -d <date>
     The date of the patch.
     This is just needed for the CHANGELOG entry.

     Example:
     2022-11-01

  -m <message>
     The message of the patch.
     This is needed for the CHANGELOG entry and for the commit message

     Example:
     Fix a very bad issue

Optional parameters:
  -v
     Raise version.
     If this switch is set, the plugin version in version.php is raised within the commit.

  -g
     Push to Github.
     If this switch is set, the branch is pushed to Github after the commit.
EOU
}

# Process parameters
while getopts 'hp:d:m:vg' OPTION; do
    case "$OPTION" in
        p)
            pluginpath=$OPTARG
            ;;
        d)
            plugindate=$OPTARG
            ;;
        m)
            pluginmessage=$OPTARG
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

# Verify that a date was given
if [[ -z "$plugindate" ]]; then
    usage
    exit 1
fi

# Verify that a message was given
if [[ -z "$pluginmessage" ]]; then
    usage
    exit 1
fi

# Confirmation
echo -e "You requested to commit a patch to the plugin at \033[1;35m$pluginpath\033[0m!"
confirm


###################################
### security net
###################################

now "Checking security nets"

cd $pluginpath \
    && success || failure
gitstatus=$(git status --porcelain)
if [[ ! -n "$gitstatus" ]]; then
    echo "The plugin git repo is clean. There is nothing to commit."
    echo "I can't continue."
    exit 1
else
    success
fi
unset gitstatus


now "Git branch status"

cd $pluginpath \
    && success || failure
gitbranch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$gitbranch" != $config_github_mainbranch ]]; then
    echo -e "The plugin git repo does not have the $config_github_mainbranch branch checked out. Instead, $gitbranch is checkout out."
    echo "Please confirm that you really want to commit the patch to this branch."
    confirm
else
    success
fi
unset gitbranch


###################################
### git
###################################

now "Prepare git commits"

git_init_commits


###################################
### action
###################################

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


now "Amend Changelog"

cd $pluginpath \
    && success || failure
changes=$(grep "### Unreleased" $pluginpath/CHANGES.md)
if [[ $? -ne 0 ]]; then
    sed -i "7i ### Unreleased\n\n* $plugindate - $pluginmessage\n" $pluginpath/CHANGES.md \
        && success || failure
else
    sed -i "9i * $plugindate - $pluginmessage" $pluginpath/CHANGES.md \
        && success || failure
fi
unset changes


now "Commit patch"

cd $pluginpath \
    && success || failure
git add --all \
    && success || failure
git commit -a -m "$pluginmessage" \
    && success || failure


if [[ $pluginpush -eq 1 ]]; then
    now "Push branch to Github"

    cd $pluginpath \
        && success || failure
    git push $config_github_remoterepo \
        && success || failure
fi


###################################
### inform admin
###################################

now "Finish"

echo -e "The patch was committed to the \033[1;35m$pluginpath\033[0m plugin."
if [[ $pluginpush -eq 1 ]]; then
    echo -e "The branch was pushed to Github as well."
fi
echo -e "Please review the results in the Git history."
