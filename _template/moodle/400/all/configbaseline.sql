-- mod_bigbluebuttonbn: Enable the plugin as it is deactivated by default
UPDATE {modules} SET visible = 1 WHERE name = 'bigbluebuttonbn'
