-- mod_chat: Disable the plugin by default
UPDATE {modules} SET visible = 0 WHERE name = 'chat'

-- mod_survey: Disable the plugin by default
UPDATE {modules} SET visible = 0 WHERE name = 'survey'
