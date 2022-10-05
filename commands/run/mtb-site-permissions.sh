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

    cat <<EOU
Usage:
mtb-site-permissions.sh -s <site> -i <instance> [-a] [-d <distro>]

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
EOU
}

# Process parameters
while getopts 'hs:i:d:a' OPTION; do
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

# Confirmation
echo -e "You requested to fix the permissions of the \033[31m$moodleinstance\033[0m instance within the \033[31m$moodlesite\033[0m site!"
confirm


###################################
### prepare working with the Moodle instance
###################################

site_verifymoodleinstance $moodlesite $moodleinstance $moodledistro
site_pickmoodleinstance $moodlesite $moodleinstance $moodledistro
site_pickmoodlebranch $moodlesite $moodleinstance $moodledistro $moodlerelease


###################################
### security net
###################################

now "Checking security nets"

if [[ ! -d $site_moodledata ]]; then
    echo "I haven't found a Moodledata directory, I expect that the Moodle instance was not initialized yet."
    echo "I can't continue."
    exit 1
else
    success
fi

if [[ ! -e $site_womenslib ]]; then
    echo "I haven't found a lib/womenslib.php file, I expect that the Moodle instance was not initialized yet."
    echo "I can't continue."
    exit 1
else
    success
fi

if [[ ! -e $site_mucconfig ]]; then
    echo "I haven't found a MUC config file, I expect that the Moodle instance was not installed yet."
    echo "I can't continue."
    exit 1
else
    success
fi

if [[ ! -e $site_configphp ]]; then
    echo "I haven't found a config.php file, I expect that the Moodle instance was not installed yet."
    echo "I can't continue."
    exit 1
else
    success
fi


###################################
### action
###################################

now "Setting the filesystem permissions for the Moodle instance files"

site_fixpermissions


###################################
### inform admin
###################################

now "Finish"

echo -e "The permissions of the \033[31m$site_instance\033[0m instance within the \033[31m$site_site\033[0m site were fixed."
