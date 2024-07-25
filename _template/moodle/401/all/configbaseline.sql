-- mod_bigbluebuttonbn: Enable the plugin as it is deactivated by default
UPDATE {modules} SET visible = 1 WHERE name = 'bigbluebuttonbn' AND visible != 1

-- mod_chat: Disable the plugin by default
UPDATE {modules} SET visible = 0 WHERE name = 'chat' AND visible != 0

-- mod_survey: Disable the plugin by default
UPDATE {modules} SET visible = 0 WHERE name = 'survey' AND visible != 0

-- block_online_users: Disable the plugin by default
UPDATE {block} SET visible = 0 WHERE name = 'online_users' AND visible != 0

-- repository_wikimedia: Remove the repository instance
DELETE FROM {repository_instances} WHERE id = (SELECT id FROM {repository} WHERE type = 'wikimedia')
DELETE FROM {repository} WHERE type = 'wikimedia'

-- repository_url: Remove the repository instance
DELETE FROM {repository_instances} WHERE id = (SELECT id FROM {repository} WHERE type = 'url')
DELETE FROM {repository} WHERE type = 'url'

-- filter_emoticon: Disable the filter
UPDATE {filter_active} SET active = -9999 WHERE filter = 'emoticon' AND active != -9999

-- filter_activitynames: Disable the filter
UPDATE {filter_active} SET active = -9999 WHERE filter = 'activitynames' AND active != -9999
