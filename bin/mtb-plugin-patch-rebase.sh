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

# This helper function checks if a rebase is currently in progress.
# If it is, the function returns 0 (i.e. success).
# If it is not, the function returns 1 (i.e. failure).
rebase_in_progress ()
{
    gitdir=$(git rev-parse --git-dir)
    if [[ -d "$gitdir/rebase-merge" ]] || [[ -d "$gitdir/rebase-apply" ]]; then
        return 0
    fi
    return 1
}


###################################
### check startup
###################################

usage ()
{
    cat <<EOU
Usage:
mtb-plugin-patch-rebase.sh -p <path> -b <branch> [-g]

Mandatory parameters:
  -p <path>
     The (full) path to the plugin directory where the plugin which contains the feature branch is located.
     This path does not necessarily have to be located within a runnning Moodle site.

     Example:
     /var/moodle-dev/mod/customcert

  -b <branch>
     The feature branch which should be rebased onto the $config_github_mainbranch branch.

     Example:
     issue-42

Optional parameters:
  -g
     Push to Github.
     If this switch is set, the feature branch is force-pushed to Github after the rebase.
EOU
}

# Process parameters
while getopts 'hp:b:g' OPTION; do
    case "$OPTION" in
        p)
            pluginpath=$OPTARG
            ;;
        b)
            pluginbranch=$OPTARG
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
if [[ -z "$pluginbranch" ]]; then
    usage
    exit 1
fi

# Verify that the given branch is not the main branch
if [[ "$pluginbranch" == "$config_github_mainbranch" ]]; then
    echo "The given branch is the $config_github_mainbranch branch itself. There is nothing to rebase."
    echo "I can't continue."
    exit 1
fi

# Confirmation
echo -e "You requested to rebase the \033[1;35m$pluginbranch\033[0m branch within the plugin at \033[1;35m$pluginpath\033[0m onto \033[1;35m$config_github_mainbranch\033[0m!"
confirm


###################################
### security net
###################################

now "Checking security nets"

cd $pluginpath \
    && success || failure
gitstatus=$(git status --porcelain)
if [[ -n "$gitstatus" ]]; then
    echo "The plugin git repo is not clean. This must be solved before the rebase."
    echo "I can't continue."
    exit 1
else
    success
fi
unset gitstatus

if rebase_in_progress; then
    echo "The plugin git repo has a rebase in progress. This must be solved before the rebase."
    echo "I can't continue."
    exit 1
fi


now "Checking branch security nets"

cd $pluginpath \
    && success || failure
gitbranch=$(git show-ref --heads $pluginbranch)
if [[ $? -ne 0 ]]; then
    echo -e "The $pluginbranch branch does not exist."
    echo "I can't continue."
    exit 1
else
    success
fi
unset gitbranch

gitbranch=$(git show-ref --heads $config_github_mainbranch)
if [[ $? -ne 0 ]]; then
    echo -e "The $config_github_mainbranch branch does not exist."
    echo "I can't continue."
    exit 1
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

now "Compare $config_github_mainbranch branch with $config_github_remoterepo"

cd $pluginpath \
    && success || failure
git fetch $config_github_remoterepo $config_github_mainbranch \
    && success || failure
localmain=$(git rev-parse $config_github_mainbranch)
remotemain=$(git rev-parse $config_github_remoterepo/$config_github_mainbranch)
if [[ "$localmain" == "$remotemain" ]]; then
    echo "The local $config_github_mainbranch branch is up to date with $config_github_remoterepo."
    success
elif git merge-base --is-ancestor $localmain $remotemain; then
    echo
    echo "The local $config_github_mainbranch branch is behind $config_github_remoterepo/$config_github_mainbranch."
    echo "It would be reasonable to pull the $config_github_mainbranch branch before rebasing $pluginbranch onto it."
    askandremember
    if [[ $doit -eq 1 ]]; then
        git checkout $config_github_mainbranch \
            && success || failure
        git pull --ff-only $config_github_remoterepo $config_github_mainbranch \
            && success || failure
    else
        echo "Ok, I will rebase onto the local state of the $config_github_mainbranch branch then."
    fi
    unset doit
elif git merge-base --is-ancestor $remotemain $localmain; then
    echo
    echo "The local $config_github_mainbranch branch is ahead of $config_github_remoterepo/$config_github_mainbranch."
    echo "This means that the $config_github_mainbranch branch has commits which are not pushed to $config_github_remoterepo yet."
    echo "Do you really want to continue?"
    confirm
else
    echo
    echo "The local $config_github_mainbranch branch and $config_github_remoterepo/$config_github_mainbranch have diverged."
    echo "Please solve this manually as I can't do this automatically."
    echo "I can't continue."
    exit 1
fi
unset localmain remotemain


now "Checkout $pluginbranch branch"

cd $pluginpath \
    && success || failure
git checkout $pluginbranch \
    && success || failure


now "Rebase $pluginbranch branch onto $config_github_mainbranch branch"

cd $pluginpath \
    && success || failure
git rebase $config_github_mainbranch \
    && success
