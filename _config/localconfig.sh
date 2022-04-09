#!/bin/bash

###################################
### local config: webserver stack
###################################

# The user who runs the webserver
config_webserver_user='www-data'

# The php binary
config_php_binary='/opt/plesk/php/7.4/bin/php'


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


###################################
### local config: nice
###################################

# The command which will be prepended to ressource-intensive commands
config_nice='ionice -c3 nice -n19'
