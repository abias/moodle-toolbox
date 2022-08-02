#!/bin/bash

###################################
### includes
###################################

CURRENTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$CURRENTDIR/../../_config/localconfig.sh"
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
mtb-init.sh -s <site> -i <instance> -f <fullname> -t <shortname> -n <dbname> -u <dbuser> -p <dbpass> [-a] [-d <distro>] [-r <release>] [-x <smtpserver>] [-y <smtpuser>] [-z <smtppass>]

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

  -x <smtpserver>
     The SMTP mail server which is used for outgoing mail

     Default value:
     $config_moodle_outgoingmailsmtphosts

  -y <smtpuser>
     The SMTP mail user which is used for outgoing mail

     Default value:
     $config_moodle_outgoingmailsmtpuser

  -z <smtppass>
     The SMTP mail password which is used for outgoing mail

     Default value:
     <hidden>
EOU
}

# Process parameters
while getopts 'hs:i:d:r:f:t:n:u:p:x:y:z:a' OPTION; do
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
        x)
            moodlesmtphosts=$OPTARG
            ;;
        y)
            moodlesmtpuser=$OPTARG
            ;;
        z)
            moodlesmtppass=$OPTARG
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

# If no SMTP host was given, use the default
if [[ -z "$moodlesmtphosts" ]]; then
    moodlesmtphosts=$config_moodle_outgoingmailsmtphosts
fi

# If no SMTP user was given, use the default
if [[ -z "$moodlesmtpuser" ]]; then
    moodlesmtpuser=$config_moodle_outgoingmailsmtpuser
fi

# If no SMTP password was given, use the default
if [[ -z "$moodlesmtppass" ]]; then
    moodlesmtppass=$config_moodle_outgoingmailsmtppass
fi

# Confirmation
echo -e "You requested to init the \033[31m$moodleinstance\033[0m instance within the \033[31m$moodlesite\033[0m site!"
confirm


###################################
### prepare working with the Moodle instance
###################################

# site_verifymoodleinstance - This standard step is not pot cssible here as Moodle is not set up yet
site_pickmoodleinstance $moodlesite $moodleinstance $moodledistro $moodlerelease


###################################
### security net
###################################

now "Checking security nets"

if [[ -d $site_instanceroot || -d $site_wwwroot || -d $site_moodledata || -e $site_configphp ]]; then
    echo "I have found already some Moodle assets, I expect that there is already a Moodle site installed."
    echo "It does not make sense to init the site again, at least not with this script."
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
    chown $moodlesite:psaserv $site_subscriptionroot \
        && success || failure
    chmod u=rX,g=X,o= $site_subscriptionroot \
        && success || failure
else
    success
fi


now "Creating $site_instanceroot Moodle instance directory"

mkdir $site_instanceroot \
    && success || failure
chown $moodlesite:psaserv $site_instanceroot \
    && success || failure
chmod u=rX,g=X,o= $site_instanceroot \
    && success || failure


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


now "Filling and placing config.php"

export configtemplate_wwwroot=$site_url
export configtemplate_dataroot=$site_moodledata
export configtemplate_dbname=$moodledbname
export configtemplate_dbuser=$moodledbuser
export configtemplate_dbpass=$moodledbpass
export configtemplate_upgradekey=$config_moodle_randomupgradekey
export configtemplate_pathtophp=$config_webserver_phpbin
export configtemplate_smtphosts=$moodlesmtphosts
export configtemplate_smtpuser=$moodlesmtpuser
export configtemplate_smtppass=$moodlesmtppass
export configtemplate_noreplyaddress=${config_moodle_outgoingmailnoreplyaddressprefix}@$moodlesite
export configtemplate_supportname="$moodlefullname"
export configtemplate_supportemail=${config_moodle_outgoingmailsupportemailprefix}@$moodlesite

cat $CURRENTDIR/../../_template/$moodledistro/$moodlerelease/$moodleinstance/config.php | envsubst '$configtemplate_wwwroot $configtemplate_dataroot $configtemplate_dbname $configtemplate_dbuser $configtemplate_dbpass $configtemplate_upgradekey $configtemplate_pathtophp $configtemplate_smtphosts $configtemplate_smtpuser $configtemplate_smtppass $configtemplate_noreplyaddress $configtemplate_supportname $configtemplate_supportemail' > $site_configphp \
    && success || failure

unset ${!configtemplate_*}


now "Setting the filesystem permissions for the Moodle instance files"

chown -R $moodlesite:psacln $site_moodledata \
    && success || failure
chmod -R u=rwX,g=rX,o=rX $site_moodledata \
    && success || failure
chown -R $moodlesite:psacln $site_wwwroot \
    && success || failure
chmod -R u=rX,g=rX,o=rX $site_wwwroot \
    && success || failure
chmod u=r,g=,o= $site_configphp \
    && success || failure


now "Installing Moodle database"

sudo -u $moodlesite $config_webserver_phpbin $site_wwwroot/admin/cli/install_database.php --lang=$config_moodle_defaultlang --agree-license --fullname="$moodlefullname" --shortname="$moodleshortname" --adminuser=$config_moodle_adminusername --adminpass=$config_moodle_adminuserpass --adminemail=$config_moodle_adminusermail \
    && success || failure


###################################
### inform admin
###################################

now "Finish"

echo -e "The \033[31m$moodleinstance\033[0m instance within the \033[31m$moodlesite\033[0m site is initiated."
echo -e "You can now login into the site on \033[31m$site_url\033[0m."
echo
echo "Please document these credentials:"
echo
echo "Username:    $config_moodle_adminusername"
echo "Password:    $config_moodle_adminuserpass"
echo "Upgrade Key: $config_moodle_randomupgradekey"
