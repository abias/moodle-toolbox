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
 * Brute-force fixing of any 'cannotdowngrade' errors.
 *
 * @copyright 2016 Davo Smith, Synergy Learning
 * @license   http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

define('CLI_SCRIPT', true);

require_once('config.php');
global $DB, $CFG;
require_once($CFG->libdir.'/clilib.php');

$tofix = [];
foreach (core_component::get_plugin_types() as $type => $location) {
    foreach (core_component::get_plugin_list($type) as $plug => $path) {
        $component = clean_param($type.'_'.$plug, PARAM_COMPONENT);
        $plugin = new stdClass();
        $plugin->version = null;
        $module = $plugin;
        require($path.'/version.php');
        $installedversion = $DB->get_field('config_plugins', 'value', array('name' => 'version', 'plugin' => $component));

        if ($installedversion && $installedversion > $plugin->version) {
            $tofix[$component] = (object)['oldversion' => $installedversion, 'newversion' => $plugin->version];
        }
    }
}

if (!$tofix) {
    echo "No plugins are being downgraded.\n";
    die();
}

echo "\nThe following plugins have downgrade issues:\n";
foreach ($tofix as $component => $info) {
    echo "{$component} - change oldversion: {$info->oldversion} to newversion: {$info->newversion}\n";
}
$answer = cli_input("Are you sure you want to reset all the version numbers as listed above? (Y/N)", '', ['yes', 'no', 'y', 'n']);
if (!in_array($answer, ['y', 'yes'])) {
    echo "\nNo changes made.\n";
    die();
}

foreach ($tofix as $component => $info) {
    set_config('version', $info->newversion, $component);
}


