#!/bin/bash

###################################
### includes
###################################

CURRENTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$CURRENTDIR/../_config/_localconfig.sh"
source "$CURRENTDIR/../_include/_functions.sh"


###################################
### local functions
###################################

# This helper function compares the local branch which is passed in $1 with the same branch in the remote repo.
# If the local branch is behind, it offers to pull it.
# If the local branch is ahead, it asks for confirmation.
# If the branches have diverged, the script terminates.
check_branch_sync ()
{
    syncbranch=$1
    if ! git ls-remote --exit-code --heads $config_github_remoterepo $syncbranch > /dev/null; then
        echo "The $syncbranch branch does not exist in $config_github_remoterepo yet. There is nothing to compare."
        success
        unset syncbranch
        return
    fi
    git fetch $config_github_remoterepo $syncbranch \
        && success || failure
    localsha=$(git rev-parse $syncbranch)
    remotesha=$(git rev-parse $config_github_remoterepo/$syncbranch)
    if [[ "$localsha" == "$remotesha" ]]; then
        echo "The local $syncbranch branch is up to date with $config_github_remoterepo."
        success
    elif git merge-base --is-ancestor $localsha $remotesha; then
        echo
        echo "The local $syncbranch branch is behind $config_github_remoterepo/$syncbranch."
        echo "It would be reasonable to pull the $syncbranch branch before the backport."
        askandremember
        if [[ $doit -eq 1 ]]; then
            git checkout $syncbranch \
                && success || failure
            git pull --ff-only $config_github_remoterepo $syncbranch \
                && success || failure
        elif [[ $pluginpush -eq 1 ]]; then
            echo "You requested to push to Github, but the push of the $syncbranch branch would be rejected if it is not pulled before."
            echo "I can't continue."
            exit 1
        else
            echo "Ok, I will use the local state of the $syncbranch branch then."
        fi
        unset doit
    elif git merge-base --is-ancestor $remotesha $localsha; then
        echo
        echo "The local $syncbranch branch is ahead of $config_github_remoterepo/$syncbranch."
        echo "This means that the $syncbranch branch has commits which are not pushed to $config_github_remoterepo yet."
        echo "Do you really want to continue?"
        confirm
    else
        echo
        echo "The local $syncbranch branch and $config_github_remoterepo/$syncbranch have diverged."
        echo "Please solve this manually as I can't do this automatically."
        echo "I can't continue."
        exit 1
    fi
    unset syncbranch localsha remotesha
}

# This helper function explains how to clean up if the script terminates in the middle of the backport to the branch which is passed in $1.
backport_abort_hint ()
{
    echo
    echo "The backport to the $1 branch was not finished and the $1 branch still contains the uncommitted changes of the backport."
    echo "You can throw these changes away and go back to the $config_github_mainbranch branch with:"
    echo "  cd $pluginpath"
    echo "  git reset --hard"
    echo "  git checkout $config_github_mainbranch"
    echo "Branches which were processed before the $1 branch are already backported (and pushed if requested)."
}


###################################
### check startup
###################################

usage ()
{
    cat <<EOU
Usage:
mtb-plugin-patch-backport.sh -p <path> -b <branches> [-s <shahash>] [-g] [-l]

Mandatory parameters:
  -p <path>
     The (full) path to the plugin directory where the plugin which contains the patch is located.
     This path does not necessarily have to be located within a runnning Moodle site.

     Example:
     /var/moodle-dev/mod/customcert

  -b <branches>
     The branches which the patch should be backported to.
     This parameter expects a comma-separated list of existing branch names.
     Instead of a full branch name, you can also use the plain Moodle release number as a shorthand.
     It is expanded to MOODLE_<number>_STABLE automatically.

     Examples:
     MOODLE_311_STABLE,MOODLE_310_STABLE
     311,310

Optional parameters:
  -s <shahash>
     The SHA hash of the patch to be backported.
     If this parameter is not given, the script backports the HEAD commit in the main branch.

     Example:
     678fsdf

  -g
     Push to Github.
     If this switch is set, the given branches are pushed to Github after the backport.

  -l
     Look at the changes before pushing.
     If this switch is set, the backported commit is shown with git show before each branch is pushed to Github.
     This switch only has an effect if -g is set as well.
EOU
}

# Process parameters
while getopts 'hp:b:s:gl' OPTION; do
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
        l)
            pluginshow=1
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

