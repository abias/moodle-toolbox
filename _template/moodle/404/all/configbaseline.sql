-- mod_bigbluebuttonbn: Enable the plugin as it is deactivated by default
UPDATE {modules} SET visible = 1 WHERE name = 'bigbluebuttonbn' AND visible != 1

-- mod_chat: Disable the plugin by default
UPDATE {modules} SET visible = 0 WHERE name = 'chat' AND visible != 0

-- mod_survey: Disable the plugin by default
UPDATE {modules} SET visible = 0 WHERE name = 'survey' AND visible != 0

-- mod_imscp: Disable the plugin by default
UPDATE {modules} SET visible = 0 WHERE name = 'imscp' AND visible != 0

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

-- filter_mathjaxloader: Disable the filter
UPDATE {filter_active} SET active = -9999 WHERE filter = 'mathjaxloader' AND active != -9999

-- filter_activitynames: Disable the filter
UPDATE {filter_active} SET active = -9999 WHERE filter = 'activitynames' AND active != -9999

-- core: Set the activity chooser favourites
INSERT INTO {favourite} (component, itemtype, itemid, contextid, userid, ordering, timecreated, timemodified) VALUES ('core_course', 'recommend_mod_assign', (SELECT id FROM {modules} WHERE name = 'assign'), 1, 1, null, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE id = id
INSERT INTO {favourite} (component, itemtype, itemid, contextid, userid, ordering, timecreated, timemodified) VALUES ('core_course', 'recommend_mod_bigbluebuttonbn', (SELECT id FROM {modules} WHERE name = 'bigbluebuttonbn'), 1, 1, null, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE id = id
INSERT INTO {favourite} (component, itemtype, itemid, contextid, userid, ordering, timecreated, timemodified) VALUES ('core_course', 'recommend_mod_book', (SELECT id FROM {modules} WHERE name = 'book'), 1, 1, null, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE id = id
INSERT INTO {favourite} (component, itemtype, itemid, contextid, userid, ordering, timecreated, timemodified) VALUES ('core_course', 'recommend_mod_customcert', (SELECT id FROM {modules} WHERE name = 'customcert'), 1, 1, null, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE id = id
INSERT INTO {favourite} (component, itemtype, itemid, contextid, userid, ordering, timecreated, timemodified) VALUES ('core_course', 'recommend_mod_feedback', (SELECT id FROM {modules} WHERE name = 'feedback'), 1, 1, null, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE id = id
INSERT INTO {favourite} (component, itemtype, itemid, contextid, userid, ordering, timecreated, timemodified) VALUES ('core_course', 'recommend_mod_folder', (SELECT id FROM {modules} WHERE name = 'folder'), 1, 1, null, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE id = id
INSERT INTO {favourite} (component, itemtype, itemid, contextid, userid, ordering, timecreated, timemodified) VALUES ('core_course', 'recommend_mod_forum', (SELECT id FROM {modules} WHERE name = 'forum'), 1, 1, null, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE id = id
INSERT INTO {favourite} (component, itemtype, itemid, contextid, userid, ordering, timecreated, timemodified) VALUES ('core_course', 'recommend_mod_h5pactivity', (SELECT id FROM {modules} WHERE name = 'h5pactivity'), 1, 1, null, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE id = id
INSERT INTO {favourite} (component, itemtype, itemid, contextid, userid, ordering, timecreated, timemodified) VALUES ('core_course', 'recommend_mod_label', (SELECT id FROM {modules} WHERE name = 'label'), 1, 1, null, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE id = id
INSERT INTO {favourite} (component, itemtype, itemid, contextid, userid, ordering, timecreated, timemodified) VALUES ('core_course', 'recommend_mod_page', (SELECT id FROM {modules} WHERE name = 'page'), 1, 1, null, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE id = id
INSERT INTO {favourite} (component, itemtype, itemid, contextid, userid, ordering, timecreated, timemodified) VALUES ('core_course', 'recommend_mod_quiz', (SELECT id FROM {modules} WHERE name = 'quiz'), 1, 1, null, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE id = id
INSERT INTO {favourite} (component, itemtype, itemid, contextid, userid, ordering, timecreated, timemodified) VALUES ('core_course', 'recommend_mod_resource', (SELECT id FROM {modules} WHERE name = 'resource'), 1, 1, null, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE id = id
INSERT INTO {favourite} (component, itemtype, itemid, contextid, userid, ordering, timecreated, timemodified) VALUES ('core_course', 'recommend_mod_scorm', (SELECT id FROM {modules} WHERE name = 'scorm'), 1, 1, null, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE id = id
INSERT INTO {favourite} (component, itemtype, itemid, contextid, userid, ordering, timecreated, timemodified) VALUES ('core_course', 'recommend_mod_url', (SELECT id FROM {modules} WHERE name = 'url'), 1, 1, null, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE id = id
