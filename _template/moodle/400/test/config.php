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
$CFG->localrequestdir = '$configtemplate_localrequestdir';



//=========================================================================
// MOODLE UI SETTINGS
//=========================================================================

// Set the language here to show database problems in german as well.
$CFG->lang = '$configtemplate_lang';

// Remote Moodle HQ campaign.
$CFG->showcampaigncontent = false;



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
$CFG->supportname = '$configtemplate_supportname';
$CFG->supportemail = '$configtemplate_supportemail';

// E-Mail digest send time (especially relevant for lern.link support forum)
$CFG->digestmailtime = 12;

// Do not send any outgoing mail.
$CFG->noemailever = true;



//=========================================================================
// ENVBAR
//=========================================================================

$CFG->local_envbar_prodwwwroot = '$configtemplate_envbarprodroot';



//=========================================================================
// SETTINGS FOR DEBUGGING AND TESTING
//=========================================================================

// Set debug level
$CFG->debug = (E_ALL | E_STRICT); // Developer level

// Show debug messages in the web frontend
$CFG->debugdisplay = 1; // Yes

// Enable performance information
$CFG->perfdebug = 7; // No



//=========================================================================
// FINAL ACTIONS
//=========================================================================

require_once(__DIR__ . '/lib/setup.php'); // Do not edit



// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!

