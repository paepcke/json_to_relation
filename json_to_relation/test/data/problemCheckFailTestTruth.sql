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
    ('7d22294395ada5d968b9d386209b8d79e95c78a3','2014-10-26T12:08:51.847076','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/problemCheckFailTest.json');
INSERT INTO EventIp (event_table_id,event_ip) VALUES 
    ('8860cd7f_9b84_4b66_8b9f_5d3213c1b8a8','58.108.173.32');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('8a46f300_3214_4575_85ff_35ae419dec1a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('91d2f469_92f4_4150_85a3_b096edebe318','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('bb5d6009_17b1_4370_9ca8_55f7399daae2','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('a0345291_698c_452a_99d9_ae8355969a6c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('afd054dd_e3a3_4cef_8e52_c9730b27e1bf','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('ccba9bd4_aba7_4c65_bf59_75c32a664422','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('fa6dc068_e3b2_4d43_9fc5_cf5f0503a67e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('c708169b_f647_412c_8c22_65ea3788037a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258'),
    ('6e81ff67_d55a_45d7_a519_590670c0a3b2','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('1096e1dc_e583_43cf_82d7_e8aa376be3b8','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('9c4f8821_d5c3_4e72_8e0d_93ae351d3029','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('6175ce98_521c_4c78_b3d0_a07ae262f484','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('f1c161ab_77e0_4875_8a39_81912572246d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('970ad2ed_119e_426f_ac95_8b481d6fa9f4','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('d24395e4_c782_41dd_bc52_fd8d9f3d81af','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('700f1ec7_95aa_4199_b1fe_58ee4884f80d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('7d190c81_2102_4dce_b1da_3de95f2a66ca','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','correct',-1,'','','',''),
    ('7dde2d70_c691_4133_b606_0b9621a8d488','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','correct',-1,'','','',''),
    ('df33cd96_863e_421c_ba9f_4cec951b9e34','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','correct',-1,'','','',''),
    ('be550011_1955_4924_9889_19d7e1bf678c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','correct',-1,'','','',''),
    ('586fd8e2_89a3_4e9d_80f7_d96c992bc634','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','incorrect',-1,'','','',''),
    ('929f755f_96d6_40ae_9d61_821570bfe9ad','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','correct',-1,'','','',''),
    ('3fdfb3af_c984_45cb_941b_ac56f2492aff','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','correct',-1,'','','',''),
    ('e8e439e0_c796_4e23_a070_0a802a30240c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','incorrect',-1,'','','','');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('ac2751aa_84ee_4ddd_b389_6bb693f7d515','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',''),
    ('baf9be1f_7969_4e47_b122_04fcd30511d8','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',''),
    ('a018f48e_0e2f_4e8d_b6fd_693675bdffd5','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',''),
    ('f3e5fcd2_4a75_4795_9cab_0e077620515b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',''),
    ('12faecc9_cb8a_4772_95cb_43f54fc04461','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',''),
    ('dca23e5f_49c3_4c93_8926_3115306b6185','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',''),
    ('a11b3314_a83b_48ee_80d9_11f16cdd4355','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',''),
    ('3c04cd40_3774_4d8f_84ca_dd7d8014d1d2','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('df712c9e_3c60_455e_b3c9_233173909add',1,'True','','6e81ff67_d55a_45d7_a519_590670c0a3b2','7d190c81_2102_4dce_b1da_3de95f2a66ca','ac2751aa_84ee_4ddd_b389_6bb693f7d515'),
    ('1766dbf4_5b02_4a57_a7b6_efd5cd114692',1,'True','','1096e1dc_e583_43cf_82d7_e8aa376be3b8','7dde2d70_c691_4133_b606_0b9621a8d488','baf9be1f_7969_4e47_b122_04fcd30511d8'),
    ('fc04511c_6b2c_4090_b4b0_bd40a9fddc1c',1,'True','','9c4f8821_d5c3_4e72_8e0d_93ae351d3029','df33cd96_863e_421c_ba9f_4cec951b9e34','a018f48e_0e2f_4e8d_b6fd_693675bdffd5'),
    ('4c22f566_d31b_4266_bc8a_d662a843b755',1,'True','','6175ce98_521c_4c78_b3d0_a07ae262f484','be550011_1955_4924_9889_19d7e1bf678c','f3e5fcd2_4a75_4795_9cab_0e077620515b'),
    ('7f3dfb33_46b5_4407_8a55_1047f471a970',1,'True','','f1c161ab_77e0_4875_8a39_81912572246d','586fd8e2_89a3_4e9d_80f7_d96c992bc634','12faecc9_cb8a_4772_95cb_43f54fc04461'),
    ('966051e7_4b82_4c82_b0ca_e42205a99bbf',1,'True','','970ad2ed_119e_426f_ac95_8b481d6fa9f4','929f755f_96d6_40ae_9d61_821570bfe9ad','dca23e5f_49c3_4c93_8926_3115306b6185'),
    ('b9453718_de1c_41bd_b84f_6c116b5ff9f6',1,'True','','d24395e4_c782_41dd_bc52_fd8d9f3d81af','3fdfb3af_c984_45cb_941b_ac56f2492aff','a11b3314_a83b_48ee_80d9_11f16cdd4355'),
    ('9ff666b3_f965_41f7_a11c_d7e5513cffa1',1,'True','','700f1ec7_95aa_4199_b1fe_58ee4884f80d','e8e439e0_c796_4e23_a070_0a802a30240c','3c04cd40_3774_4d8f_84ca_dd7d8014d1d2');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip_country,page,session,time,quarter,anon_screen_name,downtime_for,student_id,instructor_id,course_id,course_display_name,resource_display_name,organization,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,mode,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    ('8860cd7f_9b84_4b66_8b9f_5d3213c1b8a8','631cf311_306a_404d_af5d_9505fe6eb06f','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','summer2013','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','8a46f300_3214_4575_85ff_35ae419dec1a','df712c9e_3c60_455e_b3c9_233173909add','7d22294395ada5d968b9d386209b8d79e95c78a3'),
    ('f6339f87_0e95_43e0_be2c_3ce9375f45f4','631cf311_306a_404d_af5d_9505fe6eb06f','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','summer2013','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','91d2f469_92f4_4150_85a3_b096edebe318','1766dbf4_5b02_4a57_a7b6_efd5cd114692','7d22294395ada5d968b9d386209b8d79e95c78a3'),
    ('e66626d7_8d12_494d_aa8a_b7c7f6194ee2','631cf311_306a_404d_af5d_9505fe6eb06f','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','summer2013','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','bb5d6009_17b1_4370_9ca8_55f7399daae2','fc04511c_6b2c_4090_b4b0_bd40a9fddc1c','7d22294395ada5d968b9d386209b8d79e95c78a3'),
    ('eb31d11f_1ca7_477e_a0fc_9fbf57988da7','631cf311_306a_404d_af5d_9505fe6eb06f','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','summer2013','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','a0345291_698c_452a_99d9_ae8355969a6c','4c22f566_d31b_4266_bc8a_d662a843b755','7d22294395ada5d968b9d386209b8d79e95c78a3'),
    ('f10a86fd_7521_4664_961c_fbfe6f3fd4b7','631cf311_306a_404d_af5d_9505fe6eb06f','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','summer2013','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','afd054dd_e3a3_4cef_8e52_c9730b27e1bf','7f3dfb33_46b5_4407_8a55_1047f471a970','7d22294395ada5d968b9d386209b8d79e95c78a3'),
    ('47a4da84_cbac_48e3_8c77_f500c5e8b5ac','631cf311_306a_404d_af5d_9505fe6eb06f','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','summer2013','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','ccba9bd4_aba7_4c65_bf59_75c32a664422','966051e7_4b82_4c82_b0ca_e42205a99bbf','7d22294395ada5d968b9d386209b8d79e95c78a3'),
    ('9ad54cc2_7961_4e8f_909c_28433f25c6b8','631cf311_306a_404d_af5d_9505fe6eb06f','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','summer2013','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','fa6dc068_e3b2_4d43_9fc5_cf5f0503a67e','b9453718_de1c_41bd_b84f_6c116b5ff9f6','7d22294395ada5d968b9d386209b8d79e95c78a3'),
    ('c5d4121b_eb3f_4f22_afc0_80397145fd05','631cf311_306a_404d_af5d_9505fe6eb06f','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','summer2013','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','c708169b_f647_412c_8c22_65ea3788037a','9ff666b3_f965_41f7_a11c_d7e5513cffa1','7d22294395ada5d968b9d386209b8d79e95c78a3'),
    ('8b2f0e8d_4e35_441b_955c_14b6a7776289','631cf311_306a_404d_af5d_9505fe6eb06f','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','summer2013','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','c708169b_f647_412c_8c22_65ea3788037a','9ff666b3_f965_41f7_a11c_d7e5513cffa1','7d22294395ada5d968b9d386209b8d79e95c78a3');
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
