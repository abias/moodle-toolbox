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
mtb-plugin-upgrade-release.sh -p <path> -m <machinerelease> -r <release>

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
echo -e "You requested to release the plugin upgrade of \033[1;35m$pluginpath\033[0m to release \033[1;35m$pluginrelease\033[0m!"
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
changes=$(grep "### v$pluginrelease-r1" $pluginpath/CHANGES.md)
if [[ $? -ne 0 ]]; then
    echo -e "The CHANGES.md file does not contain an 'v$pluginrelease-r1' section. It seems as if the upgrade is not finished yet."
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
gitcommit=$(git log --oneline | grep "Release v$pluginrelease-r1")
if [[ $? -ne 0 ]]; then
    echo -e "The git history does not contain a commit message for finishing this upgrade."
    echo "I can't continue."
    exit 1
else
    success
fi
unset gitcommit


now "Github actions status"

echo -e "The plugin upgrade must not be released if there are still any bugs or issues. Please confirm that Github actions was 'all green'."
confirm


###################################
### git
###################################

now "Prepare git commits"

git_init_commits


###################################
### action
###################################

now "Merge upgrade branch into $config_github_mainbranch branch"

cd $pluginpath \
    && success || failure
git checkout $config_github_mainbranch \
    && success || failure
git merge upgrade-$pluginmrelease \
    && success || failure


now "Push $config_github_mainbranch branch to Github"

cd $pluginpath \
    && success || failure
git push $config_github_remoterepo $config_github_mainbranch \
    && success || failure


now "Delete upgrade branch locally and on Github"

cd $pluginpath \
    && success || failure
git branch -d upgrade-$pluginmrelease \
    && success || failure
git push $config_github_remoterepo --delete upgrade-$pluginmrelease \
    && success || failure


now "Create a release branch based on the $config_github_mainbranch branch"

cd $pluginpath \
    && success || failure
git checkout $config_github_mainbranch \
    && success || failure
git branch MOODLE_${pluginmrelease}_STABLE \
    && success || failure


now "Tag the release in the release branch"

cd $pluginpath \
    && success || failure
git checkout MOODLE_${pluginmrelease}_STABLE \
    && success || failure
git tag v$pluginrelease-r1 \
    && success || failure


now "Adapt the Github actions badge after cutting the release branch"

cd $pluginpath \
    && success || failure
git checkout MOODLE_${pluginmrelease}_STABLE \
    && success || failure
# Only replace the branch name where it is used as branch parameter in the badge image URL (branch=main) and in the
# actions link URL (branch%3Amain). Otherwise, the main branch name would also be replaced within the plugin name
# (e.g. local_maintenance_livecheck would become local_MOODLE_503_STABLEtenance_livecheck).
sed -i -E "4s/(branch=|branch%3A)${config_github_mainbranch}([^A-Za-z0-9_.-]|$)/\1MOODLE_${pluginmrelease}_STABLE\2/g" $pluginpath/README.md \
    && success || failure
git commit -a -m 'Adapt GHA badge after cutting the release branch' \
    && success || failure


now "Push release branch and the release tag to Github"

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

echo -e "The \033[1;35m$pluginpath\033[0m plugin upgrade for release \033[1;35m$pluginrelease\033[0m has been released and has been pushed to Github."
echo -e "Please review the results on Github and check if the release has been pushed properly to moodle.org by Github Actions as well."
