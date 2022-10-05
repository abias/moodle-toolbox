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
 * CLI script to set a set of Moodle configurations from a sql file.
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
                                                    'sqlfile' => null),
                                               array('h' => 'help',
                                                    's' => 'sqlfile'));
if ($unrecognized) {
    $unrecognized = implode("\n  ", $unrecognized);
    cli_error(get_string('cliunknowoption', 'admin', $unrecognized));
}

// CLI help.
if ($options['help'] || !($options['sqlfile']) || !is_readable($options['sqlfile'])) {
    $help = "CLI tool to set a set of Moodle configurations from a sql file
Options:
-q, --sqlfile   Absolute path to the .sql file with the configuration queries
-h, --help      Print out this help
Example:
\$ php moodleconfigfromsql.php -i path/to/configuration.sql";
    cli_writeln($help);
    exit(0);
}


// Process the sql queries.
cli_writeln('Running sql queries to configure Moodle...');

// Open the file.
if ($file = fopen($options['sqlfile'], 'r')) {

    // Iterate through the lines.
    while (!feof($file)) {

        // Get the next line.
        $line = fgets($file);

        // Trim the line.
	$line = trim($line);

	// If the line is empty, continue.
	if (strlen($line) < 1) {
            continue;
        }

	// If this is a comment line.
	if (substr($line, 0, 2) == '--') {
    
            // Inform the admin.
            cli_writeln('... '.substr($line, 2));

            // Otherwise, handle the line as sql query.
	} else {
           $DB->execute($line);
	}
    }

    // Close the file.
    fclose($file);
}
