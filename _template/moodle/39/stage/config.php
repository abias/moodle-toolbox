<?php

//=========================================================================
// BASICS
//=========================================================================

unset($CFG);
global $CFG;
$CFG = new stdClass();



//=========================================================================
// PATH SETTINGS
//=========================================================================

$CFG->wwwroot = '$configtemplate_wwwroot';
$CFG->dataroot = '$configtemplate_dataroot';
$CFG->sslproxy = true;
$CFG->admin = 'admin';



//=========================================================================
// DATABASE
//=========================================================================

$CFG->dbtype    = 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost    = '127.0.0.1';
$CFG->dbname    = '$configtemplate_dbname';
$CFG->dbuser    = '$configtemplate_dbuser';
$CFG->dbpass    = '$configtemplate_dbpass';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array (
  'dbpersist' => 1,
  'dbport' => '',
  'dbsocket' => '',
  'dbcollation' => 'utf8mb4_unicode_ci',
);



//=========================================================================
// SECURITY SETTINGS
//=========================================================================

$CFG->directorypermissions = 02755;
$CFG->preventexecpath = true;



//=========================================================================
// DEPLOYMENT SETTINGS
//=========================================================================

$CFG->upgradekey = '$configtemplate_upgradekey';
$CFG->uninstallclionly = true;
$CFG->disableupdateautodeploy = true;
$CFG->pathtophp = '$configtemplate_pathtophp';
$CFG->pathtodu = '$configtemplate_pathtodu';
$CFG->pathtodot = '$configtemplate_pathtodot';
$CFG->pathtogs = '$configtemplate_pathtogs';



//=========================================================================
// SIZING SETTINGS
//=========================================================================

$CFG->maxbytes = $configtemplate_maxbytes;



//=========================================================================
// PERFORMANCE SETTINGS
//=========================================================================

// Enable YUI Slash Arguments for performance improvements.
$CFG->yuislasharguments = 1;



//=========================================================================
// CACHE SETTINGS
//=========================================================================

$CFG->cachedir = '$configtemplate_cachedir';
$CFG->localcachedir = '$configtemplate_localcachedir';



//=========================================================================
// TEMP SETTINGS
//=========================================================================

$CFG->tempdir = '$configtemplate_tempdir';
$CFG->backuptempdir = '$configtemplate_backuptempdir';



//=========================================================================
// PERFORMANCE SETTINGS
//=========================================================================

$CFG->langcache = true;
$CFG->langstringcache = true;
$CFG->useexternalyui = false;
$CFG->yuicomboloading = true;
$CFG->cachejs = true;
$CFG->cachetemplates = true;
$CFG->themedesignermode = false;



//=========================================================================
// MOODLE UI SETTINGS
//=========================================================================

// Set the language here to show database problems in german as well.
$CFG->lang = '$configtemplate_lang';



//=========================================================================
// MOODLE HQ PHONE HOME
//=========================================================================

// Remove Moodle HQ campaign.
$CFG->showcampaigncontent = false;

// Remove Moodle partners campaign.
$CFG->showservicesandsupportcontent = false;

// Disable Moodle HQ feedback.
$CFG->enableuserfeedback = false;



//=========================================================================
// MOODLE BBB PLUGIN
//=========================================================================

// BBB Connection instance configuration.
$CFG->bigbluebuttonbn_server_url = '$configtemplate_bbburl';
$CFG->bigbluebuttonbn_shared_secret = '$configtemplate_bbbtoken';



//=========================================================================
// OUTGOING MAIL
//=========================================================================

// Outgoing mail server configuration.
$CFG->smtphosts = '$configtemplate_smtphosts';
$CFG->smtpsecure = 'ssl';
$CFG->smtpauthtype = 'LOGIN';

// Outgoing mail instance configuration.
$CFG->smtpuser = '$configtemplate_smtpuser';
$CFG->smtppass = '$configtemplate_smtppass';
$CFG->noreplyaddress = '$configtemplate_noreplyaddress';

// Divert all outgoing mail.
$CFG->divertallemailsto = '$configtemplate_divertallmailsaddress';



//=========================================================================
// ENVBAR
//=========================================================================

// URL of the prod instance (set it here instead of relying on the magic of the plugin).
$CFG->local_envbar_prodwwwroot = '$configtemplate_envbarprodroot';

// Secret key to allow communication between non-prod environments and the prod environment.
$CFG->local_envbar_secretkey = '$configtemplate_envbarsecretkey';

// Array of existing non-prod environments.
$CFG->local_envbar_items = array(
    array(
        'showtext' => 'TEST', 'matchpattern' => '$configtemplate_envbartestroot',
        'colourbg' => 'crimson', 'colourtext' => 'white'
    ),
    array(
        'showtext' => 'STAGE', 'matchpattern' => '$configtemplate_envbarstageroot',
        'colourbg' => 'fuchsia', 'colourtext' => 'white'
    )
);



//=========================================================================
// DATACLEANER
//=========================================================================

// URL of the prod instance (set it here instead of relying on the magic of the plugin).
$CFG->original_wwwroot = '$configtemplate_datacleanerprodroot';

// Allow local_datacleaner to run.
$CFG->local_datacleaner_allowexecution = true;



//=========================================================================
// CLAMAV
//=========================================================================

// Forced ClamAV settings.
$CFG->forced_plugin_settings['antivirus_clamav']['runningmethod'] = 'commandline';
$CFG->forced_plugin_settings['antivirus_clamav']['pathtoclam'] = '/usr/bin/clamdscan';
$CFG->forced_plugin_settings['antivirus_clamav']['clamfailureonupload'] = 'tryagain';
$CFG->forced_plugin_settings['antivirus_clamav']['tries'] = 2;



//=========================================================================
// LERN.LINK PRODUCTS WITH FEES
//=========================================================================

// Product: LMS | AddOn | KursBackups.
// Default value: 0 (Disabled).
// Change value as soon as the product is sold to: 1 (Enabled).
$CFG->forced_plugin_settings['backup']['backup_auto_active'] = 0;

// Product: LMS | Skalierung | Logfiles*
// Default value: 365 (365 days).
// Change value as soon as the product is sold to: 1000 (1000 days) or 0 (Unlimited storage).
$CFG->forced_plugin_settings['logstore_standard']['loglifetime'] = 365;

// Product: LMS | AddOn | GlobaleSuche*
// Default value: 0 (Disabled).
// Change value as soon as the product is sold to: 1 (Enabled) and leave the searchengine as 'simpledb'.
$CFG->enableglobalsearch = 0;
$CFG->searchengine = 'simpledb';



//=========================================================================
// ADDITIONAL SPECIFIC SETTINGS (LIKE CREDENTIALS TO 3RD PARTY TOOLS)
//=========================================================================



//=========================================================================
// SETTINGS FOR DEBUGGING AND TESTING
//=========================================================================

// Set debug level
$CFG->debug = E_ERROR | E_PARSE | E_WARNING | E_NOTICE; // Normal level

// Show debug messages in the web frontend
$CFG->debugdisplay = 0; // No

// Enable performance information
$CFG->perfdebug = 7; // No

// Enable string debugging
$CFG->debugstringids = 1; // Yes



//=========================================================================
// ADDITIONAL SETTINGS WHICH DIFFER BETWEEN INSTANCES
//=========================================================================



//=========================================================================
// FINAL ACTIONS
//=========================================================================

require_once(__DIR__ . '/lib/setup.php'); // Do not edit



// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!

