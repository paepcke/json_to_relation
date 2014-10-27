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
    ('f963629c7f493c4931394fd4861c859e588b8a11','2014-10-26T12:09:15.416741','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/saveProblemCheck.json');
INSERT INTO EventIp (event_table_id,event_ip) VALUES 
    ('51d00999_b559_41e3_b2a0_cc3cf47317a0','147.32.84.59');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('202ed25a_d1b0_4b5d_8bae_57933fc27b8e','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('67450fae_6f5f_4300_b695_56efab4c71b7','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('51f9d29c_9d52_449d_9f94_411b2a5567ba','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('96795008_9654_4b35_bdc3_73a0622cd6ce','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('d375f99b_67d5_45c4_b434_e53307cab6c3','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('bd9d73b8_d37b_424c_97ed_e15cd375922f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('0ce362e8_f2fb_4b92_a2d6_41a136ae68cd','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('7b18adf6_e9ca_4a04_9b34_3f49934d1180','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('9fafee7d_2720_43cc_9405_01d2da4ed42a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('f1f6009d_ff28_45ab_aa7a_b3160caffdcb','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('89b8e921_06ba_4aaa_86fe_e4fd05d1e9b4','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('dca5ce02_680d_4495_9364_076df65fc63c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('19b25891_8aa3_4afc_8b4c_a01d85fd0cf5','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('43d75fcd_7ee1_4305_b439_5e1bbc4dde7f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('555db354_c28e_4f69_b7e9_00709120b7e1','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('8ae77cff_3fb7_46dd_919b_1b2482e55e62','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('ff0e5751_2f4d_4ddf_9a27_7cac41b8a894','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('3e8acc42_7f2b_47ff_931e_626426d17892','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258'),
    ('bc42c42c_ec75_4df9_bad7_d2a8ceb1dda3','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('28608b41_72df_444e_814c_6927b1ebc40c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('529697ea_dd09_423e_a44f_16bd7fadfff7','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('b891ffb7_b11d_4cc9_89bd_0112cda89922','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('03e6ff8d_e78a_4efd_8507_b39325091d82','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('e39628c2_72fb_4a87_b6d1_be56c96dea18','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('6df2ca4d_a399_4638_8f6a_1bb939998ea5','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('001f6aa4_36ca_461b_bacd_300bf45e0919','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('e1fee4eb_ea36_4137_af70_951cff2e053c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('28ce0726_e8ee_4d80_9b61_a978942fd4f2','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('e6477f8e_2bcd_48e7_8fb0_fe3a32e12195','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('6769fc69_f5b1_468f_b835_0d3034ed940d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('41f08120_3ff9_4d24_bb0b_ec83e32ad5c7','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('05caf1c3_32ed_4302_a02e_e8675d3f3366','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('e43ca420_9fcf_4db9_ae0f_e06fa2da180c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('c52ce3e5_e612_4484_a6e4_64d542c50b98','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('90e0a97f_92ed_4898_992d_87dfacb94987','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('1674e7ec_9ae8_4d26_a96a_74a1b171b6da','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('451ed2bf_52b3_488e_af69_96e81cb1d542','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1',''),
    ('7a112311_9d80_4afa_8d2e_db8d71030cac','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1',''),
    ('d398adc5_28f6_46c9_a083_f73e048756ce','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1',''),
    ('62c13073_423e_4f1c_9a47_2ebc876091e2','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1',''),
    ('b3581d8b_ddf3_40e3_8e5b_8a22e9c83bb8','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1',''),
    ('1885536c_5ac4_46bd_b4f2_4424ca63d672','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1',''),
    ('8d020d29_1063_47d2_a43a_f5e4ed5b9733','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1',''),
    ('ae89eae5_3665_408b_a972_323269485cce','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1',''),
    ('99c3a24f_6366_44bb_9dcd_190cb48d0ab3','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1',''),
    ('54f9cc7d_8c17_4bd6_bc8d_89737b749e55','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1',''),
    ('c488a2e7_119b_48a9_b20a_deb1fb18d6da','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1',''),
    ('a3225624_6be5_48b1_9241_c372cb581eec','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1',''),
    ('6a471e5e_6284_422a_96fb_28bdf6750bf9','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1',''),
    ('dd924751_73dc_4244_89e9_150c6961f8ab','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1',''),
    ('a746a89a_6f6b_4dde_818b_a22e6fee8c2b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1',''),
    ('5418c977_2a51_42c5_ba52_e11559cd49e3','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1',''),
    ('5d2667bb_acf1_45eb_832d_46dca0490e77','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1',''),
    ('fda97311_7438_4aa7_9147_022348487619','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('27f4e317_0be2_4034_9ea8_072c6194c33a',1,'None','','bc42c42c_ec75_4df9_bad7_d2a8ceb1dda3','','451ed2bf_52b3_488e_af69_96e81cb1d542'),
    ('3c9654ba_f87e_4919_9e07_499d0b1c8b4c',1,'None','','28608b41_72df_444e_814c_6927b1ebc40c','','7a112311_9d80_4afa_8d2e_db8d71030cac'),
    ('da7e5b57_a76d_430b_8a16_b323fec01489',1,'None','','529697ea_dd09_423e_a44f_16bd7fadfff7','','d398adc5_28f6_46c9_a083_f73e048756ce'),
    ('f6e9cc67_66fd_4c15_979a_1ee531f10741',1,'None','','b891ffb7_b11d_4cc9_89bd_0112cda89922','','62c13073_423e_4f1c_9a47_2ebc876091e2'),
    ('c7d43676_b75e_4f64_8c8b_80fab132bce6',1,'None','','03e6ff8d_e78a_4efd_8507_b39325091d82','','b3581d8b_ddf3_40e3_8e5b_8a22e9c83bb8'),
    ('eeccf402_875c_40ad_a6ab_77996fb1de22',1,'None','','e39628c2_72fb_4a87_b6d1_be56c96dea18','','1885536c_5ac4_46bd_b4f2_4424ca63d672'),
    ('af4f47d5_8732_44b0_8eb8_25a98c60603d',1,'None','','6df2ca4d_a399_4638_8f6a_1bb939998ea5','','8d020d29_1063_47d2_a43a_f5e4ed5b9733'),
    ('d04a74f2_767f_4f28_9fa2_f99f37ca7d47',1,'None','','001f6aa4_36ca_461b_bacd_300bf45e0919','','ae89eae5_3665_408b_a972_323269485cce'),
    ('61822509_58ba_44e2_9750_5d8fcd3205dd',1,'None','','e1fee4eb_ea36_4137_af70_951cff2e053c','','99c3a24f_6366_44bb_9dcd_190cb48d0ab3'),
    ('9d0fc250_97fa_458c_9ce2_b2cd61d82bf9',1,'None','','28ce0726_e8ee_4d80_9b61_a978942fd4f2','','54f9cc7d_8c17_4bd6_bc8d_89737b749e55'),
    ('369f3fb4_760a_4f5e_82c9_5b4a188cadd0',1,'None','','e6477f8e_2bcd_48e7_8fb0_fe3a32e12195','','c488a2e7_119b_48a9_b20a_deb1fb18d6da'),
    ('bbaa5944_b022_4c98_9dac_32d709bd846a',1,'None','','6769fc69_f5b1_468f_b835_0d3034ed940d','','a3225624_6be5_48b1_9241_c372cb581eec'),
    ('c5695eab_0bec_45ab_ba33_e82869d42c9c',1,'None','','41f08120_3ff9_4d24_bb0b_ec83e32ad5c7','','6a471e5e_6284_422a_96fb_28bdf6750bf9'),
    ('0ec5970d_2dc1_4f66_8d7d_0d25980f8480',1,'None','','05caf1c3_32ed_4302_a02e_e8675d3f3366','','dd924751_73dc_4244_89e9_150c6961f8ab'),
    ('fa5e0166_df70_4aa9_bf99_0182899566d1',1,'None','','e43ca420_9fcf_4db9_ae0f_e06fa2da180c','','a746a89a_6f6b_4dde_818b_a22e6fee8c2b'),
    ('7ab78a69_ac29_492a_a609_6006dabb4974',1,'None','','c52ce3e5_e612_4484_a6e4_64d542c50b98','','5418c977_2a51_42c5_ba52_e11559cd49e3'),
    ('fbc2e49c_8bae_4baf_9faa_eafa69ee2c13',1,'None','','90e0a97f_92ed_4898_992d_87dfacb94987','','5d2667bb_acf1_45eb_832d_46dca0490e77'),
    ('fae315ad_faf9_46f7_b302_6cf1aeef0c12',1,'None','','1674e7ec_9ae8_4d26_a96a_74a1b171b6da','','fda97311_7438_4aa7_9147_022348487619');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip_country,page,session,time,quarter,anon_screen_name,downtime_for,student_id,instructor_id,course_id,course_display_name,resource_display_name,organization,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,mode,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    ('51d00999_b559_41e3_b2a0_cc3cf47317a0','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','202ed25a_d1b0_4b5d_8bae_57933fc27b8e','27f4e317_0be2_4034_9ea8_072c6194c33a','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('82504faf_ff4c_4825_89e9_7dc03c797840','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','67450fae_6f5f_4300_b695_56efab4c71b7','3c9654ba_f87e_4919_9e07_499d0b1c8b4c','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('c3c5162c_07f7_419e_ae08_bd94ba961f41','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','51f9d29c_9d52_449d_9f94_411b2a5567ba','da7e5b57_a76d_430b_8a16_b323fec01489','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('7b5e94b7_f3bb_472f_959e_89c6cd44ec61','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','96795008_9654_4b35_bdc3_73a0622cd6ce','f6e9cc67_66fd_4c15_979a_1ee531f10741','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('8d67952b_5278_4e3d_86f3_f3e95ad6ed9e','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','d375f99b_67d5_45c4_b434_e53307cab6c3','c7d43676_b75e_4f64_8c8b_80fab132bce6','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('0f4209ad_336e_43c9_a559_5da174823f12','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','bd9d73b8_d37b_424c_97ed_e15cd375922f','eeccf402_875c_40ad_a6ab_77996fb1de22','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('b181be8b_424d_4c4e_90b3_946b3af36d5d','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','0ce362e8_f2fb_4b92_a2d6_41a136ae68cd','af4f47d5_8732_44b0_8eb8_25a98c60603d','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('90016a50_a489_4775_ad55_a0130ad0390e','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','7b18adf6_e9ca_4a04_9b34_3f49934d1180','d04a74f2_767f_4f28_9fa2_f99f37ca7d47','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('69167f92_be4e_4da1_84fe_54ae0eaa233b','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','9fafee7d_2720_43cc_9405_01d2da4ed42a','61822509_58ba_44e2_9750_5d8fcd3205dd','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('ea1dd987_31b0_467b_b382_f5d45553bab7','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','f1f6009d_ff28_45ab_aa7a_b3160caffdcb','9d0fc250_97fa_458c_9ce2_b2cd61d82bf9','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('57f552bc_f80d_44da_a410_959a46186b25','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','89b8e921_06ba_4aaa_86fe_e4fd05d1e9b4','369f3fb4_760a_4f5e_82c9_5b4a188cadd0','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('c9ba6a71_fa57_4548_8f1d_f906930dd3eb','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','dca5ce02_680d_4495_9364_076df65fc63c','bbaa5944_b022_4c98_9dac_32d709bd846a','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('c062df3b_1c4d_4a9c_b8ad_ac235885f88f','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','19b25891_8aa3_4afc_8b4c_a01d85fd0cf5','c5695eab_0bec_45ab_ba33_e82869d42c9c','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('57eccb3b_720f_43af_9ccf_b53c00e14e4d','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','43d75fcd_7ee1_4305_b439_5e1bbc4dde7f','0ec5970d_2dc1_4f66_8d7d_0d25980f8480','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('536677f2_eaaf_4902_9c55_cd9005f52563','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','555db354_c28e_4f69_b7e9_00709120b7e1','fa5e0166_df70_4aa9_bf99_0182899566d1','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('f26ec0f0_f0a0_41de_9a6b_efaf52549162','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','8ae77cff_3fb7_46dd_919b_1b2482e55e62','7ab78a69_ac29_492a_a609_6006dabb4974','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('8828ef61_eac0_492e_99ec_83f7e1e613fa','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','ff0e5751_2f4d_4ddf_9a27_7cac41b8a894','fbc2e49c_8bae_4baf_9faa_eafa69ee2c13','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('a39aec4d_9ee6_45b4_9086_218f08d2988f','c02176ed_7f6f_469d_ade4_374a1ba74b68','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','summer2013','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','3e8acc42_7f2b_47ff_931e_626426d17892','fae315ad_faf9_46f7_b302_6cf1aeef0c12','f963629c7f493c4931394fd4861c859e588b8a11');
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
