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
    moodleuploads=`array_echo_linebyline_indented "${config_moodle_upload[@]}"`
    moodlelangs=`array_echo_linebyline_indented "${config_moodle_langs[@]}"`

    cat <<EOU
Usage:
mtb-site-install.sh -s <site> -i <instance> -f <fullname> -t <shortname> -n <dbname> -u <dbuser> -p <dbpass> [-a] [-d <distro>] [-r <release>] [-m <maxbytes>] [-l <language>] [-j]

Mandatory parameters:
  -s <site>
     The Moodle site which is to be used by this script

     Possible values:
$moodlesites

  -i <instance>
     The instance of the Moodle site which is to be used by this script
     Possible values:
$moodleinstances

  -f <fullname>
     The full name to be set for the Moodle site

  -t <shortname>
     The short name to be set for the Moodle site

  -n <dbname>
     The database name to be set for the Moodle site

  -u <dbuser>
     The database user to be set for the Moodle site

  -p <dbpass>
     The database password to be set for the Moodle site

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

  -m <maxbytes>
     The Moodle maxbytes setting to be set for the Moodle site

     Possible values:
$moodleuploads

     Default value:
     $config_moodle_upload_default

  -l <language>
     The language pack to be set for the Moodle site

     Possible values:
$moodlelangs

     Default value:
     $config_moodle_langs_default

  -j
     Initialize H5P content types
     If this flag is set, the script will download the H5P content types to the Moodle instance initially
EOU
}

# Process parameters
while getopts 'hs:i:d:r:f:t:n:u:p:m:l:aj' OPTION; do
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
        f)
            moodlefullname=$OPTARG
            ;;
        t)
            moodleshortname=$OPTARG
            ;;
        n)
            moodledbname=$OPTARG
            ;;
        u)
            moodledbuser=$OPTARG
            ;;
        p)
            moodledbpass=$OPTARG
            ;;
        m)
            if ! array_contains_element "$OPTARG" "${config_moodle_upload[@]}"; then
                 usage
                 exit 1
            else
                 moodleupload=$OPTARG
            fi
            ;;
        l)
            if ! array_contains_element "$OPTARG" "${config_moodle_langs[@]}"; then
                 usage
                 exit 1
            else
                 moodlelang=$OPTARG
            fi
            ;;
        a)
            automode=1
            ;;
        j)
            moodleinith5p=1
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

# Verify that a moodlefullname was given
if [[ -z "$moodlefullname" ]]; then
    usage
    exit 1
fi

# Verify that a moodleshortnamename was given
if [[ -z "$moodleshortname" ]]; then
    usage
    exit 1
fi

# Verify that a moodledbname was given
if [[ -z "$moodledbname" ]]; then
    usage
    exit 1
fi

# Verify that a moodledbuser was given
if [[ -z "$moodledbuser" ]]; then
    usage
    exit 1
fi

# Verify that a moodledbpass was given
if [[ -z "$moodledbpass" ]]; then
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

# If no Moodle upload size was given, use the default
if [[ -z "$moodleupload" ]]; then
    moodleupload=$config_moodle_upload_default
fi

# If no Moodle lang was given, use the default
if [[ -z "$moodlelang" ]]; then
    moodlelang=$config_moodle_langs_default
fi

# Confirmation
echo -e "You requested to init the \033[31m$moodleinstance\033[0m instance within the \033[31m$moodlesite\033[0m site!"
confirm


###################################
### prepare working with the Moodle instance
###################################

# site_verifymoodleinstance - This standard step is not possible here as the Moodle instance is not installed yet
site_pickmoodleinstance $moodlesite $moodleinstance $moodledistro
site_pickmoodlebranch $moodlesite $moodleinstance $moodledistro $moodlerelease


###################################
### security net
###################################

now "Checking security nets"

if [[ $site_instanceisprod -eq 0 && ! -d $site_instancerootrealprod ]]; then
    echo "You want to install a non-prod instance but I have not found the prod instance."
    echo "The prod instance has to be created before any non-prod instance."
    echo "If the prod instance is a singleton instance, then you have to be aware that there cannot be any non-prod instances in addition to a singleton instance."
    echo "I can't continue."
    exit 1
else
    success
fi

# The following security nets are run here as site_verifymoodleinstance was not run before

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

if [[ -e $site_mucconfig ]]; then
    echo "I have found already a MUC config file, I expect that there is already a Moodle instance installed."
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

dbconnectionworking=`$config_webserver_mariadbbin -u $moodledbuser -p$moodledbpass -D $moodledbname -e "SELECT table_name FROM information_schema.columns WHERE table_schema = '$moodledbname'"`
if [ $? -gt 0 ]; then
    echo "I think the given database credentials do not work, I can't connect to the database."
    echo "I can't continue."
    exit 1
else
    success
fi
unset dbconnectionworking

tablesexisting=`$config_webserver_mariadbbin -u $moodledbuser -p$moodledbpass -D $moodledbname --skip-column-names -e "SELECT COUNT(DISTINCT table_name) FROM information_schema.columns WHERE table_schema = '$moodledbname'"`
if [ $tablesexisting -gt 0 ]; then
    echo "I have found already some database tables, I expect that there is already a Moodle instance installed."
    echo "It does not make sense to init the instance again, at least not with this script."
    echo "I can't continue."
    exit 1
