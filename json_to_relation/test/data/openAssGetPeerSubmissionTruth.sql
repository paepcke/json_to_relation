# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

-- If loading this file from the Linux commandline or the
-- MySQL shell, then first remove the '-- ' chars from the
-- 'ALTER ENABLE KEYS' statements below. Keep those chars 
-- in place if loading this .sql file via the manageEdxDb.py script,
-- as you should.
CREATE DATABASE IF NOT EXISTS Edx;
CREATE DATABASE IF NOT EXISTS EdxPrivate;
USE Edx;
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS EdxTrackEvent, Answer, InputState, CorrectMap, State, Account, EdxPrivate.Account, LoadInfo, ABExperiment, OpenAssessment;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS Answer (
    answer_id VARCHAR(40) NOT NULL PRIMARY KEY,
    problem_id VARCHAR(255) NOT NULL,
    answer TEXT NOT NULL,
    course_id VARCHAR(255) NOT NULL
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS CorrectMap (
    correct_map_id VARCHAR(40) NOT NULL PRIMARY KEY,
    answer_identifier TEXT NOT NULL,
    correctness VARCHAR(255) NOT NULL,
    npoints INT NOT NULL,
    msg TEXT NOT NULL,
    hint TEXT NOT NULL,
    hintmode VARCHAR(255) NOT NULL,
    queuestate TEXT NOT NULL
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS InputState (
    input_state_id VARCHAR(40) NOT NULL PRIMARY KEY,
    problem_id VARCHAR(255) NOT NULL,
    state TEXT NOT NULL
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS State (
    state_id VARCHAR(40) NOT NULL PRIMARY KEY,
    seed TINYINT NOT NULL,
    done VARCHAR(255) NOT NULL,
    problem_id VARCHAR(255) NOT NULL,
    student_answer VARCHAR(40) NOT NULL,
    correct_map VARCHAR(40) NOT NULL,
    input_state VARCHAR(40) NOT NULL,
    FOREIGN KEY(student_answer) REFERENCES Answer(answer_id) ON DELETE CASCADE,
    FOREIGN KEY(correct_map) REFERENCES CorrectMap(correct_map_id) ON DELETE CASCADE,
    FOREIGN KEY(input_state) REFERENCES InputState(input_state_id) ON DELETE CASCADE
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS Account (
    account_id VARCHAR(40) NOT NULL PRIMARY KEY,
    screen_name TEXT NOT NULL,
    name TEXT NOT NULL,
    anon_screen_name TEXT NOT NULL,
    mailing_address TEXT NOT NULL,
    zipcode VARCHAR(255) NOT NULL,
    country VARCHAR(255) NOT NULL,
    gender VARCHAR(255) NOT NULL,
    year_of_birth INT NOT NULL,
    level_of_education VARCHAR(255) NOT NULL,
    goals TEXT NOT NULL,
    honor_code TINYINT NOT NULL,
    terms_of_service TINYINT NOT NULL,
    course_id TEXT NOT NULL,
    enrollment_action VARCHAR(255) NOT NULL,
    email TEXT NOT NULL,
    receive_emails VARCHAR(255) NOT NULL
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS EdxPrivate.Account (
    account_id VARCHAR(40) NOT NULL PRIMARY KEY,
    screen_name TEXT NOT NULL,
    name TEXT NOT NULL,
    anon_screen_name TEXT NOT NULL,
    mailing_address TEXT NOT NULL,
    zipcode VARCHAR(255) NOT NULL,
    country VARCHAR(255) NOT NULL,
    gender VARCHAR(255) NOT NULL,
    year_of_birth INT NOT NULL,
    level_of_education VARCHAR(255) NOT NULL,
    goals TEXT NOT NULL,
    honor_code TINYINT NOT NULL,
    terms_of_service TINYINT NOT NULL,
    course_id TEXT NOT NULL,
    enrollment_action VARCHAR(255) NOT NULL,
    email TEXT NOT NULL,
    receive_emails VARCHAR(255) NOT NULL
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS EventIp (
    event_table_id VARCHAR(40) NOT NULL PRIMARY KEY,
    event_ip VARCHAR(255) NOT NULL
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS EdxPrivate.EventIp (
    event_table_id VARCHAR(40) NOT NULL PRIMARY KEY,
    event_ip VARCHAR(255) NOT NULL
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS ABExperiment (
    event_table_id VARCHAR(40) NOT NULL PRIMARY KEY,
    event_type VARCHAR(255) NOT NULL,
    anon_screen_name VARCHAR(40) NOT NULL,
    group_id INT NOT NULL,
    group_name VARCHAR(255) NOT NULL,
    partition_id INT NOT NULL,
    partition_name VARCHAR(255) NOT NULL,
    child_module_id VARCHAR(255) NOT NULL,
    resource_display_name VARCHAR(255) NOT NULL,
    cohort_id INT NOT NULL,
    cohort_name VARCHAR(255) NOT NULL
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS OpenAssessment (
    event_table_id VARCHAR(40) NOT NULL PRIMARY KEY,
    event_type VARCHAR(255) NOT NULL,
    anon_screen_name VARCHAR(40) NOT NULL,
    score_type VARCHAR(255) NOT NULL,
    submission_uuid VARCHAR(255) NOT NULL,
    edx_anon_id TEXT NOT NULL,
    time DATETIME NOT NULL,
    time_aux DATETIME NOT NULL,
    course_display_name VARCHAR(255) NOT NULL,
    resource_display_name VARCHAR(255) NOT NULL,
    resource_id VARCHAR(255) NOT NULL,
    submission_text MEDIUMTEXT NOT NULL,
    feedback_text MEDIUMTEXT NOT NULL,
    comment_text MEDIUMTEXT NOT NULL,
    attempt_num INT NOT NULL,
    options VARCHAR(255) NOT NULL,
    corrections TEXT NOT NULL,
    points TEXT NOT NULL
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS LoadInfo (
    load_info_id VARCHAR(40) NOT NULL PRIMARY KEY,
    load_date_time DATETIME NOT NULL,
    load_file TEXT NOT NULL
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS EdxTrackEvent (
    _id VARCHAR(40) NOT NULL PRIMARY KEY,
    event_id VARCHAR(40) NOT NULL,
    agent TEXT NOT NULL,
    event_source VARCHAR(255) NOT NULL,
    event_type TEXT NOT NULL,
    ip_country VARCHAR(255) NOT NULL,
    page TEXT NOT NULL,
    session TEXT NOT NULL,
    time DATETIME NOT NULL,
    quarter VARCHAR(255) NOT NULL,
    anon_screen_name TEXT NOT NULL,
    downtime_for DATETIME NOT NULL,
    student_id TEXT NOT NULL,
    instructor_id TEXT NOT NULL,
    course_id VARCHAR(255) NOT NULL,
    course_display_name VARCHAR(255) NOT NULL,
    resource_display_name VARCHAR(255) NOT NULL,
    organization VARCHAR(255) NOT NULL,
    sequence_id VARCHAR(255) NOT NULL,
    goto_from INT NOT NULL,
    goto_dest INT NOT NULL,
    problem_id VARCHAR(255) NOT NULL,
    problem_choice TEXT NOT NULL,
    question_location TEXT NOT NULL,
    submission_id TEXT NOT NULL,
    attempts INT NOT NULL,
    long_answer TEXT NOT NULL,
    student_file TEXT NOT NULL,
    can_upload_file VARCHAR(255) NOT NULL,
    feedback TEXT NOT NULL,
    feedback_response_selected TINYINT NOT NULL,
    transcript_id TEXT NOT NULL,
    transcript_code VARCHAR(255) NOT NULL,
    rubric_selection INT NOT NULL,
    rubric_category INT NOT NULL,
    video_id VARCHAR(255) NOT NULL,
    video_code TEXT NOT NULL,
    video_current_time VARCHAR(255) NOT NULL,
    video_speed VARCHAR(255) NOT NULL,
    video_old_time VARCHAR(255) NOT NULL,
    video_new_time VARCHAR(255) NOT NULL,
    video_seek_type VARCHAR(255) NOT NULL,
    video_new_speed VARCHAR(255) NOT NULL,
    video_old_speed VARCHAR(255) NOT NULL,
    book_interaction_type VARCHAR(255) NOT NULL,
    success VARCHAR(255) NOT NULL,
    answer_id TEXT NOT NULL,
    hint TEXT NOT NULL,
    mode VARCHAR(255) NOT NULL,
    msg TEXT NOT NULL,
    npoints TINYINT NOT NULL,
    queuestate TEXT NOT NULL,
    orig_score INT NOT NULL,
    new_score INT NOT NULL,
    orig_total INT NOT NULL,
    new_total INT NOT NULL,
    event_name VARCHAR(255) NOT NULL,
    group_user VARCHAR(255) NOT NULL,
    group_action VARCHAR(255) NOT NULL,
    position INT NOT NULL,
    badly_formatted TEXT NOT NULL,
    correctMap_fk VARCHAR(40) NOT NULL,
    answer_fk VARCHAR(40) NOT NULL,
    state_fk VARCHAR(40) NOT NULL,
    load_info_fk VARCHAR(40) NOT NULL
    ) ENGINE=InnoDB
PARTITION BY LIST COLUMNS(quarter) ( 
PARTITION pAY2012_Spring VALUES IN ('spring2013'),
PARTITION pAY2012_Summer VALUES IN ('summer2013'),
PARTITION pAY2013_Fall VALUES IN ('fall2013'),
PARTITION pAY2013_Winter VALUES IN ('winter2014'),
PARTITION pAY2013_Spring VALUES IN ('spring2014'),
PARTITION pAY2013_Summer VALUES IN ('summer2014'),
PARTITION pAY2014_Fall VALUES IN ('fall2014'),
PARTITION pAY2014_Winter VALUES IN ('winter2015'),
PARTITION pAY2014_Spring VALUES IN ('spring2015'),
PARTITION pAY2014_Summer VALUES IN ('summer2015'),
PARTITION pAY2015_Fall VALUES IN ('fall2015'),
PARTITION pAY2015_Winter VALUES IN ('winter2016'),
PARTITION pAY2015_Spring VALUES IN ('spring2016'),
PARTITION pAY2015_Summer VALUES IN ('summer2016'),
PARTITION pAY2016_Fall VALUES IN ('fall2016'),
PARTITION pAY2016_Winter VALUES IN ('winter2017'),
PARTITION pAY2016_Spring VALUES IN ('spring2017'),
PARTITION pAY2016_Summer VALUES IN ('summer2017'),
PARTITION pAY2017_Fall VALUES IN ('fall2017'),
PARTITION pAY2017_Winter VALUES IN ('winter2018'),
PARTITION pAY2017_Spring VALUES IN ('spring2018'),
PARTITION pAY2017_Summer VALUES IN ('summer2018'));
LOCK TABLES `EdxTrackEvent` WRITE, `State` WRITE, `InputState` WRITE, `Answer` WRITE, `CorrectMap` WRITE, `LoadInfo` WRITE, `Account` WRITE, `EventIp` WRITE, `ABExperiment` WRITE, `OpenAssessment` WRITE;
/*!40000 ALTER TABLE `EdxTrackEvent` DISABLE KEYS */;
/*!40000 ALTER TABLE `State` DISABLE KEYS */;
/*!40000 ALTER TABLE `InputState` DISABLE KEYS */;
/*!40000 ALTER TABLE `Answer` DISABLE KEYS */;
/*!40000 ALTER TABLE `CorrectMap` DISABLE KEYS */;
/*!40000 ALTER TABLE `LoadInfo` DISABLE KEYS */;
/*!40000 ALTER TABLE `Account` DISABLE KEYS */;
/*!40000 ALTER TABLE `EventIp` DISABLE KEYS */;
/*!40000 ALTER TABLE `ABExperiment` DISABLE KEYS */;
/*!40000 ALTER TABLE `OpenAssessment` DISABLE KEYS */;
INSERT INTO LoadInfo (load_info_id,load_date_time,load_file) VALUES 
    ('4a0182a8f0801de9a24791c15de93f02028762c7','2014-10-26T12:08:40.928296','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/openAssGetPeerSubmission.json');
INSERT INTO EventIp (event_table_id,event_ip) VALUES 
    ('466b1b9a_1cd6_49dc_ac55_ae44fccfb4da','171.67.220.125');
INSERT INTO ABExperiment (event_table_id,event_type,anon_screen_name,group_id,group_name,partition_id,partition_name,child_module_id,resource_display_name,cohort_id,cohort_name) VALUES 
    ('466b1b9a_1cd6_49dc_ac55_ae44fccfb4da','openassessmentblock.get_peer_submission','',-1,'',-1,'','','Peer Assessment',-1,'');
INSERT INTO OpenAssessment (event_table_id,event_type,anon_screen_name,score_type,submission_uuid,edx_anon_id,time,time_aux,course_display_name,resource_display_name,resource_id,submission_text,feedback_text,comment_text,attempt_num,options,corrections,points) VALUES 
    ('466b1b9a_1cd6_49dc_ac55_ae44fccfb4da','openassessmentblock.get_peer_submission','e07a3da71f0330452a6aa650ed598e2911301491','',null,'5ee2c96e6d6b84818d41c489a0ce89ac','2014-05-15T18:09:04.697762+00:00','','StanfordOnline/OpenEdX/Demo','Peer Assessment','i4x://StanfordOnline/OpenEdX/openassessment/bdb10e5302c64229b897f8a2e9110293','','','',-1,'','','');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip_country,page,session,time,quarter,anon_screen_name,downtime_for,student_id,instructor_id,course_id,course_display_name,resource_display_name,organization,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,mode,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    ('466b1b9a_1cd6_49dc_ac55_ae44fccfb4da','9cf18103_267b_4122_8f5b_6af225093c26','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.137 Safari/537.36','server','openassessmentblock.get_peer_submission','USA','x_module','','2014-05-15T18:09:04.697762+00:00','spring2014','e07a3da71f0330452a6aa650ed598e2911301491','0:00:00','','','StanfordOnline/OpenEdX/Demo','StanfordOnline/OpenEdX/Demo','Peer Assessment','StanfordOnline','',-1,-1,'','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','','','4a0182a8f0801de9a24791c15de93f02028762c7');
-- /*!40000 ALTER TABLE `EdxTrackEvent` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `State` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `InputState` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `Answer` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `CorrectMap` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `LoadInfo` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `Account` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `EventIp` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `ABExperiment` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `OpenAssessment` ENABLE KEYS */;
UNLOCK TABLES;
REPLACE INTO EdxPrivate.Account (account_id,screen_name,name,anon_screen_name,mailing_address,zipcode,country,gender,year_of_birth,level_of_education,goals,honor_code,terms_of_service,course_id,enrollment_action,email,receive_emails) SELECT account_id,screen_name,name,anon_screen_name,mailing_address,zipcode,country,gender,year_of_birth,level_of_education,goals,honor_code,terms_of_service,course_id,enrollment_action,email,receive_emails FROM Edx.Account;
DROP TABLE Edx.Account;
REPLACE INTO EdxPrivate.EventIp (event_table_id,event_ip) SELECT event_table_id,event_ip FROM Edx.EventIp;
DROP TABLE Edx.EventIp;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
