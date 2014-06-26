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
    ('7d22294395ada5d968b9d386209b8d79e95c78a3','2014-06-25T11:29:33.327867','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/problemCheckFailTest.json');
INSERT INTO EventIp (event_table_id,event_ip) VALUES 
    ('f25362b2_d832_4451_a93d_cd6a11869afc','58.108.173.32');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('69623abf_6e1b_4abc_8f57_d72c0dce22ef','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('d73f9efe_bfbf_4fb9_9751_66fd1afd57b0','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('627c01f8_5a7f_4372_8022_425e9e0be015','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('f313b02a_1721_43a6_98a8_7b44fb5cac7d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('1ee682a2_b64b_4148_b101_622c0e5a4594','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('b30add8e_d465_44cc_bcb2_4a616fbdf89a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('f34cd008_5629_4082_9aec_ae8eda7cd615','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('7d0f9e48_bf73_4c35_84e0_e17a4bacca96','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258'),
    ('7682ea91_097a_4d7b_a367_e1a58b507446','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('b4b9ca4e_b9cb_4dad_93c0_0a5ac98ea679','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('fadb5531_d775_4813_8bf9_07762a3c01c1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('cc14bbbe_2b8c_4167_841c_e6cdebcb9f82','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('176f9bbb_a363_4314_9614_5dd8820dee0f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('047fd3e8_a2a4_4f6a_ad08_6493e6fa3ebd','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('e36e73fd_c840_40d3_83b7_e366438ed9e6','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('153820d8_08b4_45b9_b08c_c1830a78aeac','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('89ecc1ee_ccf8_41bf_94cb_455d3141a9e4','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','correct',-1,'','','',''),
    ('1127ace6_1e5c_45ec_979d_5c1eced19797','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','correct',-1,'','','',''),
    ('a286c462_94b6_47b1_b2b9_a332e4c9b51d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','correct',-1,'','','',''),
    ('3e7f254d_bd63_448c_9691_cb6d29083871','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','correct',-1,'','','',''),
    ('1166bbff_f78f_4a21_889d_7efa0de2aa06','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','incorrect',-1,'','','',''),
    ('c03830fa_2b0d_41ea_8efa_c5bea049b79c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','correct',-1,'','','',''),
    ('6d36cfa0_553d_4c3f_b028_94b519b913a8','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','correct',-1,'','','',''),
    ('3d555051_5375_4d1c_a930_c5db688f570b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','incorrect',-1,'','','','');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('9b39d7af_15d1_4be8_b62c_33f25a1bd091','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',''),
    ('57ca5901_7c56_4cc4_8fb8_d112667b7b6e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',''),
    ('7a03f671_a3df_4b60_920f_324b9ed1c199','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',''),
    ('c77b5ece_cb62_4e85_9499_72bc5547cd11','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',''),
    ('077490f4_de0e_41a1_8795_5123a99c257b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',''),
    ('c7d664c1_2adf_4381_a01d_2499e5c75013','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',''),
    ('8f60a464_63e4_42fb_8795_84d074a4f560','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',''),
    ('51520f3d_b600_4774_95f3_7acf64e4e76f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('c3be55c9_3a07_455e_953e_c059b0bacf1c',1,'True','','7682ea91_097a_4d7b_a367_e1a58b507446','89ecc1ee_ccf8_41bf_94cb_455d3141a9e4','9b39d7af_15d1_4be8_b62c_33f25a1bd091'),
    ('340d6676_d3d7_46d9_8851_4e7e44419dc2',1,'True','','b4b9ca4e_b9cb_4dad_93c0_0a5ac98ea679','1127ace6_1e5c_45ec_979d_5c1eced19797','57ca5901_7c56_4cc4_8fb8_d112667b7b6e'),
    ('9ebb7377_3f88_4133_82fa_56291f064426',1,'True','','fadb5531_d775_4813_8bf9_07762a3c01c1','a286c462_94b6_47b1_b2b9_a332e4c9b51d','7a03f671_a3df_4b60_920f_324b9ed1c199'),
    ('2de38efe_9941_496b_9613_f367a757f140',1,'True','','cc14bbbe_2b8c_4167_841c_e6cdebcb9f82','3e7f254d_bd63_448c_9691_cb6d29083871','c77b5ece_cb62_4e85_9499_72bc5547cd11'),
    ('e8bc5256_d3e6_43e3_bb6c_217cf2e7cdb3',1,'True','','176f9bbb_a363_4314_9614_5dd8820dee0f','1166bbff_f78f_4a21_889d_7efa0de2aa06','077490f4_de0e_41a1_8795_5123a99c257b'),
    ('adde9e70_39ee_4792_9893_51cbfaab481e',1,'True','','047fd3e8_a2a4_4f6a_ad08_6493e6fa3ebd','c03830fa_2b0d_41ea_8efa_c5bea049b79c','c7d664c1_2adf_4381_a01d_2499e5c75013'),
    ('e5a3f952_4cb1_4375_8b3b_07b8ec727d9b',1,'True','','e36e73fd_c840_40d3_83b7_e366438ed9e6','6d36cfa0_553d_4c3f_b028_94b519b913a8','8f60a464_63e4_42fb_8795_84d074a4f560'),
    ('ef262a5b_e3c6_43a7_819c_ac45b5b0678e',1,'True','','153820d8_08b4_45b9_b08c_c1830a78aeac','3d555051_5375_4d1c_a930_c5db688f570b','51520f3d_b600_4774_95f3_7acf64e4e76f');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip_country,page,session,time,anon_screen_name,downtime_for,student_id,instructor_id,course_id,course_display_name,resource_display_name,organization,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,mode,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    ('f25362b2_d832_4451_a93d_cd6a11869afc','ba9bdd98_be5a_42c1_ba1e_30edaf4a9571','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','69623abf_6e1b_4abc_8f57_d72c0dce22ef','c3be55c9_3a07_455e_953e_c059b0bacf1c','7d22294395ada5d968b9d386209b8d79e95c78a3'),
    ('6537b2c8_1f5a_4751_9452_4dabeb3f947a','ba9bdd98_be5a_42c1_ba1e_30edaf4a9571','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','d73f9efe_bfbf_4fb9_9751_66fd1afd57b0','340d6676_d3d7_46d9_8851_4e7e44419dc2','7d22294395ada5d968b9d386209b8d79e95c78a3'),
    ('2b1e56e5_ba5b_4863_8a32_320137331695','ba9bdd98_be5a_42c1_ba1e_30edaf4a9571','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','627c01f8_5a7f_4372_8022_425e9e0be015','9ebb7377_3f88_4133_82fa_56291f064426','7d22294395ada5d968b9d386209b8d79e95c78a3'),
    ('71dc9cf8_a82b_4f9b_810a_e40a661e0f7b','ba9bdd98_be5a_42c1_ba1e_30edaf4a9571','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','f313b02a_1721_43a6_98a8_7b44fb5cac7d','2de38efe_9941_496b_9613_f367a757f140','7d22294395ada5d968b9d386209b8d79e95c78a3'),
    ('e354f0ed_a1da_46f3_80f7_1e4b1771415c','ba9bdd98_be5a_42c1_ba1e_30edaf4a9571','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','1ee682a2_b64b_4148_b101_622c0e5a4594','e8bc5256_d3e6_43e3_bb6c_217cf2e7cdb3','7d22294395ada5d968b9d386209b8d79e95c78a3'),
    ('0e43e5c3_43a5_45b5_be1b_645404544e69','ba9bdd98_be5a_42c1_ba1e_30edaf4a9571','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','b30add8e_d465_44cc_bcb2_4a616fbdf89a','adde9e70_39ee_4792_9893_51cbfaab481e','7d22294395ada5d968b9d386209b8d79e95c78a3'),
    ('10323a3d_28b0_4a6c_a7b8_4df4a6ac4e08','ba9bdd98_be5a_42c1_ba1e_30edaf4a9571','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','f34cd008_5629_4082_9aec_ae8eda7cd615','e5a3f952_4cb1_4375_8b3b_07b8ec727d9b','7d22294395ada5d968b9d386209b8d79e95c78a3'),
    ('ca6bb8c0_2663_492d_9b7b_5cc2be4d440d','ba9bdd98_be5a_42c1_ba1e_30edaf4a9571','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','7d0f9e48_bf73_4c35_84e0_e17a4bacca96','ef262a5b_e3c6_43a7_819c_ac45b5b0678e','7d22294395ada5d968b9d386209b8d79e95c78a3'),
    ('847fc130_e28a_4db3_b7ed_3fad8ced329c','ba9bdd98_be5a_42c1_ba1e_30edaf4a9571','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','AUS','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','7d0f9e48_bf73_4c35_84e0_e17a4bacca96','ef262a5b_e3c6_43a7_819c_ac45b5b0678e','7d22294395ada5d968b9d386209b8d79e95c78a3');
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