else
    success
fi
unset tablesexisting


###################################
### action
###################################

now "Filling and placing config.php"

site_pickupgradekey
site_pickenvbarsecretkey

export configtemplate_wwwroot=$site_url
export configtemplate_dataroot=$site_moodledata
export configtemplate_dbname=$moodledbname
export configtemplate_dbuser=$moodledbuser
export configtemplate_dbpass=$moodledbpass
export configtemplate_upgradekey=$site_upgradekey
export configtemplate_bbburl="${config_moodle_bbburlprefix}/${config_moodle_bbbuser}/${config_moodle_bbburlsuffix}"
export configtemplate_bbbtoken=${config_moodle_bbbtoken}
export configtemplate_pathtophp=$site_moodlephpbin
export configtemplate_pathtodu=$config_webserver_dubin
export configtemplate_pathtodot=$config_webserver_dotbin
export configtemplate_pathtogs=$config_webserver_gsbin
export configtemplate_smtphosts=$config_moodle_outgoingmailsmtphosts
export configtemplate_smtpuser=$config_moodle_outgoingmailsmtpuser
export configtemplate_smtppass=$config_moodle_outgoingmailsmtppass
export configtemplate_noreplyaddress=${config_moodle_outgoingmailnoreplyaddressprefix}@$site_site
export configtemplate_maxbytes=$((moodleupload * 1024 * 1024))
export configtemplate_envbarprodroot=$site_envbarprodroot
export configtemplate_envbartestroot=$site_envbartestroot
export configtemplate_envbarsecretkey=$site_envbarsecretkey
export configtemplate_divertallmailsaddress=$site_divertallmailsaddress
export configtemplate_datacleanerprodroot=$site_datacleanerprodroot
export configtemplate_cachedir=$site_moodledata/cache
export configtemplate_localcachedir=$site_moodledata/localcache
export configtemplate_tempdir=$site_moodledata/temp
export configtemplate_backuptempdir=$site_moodledata/backuptemp
export configtemplate_localrequestdir=/tmp/$site_site
export configtemplate_lang=$moodlelang
export configvalue_supportname="$moodlefullname $config_moodle_outgoingmailsupportnamesuffix"
export configvalue_supportemail=${config_moodle_outgoingmailsupportemailprefix}@$site_site


cat $CURRENTDIR/../../_template/$site_moodledistro/$site_moodlerelease/$site_instance/config.php | envsubst '$configtemplate_wwwroot $configtemplate_dataroot $configtemplate_dbname $configtemplate_dbuser $configtemplate_dbpass $configtemplate_upgradekey $configtemplate_bbburl $configtemplate_bbbtoken $configtemplate_pathtophp $configtemplate_pathtodu $configtemplate_pathtodot $configtemplate_pathtogs $configtemplate_smtphosts $configtemplate_smtpuser $configtemplate_smtppass $configtemplate_noreplyaddress $configtemplate_maxbytes $configtemplate_envbarprodroot $configtemplate_envbartestroot $configtemplate_envbarsecretkey $configtemplate_divertallmailsaddress $configtemplate_datacleanerprodroot $configtemplate_cachedir $configtemplate_localcachedir $configtemplate_tempdir $configtemplate_backuptempdir $configtemplate_localrequestdir $configtemplate_lang' > $site_configphp \
    && success || failure

unset ${!configtemplate_*}


now "Setting the filesystem permissions for the Moodle instance files"

site_fixpermissions


now "Installing Moodle database"

cd $site_wwwroot \
    && success || failure
sudo -u $site_site $site_moodlephpbin admin/cli/install_database.php --lang=$moodlelang --agree-license --fullname="$moodlefullname" --shortname="$moodleshortname" --adminuser=$config_moodle_adminusername --adminpass=$config_moodle_adminuserpass --adminemail=$config_moodle_adminusermail \
    && success || failure


now "Setting site configuration values"

cd $site_wwwroot \
    && success || failure
sudo -u $site_site $site_moodlephpbin admin/cli/cfg.php --name=supportname --set="$configvalue_supportname" \
    && success || failure
sudo -u $site_site $site_moodlephpbin admin/cli/cfg.php --name=supportemail --set="$configvalue_supportemail" \
    && success || failure


if [[ $moodleinith5p -eq 1 ]]; then
    now "Download H5P content types"

    cd $site_wwwroot \
        && success || failure
    # The following scheduled task can fail for several reasons, especially because we are downloading stuff from a third party system
    sudo -u $site_site $site_moodlephpbin admin/cli/scheduled_task.php --execute=\\core\\task\\h5p_get_content_types_task \
        && success || failureconfirm
fi


###################################
### inform admin
###################################

now "Finish"

echo -e "The \033[31m$site_instance\033[0m instance within the \033[31m$site_site\033[0m site is installed."
echo -e "You can now login into the site on \033[31m$site_url\033[0m"
echo
echo "Please document these credentials:"
echo
echo "Username:    $config_moodle_adminusername"
echo "Password:    $config_moodle_adminuserpass"
echo "Upgrade Key: $site_upgradekey"
