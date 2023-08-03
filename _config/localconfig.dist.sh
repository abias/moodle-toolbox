#!/bin/bash

###################################
### local config: webserver stack
###################################

# The php binary, depending on the Moodle version
config_webserver_phpbin_upto400='/opt/plesk/php/7.4/bin/php'
config_webserver_phpbin_from401='/opt/plesk/php/8.1/bin/php'


###################################
### local config: backend tools
###################################

# The du binary
config_webserver_dubin='/usr/bin/du'

# The dot binary
config_webserver_dotbin='/usr/bin/dot'

# The gs binary
config_webserver_gsbin='/usr/bin/gs'


###################################
### local config: helper tools
###################################

# The command which will be prepended to ressource-intensive commands
config_webserver_nice='ionice -c3 nice -n19'

# The rsync binary
config_webserver_rsyncbin='/usr/bin/rsync'


###################################
### local config: database stack
###################################

# The mariadb binary
config_webserver_mariadbbin='/usr/bin/mariadb'

# The mysqldump binary
config_webserver_mysqldumpbin='/usr/bin/mysqldump'


###################################
### local config: webserver environment
###################################

# The directory where all Moodle sites are located (without trailing slash)
config_vhost_basedir='/var/www/vhosts'

# The directories within the basedir which should not be handled as Moodle sites
config_vhost_basedir_ignore=('chroot' 'default' '.skel' 'system')

# The directory below the basedir which holds the Moodle site
config_vhost_wwwroot='www'

# The group which is used for subscription root and instance root during the instance initialization
config_vhost_group_subscription='psaserv'

# The permissions which are used for subscription root and instance root during the instance initialization
config_vhost_perms_subscription='u=rX,g=X,o='

# The group which is used for wwwroot when fixing permissions
config_vhost_group_wwwroot='psacln'

# The group which is used for moodledata when fixing permissions
config_vhost_group_moodledata='psacln'

# The permissions which are used for wwwroot when fixing permissions
config_vhost_perms_wwwroot='u=rX,g=rX,o=rX'
# The permissions which are used for wwwroot when fixing permissions (for dev instances)
config_vhost_perms_wwwroot_dev='u=rwX,g=rX,o=rX'

# The permissions which are used for moodledata when fixing permissions
config_vhost_perms_moodledata='u=rwX,g=rX,o=rX'
# The permissions which are used for moodledata when fixing permissions (for dev instances)
config_vhost_perms_moodledata_dev='u=rwX,g=rwX,o=rwX'

# The permissions which are used for config.php when fixing permissions
config_vhost_perms_configphp='u=r,g=,o='
# The permissions which are used for config.php when fixing permissions (for dev instances)
config_vhost_perms_configphp_dev='u=rw,g=,o='

# The directory prefixes below the wwwroot which hold the particular Moodle instance
# If you want to deploy any other instance, please check all scripts for correct behaviour (Especially the envbar stuff which is currently hardcoded to just handle prod, test and pg)
config_vhost_instances=('prod' 'test' 'pg' 'dev')
# The prod instance might have to be handled specially in the scripts
# Make sure that the prod value is an allowed value as well
config_vhost_instances_prod='prod'
# The singleton instances are installed and handled as if they are a prod instance, but they a) will get different configuration templates and b) will not be able to get any test instance besides them
# Make sure that the values are allowed values as well
config_vhost_instances_singleton=('pg')
# The dev instances are installed and handled as if they are another singleton instance, but a) MTB will use the upstream Git repo and b) MTB will just install and never update them
# Make sure that the values are allowed values as well
config_vhost_instances_dev=('dev')

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
config_vhost_releases=('39' '311' '400' '401')
# As this is an optional parameter in the scripts, you can also set a default value
# Make sure that the default value is an allowed value as well
config_vhost_releases_default='401'


###################################
### local config: git environment
###################################

# The Github URL prefix for Git repositories. This URL is amended by the site's distro type and the site name and the '.git' suffix.
config_git_githuburlprefix='git@github.com:lernlink-intern/lms-site'

# The Github URL for the upstream repo.
config_git_gitupstream='git@github.com:moodle/moodle.git'


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

# A random envbar secret key which can be set during the installation.
config_moodle_randomenvbarsecretkey=`openssl rand -base64 48`

# The Moodle language which will be set during the installation.
config_moodle_langs=('en' 'de')
# As this is an optional parameter in the scripts, you can also set a default value
# Make sure that the default value is an allowed value as well
config_moodle_langs_default='de'

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

# The noreply prefix which will be added to the domain and which will be set during the installation.
config_moodle_outgoingmailnoreplyaddressprefix='noreply'

# The support prefix which will be added to the domain and which will be set during the installation.
config_moodle_outgoingmailsupportemailprefix='support'

# The supportname suffix which will be added to the site fullname and which will be set during the installation.
config_moodle_outgoingmailsupportnamesuffix='Support'

# The domain which has a catchall postbox where all mails from non-prod instances can be diverted to.
config_moodle_outgoingmailtestmailer='lern.li'


###################################
### toolbox config
###################################

# The amount of minutes which should be waited until the maintenance mode is enabled for a Moodle update.
config_toolbox_maintenancesleep=10


###################################
### dev tools: git
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
