#!/bin/bash

###################################
### workflow functions
###################################

# This helper function simply shows a success message.
success ()
{
    echo -e "\033[32mSuccess\033[0m"
    return 0
}

# This helper function shows a failure message and terminates the script afterwards.
failure ()
{
    echo -e "\033[31mFailed (return code: $?)\033[0m" >&2
    echo "Exiting..."
    exit 1
}

# This helper function shows a failure message after a failed command, asks for confirmation and does _not_ terminate the script afterwards.
# If the automode variable is set to 1, the script terminates anyway.
failureconfirm ()
{
    echo -e "\033[31mFailed (return code: $?)\033[0m" >&2

    if [[ $automode -eq 1 ]]; then
        echo "Exiting..."
        exit 1
    fi

    read -p "Do you want me to continue and will you check and handle the failure after the script is completed (y/n)? " CONT
    if [ "$CONT" != "y" ]; then
        echo "Ok, exiting...";
        exit 1;
    fi
}

# This helper function simply shows a status message to make clear what is happening.
now ()
{
    echo
    echo -e "\033[1;35mNow: $1\033[0m"
}

# This helper function simply shows a note message for side information.
note ()
{
    echo -e "\033[1;33mNote: $1\033[0m"
}

# This helper function asks for confirmation. 
# If the automode variable is set to 1, the function returns directly.
# If the user enters y, the script continues.
# If the user enters anything else, the script terminates.
confirm ()
{
    if [[ $automode -eq 1 ]]; then
        return;
    fi

    read -p "Continue (y/n)? " CONT
    if [ "$CONT" != "y" ]; then
        echo "Ok, exiting...";
        exit 1;
    fi
}

# This helper function asks for confirmation. 
# If the automode variable is set to 1, the function returns directly.
# If the user enters y, the script executes the command which is passed in $1.
# If the user enters n, the script continues without executing the command.
# If the user enters anything else, the script terminates.
ask ()
{
    if [[ $automode -eq 1 ]]; then
        return;
    fi

    read -p "Do you want me to do this (y/n)? " CONT
    if [ "$CONT" == "y" ]; then
        echo "Ok, I will do this...";
        $1 \
            && success || failure
    elif [ "$CONT" == "n" ]; then
        echo "Ok, I will not do this...";
    else
        echo "Invalid answer, exiting...";
        exit 1;
    fi
}

# This helper function asks for confirmation. 
# If the automode variable is set to 1, the function returns directly.
# If the user enters y, the script sets the variable doit to 1.
# If the user enters n, the script sets the variable doit to 0.
# If the user enters anything else, the script terminates.
askandremember ()
{
    if [[ $automode -eq 1 ]]; then
        return;
    fi

    read -p "Do you want me to do this (y/n)? " CONT
    if [ "$CONT" == "y" ]; then
        echo "Ok, I will do this...";
        doit=1
    elif [ "$CONT" == "n" ]; then
        echo "Ok, I will not do this...";
        doit=0
    else
        echo "Invalid answer, exiting...";
        exit 1;
    fi
}

# This helper function simply pauses the script execution and waits for a key press.
# If the automode variable is set to 1, the function returns directly.
acknowledge ()
{
    if [[ $automode -eq 1 ]]; then
        return;
    fi

    read -p "Press any key to continue."
}


###################################
### user checks
###################################

# This helper function checks if the script is run as root.
# If it is not, the script terminates.
require_root ()
{
if (( $EUID != 0 )); then
    echo "This script has to be run as root"
    echo "Please run it as root or with sudo"
    echo "Exiting..."
    exit 1
fi
}

# This helper function checks if the script is run as root.
# If it is, the script terminates.
require_nonroot ()
{
if (( $EUID == 0 )); then
    echo "This script has to be as normal user"
    echo "Please run it as normal user"
    echo "It will use sudo itself for all commands which require root permissions"
    echo "Exiting..."
    exit 1
fi
}


###################################
### host checks
###################################

# This helper function checks if the script is run on the building host.
# If it is not, the script terminates.
require_buildinghost ()
{
if [ $HOSTNAME != $config_build_buildinghost ]; then
    echo "This script can only be run on the building host"
    echo "Exiting..."
    exit 1
fi
}


###################################
### array handling functions
###################################

# This helper function takes the array which is passed in $2 and implodes it with the string passed in $1.
array_join_by ()
{
    local IFS="$1"
    shift
    echo "$*"
}

# This helper function takes the array which is passed in $1 and echoes the elements line by line.
array_echo_linebyline ()
{
    array=("$@")
    for item in "${array[@]}"
    do
        echo "$item"
    done
}

# This helper function takes the array which is passed in $1 and echoes the elements line by line.
# The lines are indented by 5 spaces.
array_echo_linebyline_indented ()
{
    array=("$@")
    for item in "${array[@]}"
    do
        echo "     $item"
    done
}

