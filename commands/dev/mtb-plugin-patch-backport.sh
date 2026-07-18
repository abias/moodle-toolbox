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
mtb-plugin-patch-backport.sh -p <path> -b <branches> [-s <shahash>] [-g]

Mandatory parameters:
  -p <path>
     The (full) path to the plugin directory where the plugin which contains the patch is located.
     This path does not necessarily have to be located within a runnning Moodle site.

     Example:
     /var/moodle-dev/mod/customcert

  -b <branches>
     The branches which the patch should be backported to.
     This parameter expects a comma-separated list of existing branch names.

     Example:
     MOODLE_311_STABLE,MOODLE_310_STABLE

Optional parameters:
  -s <shahash>
     The SHA hash of the patch to be backported.
     If this parameter is not given, the script backports the HEAD commit in the main branch.

     Example:
     678fsdf

  -g
     Push to Github.
     If this switch is set, the given branches are pushed to Github after the backport.
EOU
}

# Process parameters
while getopts 'hp:b:s:g' OPTION; do
    case "$OPTION" in
        p)
            pluginpath=$OPTARG
            ;;
        b)
            pluginbranches=$OPTARG
            ;;
        s)
            pluginhash=$OPTARG
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

# Verify that a branch was given
if [[ -z "$pluginbranches" ]]; then
    usage
    exit 1
fi

# Confirmation
echo -e "You requested to backport a patch within the plugin at \033[1;35m$pluginpath\033[0m!"
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


###################################
### git
###################################

now "Prepare git commits"

git_init_commits


###################################
### action
###################################

now "Extract existing commit message"

cd $pluginpath \
    && success || failure
if [[ -z "$pluginhash" ]]; then
    git checkout $config_github_mainbranch \
        && success || failure
    pluginhash=$(git rev-parse HEAD)
fi
commitmessage=$(git show $pluginhash --pretty=format:"%B" --no-patch)
changesmessage=$(git show $pluginhash CHANGES.md | grep -m 1 "+* 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] - " | cut -c4-)
if [[ -z $commitmessage ]]; then
    echo "The extracted commit message is - for whatever reason - empty."
    echo "Do you really want to continue?"
    confirm
fi
if [[ -z $changesmessage ]]; then
    echo "The extracted changes message is - for whatever reason - empty."
    echo "There won't be any entry in CHANGES.md for this patch then."
    echo "Do you really want to continue?"
    confirm
fi


now "Start to loop through given backport branches"

success

for branch in ${pluginbranches//,/ }
do
    now "Checking branch security nets"

    cd $pluginpath \
        && success || failure
    gitbranch=$(git show-ref --heads $branch)
    if [[ $? -ne 0 ]]; then
        echo -e "The $branch branch does not exist."
        echo "I can't continue."
        exit 1
    else
        success
    fi
    unset gitbranch


    now "Cherry-pick patch to $branch branch (without the changes to CHANGES.md and version.php)"

    cd $pluginpath \
        && success || failure
    git checkout $branch \
        && success || failure
    git cherry-pick $pluginhash --no-commit \
        && success
    conflictincherrypick=$?
    changesmdchanges=$(git diff --name-only --cached | grep CHANGES.md | wc -l)
    if [[ $changesmdchanges -gt 0 ]]; then
        echo
	echo "CHANGES.md has changes in the patch. However, I will reset CHANGES.md now as the CHANGES.md entry will be re-applied cleanly by me later."
        git reset CHANGES.md \
            && success || failure
        git checkout -- CHANGES.md \
            && success || failure
    fi
    if [[ $conflictincherrypick -ne 0 ]]; then
        echo
	echo "There were conflicts during git cherry-pick. That's not an issue (yet)."
	versionphpchanges=$(git diff --check | grep version.php | wc -l)
	if [[ $versionphpchanges -gt 0 ]]; then
            echo
	    echo "There was a conflict in version.php."
	    echo "Please resolve the conflict manually as I can't do this automatically."
	    echo "Please take special care that you set the new version right so that it matches the plugin version scheme for branch $branch"
	fi
	otherchanges=$(git diff --check | grep -v version.php | wc -l)
	if [[ $otherchanges -gt 0 ]]; then
            echo
	    echo "There were conflicts in the following files:"
	    git diff --check |grep -v version.php | cut -d":" -f1 |sort -u
	    echo "Please resolve the conflicts manually as I can't do this automatically."
        fi
        if [[ $versionphpchanges -gt 0 || $otherchanges -gt 0 ]]; then
            echo
            echo "The rough process for resolving the conflicts is:"
            echo "  Open a new terminal"
            echo "  cd $pluginpath"
            echo "  vim somefile.php"
            echo "  git add somefile.php"
            echo
            echo "However, please do not commit anything and let me continue as soon as all conflicts are resolved."
            acknowledge
	fi
        unset changesmdchanges versionphpchanges otherchanges
    fi

    if [[ -n $changesmessage ]]; then
        now "Amend Changelog (again)"

        cd $pluginpath \
            && success || failure
        changes=$(grep "### Unreleased" $pluginpath/CHANGES.md)
        if [[ $? -ne 0 ]]; then
            sed -i "7i ### Unreleased\n\n* $changesmessage\n" $pluginpath/CHANGES.md \
                && success || failure
        else
            sed -i "9i * $changesmessage" $pluginpath/CHANGES.md \
                && success || failure
        fi
        unset changes
    fi


    now "Commit patch"

    cd $pluginpath \
        && success || failure
    git add --all \
        && success || failure
    git commit -a -m "$commitmessage" \
        && success || failure


    if [[ $pluginpush -eq 1 ]]; then
        now "Push branch to Github"

        cd $pluginpath \
            && success || failure
        git push $config_github_remoterepo \
            && success || failure
    fi
done


now "Finish to loop through given backport branches"

success


now "Checkout $config_github_mainbranch branch again (just for cleanup)"

cd $pluginpath \
    && success || failure
git checkout $config_github_mainbranch \
    && success || failure


###################################
### inform admin
###################################

now "Finish"

echo -e "The patch was backported within the \033[1;35m$pluginpath\033[0m plugin."
if [[ $pluginpush -eq 1 ]]; then
	echo -e "The branch(es) was/were pushed to Github as well."
fi
echo -e "Please review the results in the Git history."
