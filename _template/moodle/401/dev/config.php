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

$CFG->directorypermissions = 02777;
$CFG->preventexecpath = true;



//=========================================================================
// DEPLOYMENT SETTINGS
//=========================================================================

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
$CFG->supportname = '$configtemplate_supportname';
$CFG->supportemail = '$configtemplate_supportemail';



//=========================================================================
// FINAL ACTIONS
//=========================================================================

require_once(__DIR__ . '/lib/setup.php'); // Do not edit



// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!