# This helper function takes the array which is passed in $2 and checks if the string passed in $1 is contained in the array.
# If it is, the function returns 1.
# If it is not, the function returns 0.
array_contains_element ()
{
    local e match="$1"
    shift
    for e
    do
        if [[ "$e" == "$match" ]]; then
            return 0
        fi
    done
    return 1
}


###################################
### moodle site-related functions
###################################

# This helper function scans all directories below the configured basedir and collects all Moodle sites.
# As a result, the array moodlesites contains the directory names of these Moodle sites.
site_scanmoodlesites()
{
    # Initialize an empty array for the moodle instances
    moodlesites=()

    # Get all subdirectories below the vhost basedir
    readarray allsites < <(find $config_vhost_basedir -maxdepth 1 -mindepth 1 -type d -printf "%f\n")

    # Iterate over these subdirectories
    for site in ${allsites[@]}
    do
        # If this subdirectory is not a ignored directory
        if ! array_contains_element $site "${config_vhost_basedir_ignore[@]}"; then
            # Add the subdirectory to the list of moodle sites
	    moodlesites+=($site)
        fi
    done
}

# This helper function picks the Moodle site from the given parameters $1 and $2 and $3.
# As a result, the site_* variables are filled with paths and other data for the Moodle site.
site_pickmoodleinstance()
{
    # Fill the site_instancerootrealprod variable
    site_instancerootrealprod=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-${config_vhost_instances_prod}

    # If we are dealing with a singleton instance.
    if array_contains_element "$2" "${config_vhost_instances_singleton[@]}"; then
        # Pretend that the singleton instance is handled like it was the prod instance
        config_vhost_instances_prod=$2

        # Fill the site_instanceissingleton variable
        site_instanceissingleton=1

        # Fill the site_instanceisdev variable
        site_instanceisdev=0

    # If we are dealing with a dev instance.
    elif array_contains_element "$2" "${config_vhost_instances_dev[@]}"; then
        # Pretend that the dev instance is handled like it was the prod instance
        config_vhost_instances_prod=$2

        # Fill the site_instanceissingleton variable
        site_instanceissingleton=0

        # Fill the site_instanceisdev variable
        site_instanceisdev=1

    # Otherwise.
    else
        # Fill the site_instanceissingleton variable
        site_instanceissingleton=0

        # Fill the site_instanceisdev variable
        site_instanceisdev=0
    fi

    # If we are dealing with the prod instance.
    if [[ $2 == ${config_vhost_instances_prod} ]]; then
        # Fill the site_instanceisprod variable
        site_instanceisprod=1
    else
        # Fill the site_instanceisprod variable
        site_instanceisprod=0
    fi

    # Fill the site_site variable
    site_site=$1

    # Fill the site_instance variable
    site_instance=$2

    # Fill the site_subscriptionbasedir variable
    site_subscriptionbasedir=${config_vhost_basedir}/$1

    # Fill the site_subscriptionroot variable
    site_subscriptionroot=${config_vhost_basedir}/$1/${config_vhost_wwwroot}

    # Fill the site_instanceroot variable
    site_instanceroot=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2

    # Fill the site_instancerootprod variable
    site_instancerootprod=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-${config_vhost_instances_prod}

    # Fill the site_wwwroot variable
    site_wwwroot=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3

    # Fill the site_wwwrootprod variable
    site_wwwrootprod=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-${config_vhost_instances_prod}/$3

    # Fill the site_wwwrootupdate variable
    site_wwwrootupdate=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3_update

    # Fill the site_moodledata variable
    site_moodledata=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3data

    # Fill the site_moodledataprod variable
    site_moodledataprod=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-${config_vhost_instances_prod}/$3data

    # Fill the site_configphp variable
    site_configphp=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3/config.php

    # Fill the site_configphpprod variable
    site_configphpprod=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-${config_vhost_instances_prod}/$3/config.php

    # Fill the site_configphpupdate variable
    site_configphpupdate=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3_update/config.php

    # Fill the site_mucconfig variable
    site_mucconfig=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3data/muc/config.php

    # Fill the site_womenslib variable
    site_womenslib=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3/lib/womenslib.php

    # Fill the site_url variable
    site_url=https://$2.$1

    # Fill the site_envbarprodroot variable
    site_envbarprodroot=https://${config_vhost_instances_prod}.$1

    # Fill the site_envbartestroot variable
    site_envbartestroot=https://test.$1

    # Fill the site_divertgallmailsaddress variable
    site_divertallmailsaddress=$2.$1@${config_moodle_outgoingmailtestmailer}

    # Fill the site_datacleanerprodroot variable
    site_datacleanerprodroot=https://${config_vhost_instances_prod}.$1

    # Fill the site_moodledistro variable
    site_moodledistro=$3

    # Fill the site_moodlebranchprefix variable
    site_moodlebranchprefix=${3^^}_

    # If we are dealing with a dev instance.
    if [[ $site_instanceisdev -eq 1 ]]; then
        # Fill the site_githuburl variable
        site_githuburl=${config_git_gitupstream}
    # Otherwise
    else
        # Fill the site_githuburl variable
        site_githuburl=${config_git_githuburlprefix}${config_build_siteprefix}$3-$1.git
    fi

    # Fill the site_climaintenance variable
    site_climaintenance=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3data/climaintenance.html
}

