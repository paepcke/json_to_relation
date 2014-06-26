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
DROP TABLE IF EXISTS EdxTrackEvent, Answer, InputState, CorrectMap, State, Account, EdxPrivate.Account, LoadInfo;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS Answer (
    answer_id VARCHAR(40) NOT NULL PRIMARY KEY,
    problem_id VARCHAR(255) NOT NULL,
    answer TEXT NOT NULL,
    course_id VARCHAR(255) NOT NULL
    ) ENGINE=MyISAM;
CREATE TABLE IF NOT EXISTS CorrectMap (
    correct_map_id VARCHAR(40) NOT NULL PRIMARY KEY,
    answer_identifier TEXT NOT NULL,
    correctness VARCHAR(255) NOT NULL,
    npoints INT NOT NULL,
    msg TEXT NOT NULL,
    hint TEXT NOT NULL,
    hintmode VARCHAR(255) NOT NULL,
    queuestate TEXT NOT NULL
    ) ENGINE=MyISAM;
CREATE TABLE IF NOT EXISTS InputState (
    input_state_id VARCHAR(40) NOT NULL PRIMARY KEY,
    problem_id VARCHAR(255) NOT NULL,
    state TEXT NOT NULL
    ) ENGINE=MyISAM;
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
    ) ENGINE=MyISAM;
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
    ) ENGINE=MyISAM;
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
    ) ENGINE=MyISAM;
CREATE TABLE IF NOT EXISTS EventIp (
    event_table_id VARCHAR(40) NOT NULL PRIMARY KEY,
    event_ip VARCHAR(255) NOT NULL
    ) ENGINE=MyISAM;
CREATE TABLE IF NOT EXISTS EdxPrivate.EventIp (
    event_table_id VARCHAR(40) NOT NULL PRIMARY KEY,
    event_ip VARCHAR(255) NOT NULL
    ) ENGINE=MyISAM;
CREATE TABLE IF NOT EXISTS ABExperiment (
    event_table_id VARCHAR(40) NOT NULL PRIMARY KEY,
    event_type VARCHAR(255) NOT NULL,
    group_id INT NOT NULL,
    group_name VARCHAR(255) NOT NULL,
    partition_id INT NOT NULL,
    partition_name VARCHAR(255) NOT NULL,
    child_module_id VARCHAR(255) NOT NULL
    ) ENGINE=MyISAM;
CREATE TABLE IF NOT EXISTS LoadInfo (
    load_info_id VARCHAR(40) NOT NULL PRIMARY KEY,
    load_date_time DATETIME NOT NULL,
    load_file TEXT NOT NULL
    ) ENGINE=MyISAM;
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
    load_info_fk VARCHAR(40) NOT NULL,
    FOREIGN KEY(correctMap_fk) REFERENCES CorrectMap(correct_map_id) ON DELETE CASCADE,
    FOREIGN KEY(answer_fk) REFERENCES Answer(answer_id) ON DELETE CASCADE,
    FOREIGN KEY(state_fk) REFERENCES State(state_id) ON DELETE CASCADE,
    FOREIGN KEY(load_info_fk) REFERENCES LoadInfo(load_info_id) ON DELETE CASCADE
    ) ENGINE=MyISAM;
LOCK TABLES `EdxTrackEvent` WRITE, `State` WRITE, `InputState` WRITE, `Answer` WRITE, `CorrectMap` WRITE, `LoadInfo` WRITE, `Account` WRITE, `EventIp` WRITE, `ABExperiment` WRITE;
/*!40000 ALTER TABLE `EdxTrackEvent` DISABLE KEYS */;
/*!40000 ALTER TABLE `State` DISABLE KEYS */;
/*!40000 ALTER TABLE `InputState` DISABLE KEYS */;
/*!40000 ALTER TABLE `Answer` DISABLE KEYS */;
/*!40000 ALTER TABLE `CorrectMap` DISABLE KEYS */;
/*!40000 ALTER TABLE `LoadInfo` DISABLE KEYS */;
/*!40000 ALTER TABLE `Account` DISABLE KEYS */;
/*!40000 ALTER TABLE `EventIp` DISABLE KEYS */;
/*!40000 ALTER TABLE `ABExperiment` DISABLE KEYS */;
INSERT INTO LoadInfo (load_info_id,load_date_time,load_file) VALUES 
    ('f963629c7f493c4931394fd4861c859e588b8a11','2014-06-25T11:29:48.024298','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/saveProblemCheck.json');
