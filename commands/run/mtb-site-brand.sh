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
mtb-site-brand.sh -s <site> -i <instance> [-a] [-d <distro>] [-k <customerdomain>] [-b <bbbuser> -c <bbbtoken>] [[-x <smtpserver>] -y <smtpuser> -z <smtppass>]

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

  Customer domain:

    -k <customerdomain>
       The customer domain to be set for the Moodle site

  BBB token (all or none of these optional parameters have to be given):

    -b <bbbuser>
       The BBB user to be set for the Moodle site

    -c <bbbtoken>
       The BBB token to be set for the Moodle site

  SMTP server (at least the user and pass parameters or none of these optional parameters have to be given):

    -x <smtpserver>
       The SMTP mail server which is used for outgoing mail

    -y <smtpuser>
       The SMTP mail user which is used for outgoing mail

    -z <smtppass>
       The SMTP mail password which is used for outgoing mail
EOU
}

# Process parameters
while getopts 'hs:i:d:k:b:c:x:y:z:a' OPTION; do
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
        k)
            moodlecustomerdomain=$OPTARG
            ;;
        b)
            moodlebbbuser=$OPTARG
            ;;
        c)
            moodlebbbtoken=$OPTARG
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

# If no distro was given, use the default
if [[ -z "$moodledistro" ]]; then
    moodledistro=$config_vhost_distros_default
fi

# If a customer domain were given, remember this fact.
if [[ -n "$moodlecustomerdomain" ]]; then
    branddomain=1
fi

# If one of the BBB parameters was given, verify that all of them were given
if [[ -n "$moodlebbbuser" && -z "$moodlebbbtoken" ]]; then
    usage
    exit 1
fi
if [[ -n "$moodlebbbtoken" && -z "$moodlebbbuser" ]]; then
    usage
    exit 1
fi

# Otherwise, if all BBB parameters were given, remember this fact.
if [[ -n "$moodlebbbuser" && -n "$moodlebbbtoken" ]]; then
    brandbbb=1
fi

# If one of the SMTP parameters was given, verify that at least user + pass is given
if [[ -n "$moodlesmtphosts" && -z "$moodlesmtpuser" ||  -n "$moodlesmtphosts" && -z "$moodlesmtppass" ]]; then
    usage
    exit 1
fi
if [[ -n "$moodlesmtpuser" && -z "$moodlesmtppass" ]]; then
    usage
    exit 1
fi
if [[ -n "$moodlesmtppass" && -z "$moodlesmtpuser" ]]; then
    usage
    exit 1
fi

# Otherwise, if SMTP parameters were given, remember this fact.
if [[ -n "$moodlesmtpuser" && -n "$moodlesmtppass"  ]]; then
    brandsmtp=1
fi

# If SMTP credentials without SMTP host were given, use the default host
if [[ "$brandsmtp" -eq 1 && -z "$moodlesmtphosts" ]]; then
    moodlesmtphosts=$config_moodle_outgoingmailsmtphosts
fi

# If no branding parameters were given at all.
if [[ "$branddomain" -ne 1 && "$brandbbb" -ne 1 && "$brandsmtp" -ne 1 ]]; then
    usage
    exit 1
fi

# Confirmation
echo -e "You requested to brand the \033[31m$moodleinstance\033[0m instance within the \033[31m$moodlesite\033[0m site!"
confirm


###################################
### prepare working with the Moodle instance
###################################

site_verifymoodleinstance $moodlesite $moodleinstance $moodledistro
site_pickmoodleinstance $moodlesite $moodleinstance $moodledistro


###################################
### action
###################################

if [[ $branddomain -eq 1 ]]; then
    now "Branding domain"

    cd $site_wwwroot \
        && success || failure

    if [[ $site_instanceisprod -eq 1 ]]; then
        configsed_wwwroot=https://$moodlecustomerdomain
    else
        configsed_wwwroot=https://$moodleinstance.$moodlecustomerdomain
    fi
    # In the following sed call, the slashes in the configsed_wwwroot variable have to be escaped.
    sed -i "s/^\$CFG->wwwroot =.*/\$CFG->wwwroot = '${configsed_wwwroot//\//\\/}';/" $site_configphp \
        && success || failure

    configsed_envbarprodroot=https://$moodlecustomerdomain
    # In the following sed call, the slashes in the configsed_envbarprodroot variable have to be escaped.
    sed -i "s/^\$CFG->local_envbar_prodwwwroot =.*/\$CFG->local_envbar_prodwwwroot = '${configsed_envbarprodroot//\//\\/}';/" $site_configphp \
        && success || failure

    configsed_noreplyaddress=${config_moodle_outgoingmailnoreplyaddressprefix}@$moodlecustomerdomain
    sed -i "s/^\$CFG->noreplyaddress =.*/\$CFG->noreplyaddress = '$configsed_noreplyaddress';/" $site_configphp \
        && success || failure

    configsed_supportemail=${config_moodle_outgoingmailsupportemailprefix}@$moodlecustomerdomain
    sed -i "s/^\$CFG->supportemail =.*/\$CFG->supportemail = '$configsed_supportemail';/" $site_configphp \
        && success || failure

    unset ${!configsed_*}
fi

if [[ $brandbbb -eq 1 ]]; then
    now "Branding BBB"

    cd $site_wwwroot \
        && success || failure
    configsed_bbburl="${config_moodle_bbburlprefix}/$moodlebbbuser/${config_moodle_bbburlsuffix}"
    # In the following sed call, the slashes in the configsed_bbburl variable have to be escaped.
    sed -i "s/^\$CFG->bigbluebuttonbn_server_url =.*/\$CFG->bigbluebuttonbn_server_url = '${configsed_bbburl//\//\\/}';/" $site_configphp \
        && success || failure

    configsed_bbbtoken=$moodlebbbtoken
    sed -i "s/^\$CFG->bigbluebuttonbn_shared_secret =.*/\$CFG->bigbluebuttonbn_shared_secret = '$configsed_bbbtoken';/" $site_configphp \
        && success || failure

    unset ${!configsed_*}
fi

if [[ $brandsmtp -eq 1 ]]; then
    now "Branding SMTP"

    cd $site_wwwroot \
        && success || failure
      
    configsed_smtphosts=$moodlesmtphosts
    sed -i "s/^\$CFG->smtphosts =.*/\$CFG->smtphosts = '$configsed_smtphosts';/" $site_configphp \
        && success || failure

    configsed_smtpuser=$moodlesmtpuser
    sed -i "s/^\$CFG->smtpuser =.*/\$CFG->smtpuser = '$configsed_smtpuser';/" $site_configphp \
        && success || failure

    configsed_smtppass=$moodlesmtppass
    sed -i "s/^\$CFG->smtppass =.*/\$CFG->smtppass = '$configsed_smtppass';/" $site_configphp \
        && success || failure

    unset ${!configsed_*}
fi


###################################
### inform admin
###################################

now "Finish"

echo -e "The \033[31m$moodleinstance\033[0m instance within the \033[31m$moodlesite\033[0m site was branded."