# This helper function picks the Moodle site branch und release from the given parameters $1 and $2 and $3 and $4.
# As a result, the site_moodlebranchsite and site_moodlerelease variables are filled for the Moodle site.
site_pickmoodlebranch()
{
    # If we are dealing with a dev instance.
    if [[ $site_instanceisdev -eq 1 ]]; then
        # Fill the site_moodlebranchsite variable
        site_moodlebranchsite=${3^^}_${4}_STABLE
    # Otherwise
    else
        # Fill the site_moodlebranchsite variable
        if [[ $site_instanceisprod -eq 1 ]]; then
            site_moodlebranchsite=${3^^}_${4}_STABLE_${config_build_sitebranch}
        else
            site_moodlebranchsite=${3^^}_${4}_STABLE_${config_build_sitebranch}_${2}
        fi
    fi

    # Fill the site_moodlerelease variable
    site_moodlerelease=$4

    # If we are dealing with an instance up to 4.0.
    if [[ $site_moodlerelease -le 400 ]]; then
        # Fill the site_moodlephpbin variable
        site_moodlephpbin=${config_webserver_phpbin_upto400}
    # Otherwise
    else
        # Fill the site_moodlephpbin variable
        site_moodlephpbin=${config_webserver_phpbin_from401}
    fi
}

