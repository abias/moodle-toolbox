#!/bin/bash

###################################
### includes
###################################

CURRENTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$CURRENTDIR/../../_config/localconfig.sh"
source "$CURRENTDIR/../../_include/sh/functionslib.sh"


###################################
### check host
###################################

require_buildinghost


###################################
### check user
###################################

require_root


###################################
### get existing moodle site repos
###################################

siterepo_scanmoodlesiterepos


###################################
### check startup
###################################

usage ()
{
    moodlesiterepos=`array_echo_linebyline_indented "${moodlesiterepos[@]}"`
    moodledistros=`array_echo_linebyline_indented "${config_vhost_distros[@]}"`
    moodlereleases=`array_echo_linebyline_indented "${config_vhost_releases[@]}"`

    cat <<EOU
Usage:
mtb-site-update.sh -s <site> [-a] [-d <distro>] [-r <release>]

Mandatory parameters:
  -s <site>
     The Moodle site which is to be used by this script

     Possible values:
$moodlesiterepos

Optional parameters:
  -a
     Auto mode
     If this flag is set, the script will not ask for any confirmations

  -d <distro>
     The Moodle distribution which is to be used by the scripts

     Possible values:
$moodledistros

     Default value:
     $config_vhost_distros_default

  -r <release>
     The Moodle release which is to be used by the scripts

     Possible values:
$moodlereleases

     Default value:
     $config_vhost_releases_default
EOU
}

# Process parameters
while getopts 'hs:d:r:a' OPTION; do
    case "$OPTION" in
        s)
            if ! array_contains_element "$OPTARG" "${moodlesiterepos[@]}"; then
                 usage
                 exit 1
	    else
                 moodlesite=$OPTARG
	    fi
            ;;
        d)
            if ! array_contains_element "$OPTARG" "${config_vhost_distros[@]}"; then
                 usage
                 exit 1
        else
                 moodledistro=$OPTARG
        fi
            ;;
        r)
            if ! array_contains_element "$OPTARG" "${config_vhost_releases[@]}"; then
                 usage
                 exit 1
            else
                 moodlerelease=$OPTARG
            fi
            ;;
        a)
            automode=1
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

# Verify that a moodlesite was given
if [[ -z "$moodlesite" ]]; then
    usage
    exit 1
fi

# If no distro was given, use the default
if [[ -z "$moodledistro" ]]; then
    moodledistro=$config_vhost_distros_default
fi

# If no release was given, use the default
if [[ -z "$moodlerelease" ]]; then
    moodlerelease=$config_vhost_releases_default
fi

# Confirmation
echo -e "You requested to update the Moodle site repo for the \033[1;35m$moodlesite\033[0m site!"
confirm


###################################
### prepare working with the Moodle site repo
###################################

siterepo_pickmoodlesiterepo $moodlesite $moodledistro $moodlerelease
site_verifygithubrepo $siterepo_githuburl


###################################
### security net
###################################

now "Checking security nets"

cd $siterepo_repopath \
    && success || failure
coreremoteexists=`git remote | grep $config_build_coreremote`
if [ $? -gt 0 ]; then
    echo "I have not found a configured remote repo called $config_build_coreremote, I have to expect that the repo is broken."
    echo "I can't continue."
    exit 1
else
    success
fi
unset coreremoteexists


cd $siterepo_repopath \
    && success || failure
corebranchexists=`git branch | grep $siterepo_branchcore`
if [ $? -gt 0 ]; then
    echo "I have not found the $siterepo_branchcore in this repo, I have to expect that the repo is broken."
    echo "I can't continue."
    exit 1
else
    success
fi
unset corebranchexists


cd $siterepo_repopath \
    && success || failure
sitebranchexists=`git branch | grep $siterepo_branchsite`
if [ $? -gt 0 ]; then
    echo "I have not found the $siterepo_branchsite in this repo, I have to expect that the repo is broken."
    echo "I can't continue."
    exit 1
else
    success
fi
unset sitebranchexists


cd $siterepo_repopath \
    && success || failure
sitetestbranchexists=`git branch | grep $siterepo_branchsitetest`
if [ $? -gt 0 ]; then
    echo "I have not found the $siterepo_branchsitetest in this repo, I have to expect that the repo is broken."
    echo "I can't continue."
    exit 1
else
    success
fi
unset sitetestbranchexists


###################################
### action
###################################

now "Fetching Git status from the core repository"

cd $siterepo_repopath \
    && success || failure
git fetch $config_build_coreremote \
    && success || failure


now "Reset $config_build_corebranch branch to the status from the $config_build_coreremote repository"

cd $siterepo_repopath \
    && success || failure
git checkout ${siterepo_branchcore} --recurse-submodules \
    && success || failure
git reset --hard ${config_build_coreremote}/${siterepo_branchcore} \
    && success || failure
git push origin ${siterepo_branchcore} --force \
    && success || failure


now "Rebase $config_build_sitebranch branch to the status from the $config_build_coreremote repository"

cd $siterepo_repopath \
    && success || failure
git checkout ${siterepo_branchsite} --recurse-submodules \
    && success || failure
note "The following output might contain warnings like 'unable to rmdir'. This is an artefact of the rebase which can be ignored"
git rebase ${siterepo_branchcore} \
    && success || failure


now "Update submodules"

git submodule update --remote --checkout \
    && success || failure


now "Commit updated submodules to the repo with a clear commit message"

echo "$config_build_commitpluginupdates" > $config_build_commitmessage \
    && success || failure
echo >> $config_build_commitmessage \
    && success || failure
git status | grep modified | awk '{print $2}' >> $config_build_commitmessage \
    && success || failure
git commit --all --file=$config_build_commitmessage \
    && success || if [ $? -eq 1 ]; then success; else failure; fi # if nothing was there to commit, the exit code is 1 which is also a success for us.
rm $config_build_commitmessage \
    && success || failure


now "Push $config_build_sitebranch branch to Github"
    
git push origin ${siterepo_branchsite} --force \
    && success || failure


now "Rebase ${config_build_sitebranch}_test branch"

git checkout ${siterepo_branchsitetest} \
    && success || failure
git rebase ${siterepo_branchsite} \
    && success || failure
git push origin ${siterepo_branchsitetest} --force \
    && success || failure


now "Checkout $config_build_sitebranch branch again"

git checkout ${siterepo_branchsite} \
    && success || failure


###################################
### inform admin
###################################

now "Finish"

echo -e "The Moodle site repo for the \033[1;35m$moodlesite\033[0m site was updated."
echo -e "You can now pull the site on the site's webserver."