# Expand the shorthand branch names to full branch names
expandedbranches=""
for branch in ${pluginbranches//,/ }
do
    if [[ "$branch" =~ ^[0-9]+$ ]]; then
        branch="MOODLE_${branch}_STABLE"
    fi
    if [[ -z "$expandedbranches" ]]; then
        expandedbranches="$branch"
    else
        expandedbranches="$expandedbranches,$branch"
    fi
done
pluginbranches=$expandedbranches
unset expandedbranches branch

# Confirmation
echo -e "You requested to backport a patch within the plugin at \033[1;35m$pluginpath\033[0m to the branch(es) \033[1;35m${pluginbranches//,/, }\033[0m!"
confirm


###################################
### security net
###################################

now "Checking security nets"

cd $pluginpath \
    && success || failure
gitstatus=$(git status --porcelain)
if [[ -n "$gitstatus" ]]; then
    echo "The plugin git repo is not clean. This must be solved before the backport."
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
    check_branch_sync $config_github_mainbranch
    pluginhash=$(git rev-parse HEAD)
fi
commitmessage=$(git show $pluginhash --pretty=format:"%B" --no-patch)
changesmessage=$(git show $pluginhash -- CHANGES.md | grep -m 1 -E "^\+\* 20[0-9]{2}-[0-9]{2}-[0-9]{2} - " | cut -c4-)
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


# All branches are checked before the first one is touched, so that the backport does not stop halfway because of one of them.
for branch in ${pluginbranches//,/ }
do
    now "Checking branch security nets for $branch branch"

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
    check_branch_sync $branch
done


now "Start to loop through given backport branches"

success

for branch in ${pluginbranches//,/ }
do
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
    unset changesmdchanges
    if [[ $conflictincherrypick -ne 0 ]]; then
        echo
        echo "There were conflicts during git cherry-pick. That's not an issue (yet)."
        conflictedfiles=$(git diff --name-only --diff-filter=U)
        versionphpconflict=$(echo "$conflictedfiles" | grep -Fx "version.php")
        otherconflicts=$(echo "$conflictedfiles" | grep -Fvx "version.php")
        if [[ -n $versionphpconflict ]]; then
            echo
            echo "There was a conflict in version.php."
            echo "Please resolve the conflict manually as I can't do this automatically."
            echo "Please take special care that you set the new version right so that it matches the plugin version scheme for branch $branch"
        fi
        if [[ -n $otherconflicts ]]; then
            echo
            echo "There were conflicts in the following files:"
            echo "$otherconflicts"
            echo "Please resolve the conflicts manually as I can't do this automatically."
        fi
        if [[ -n $conflictedfiles ]]; then
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
        unset conflictedfiles versionphpconflict otherconflicts
    fi


    now "Verify that all conflicts are resolved"

    cd $pluginpath \
        && success || failure
    remainingconflicts=$(git diff --name-only --diff-filter=U)
    if [[ -n $remainingconflicts ]]; then
        echo "There are still unresolved conflicts in the following files:"
        echo "$remainingconflicts"
        echo "I can't continue."
        backport_abort_hint $branch
        exit 1
    else
        success
    fi
    unset remainingconflicts


    now "Verify that the patch is not backported to $branch branch already"

    cd $pluginpath \
        && success || failure
    git add --all \
        && success || failure
    if git diff --cached --quiet -- . ':(exclude)version.php'; then
        echo "The patch does not change anything in the $branch branch (apart from version.php)."
        echo "It seems that the patch is already backported to this branch."
        echo "I will skip the $branch branch and throw away the changes of the backport there."
        git reset -q --hard \
            && success || failure
        skippedbranches="$skippedbranches $branch"
        continue
    else
        success
    fi


    if [[ -n $changesmessage ]]; then
        now "Amend Changelog (again)"

        cd $pluginpath \
            && success || failure
        if grep -Fqx -- "* $changesmessage" $pluginpath/CHANGES.md; then
            echo "The CHANGES.md entry is already there. I won't add it a second time."
            success
        else
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
    fi


    now "Commit patch"

    cd $pluginpath \
        && success || failure
    git add --all \
        && success || failure
    git commit -a -m "$commitmessage" \
        && success || failure


    if [[ $pluginpush -eq 1 ]]; then
        if [[ $pluginshow -eq 1 ]]; then
            now "Show changes in $branch branch before pushing"

            cd $pluginpath \
                && success || failure
            backportsha=$(git rev-parse HEAD)
            git show $backportsha
            unset backportsha
            echo
            echo "These are the changes which will be pushed to the $branch branch now."
            confirm
        fi


        now "Push branch to Github"

        cd $pluginpath \
            && success || failure
        git push $config_github_remoterepo $branch \
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
if [[ -n $skippedbranches ]]; then
    echo -e "The following branch(es) was/were skipped as the patch is already backported there:\033[1;35m$skippedbranches\033[0m"
fi
echo -e "Please review the results in the Git history."
