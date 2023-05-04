#!/bin/bash

###################################
### includes
###################################

CURRENTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$CURRENTDIR/../../_config/localconfig.sh"
source "$CURRENTDIR/../../_config/localcredentials.sh"
source "$CURRENTDIR/../../_include/sh/functionslib.sh"


###################################
### check user
###################################

require_root


###################################
### get existing moodle sites
###################################

site_scanmoodlesites


###################################
### check startup
###################################

usage ()
{
    moodlesites=`array_echo_linebyline_indented "${moodlesites[@]}"`
    moodleinstances=`array_echo_linebyline_indented "${config_vhost_instances[@]}"`
    moodledistros=`array_echo_linebyline_indented "${config_vhost_distros[@]}"`
    moodlereleases=`array_echo_linebyline_indented "${config_vhost_releases[@]}"`

    cat <<EOU
Usage:
mtb-site-pull.sh -s <site> -i <instance> [-a] [-d <distro>] [-r <release>] [-n]

Mandatory parameters:
  -s <site>
     The Moodle site which is to be used by this script

     Possible values:
$moodlesites

  -i <instance>
     The instance of the Moodle site which is to be used by this script

     Possible values:
$moodleinstances

Optional parameters:
  -a
     Auto mode
     If this flag is set, the script will not ask for any confirmations

  -n
     No sleep mode
     If this flag is set, the script will not sleep before enabling the maintenance mode

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
while getopts 'hs:i:d:r:an' OPTION; do
    case "$OPTION" in
        s)
            if ! array_contains_element "$OPTARG" "${moodlesites[@]}"; then
                 usage
                 exit 1
	    else
                 moodlesite=$OPTARG
	    fi
            ;;
        i)
            if ! array_contains_element "$OPTARG" "${config_vhost_instances[@]}"; then
                 usage
                 exit 1
	    else
                 moodleinstance=$OPTARG
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
        n)
            nosleepmode=1
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

# Verify that a moodleinstance was given
if [[ -z "$moodleinstance" ]]; then
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
echo -e "You requested to pull the latest codebase into the \033[31m$moodleinstance\033[0m instance within the \033[31m$moodlesite\033[0m site!"
echo "I will pull the codebase and run a DB update afterwards."
confirm


###################################
### prepare working with the Moodle instance
###################################

site_verifymoodleinstance $moodlesite $moodleinstance $moodledistro
site_pickmoodleinstance $moodlesite $moodleinstance $moodledistro
site_pickmoodlebranch $moodlesite $moodleinstance $moodledistro $moodlerelease
site_verifygithubrepo


###################################
### security net
###################################

now "Checking security nets"

cd $site_wwwroot \
    && success || failure
gitstatus=$(git status --porcelain)
if [[ -n "$gitstatus" ]]; then
    echo -e "\033[31mThe main git repo is not clean. This MUST be solved before the rollout.\033[0m"
    echo "This Moodle instance's git repo is not clean. This should not happy and MUST be solved before the pull."
    echo "I can't continue."
    exit 1
else
    success
fi
unset gitstatus


###################################
### action
###################################

now "Cloning $site_wwwroot Moodle wwwroot directory from Github into update directory"

$config_webserver_nice git clone $site_githuburl $site_wwwrootupdate \
    && success || failure
trap 'rm -rf "$site_wwwrootupdate"' EXIT \
    && success || failure


now "Checking out the $site_moodlebranchsite branch"

cd $site_wwwrootupdate \
    && success || failure
$config_webserver_nice git checkout $site_moodlebranchsite \
    && success || failure


now "Initializing the Git submodules"

cd $site_wwwrootupdate \
    && success || failure
$config_webserver_nice git submodule update --init --recursive \
    && success || failure


now "Copying config.php into update directory"

cp -p $site_configphp $site_configphpupdate \
    && success || failure


now "Setting the filesystem permissions for the update directory"

site_fixpermissions update


now "Stop cron"

cd $site_wwwroot \
    && success || failure
sudo -u $site_site $config_webserver_phpbin admin/cli/cron.php --stop \
    && success || failure


if [[ $moodlerelease -gt 310 ]]; then
    now "Disable cron"

    cd $site_wwwroot \
        && success || failure
    sudo -u $site_site $config_webserver_phpbin admin/cli/cron.php --disable-wait \
        && success || failure
fi


now "Enable maintenance mode"

cd $site_wwwroot \
    && success || failure
if [[ $nosleepmode -eq 1 ]]; then
    sudo -u $site_site $config_webserver_phpbin admin/cli/maintenance.php --enable \
        && success || failure
else
    sudo -u $site_site $config_webserver_phpbin admin/cli/maintenance.php --enablelater=$config_toolbox_maintenancesleep \
        && success || failure
    sleep ${config_toolbox_maintenancesleep}m
fi


now "Deploy the updated codebase"

mv $site_wwwroot ${site_wwwroot}_old \
    && success || failure
mv $site_wwwrootupdate $site_wwwroot \
    && success || failure
rm -rf ${site_wwwroot}_old \
    && success || failure


now "Update Moodle database"

cd $site_wwwroot \
    && success || failure
sudo -u $site_site $config_webserver_phpbin admin/cli/upgrade.php --non-interactive \
    && success || failure


now "Disable maintenance mode"

cd $site_wwwroot \
    && success || failure
sudo -u $site_site $config_webserver_phpbin admin/cli/maintenance.php --disable \
    && success || failure


if [[ $moodlerelease -gt 310 ]]; then
    now "Enable cron"

    cd $site_wwwroot \
        && success || failure
    sudo -u $site_site $config_webserver_phpbin admin/cli/cron.php --enable \
        && success || failure
fi


###################################
### inform admin
###################################

now "Finish"

echo -e "The \033[31m$site_instance\033[0m instance within the \033[31m$site_site\033[0m site was pulled and updated."
