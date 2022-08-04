#!/bin/bash

###################################
### local config: webserver stack
###################################

# The php binary
config_webserver_phpbin='/opt/plesk/php/7.4/bin/php'

# The command which will be prepended to ressource-intensive commands
config_webserver_nice='ionice -c3 nice -n19'

# The mariadb binary
config_webserver_mariadbbin='/usr/bin/mariadb'


###################################
### local config: webserver environment
###################################

# The directory where all Moodle sites are located (without trailing slash)
config_vhost_basedir='/var/www/vhosts'

# The directories within the basedir which should not be handled as Moodle sites
config_vhost_basedir_ignore=('chroot' 'default' '.skel' 'system')

# The directory below the basedir which holds the Moodle site
config_vhost_wwwroot='www'

# The directory prefixes below the wwwroot which hold the particular Moodle instance
config_vhost_instances=('prod' 'test')

# The Moodle distributions which should be allowed
# Currently, moodle and iomad are supported and are used in Git branch names and directory names
# If you want to use any other distribution, please check all scripts for correct behaviour
config_vhost_distros=('moodle' 'iomad')
# As this is an optional parameter in the scripts, you can also set a default value
# Make sure that the default value is an allowed value as well
config_vhost_distros_default='moodle'

# The Moodle releases which should be allowed
# Currently, 39 and 311 are supported and are used in Git branch names
# If you want to use any other release, please check all scripts for correct behaviour
config_vhost_releases=('39' '311' '400')
# As this is an optional parameter in the scripts, you can also set a default value
# Make sure that the default value is an allowed value as well
config_vhost_releases_default='39'


###################################
### local config: git environment
###################################

# The Github URL prefix for Git repositories. This URL is amended by the site's distro type and the site name.
config_git_githuburlprefix='git@github.com:lernlink-intern/lms-site'


###################################
### local config: moodle environment
###################################

# The Moodle admin username which will be created with the installation.
config_moodle_adminusername='support@lernlink.de'

# The Moodle admin user email which will be set during the installation.
config_moodle_adminusermail='support@lernlink.de'

# A random Moodle admin password which will be set during the installation.
config_moodle_adminuserpass=`openssl rand -base64 48`

# A random upgrade key which can be set during the installation.
config_moodle_randomupgradekey=`openssl rand -base64 24`

# The Moodle default language which will be set duting the installation.
config_moodle_defaultlang='DE'

# The Moodle upload sizes which should be allowed
config_moodle_upload=('24' '64' '128' '256' '512' '1024' '2048')
# As this is an optional parameter in the scripts, you can also set a default value
# Make sure that the default value is an allowed value as well
config_moodle_upload_default='64'


###################################
### local config: moodle bigbluebutton plugin
###################################

# The BBB URL prefix and suffix which will be used to compose the BBB URL.
# The BBB URL will be composed from the prefix, the BBB user name (which is provided as command line parameter) and the suffix.
# All three components will be imploded by forward slashes.
config_moodle_bbburlprefix='https://bbb.pool.lern.link'
config_moodle_bbburlsuffix='bigbluebutton'


###################################
### local config: moodle outgoing mail
###################################

# The default SMTP mail server which is used for outgoing mail and which will be set during the installation.
config_moodle_outgoingmailsmtphosts='smtp.eu.mailgun.org:465'

# The default SMTP mail user which is used for outgoing mail and which will be set during the installation.
config_moodle_outgoingmailsmtpuser=''

# The default SMTP mail password which is used for outgoing mail and which will be set during the installation.
config_moodle_outgoingmailsmtppass=''

# The noreply prefix which will be added to the domain and which will be set during the installation.
config_moodle_outgoingmailnoreplyaddressprefix='noreply'

# The support prefix which will be added to the domain and which will be set during the installation.
config_moodle_outgoingmailsupportemailprefix='noreply'


###################################
### dev tools:git
###################################

# The git author name which will be used for git commits.
config_git_author_name='Alexander Bias'

# The git author mail which will be used for git commits.
config_git_author_mail='alexander.bias@lernlink.de'

# The git committer name which will be used for git commits.
config_git_committer_name='Alexander Bias'

# The git committer mail which will be used for git commits.
config_git_committer_mail='alexander.bias@lernlink.de'


###################################
### dev tools: github
###################################

# The remote repo name for Github used in Moodle plugins.
config_github_remoterepo='origin'

# The main branch used in Moodle plugins.
# From this branch, the release branches will be branched.
config_github_mainbranch='master'

# The Github actions workflow file used in Moodle plugins.
config_github_ghaworkflow='.github/workflows/moodle-plugin-ci.yml'
