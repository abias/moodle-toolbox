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
# If it is, the function returns 0 (i.e. success).
# If it is not, the function returns 1 (i.e. failure).
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
