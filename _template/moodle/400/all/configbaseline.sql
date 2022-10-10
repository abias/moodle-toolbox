-- mod_bigbluebuttonbn: Enable the plugin as it is deactivated by default
UPDATE {modules} SET visible = 1 WHERE name = 'bigbluebuttonbn'

-- mod_chat: Disable the plugin by default
UPDATE {modules} SET visible = 0 WHERE name = 'chat'

-- mod_survey: Disable the plugin by default
UPDATE {modules} SET visible = 0 WHERE name = 'survey'

-- repository_wikimedia: Remove the repository instance
DELETE FROM {repository_instances} WHERE id = (SELECT id FROM {repository} WHERE type = 'wikimedia')
DELETE FROM {repository} WHERE type = 'wikimedia'

-- repository_url: Remove the repository instance
DELETE FROM {repository_instances} WHERE id = (SELECT id FROM {repository} WHERE type = 'url')
DELETE FROM {repository} WHERE type = 'url'
