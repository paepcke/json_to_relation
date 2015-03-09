# Use to remove all duplicates that were accidentally created
# when loading the same files multiple times. We do not use 
# UNIQUE keys to prevent duplicates, because they are prohibitively
# expensive when loading. In this script we temporarily add
# a unique key on the one column that is intended to be unique.
# We remove those indexes again at the end.

# Add UNIQUE index to each of the tables:

USE Edx;
-- SELECT CONCAT(CURRENT_TIMESTAMP(), ": Remove dups from ABExperiment...");
--     ALTER IGNORE TABLE `ABExperiment` ADD UNIQUE INDEX (`event_table_id`);
-- SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done remove dups from ABExperiment...");
-- SELECT CONCAT(CURRENT_TIMESTAMP(), ": Remove dups from Answer...");
--     ALTER IGNORE TABLE `Answer` ADD UNIQUE INDEX (`answer_id`);
-- SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done remove dups from Answer...");
-- SELECT CONCAT(CURRENT_TIMESTAMP(), ": Remove dups from CorrectMap...");
--     ALTER IGNORE TABLE `CorrectMap` ADD UNIQUE INDEX (`correct_map_id`);
-- SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done remove dups from CorrectMap...");
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Remove dups from InputState...");
    ALTER IGNORE TABLE `InputState` ADD UNIQUE INDEX (`input_state_id`);
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done remove dups from InputState...");
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Remove dups from LoadInfo...");
    ALTER IGNORE TABLE `LoadInfo` ADD UNIQUE INDEX (`load_info_id`);
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done remove dups from LoadInfo...");
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Remove dups from OpenAssessment...");
    ALTER IGNORE TABLE `OpenAssessment` ADD UNIQUE INDEX (`event_table_id`);
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done remove dups from OpenAssessment...");
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Remove dups from State...");
    ALTER IGNORE TABLE `State` ADD UNIQUE INDEX (`state_id`);
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done remove dups from State...");
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Remove dups from EdxTrackEvent...");
    ALTER IGNORE TABLE `EdxTrackEvent` ADD UNIQUE INDEX (`_id`, `quarter`);
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done remove dups from EdxTrackEvent...");

USE EdxPrivate;
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done remove dups from Account...");
    ALTER IGNORE TABLE `Account` ADD UNIQUE INDEX (`account_id`);
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done remove dups from Account...");
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done remove dups from EventIp...");
    ALTER IGNORE TABLE `EventIp` ADD UNIQUE INDEX (`event_table_id`);
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done remove dups from EventIp...");

# Remove the UNIQUE indexes from each of the tables:

USE EdX;
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Start deleting the UNIQUE indexes in Edx tables...");
DROP INDEX event_table_id  ON ABExperiment;
DROP INDEX answer_id ON Answer;
DROP INDEX correct_map_id ON CorrectMap;
DROP INDEX _id ON EdxTrackEvent;
DROP INDEX input_state_id ON InputState;
DROP INDEX load_info_id ON LoadInfo;
DROP INDEX event_table_id ON OpenAssessment;
DROP INDEX state_id  ON `State`;
-- ***** DROP INDEX ????  ON `EdxTrackEvent`;
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done deleting the UNIQUE indexes in EdxPrivate tables...");

USE EdxPrivate;
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Start deleting the UNIQUE indexes in EdxPrivate tables...");
DROP INDEX account_id  ON Account;
DROP INDEX event_table_id  ON EventIp;
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done deleting the UNIQUE indexes in EdxPrivate tables...");
