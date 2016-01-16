# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Use to remove all duplicates that were accidentally created
# when loading the same files multiple times. We do not use 
# UNIQUE keys to prevent duplicates, because they are prohibitively
# expensive when loading, and you cannot disable them even
# temporarily. 
#
# In this script we temporarily add a unique key on the one 
# column that is intended to be unique. We remove those indexes 
# again at the end.

# Add UNIQUE index to each of the tables:

USE Edx;
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Remove dups from ABExperiment...");
    ALTER IGNORE TABLE `ABExperiment` ADD UNIQUE INDEX (`event_table_id`);
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done remove dups from ABExperiment...");
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Remove dups from Answer...");
    ALTER IGNORE TABLE `Answer` ADD UNIQUE INDEX (`answer_id`);
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done remove dups from Answer...");
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Remove dups from CorrectMap...");
    ALTER IGNORE TABLE `CorrectMap` ADD UNIQUE INDEX (`correct_map_id`);
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done remove dups from CorrectMap...");
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

USE Edx;
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Start deleting the UNIQUE indexes in Edx tables...");
DROP INDEX event_table_id  ON ABExperiment;
DROP INDEX answer_id ON Answer;
DROP INDEX correct_map_id ON CorrectMap;
DROP INDEX _id ON EdxTrackEvent;
DROP INDEX input_state_id ON InputState;
DROP INDEX load_info_id ON LoadInfo;
DROP INDEX event_table_id ON OpenAssessment;
DROP INDEX state_id  ON `State`;
DROP INDEX _id  ON `EdxTrackEvent`;
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done deleting the UNIQUE indexes in EdxPrivate tables...");

USE EdxPrivate;
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Start deleting the UNIQUE indexes in EdxPrivate tables...");
DROP INDEX account_id  ON Account;
DROP INDEX event_table_id  ON EventIp;
SELECT CONCAT(CURRENT_TIMESTAMP(), ": Done deleting the UNIQUE indexes in EdxPrivate tables...");
