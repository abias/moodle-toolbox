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
mtb-site-reset.sh -s <site> -i <instance> [-a] [-d <distro>]

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
echo -e "You requested to reset the \033[31m$moodleinstance\033[0m instance within the \033[31m$moodlesite\033[0m site!"
echo "I will reset the whole instance to the current status (code + data) of the prod instance."
echo -e "I will \033[31mnot reset the config.php file\033[0m. If you have changed this file in any way, please make sure to reset it manually back to a stable state."
confirm


###################################
### prepare working with the Moodle instance
###################################

site_verifymoodleinstance $moodlesite $moodleinstance $moodledistro
site_pickmoodleinstance $moodlesite $moodleinstance $moodledistro


###################################
### security net
###################################

now "Checking security nets"

if [[ $site_instanceisprod -eq 1 ]]; then
    echo "You want to reset the prod instance."
    echo "This is not possible."
    echo "I can't continue."
    exit 1
else
    success
fi


###################################
### action
###################################

now "Disable cron"

cd $site_wwwroot \
    && success || failure
sudo -u $site_site $config_webserver_phpbin admin/cli/cron.php --stop \
    && success || failure
sudo -u $site_site $config_webserver_phpbin admin/cli/cron.php --disable-wait \
    && success || failure


now "Enable maintenance mode"

cat > $site_climaintenance << EOL
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
        "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <meta http-equiv="Content-type" content="text/html;charset=UTF-8">
    <title>Moodle Reset</title>
    <style type="text/css">
        body { text-align: center; padding: 150px; font: 20px Helvetica, sans-serif; color: #333; }
        h1 { font-size: 50px; }
    </style>
</head>
<body>
    <div id="article">
        <h1>Moodle Reset</h1>
        <p>This Moodle instance is currently being reset.<br />Please be patient, we will be back in a few minutes.</p>
    </div>
</body>
</html>
EOL

chown $site_site:psacln $site_climaintenance \
    && success || failure

chmod u=rwX,g=rX,o= $site_climaintenance \
    && success || failure


now "Syncing Moodle wwwroot"

$config_webserver_nice $config_webserver_rsyncbin --verbose --recursive --perms --owner --group --times --delete --exclude=/config.php $site_wwwrootprod/ $site_wwwroot/ \
    && success || failure


now "Syncing Moodle moodledata"

$config_webserver_nice $config_webserver_rsyncbin --verbose --recursive --perms --owner --group --times --delete --exclude=/climaintenance.html --ignore-missing-args --delete-missing-args $site_moodledataprod/ $site_moodledata/ \
    && success || if [ $? -eq 24 ]; then success; else failure; fi # if files have vanished during sync, the exit code is 24 which is also a success for us.


now "Syncing Moodle database"

site_pickdbcredentials

dumpfile=$(mktemp -p $site_subscriptionbasedir) \
    && success || failure

trap 'rm -f "$dumpfile"' EXIT \
    && success || failure

$config_webserver_mysqldumpbin --user=$site_dbuserprod --password=$site_dbpassprod --add-drop-database --single-transaction --quick --databases $site_dbnameprod > $dumpfile \
    && success || failure

sed -i "s/$site_dbnameprod/$site_dbname/" $dumpfile \
    && success || failure

$config_webserver_mariadbbin -u $site_dbuser -p$site_dbpass -D $site_dbname < $dumpfile \
    && success || failure

rm -rf $dumpfile \
    && success || failure


now "Setting the filesystem permissions for the Moodle instance files"

site_fixpermissions


now "Kill all sessions"

cd $site_wwwroot \
    && success || failure
sudo -u $site_site $config_webserver_phpbin admin/cli/kill_all_sessions.php \
    && success || failure


if [[ -f $site_wwwroot/local/datacleaner/cli/clean.php ]]; then
    now "Run local_datacleaner tasks"

    cd $site_wwwroot \
        && success || failure
    sudo -u $site_site $config_webserver_phpbin local/datacleaner/cli/clean.php --run --verbose \
        && success || failure
fi


now "Purge caches"

cd $site_wwwroot \
    && success || failure
sudo -u $site_site $config_webserver_phpbin admin/cli/purge_caches.php \
    && success || failure


now "Disable maintenance mode"

cd $site_wwwroot \
    && success || failure
sudo -u $site_site $config_webserver_phpbin admin/cli/maintenance.php --disable \
    && success || failure


now "Enable cron"

cd $site_wwwroot \
    && success || failure
sudo -u $site_site $config_webserver_phpbin admin/cli/cron.php --enable \
    && success || failure


###################################
### inform admin
###################################

now "Finish"

echo -e "The \033[31m$site_instance\033[0m instance within the \033[31m$site_site\033[0m site was reset."
