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
    year_of_birth TINYINT NOT NULL,
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
    year_of_birth TINYINT NOT NULL,
    level_of_education VARCHAR(255) NOT NULL,
    goals TEXT NOT NULL,
    honor_code TINYINT NOT NULL,
    terms_of_service TINYINT NOT NULL,
    course_id TEXT NOT NULL,
    enrollment_action VARCHAR(255) NOT NULL,
    email TEXT NOT NULL,
    receive_emails VARCHAR(255) NOT NULL
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
    ip VARCHAR(255) NOT NULL,
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
    hintmode VARCHAR(255) NOT NULL,
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
    load_info_fk INT NOT NULL,
    FOREIGN KEY(correctMap_fk) REFERENCES CorrectMap(correct_map_id) ON DELETE CASCADE,
    FOREIGN KEY(answer_fk) REFERENCES Answer(answer_id) ON DELETE CASCADE,
    FOREIGN KEY(state_fk) REFERENCES State(state_id) ON DELETE CASCADE,
    FOREIGN KEY(load_info_fk) REFERENCES LoadInfo(load_info_id) ON DELETE CASCADE
    ) ENGINE=MyISAM;
LOCK TABLES `EdxTrackEvent` WRITE, `State` WRITE, `InputState` WRITE, `Answer` WRITE, `CorrectMap` WRITE, `LoadInfo` WRITE, `Account` WRITE;
/*!40000 ALTER TABLE `EdxTrackEvent` DISABLE KEYS */;
/*!40000 ALTER TABLE `State` DISABLE KEYS */;
/*!40000 ALTER TABLE `InputState` DISABLE KEYS */;
/*!40000 ALTER TABLE `Answer` DISABLE KEYS */;
/*!40000 ALTER TABLE `CorrectMap` DISABLE KEYS */;
/*!40000 ALTER TABLE `LoadInfo` DISABLE KEYS */;
/*!40000 ALTER TABLE `Account` DISABLE KEYS */;
INSERT INTO LoadInfo (load_info_id,load_date_time,load_file) VALUES 
    ('cc49617c_302a_41e7_9ac2_a81885892c75','2013120302351386066929','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/problemCheckFailTest.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('40b4ad0e_d41e_45c8_89eb_4f8813c392c2','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('24447dc5_11c1_45ea_9592_28b38759a5de','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('0ceae2f6_1d62_4564_a75a_e58622234019','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('c8033ce6_39cb_478e_abf2_5e09703ca7a7','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('0a2b86d4_88c0_4120_88d6_45010c485ee6','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('a3162744_251a_4aad_b54e_f59518ed1bbd','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('7fda172c_16ba_42c7_82a7_7e3621977d5a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('84f808ec_9669_4e07_a45f_b65707a8633d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258'),
    ('17379960_0705_42c8_8637_ef2c0f0a7e11','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('56d39e9b_b25d_41e0_823e_56534ce90a83','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('f1096c4c_448d_42f6_8e58_a7ca8b20b78d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('2a51163a_7f24_4284_a1d9_a74a03f2f5eb','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('accc09c9_b6e2_4f9f_b22a_a31ebc7dc9f3','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('81830b6b_2eec_4cf5_9c96_5940811877c8','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('b2f6d49f_bff0_4dd4_8a37_9ab05e884aca','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('7edb4ebb_0949_404c_b37e_706c63ca743e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('d21365eb_016d_4d7a_a4cd_451a70eb5e48','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','correct',-1,'','','',''),
    ('98c9ca92_706e_4d15_80cb_57defad7cb61','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','correct',-1,'','','',''),
    ('cfd8bd27_0554_42c3_8940_8a203666e242','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','correct',-1,'','','',''),
    ('290bf593_0888_4dcc_a783_965f90b54c16','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','correct',-1,'','','',''),
    ('e5e31f33_f622_4160_9eea_a5ac0853d8bd','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','incorrect',-1,'','','',''),
    ('d5a85079_6336_4f0a_831f_6c8d58f67dba','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','correct',-1,'','','',''),
    ('917adac9_6b2d_4649_b252_620eeb924d7d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','correct',-1,'','','',''),
    ('66211257_4e36_4b53_91ab_3e574d3206b9','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','incorrect',-1,'','','','');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('24de66c5_c3ce_466d_a174_ca4aae5ae118','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',''),
    ('70ab6820_351c_4541_b90f_4739f75629ab','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',''),
    ('b8dbd4ff_5da7_42ff_b3cb_4473eb3805e3','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',''),
    ('5b45c5ab_e834_458b_a766_46a9e9ba8786','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',''),
    ('e80a97d9_5a93_449e_bc59_a97dc5cfbc61','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',''),
    ('efe20627_ef9d_46c7_a07d_1f0d509cdb55','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',''),
    ('2c079ef9_389e_4bed_90b9_e6170080fa44','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',''),
    ('c5f220da_4de9_4701_9893_43eb5568ec91','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('c7a82eca_f7b3_4f94_9442_a448247ee4a2',1,'True','','17379960_0705_42c8_8637_ef2c0f0a7e11','d21365eb_016d_4d7a_a4cd_451a70eb5e48','24de66c5_c3ce_466d_a174_ca4aae5ae118'),
    ('b7f316c4_73e8_42d8_8447_dbbce9efe45f',1,'True','','56d39e9b_b25d_41e0_823e_56534ce90a83','98c9ca92_706e_4d15_80cb_57defad7cb61','70ab6820_351c_4541_b90f_4739f75629ab'),
    ('1dac5d06_0a27_44cb_bf26_935b00e65e7a',1,'True','','f1096c4c_448d_42f6_8e58_a7ca8b20b78d','cfd8bd27_0554_42c3_8940_8a203666e242','b8dbd4ff_5da7_42ff_b3cb_4473eb3805e3'),
    ('6b5af293_8580_479b_994e_8109a144cc84',1,'True','','2a51163a_7f24_4284_a1d9_a74a03f2f5eb','290bf593_0888_4dcc_a783_965f90b54c16','5b45c5ab_e834_458b_a766_46a9e9ba8786'),
    ('de596103_23df_4ffe_a42f_55ab27ca8d96',1,'True','','accc09c9_b6e2_4f9f_b22a_a31ebc7dc9f3','e5e31f33_f622_4160_9eea_a5ac0853d8bd','e80a97d9_5a93_449e_bc59_a97dc5cfbc61'),
    ('ab69fd41_08a5_4137_85ae_dfe11d374018',1,'True','','81830b6b_2eec_4cf5_9c96_5940811877c8','d5a85079_6336_4f0a_831f_6c8d58f67dba','efe20627_ef9d_46c7_a07d_1f0d509cdb55'),
    ('7cbc22fc_ceae_4b8c_b93a_a3768ce4ebfe',1,'True','','b2f6d49f_bff0_4dd4_8a37_9ab05e884aca','917adac9_6b2d_4649_b252_620eeb924d7d','2c079ef9_389e_4bed_90b9_e6170080fa44'),
    ('2921ec2b_1e03_4668_ad82_fc36d54c3b5d',1,'True','','7edb4ebb_0949_404c_b37e_706c63ca743e','66211257_4e36_4b53_91ab_3e574d3206b9','c5f220da_4de9_4701_9893_43eb5568ec91');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,anon_screen_name,downtime_for,student_id,instructor_id,course_id,course_display_name,resource_display_name,organization,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    ('61866918_0cbe_40b1_9a15_4e046108be2c','ac41cea2_9b82_4d28_9c69_3d0bca7025e2','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','40b4ad0e_d41e_45c8_89eb_4f8813c392c2','c7a82eca_f7b3_4f94_9442_a448247ee4a2','cc49617c_302a_41e7_9ac2_a81885892c75'),
    ('0133acd1_a506_43de_9ccd_04466c9c6ef6','ac41cea2_9b82_4d28_9c69_3d0bca7025e2','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','24447dc5_11c1_45ea_9592_28b38759a5de','b7f316c4_73e8_42d8_8447_dbbce9efe45f','cc49617c_302a_41e7_9ac2_a81885892c75'),
    ('1d1c60e7_78a0_4265_91fc_a14bc58a4cc7','ac41cea2_9b82_4d28_9c69_3d0bca7025e2','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','0ceae2f6_1d62_4564_a75a_e58622234019','1dac5d06_0a27_44cb_bf26_935b00e65e7a','cc49617c_302a_41e7_9ac2_a81885892c75'),
    ('fc4dcf1e_4e27_4421_bbb6_794d777dacd6','ac41cea2_9b82_4d28_9c69_3d0bca7025e2','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','c8033ce6_39cb_478e_abf2_5e09703ca7a7','6b5af293_8580_479b_994e_8109a144cc84','cc49617c_302a_41e7_9ac2_a81885892c75'),
    ('694649ae_3633_4f93_bf16_fd6e1d1b95e5','ac41cea2_9b82_4d28_9c69_3d0bca7025e2','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','0a2b86d4_88c0_4120_88d6_45010c485ee6','de596103_23df_4ffe_a42f_55ab27ca8d96','cc49617c_302a_41e7_9ac2_a81885892c75'),
    ('5c5e6fdc_1de4_42d2_a795_85b7bd0b277e','ac41cea2_9b82_4d28_9c69_3d0bca7025e2','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','a3162744_251a_4aad_b54e_f59518ed1bbd','ab69fd41_08a5_4137_85ae_dfe11d374018','cc49617c_302a_41e7_9ac2_a81885892c75'),
    ('51b5e730_270c_41f7_89e5_fccae5bb53a4','ac41cea2_9b82_4d28_9c69_3d0bca7025e2','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','7fda172c_16ba_42c7_82a7_7e3621977d5a','7cbc22fc_ceae_4b8c_b93a_a3768ce4ebfe','cc49617c_302a_41e7_9ac2_a81885892c75'),
    ('52b41ca3_eb03_487c_8631_23f3ac33184c','ac41cea2_9b82_4d28_9c69_3d0bca7025e2','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','84f808ec_9669_4e07_a45f_b65707a8633d','2921ec2b_1e03_4668_ad82_fc36d54c3b5d','cc49617c_302a_41e7_9ac2_a81885892c75'),
    ('06377e1f_ad9a_4d5a_87a8_38686bf539d1','ac41cea2_9b82_4d28_9c69_3d0bca7025e2','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','28179e16fa4410d45fd155d1b8ce5c6542392975','0:00:00','','','Medicine-HRP258','','Unit 6 Homework','','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','84f808ec_9669_4e07_a45f_b65707a8633d','2921ec2b_1e03_4668_ad82_fc36d54c3b5d','cc49617c_302a_41e7_9ac2_a81885892c75');
/*!40000 ALTER TABLE `EdxTrackEvent` ENABLE KEYS */;
/*!40000 ALTER TABLE `State` ENABLE KEYS */;
/*!40000 ALTER TABLE `InputState` ENABLE KEYS */;
/*!40000 ALTER TABLE `Answer` ENABLE KEYS */;
/*!40000 ALTER TABLE `CorrectMap` ENABLE KEYS */;
/*!40000 ALTER TABLE `LoadInfo` ENABLE KEYS */;
/*!40000 ALTER TABLE `Account` ENABLE KEYS */;
UNLOCK TABLES;
INSERT INTO EdxPrivate.Account (account_id,screen_name,name,anon_screen_name,mailing_address,zipcode,country,gender,year_of_birth,level_of_education,goals,honor_code,terms_of_service,course_id,enrollment_action,email,receive_emails) SELECT account_id,screen_name,name,anon_screen_name,mailing_address,zipcode,country,gender,year_of_birth,level_of_education,goals,honor_code,terms_of_service,course_id,enrollment_action,email,receive_emails FROM Edx.Account;
DROP TABLE Edx.Account;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