rebaseround=0
while rebase_in_progress
do
    rebaseround=$((rebaseround + 1))
    if [[ $rebaseround -gt 100 ]]; then
        echo "The rebase did not finish after 100 rounds. Something is definitely wrong here."
        echo "I can't continue."
        exit 1
    fi


    now "Handle conflicts in rebase round $rebaseround"

    cd $pluginpath \
        && success || failure
    stoppedsha=$(git rev-parse REBASE_HEAD)
    if [[ -z $stoppedsha ]]; then
        echo "I can't determine which commit the rebase stopped at."
        echo "I can't continue."
        exit 1
    fi
    echo "The rebase stopped while applying this commit:"
    git --no-pager show $stoppedsha --pretty=format:"%h %s" --no-patch
    conflictedfiles=$(git diff --name-only --diff-filter=U)
    if [[ -z $conflictedfiles ]]; then
        echo
        echo "There are no conflicts in this rebase round. I will just continue the rebase."
    else
        hadconflicts=1
        echo
        echo "There were conflicts during git rebase. That's not an issue (yet)."
        changesmdconflict=$(echo "$conflictedfiles" | grep -Fx "CHANGES.md")
        versionphpconflict=$(echo "$conflictedfiles" | grep -Fx "version.php")
        otherconflicts=$(echo "$conflictedfiles" | grep -Fvx "CHANGES.md" | grep -Fvx "version.php")

        if [[ -n $changesmdconflict ]]; then
            echo
            echo "There was a conflict in CHANGES.md. That's not an issue at all as I will re-apply the CHANGES.md entry cleanly by myself."
            changesmessage=$(git show $stoppedsha -- CHANGES.md | grep -m 1 -E "^\+\* 20[0-9]{2}-[0-9]{2}-[0-9]{2} - " | cut -c4-)
            git checkout --ours -- CHANGES.md \
                && success || failure
            if [[ -z $changesmessage ]]; then
                echo "The extracted changes message is - for whatever reason - empty."
                echo "There won't be any entry in CHANGES.md for this commit then."
                echo "Do you really want to continue?"
                confirm
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
            git add CHANGES.md \
                && success || failure
            unset changesmessage
        fi

        if [[ -n $versionphpconflict ]]; then
            echo
            echo "There was a conflict in version.php."
            echo "Please resolve the conflict manually as I can't do this automatically."
            echo "Please take special care that you set the new version right so that it matches the plugin version scheme for branch $pluginbranch"
        fi

        if [[ -n $otherconflicts ]]; then
            echo
            echo "There were conflicts in the following files:"
            echo "$otherconflicts"
            echo "Please resolve the conflicts manually as I can't do this automatically."
        fi

        if [[ -n $versionphpconflict ]] || [[ -n $otherconflicts ]]; then
            echo
            echo "The rough process for resolving the conflicts is:"
            echo "  Open a new terminal"
            echo "  cd $pluginpath"
            echo "  vim somefile.php"
            echo "  git add somefile.php"
            echo
            echo "However, please do not commit anything and do not continue the rebase yourself. Let me continue as soon as all conflicts are resolved."
            acknowledge
        fi
        unset changesmdconflict versionphpconflict otherconflicts
    fi
    unset conflictedfiles


    now "Verify that all conflicts are resolved in rebase round $rebaseround"

    cd $pluginpath \
        && success || failure
    remainingconflicts=$(git diff --name-only --diff-filter=U)
    if [[ -n $remainingconflicts ]]; then
        echo "There are still unresolved conflicts in the following files:"
        echo "$remainingconflicts"
        echo "I can't continue."
        exit 1
    else
        success
    fi
    unset remainingconflicts


    now "Continue rebase after rebase round $rebaseround"

    cd $pluginpath \
        && success || failure
    if [[ $hadconflicts -eq 1 ]] && git diff --cached --quiet; then
        echo "The commit does not have any changes left after resolving the conflicts. I will skip it."
        git rebase --skip \
            && success
    else
        GIT_EDITOR=true git rebase --continue \
            && success
    fi
    unset stoppedsha hadconflicts
done
unset rebaseround


now "Verify that the rebase was completed"

cd $pluginpath \
    && success || failure
gitbranch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$gitbranch" != "$pluginbranch" ]]; then
    echo "The $pluginbranch branch is not checked out anymore after the rebase. Something went wrong here."
    echo "I can't continue."
    exit 1
fi
if ! git merge-base --is-ancestor $config_github_mainbranch $pluginbranch; then
    echo "The $pluginbranch branch does not contain the $config_github_mainbranch branch after the rebase. Something went wrong here."
    echo "I can't continue."
    exit 1
fi
success
unset gitbranch


if [[ $pluginpush -eq 1 ]]; then
    now "Push branch to Github"

    cd $pluginpath \
        && success || failure
    echo "The $pluginbranch branch was rewritten by the rebase and has to be force-pushed to $config_github_remoterepo."
    echo "Please confirm that you really want to force-push the branch."
    confirm
    git push --force-with-lease $config_github_remoterepo $pluginbranch \
        && success || failure
fi


###################################
### inform admin
###################################

now "Finish"

echo -e "The \033[1;35m$pluginbranch\033[0m branch was rebased onto the \033[1;35m$config_github_mainbranch\033[0m branch within the \033[1;35m$pluginpath\033[0m plugin."
if [[ $pluginpush -eq 1 ]]; then
    echo -e "The branch was force-pushed to Github as well."
fi
echo -e "Please review the results in the Git history."
