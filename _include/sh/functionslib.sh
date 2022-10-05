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
    # Fill the site_subscriptionroot variable
    site_subscriptionroot=${config_vhost_basedir}/$1/${config_vhost_wwwroot}

    # Fill the site_instanceroot variable
    site_instanceroot=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2

    # Fill the site_wwwroot variable
    site_wwwroot=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3

    # Fill the site_moodledata variable
    site_moodledata=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3data

    # Fill the site_configphp variable
    site_configphp=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3/config.php

    # Fill the site_mucconfig variable
    site_mucconfig=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3data/muc/config.php

    # Fill the site_womenslib variable
    site_womenslib=${config_vhost_basedir}/$1/${config_vhost_wwwroot}/$3-$2/$3/lib/womenslib.php

    # Fill the site_url variable
    site_url=https://$2.$1

    # Fill the site_envbarprodroot variable
    site_envbarprodroot=https://${config_vhost_instances_prod}.$1

    # Fill the site_moodledistro variable
    site_moodledistro=$3

    # Fill the site_moodlebranchprefix variable
    site_moodlebranchprefix=${3^^}_

    # Fill the site_githuburl variable
    site_githuburl=${config_git_githuburlprefix}-$3-$1.git

    # Fill the site_instanceisprod variable
    if [[ $2 == ${config_vhost_instances_prod} ]]; then
        site_instanceisprod=1
    else
        site_instanceisprod=0
    fi
}

# This helper function picks the Moodle site branch from the given parameters $1 and $2 and $3 and $4.
# As a result, the site_moodlebranchsite variable is filled for the Moodle site.
site_pickmoodlebranch()
{
    # Fill the site_moodlebranchsite variable
    if [[ $2 == ${config_vhost_instances_prod} ]]; then
        site_moodlebranchsite=${3^^}_${4}_STABLE_site
    else
        site_moodlebranchsite=${3^^}_${4}_STABLE_site_${2}
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
### git-related functions
###################################

# This helper function sets some environment variables for git comits.
git_init_commits()
{
    export GIT_AUTHOR_NAME=$config_git_author_name
    export GIT_AUTHOR_EMAIL=$config_git_author_mail
    export GIT_COMMITTER_NAME=$config_git_committer_name
    export GIT_COMMITTER_EMAIL=$config_git_committer_mail
    success
}
