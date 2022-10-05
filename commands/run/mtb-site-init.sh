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
mtb-site-init.sh -s <site> -i <instance> [-a] [-d <distro>] [-r <release>]

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
while getopts 'hs:i:d:r:a' OPTION; do
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
echo -e "You requested to init the \033[31m$moodleinstance\033[0m instance within the \033[31m$moodlesite\033[0m site!"
confirm


###################################
### prepare working with the Moodle instance
###################################

# site_verifymoodleinstance - This standard step is not possible here as the Moodle instance is not initiated yet
site_pickmoodleinstance $moodlesite $moodleinstance $moodledistro
site_pickmoodlebranch $moodlesite $moodleinstance $moodledistro $moodlerelease


###################################
### security net
###################################

now "Checking security nets"

if [[ $site_instanceisprod -eq 0 && ! -d $site_instancerootprod ]]; then
    echo "You want to install a non-prod instance but I have not found the prod instance."
    echo "The prod instance has to be created before any non-prod instance."
    echo "I can't continue."
    exit 1
else
    success
fi

# The following security nets are run here as site_verifymoodleinstance was not run before

if [[ -d $site_moodledata ]]; then
    echo "I have found already a Moodledata directory, I expect that there is already a Moodle instance installed."
    echo "It does not make sense to init the instance again, at least not with this script."
    echo "I can't continue."
    exit 1
else
    success
fi

if [[ -e $site_configphp ]]; then
    echo "I have found already a config.php file, I expect that there is already a Moodle instance installed."
    echo "It does not make sense to init the instance again, at least not with this script."
    echo "I can't continue."
    exit 1
else
    success
fi

if [[ -e $site_womenslib ]]; then
    echo "I have found already a lib/womenslib.php file, I expect that there is already a Moodle instance installed."
    echo "It does not make sense to init the instance again, at least not with this script."
    echo "I can't continue."
    exit 1
else
    success
fi

git ls-remote $site_githuburl 2>/dev/null 1>/dev/null
if [ $? -gt 0 ]; then
    echo "I haven't found a Github repository on $site_githuburl for the given Moodle site."
    echo "I can't continue."
    exit 1
else
    success
fi


###################################
### action
###################################

now "Creating $site_subscriptionroot root directory (if it does not exist yet)"

if [[ ! -d $site_subscriptionroot ]]; then
    mkdir $site_subscriptionroot \
        && success || failure
    chown $site_site:psaserv $site_subscriptionroot \
        && success || failure
    chmod u=rX,g=X,o= $site_subscriptionroot \
        && success || failure
else
    success
fi


now "Creating $site_instanceroot Moodle instance directory (if it does not exist yet)"

if [[ ! -d $site_instanceroot ]]; then
    mkdir $site_instanceroot \
        && success || failure
    chown $site_site:psaserv $site_instanceroot \
        && success || failure
    chmod u=rX,g=X,o= $site_instanceroot \
        && success || failure
else
    success
fi


now "Removing $site_wwwroot Moodle instance directory (if it does exist already without a Moodle codebase in it)"

if [[ -d $site_wwwroot ]]; then
    rm -rf $site_wwwroot \
        && success || failure
else
    success
fi


now "Creating $site_moodledata Moodledata directory"

mkdir $site_moodledata \
    && success || failure


now "Cloning $site_wwwroot Moodle wwwroot directory from Github"

git clone $site_githuburl $site_wwwroot \
    && success || failure


now "Checking out the $site_moodlebranchsite branch"

cd $site_wwwroot \
    && success || failure
git checkout $site_moodlebranchsite \
    && success || failure


now "Initializing the Git submodules"

cd $site_wwwroot \
    && success || failure
git submodule update --init \
    && success || failure


now "Setting the filesystem permissions for the Moodle instance files"

site_fixpermissions


###################################
### inform admin
###################################

now "Finish"

echo -e "The \033[31m$site_instance\033[0m instance within the \033[31m$site_site\033[0m site is initiated."
echo -e "You can now install the site."
