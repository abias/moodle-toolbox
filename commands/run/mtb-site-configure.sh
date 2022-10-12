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
mtb-site-configure.sh -s <site> -i <instance> [-a] [-d <distro>] [-r <release>]

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
echo -e "You requested to configure the \033[31m$moodleinstance\033[0m instance within the \033[31m$moodlesite\033[0m site!"
confirm


###################################
### prepare working with the Moodle instance
###################################

site_verifymoodleinstance $moodlesite $moodleinstance $moodledistro
site_pickmoodleinstance $moodlesite $moodleinstance $moodledistro
site_pickmoodlebranch $moodlesite $moodleinstance $moodledistro $moodlerelease


###################################
### action
###################################

now "Setting Moodle baseline configuration (from ini file)"

cd $site_wwwroot \
    && success || failure
sudo -u $site_site $config_webserver_phpbin $CURRENTDIR/../../_include/php/moodleconfigfromini.php -i="$CURRENTDIR/../../_template/$site_moodledistro/$site_moodlerelease/all/configbaseline.ini" \
    && success || failure


now "Setting Moodle baseline configuration (from sql file)"

cd $site_wwwroot \
    && success || failure
sudo -u $site_site $config_webserver_phpbin $CURRENTDIR/../../_include/php/moodleconfigfromsql.php -s="$CURRENTDIR/../../_template/$site_moodledistro/$site_moodlerelease/all/configbaseline.sql" \
    && success || failure


# The language pack import is not available before Moodle 3.10
if [[ $site_moodlerelease -ge 310 ]]; then
    now "Importing Moodle language customizations"

    # Confirmation
    echo "Due to MDL-75974, please login now into the Moodle GUI, go to 'Site administration -> Language -> Language customization' and do an initial customization checkout of all installed language packs"
    acknowledge


    cd $site_wwwroot \
        && success || failure

    # Get all language pack customizations for the given Moodle release
    readarray allcustomlang < <(find $CURRENTDIR/../../_template/$site_moodledistro/$site_moodlerelease/all/ -name *_local.zip -type f -printf "%f\n")

    # Iterate over these languages
    for langfile in ${allcustomlang[@]}
    do
        # Extract the language pack identifier
        lang=`cut -d "_" -f 1 <<<"$langfile"` \
            && success || failure
        # Import the language pack
        sudo -u $site_site $config_webserver_phpbin $site_wwwroot/admin/tool/customlang/cli/import.php --lang=$lang --source="$CURRENTDIR/../../_template/$site_moodledistro/$site_moodlerelease/all/$langfile" --checkin --mode=all \
            && success || failure
    done
fi


now "Updating Moodle DB to apply the new settings is necessary"

cd $site_wwwroot \
    && success || failure
# Updating the database is done now to make sure that Moodle core not show the database wizard on the first login after setting the baseline config
sudo -u $site_site $config_webserver_phpbin admin/cli/upgrade.php --non-interactive \
    && success || failure


###################################
### inform admin
###################################

now "Finish"

echo -e "The \033[31m$site_instance\033[0m instance within the \033[31m$site_site\033[0m site is configured."