INSERT INTO EventIp (event_table_id,event_ip) VALUES 
    ('6a71cfdf_cb54_4d01_afc7_ce35eb022497','147.32.84.59');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('993ed9d0_79b4_460f_9de6_442f909d981e','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('38250b45_cb9b_4b4c_bd15_9556ac0b3f9d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('cab0009c_f2fd_49cb_87c5_17a755b24f67','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('79b51f35_4f20_4e9b_8ba5_b60ffa19041d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('7fd6de1e_63b1_4df1_abbd_b997350e9fbc','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('9808573a_4e2b_41bc_9182_77706215f585','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('a3cf0ba3_ee97_4648_be5d_ddfe685ddd47','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('73eef073_3c49_408e_823d_024dd9bf9b5b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('567d56d6_a85a_47f1_bfba_ebcda0d062e8','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('70ea8c14_f179_4f97_96f6_58e4c45efee7','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('88b62621_d22c_40b9_9c0e_7b42e7d9c336','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('96fd53d8_df50_4cd9_b710_a6373a64083d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('b609c6db_6a30_482a_8de1_bfa65b5814e5','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('1802d572_a83a_4bf9_b839_19ef8712a984','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('38cd7eda_f15f_4fd6_9087_331834be7e72','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('5c2f01d6_0249_4519_b2de_d0047b12b8e0','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('c6483d5f_a3c9_4285_a962_ca19a78e608a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('ab7d1304_6882_47d3_8219_92650f9a20e0','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258'),
    ('a2712983_fb95_472f_88c2_159aabcaa35a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('84508a7e_36b3_4f66_a12e_193cf1c50151','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('6aca4062_61c7_4bef_99b5_a0d265f2c8fd','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('883b42ab_427a_436e_810c_ba7ce459a4d5','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('8e8313bb_5d57_4f13_bb90_ecb4f3681fef','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('c7d59946_4be0_4d79_9aa9_04c8bd88db63','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('d4e8ed09_28bf_42b6_a442_b4ec705d6df4','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('6831f551_3244_4eeb_b3ce_ab819bfeff8b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('db345ee8_47b4_4bae_a700_c22a7e43fd2b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('d55d8e79_6c0f_4e18_98e5_5da956456c1a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('6c3f4113_98ad_480b_9275_5014a7e21477','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('3c4b7e95_e59c_4096_bbae_701ee75a7aa8','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('6eaaed43_8f5c_4f5e_b430_b5fba843dad1','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('df54bd96_7294_4261_95be_3577421d7d49','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('b2bb49cd_eb24_43f5_a710_d13dc21eba16','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('9ffb8ffb_a888_421a_8978_8bb7dd9742b6','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('e4501541_9167_4ab9_b5ae_3f3eb243f4b5','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('8bb6b7e2_d59d_4e4c_b017_e55b65f3b078','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('ef70531f_2e73_43ff_91c5_0fdac766bb9d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1',''),
    ('73c9314d_6f96_43b6_a07c_8fbd0cbb02b2','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1',''),
    ('af9342f8_e56e_47af_8c55_a903c4c94dd5','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1',''),
    ('37ad5112_28e8_48aa_8604_fc66cc7cf2d6','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1',''),
    ('42163f08_4426_49a1_8fc1_cb0d20082d2c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1',''),
    ('0f60eee6_14a8_41fd_81b4_3f79cdcbd18c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1',''),
    ('e58a1c06_e7f2_4fe3_b45c_16ac7527b3d8','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1',''),
    ('0a997779_f9fb_4534_80b1_6a7aaac9b42d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1',''),
    ('5433dc1c_05a4_427f_94af_b122a14181b7','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1',''),
    ('cd04a252_2b88_41b6_b38f_3ca87ce0260e','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1',''),
    ('b0bfb88c_2e14_47fa_a62c_3d765369e258','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1',''),
    ('ef6c510f_cc02_406a_aaae_2047a7b93e39','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1',''),
    ('0bda6f8c_47f0_4ded_9aec_d0ffb11f11ad','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1',''),
    ('9c2d6fb4_9ec0_43bb_ae43_50fd44431b36','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1',''),
    ('e6332831_53c7_49de_9d20_b014553bb9b3','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1',''),
    ('0f6e31bc_9850_4039_9754_a21124382615','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1',''),
    ('6f9f6748_9d6c_480a_bdee_4dd8bc4f3b13','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1',''),
    ('471a40f5_b5cf_44af_a692_df8ed30eaa87','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('c9caa87d_ac22_4675_92cc_4f75eb4030a8',1,'None','','a2712983_fb95_472f_88c2_159aabcaa35a','','ef70531f_2e73_43ff_91c5_0fdac766bb9d'),
    ('92b3744e_a5ba_467a_a300_e006d244af15',1,'None','','84508a7e_36b3_4f66_a12e_193cf1c50151','','73c9314d_6f96_43b6_a07c_8fbd0cbb02b2'),
    ('e5b96de7_69a4_401a_94a7_82fa80594bdb',1,'None','','6aca4062_61c7_4bef_99b5_a0d265f2c8fd','','af9342f8_e56e_47af_8c55_a903c4c94dd5'),
    ('40085635_4958_44cd_af9b_918a22198e9d',1,'None','','883b42ab_427a_436e_810c_ba7ce459a4d5','','37ad5112_28e8_48aa_8604_fc66cc7cf2d6'),
    ('32f5248f_3430_4091_ad87_ad6e3d8ae4b9',1,'None','','8e8313bb_5d57_4f13_bb90_ecb4f3681fef','','42163f08_4426_49a1_8fc1_cb0d20082d2c'),
    ('5297e2b5_98fa_4b39_8624_c2579f375299',1,'None','','c7d59946_4be0_4d79_9aa9_04c8bd88db63','','0f60eee6_14a8_41fd_81b4_3f79cdcbd18c'),
    ('92b8cf24_7e97_4901_8734_c8904cbea4ec',1,'None','','d4e8ed09_28bf_42b6_a442_b4ec705d6df4','','e58a1c06_e7f2_4fe3_b45c_16ac7527b3d8'),
    ('04904a73_b969_426b_8e25_458a49c2d216',1,'None','','6831f551_3244_4eeb_b3ce_ab819bfeff8b','','0a997779_f9fb_4534_80b1_6a7aaac9b42d'),
    ('9743356b_12d4_4447_a597_6aec7503be19',1,'None','','db345ee8_47b4_4bae_a700_c22a7e43fd2b','','5433dc1c_05a4_427f_94af_b122a14181b7'),
    ('69bc68b0_0f88_4974_8a7a_fd99c27201a6',1,'None','','d55d8e79_6c0f_4e18_98e5_5da956456c1a','','cd04a252_2b88_41b6_b38f_3ca87ce0260e'),
    ('faa50709_b777_43a4_b63f_6a1548297fd2',1,'None','','6c3f4113_98ad_480b_9275_5014a7e21477','','b0bfb88c_2e14_47fa_a62c_3d765369e258'),
    ('444ae2c3_5b23_4f7e_a09b_4391071bb2ad',1,'None','','3c4b7e95_e59c_4096_bbae_701ee75a7aa8','','ef6c510f_cc02_406a_aaae_2047a7b93e39'),
    ('6ae1825a_aad2_46c3_9410_8918d45eaa3f',1,'None','','6eaaed43_8f5c_4f5e_b430_b5fba843dad1','','0bda6f8c_47f0_4ded_9aec_d0ffb11f11ad'),
    ('400352d6_6248_4d76_9ed4_ebf1ed4c0900',1,'None','','df54bd96_7294_4261_95be_3577421d7d49','','9c2d6fb4_9ec0_43bb_ae43_50fd44431b36'),
    ('e0e60827_259f_43ab_bd1a_6d5d59fcbc4b',1,'None','','b2bb49cd_eb24_43f5_a710_d13dc21eba16','','e6332831_53c7_49de_9d20_b014553bb9b3'),
    ('807c4db2_8074_48f0_8a44_1745ce427a0e',1,'None','','9ffb8ffb_a888_421a_8978_8bb7dd9742b6','','0f6e31bc_9850_4039_9754_a21124382615'),
    ('05a3c2ed_473c_4d1e_9ada_8c6f7914f765',1,'None','','e4501541_9167_4ab9_b5ae_3f3eb243f4b5','','6f9f6748_9d6c_480a_bdee_4dd8bc4f3b13'),
    ('2ad58878_2e72_4249_8dae_46960d7e65c9',1,'None','','8bb6b7e2_d59d_4e4c_b017_e55b65f3b078','','471a40f5_b5cf_44af_a692_df8ed30eaa87');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip_country,page,session,time,anon_screen_name,downtime_for,student_id,instructor_id,course_id,course_display_name,resource_display_name,organization,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,mode,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    ('6a71cfdf_cb54_4d01_afc7_ce35eb022497','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','993ed9d0_79b4_460f_9de6_442f909d981e','c9caa87d_ac22_4675_92cc_4f75eb4030a8','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('48276ce4_19fb_49a3_b5ea_5846bca66f2f','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','38250b45_cb9b_4b4c_bd15_9556ac0b3f9d','92b3744e_a5ba_467a_a300_e006d244af15','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('0a426f1d_594a_4ff5_832a_fa42c4fdabf5','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','cab0009c_f2fd_49cb_87c5_17a755b24f67','e5b96de7_69a4_401a_94a7_82fa80594bdb','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('31666c2b_1da6_433e_b772_98339f370a82','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','79b51f35_4f20_4e9b_8ba5_b60ffa19041d','40085635_4958_44cd_af9b_918a22198e9d','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('b698a4b7_b39b_4c85_99af_1c73aff9ef2a','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','7fd6de1e_63b1_4df1_abbd_b997350e9fbc','32f5248f_3430_4091_ad87_ad6e3d8ae4b9','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('cf02ed37_737d_4733_bb2d_a700ad330fd7','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','9808573a_4e2b_41bc_9182_77706215f585','5297e2b5_98fa_4b39_8624_c2579f375299','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('068dc624_efc4_4e57_9d62_a8bcc8b1a95f','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','a3cf0ba3_ee97_4648_be5d_ddfe685ddd47','92b8cf24_7e97_4901_8734_c8904cbea4ec','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('ae79f9d7_2d13_48a7_9234_b0857f4c7582','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','73eef073_3c49_408e_823d_024dd9bf9b5b','04904a73_b969_426b_8e25_458a49c2d216','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('853311ff_698d_422b_a0cc_31c561ac39cc','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','567d56d6_a85a_47f1_bfba_ebcda0d062e8','9743356b_12d4_4447_a597_6aec7503be19','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('8a9ee337_2f08_430e_bfec_6802c4872704','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','70ea8c14_f179_4f97_96f6_58e4c45efee7','69bc68b0_0f88_4974_8a7a_fd99c27201a6','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('b3a8ecea_f42a_499a_b05f_826e96bf69b5','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','88b62621_d22c_40b9_9c0e_7b42e7d9c336','faa50709_b777_43a4_b63f_6a1548297fd2','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('c44443f6_c925_4311_9ff9_05964ed37a44','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','96fd53d8_df50_4cd9_b710_a6373a64083d','444ae2c3_5b23_4f7e_a09b_4391071bb2ad','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('9c655d71_1630_4da9_be81_efb1fd7df579','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','b609c6db_6a30_482a_8de1_bfa65b5814e5','6ae1825a_aad2_46c3_9410_8918d45eaa3f','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('9d9b0781_f1c6_49d0_af85_a5a000be9a9f','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','1802d572_a83a_4bf9_b839_19ef8712a984','400352d6_6248_4d76_9ed4_ebf1ed4c0900','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('f3c474e4_5ebb_4379_8001_db3f76ca14a3','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','38cd7eda_f15f_4fd6_9087_331834be7e72','e0e60827_259f_43ab_bd1a_6d5d59fcbc4b','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('b60b4910_012e_421c_b29f_faab109022f2','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','5c2f01d6_0249_4519_b2de_d0047b12b8e0','807c4db2_8074_48f0_8a44_1745ce427a0e','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('a9e67736_5155_47a4_ba8a_bfdb2cae575e','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','c6483d5f_a3c9_4285_a962_ca19a78e608a','05a3c2ed_473c_4d1e_9ada_8c6f7914f765','f963629c7f493c4931394fd4861c859e588b8a11'),
    ('fb6a319b_22b7_4fd5_96dd_0ac6c197bfbd','c480d095_5874_4e0b_a62d_f123eed219d9','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','CZE','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','ab7d1304_6882_47d3_8219_92650f9a20e0','2ad58878_2e72_4249_8dae_46960d7e65c9','f963629c7f493c4931394fd4861c859e588b8a11');
-- /*!40000 ALTER TABLE `EdxTrackEvent` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `State` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `InputState` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `Answer` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `CorrectMap` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `LoadInfo` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `Account` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `EventIp` ENABLE KEYS */;
-- /*!40000 ALTER TABLE `ABExperiment` ENABLE KEYS */;
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