# This helper function checks if the Moodle site from the given parameters $1 and $2 and $3 exists.
# If it does not, the script terminates.
site_verifymoodleinstance()
{
    # Check if the instance's moodle directory exists. 
    if ! [ -d ${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3 ]; then
        echo "The directory ${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3 does not exist"
	echo "I have to assume that this is an incomplete Moodle instance."
	echo "Exiting..."
	exit 1
    fi

    # Check if the instance's moodledata directory exists. 
    if ! [ -d ${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3data ]; then
        echo "The directory ${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3data does not exist"
	echo "I have to assume that this is an incomplete Moodle instance."
	echo "Exiting..."
	exit 1
    fi

    # Check if the instance's config.php exists. 
    if ! [ -e ${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3/config.php ]; then
        echo "The file ${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3/config.php does not exist"
	echo "I have to assume that this is an incomplete Moodle instance."
	echo "Exiting..."
	exit 1
    fi

    # Check if the instance's womenslib exists. 
    if ! [ -e ${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3/lib/womenslib.php ]; then
        echo "The file ${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3/lib/womenslib.php does not exist"
	echo "I have to assume that this is an incomplete Moodle instance."
	echo "Exiting..."
	exit 1
    fi
}


###################################
### moodle action functions
###################################

# This helper function sets the file system permissions of the Moodle instance.
# It uses variable values which must have been set by site_pickmoodleinstance() before.
# If parameter $1 equals 'update' then the update paths are used instead.
site_fixpermissions()
{
    if [[ "$1" == 'update' ]]; then
        setperms_moodledata=$site_moodledata
        setperms_wwwroot=$site_wwwrootupdate
        setperms_configphp=$site_configphpupdate
    else
        setperms_moodledata=$site_moodledata
        setperms_wwwroot=$site_wwwroot
        setperms_configphp=$site_configphp
    fi

    if [[ $site_instanceisdev -eq 1 ]]; then
        setperms_perms_wwwroot=$config_vhost_perms_wwwroot_dev
        setperms_perms_moodledata=$config_vhost_perms_moodledata_dev
        setperms_perms_configphp=$config_vhost_perms_configphp_dev
    else
        setperms_perms_wwwroot=$config_vhost_perms_wwwroot
        setperms_perms_moodledata=$config_vhost_perms_moodledata
        setperms_perms_configphp=$config_vhost_perms_configphp
    fi

    chown -R $site_site:$config_vhost_group_moodledata $setperms_moodledata \
        && success || failure
    chmod -R $setperms_perms_moodledata $setperms_moodledata \
        && success || failure
    chown -R $site_site:$config_vhost_group_wwwroot $setperms_wwwroot \
        && success || failure
    chmod -R $setperms_perms_wwwroot $setperms_wwwroot \
        && success || failure
    if [ -e $setperms_configphp ]; then
        chmod $setperms_perms_configphp $setperms_configphp \
            && success || failure
    fi

    unset setperms_moodledata setperms_wwwroot setperms_configphp
}


###################################
### moodle cross-site-related functions
###################################

# This helper function picks the Moodle upgrade key - either from the configuration or from the existing prod instance.
# As a result, the site_upgradekey variable is filled for the Moodle site.
site_pickupgradekey()
{
    # Fill the site_upgradekey variable
    if [[ $site_instanceisprod -eq 1 ]]; then
        site_upgradekey=$config_moodle_randomupgradekey
    else
        site_upgradekey=`grep upgradekey $site_configphpprod | cut -d"'" -f2`
    fi
}

# This helper function picks the Envbar secret key - either from the configuration or from the existing prod instance.
# As a result, the site_envbarsecretkey variable is filled for the Moodle site.
site_pickenvbarsecretkey()
{
    # Fill the site_envbarsecretkey variable
    if [[ $site_instanceisprod -eq 1 ]]; then
        site_envbarsecretkey=$config_moodle_randomenvbarsecretkey
    else
        site_envbarsecretkey=`grep local_envbar_secretkey $site_configphpprod | cut -d"'" -f2`
    fi
}

# This helper function picks the Moodle database credentials from the Moodle config - for the given instance as well as for the prod instance.
# As a result, the site_db* variables are filled for the Moodle site.
site_pickdbcredentials()
{
    # Fill the site_dbname variable
    site_dbname=`grep dbname $site_configphp | cut -d"'" -f2`

    # Fill the site_dbuser variable
    site_dbuser=`grep dbuser $site_configphp | cut -d"'" -f2`

    # Fill the site_dbpass variable
    site_dbpass=`grep dbpass $site_configphp | cut -d"'" -f2`

    # Fill the site_dbnameprod variable
    site_dbnameprod=`grep dbname $site_configphpprod | cut -d"'" -f2`

    # Fill the site_dbuserprod variable
    site_dbuserprod=`grep dbuser $site_configphpprod | cut -d"'" -f2`

    # Fill the site_dbpassprod variable
    site_dbpassprod=`grep dbpass $site_configphpprod | cut -d"'" -f2`
}


###################################
### moodle repo-related functions
###################################

# This helper function scans all directories below the configured repo dir and collects all Moodle site repos.
# As a result, the array moodlesiterepos contains the directory names of these Moodle site repos.
siterepo_scanmoodlesiterepos()
{
    # Initialize an empty array for the moodle repos
    moodlesiterepos=()

    # Get all subdirectories below the repo dir
    readarray allrepos < <(find $config_build_repodir -maxdepth 1 -mindepth 1 -type d -printf "%f\n")

    # Iterate over these subdirectories
    for repo in ${allrepos[@]}
    do
        # If this subdirectory is a site repo
        if [[ $repo == ${config_build_siteprefix}* ]]; then
            # Add the subdirectory to the list of moodle site repos (and remove the prefixes)
            reponame=$(echo $repo | cut -d'-' -f 4- -s)
            moodlesiterepos+=($reponame)
        fi
    done
}

# This helper function picks the Moodle site repo from the given parameter $1.
# As a result, the siterepo_* variables are filled with paths and other data for the Moodle site repo.
siterepo_pickmoodlesiterepo()
{
    # Fill the siterepo_repopath variable
    siterepo_repopath=${config_build_repodir}${config_build_siteprefix}$2-$1

    # Fill the siterepo_branchsite and siterepo_branchsitetest variables
    siterepo_branchcore=${2^^}_${3}_STABLE_${config_build_corebranch}
 
    # Fill the siterepo_branchsite and siterepo_branchsitetest variables
    siterepo_branchsite=${2^^}_${3}_STABLE_${config_build_sitebranch}
    siterepo_branchsitetest=${2^^}_${3}_STABLE_${config_build_sitebranch}_test

    # Fill the siterepo_githuburl variable
    siterepo_githuburl=${config_git_githuburlprefix}${config_build_siteprefix}$2-$1.git
}


###################################
### git-related functions
###################################

# This helper function checks if there is a valid Github repository based on parameter $1.
site_verifygithubrepo()
{
    # Check if the given Github repo exists.
    git ls-remote $1 2>/dev/null 1>/dev/null
    if [ $? -gt 0 ]; then
        echo "I haven't found a Github repository on $1."
        echo "I can't continue."
        echo "Exiting..."
        exit 1
    fi
}

# This helper function sets some environment variables for git comits.
git_init_commits()
{
    export GIT_AUTHOR_NAME=$config_git_author_name
    export GIT_AUTHOR_EMAIL=$config_git_author_mail
    export GIT_COMMITTER_NAME=$config_git_committer_name
    export GIT_COMMITTER_EMAIL=$config_git_committer_mail
    success
}
