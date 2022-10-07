<?php
// This file is part of Moodle - http://moodle.org/
//
// Moodle is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Moodle is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Moodle.  If not, see <http://www.gnu.org/licenses/>.

/**
 * CLI script to set a set of Moodle configurations from a ini file.
 *
 * @copyright 2022 Alexander Bias, lern.link GmbH <alexander.bias@lernlink.de>
 * @license   http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

define('CLI_SCRIPT', true);

require_once('config.php');
require_once($CFG->libdir.'/clilib.php');

global $CFG, $DB;

// Get cli options.
list($options, $unrecognized) = cli_get_params(array('help' => false,
                                                    'inifile' => null),
                                               array('h' => 'help',
                                                    'i' => 'inifile'));
if ($unrecognized) {
    $unrecognized = implode("\n  ", $unrecognized);
    cli_error(get_string('cliunknowoption', 'admin', $unrecognized));
}

// CLI help.
if ($options['help'] || !($options['inifile']) || !is_readable($options['inifile'])) {
    $help = "CLI tool to set a set of Moodle configurations from a ini file
Options:
-i, --inifile   Absolute path to the .ini file with the configurations
-h, --help      Print out this help
Example:
\$ php moodleconfigfromini.php -i path/to/configuration.ini";
    cli_writeln($help);
    exit(0);
}


// Parse the ini file.
$config = parse_ini_file($options['inifile'], true);


// Process core settings first.
cli_writeln('Setting config for Moodle core...');

// Sort the settings for a nicer output.
ksort($config['core']);

// Iterate over the settings.
foreach($config['core'] as $cname => $cvalue) {
    // Set the setting.
    set_config($cname, $cvalue);

    // And inform the admin.
    cli_writeln('... '.$cname.': '.$cvalue);
}


// Config areas which are stored like plugins but which are not really plugins (with an installed version).
$pseudoplugins = array('moodlecourse', 'backup', 'core_competency');

// Iterate over the pseudo-plugins.
foreach ($pseudoplugins as $ps) {
    // If there isn't any configuration for this pseudo-plugin in the configuration file, skip it silently.
    if (array_key_exists($ps, $config) == false) {
        continue;
    }

    // Inform the admin.
    cli_writeln('Setting config for pseudo-plugin '.$ps.'...');

    // Sort the settings for a nicer output.
    ksort($config[$ps]);

    // Iterate over the settings.
    foreach($config[$ps] as $cname => $cvalue) {
        // Split the plugin name from the config name.
        $setting = explode('/', $cname);
    
        // Set the setting.
        set_config($setting[1], $cvalue, $setting[0]);

        // And inform the admin.
	cli_writeln('... '.$cname.': '.$cvalue);
    }
}


// Iterate over the plugin sections.
foreach ($config as $pluginname => $pluginconfig) {
    // If we have found the core or a pseudo-plugin (again), skip it.
    if ($pluginname == 'core' || in_array($pluginname, $pseudoplugins)) {
        continue;
    }

    // Inform the admin.
    cli_writeln('Setting config for plugin '.$pluginname.'...');
    
    // If the plugin is not installed at all, skip it.
    if ($DB->record_exists('config_plugins', array('plugin' => $pluginname, 'name' => 'version')) == false) {
        cli_writeln('... Plugin is not installed.');
        continue;
    }

    // Sort the settings for a nicer output.
    ksort($pluginconfig);

    // Iterate over the settings.
    foreach($pluginconfig as $cname => $cvalue) {
	// Split the plugin name from the config name.
	$setting = explode('/', $cname);

	// If this is a core setting (for example because the plugin stores its settings in the wrong place).
	if (count($setting) == 1) {
            // Set the setting.
            set_config($cname, $cvalue);

            // Otherwise, if this is a plugin setting.
	} else {
            // Set the setting.
            set_config($setting[1], $cvalue, $setting[0]);
	}

        // And inform the admin.
        cli_writeln('... '.$cname.': '.$cvalue);
    }  
}
