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
    problem_id TEXT NOT NULL,
    answer TEXT NOT NULL,
    course_id TEXT NOT NULL
    ) ENGINE=MyISAM;
CREATE TABLE IF NOT EXISTS CorrectMap (
    correct_map_id VARCHAR(40) NOT NULL PRIMARY KEY,
    answer_identifier TEXT NOT NULL,
    correctness TINYTEXT NOT NULL,
    npoints INT NOT NULL,
    msg TEXT NOT NULL,
    hint TEXT NOT NULL,
    hintmode TINYTEXT NOT NULL,
    queuestate TEXT NOT NULL
    ) ENGINE=MyISAM;
CREATE TABLE IF NOT EXISTS InputState (
    input_state_id VARCHAR(40) NOT NULL PRIMARY KEY,
    problem_id TEXT NOT NULL,
    state TEXT NOT NULL
    ) ENGINE=MyISAM;
CREATE TABLE IF NOT EXISTS State (
    state_id VARCHAR(40) NOT NULL PRIMARY KEY,
    seed TINYINT NOT NULL,
    done TINYTEXT NOT NULL,
    problem_id TEXT NOT NULL,
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
    zipcode TINYTEXT NOT NULL,
    country TINYTEXT NOT NULL,
    gender TINYTEXT NOT NULL,
    year_of_birth TINYINT NOT NULL,
    level_of_education TINYTEXT NOT NULL,
    goals TEXT NOT NULL,
    honor_code TINYINT NOT NULL,
    terms_of_service TINYINT NOT NULL,
    course_id TEXT NOT NULL,
    enrollment_action TINYTEXT NOT NULL,
    email TEXT NOT NULL,
    receive_emails TINYTEXT NOT NULL
    ) ENGINE=MyISAM;
CREATE TABLE IF NOT EXISTS EdxPrivate.Account (
    account_id VARCHAR(40) NOT NULL PRIMARY KEY,
    screen_name TEXT NOT NULL,
    name TEXT NOT NULL,
    anon_screen_name TEXT NOT NULL,
    mailing_address TEXT NOT NULL,
    zipcode TINYTEXT NOT NULL,
    country TINYTEXT NOT NULL,
    gender TINYTEXT NOT NULL,
    year_of_birth TINYINT NOT NULL,
    level_of_education TINYTEXT NOT NULL,
    goals TEXT NOT NULL,
    honor_code TINYINT NOT NULL,
    terms_of_service TINYINT NOT NULL,
    course_id TEXT NOT NULL,
    enrollment_action TINYTEXT NOT NULL,
    email TEXT NOT NULL,
    receive_emails TINYTEXT NOT NULL
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
    event_source TINYTEXT NOT NULL,
    event_type TEXT NOT NULL,
    ip TINYTEXT NOT NULL,
    page TEXT NOT NULL,
    session TEXT NOT NULL,
    time DATETIME NOT NULL,
    anon_screen_name TEXT NOT NULL,
    downtime_for DATETIME NOT NULL,
    student_id TEXT NOT NULL,
    instructor_id TEXT NOT NULL,
    course_id TEXT NOT NULL,
    sequence_id TEXT NOT NULL,
    goto_from INT NOT NULL,
    goto_dest INT NOT NULL,
    problem_id TEXT NOT NULL,
    problem_choice TEXT NOT NULL,
    question_location TEXT NOT NULL,
    submission_id TEXT NOT NULL,
    attempts INT NOT NULL,
    long_answer TEXT NOT NULL,
    student_file TEXT NOT NULL,
    can_upload_file TINYTEXT NOT NULL,
    feedback TEXT NOT NULL,
    feedback_response_selected TINYINT NOT NULL,
    transcript_id TEXT NOT NULL,
    transcript_code TINYTEXT NOT NULL,
    rubric_selection INT NOT NULL,
    rubric_category INT NOT NULL,
    video_id TEXT NOT NULL,
    video_code TEXT NOT NULL,
    video_current_time TINYTEXT NOT NULL,
    video_speed TINYTEXT NOT NULL,
    video_old_time TINYTEXT NOT NULL,
    video_new_time TINYTEXT NOT NULL,
    video_seek_type TINYTEXT NOT NULL,
    video_new_speed TINYTEXT NOT NULL,
    video_old_speed TINYTEXT NOT NULL,
    book_interaction_type TINYTEXT NOT NULL,
    success TINYTEXT NOT NULL,
    answer_id TEXT NOT NULL,
    hint TEXT NOT NULL,
    hintmode TINYTEXT NOT NULL,
    correctness TINYTEXT NOT NULL,
    msg TEXT NOT NULL,
    npoints TINYINT NOT NULL,
    queuestate TEXT NOT NULL,
    orig_score INT NOT NULL,
    new_score INT NOT NULL,
    orig_total INT NOT NULL,
    new_total INT NOT NULL,
    event_name TINYTEXT NOT NULL,
    group_user TINYTEXT NOT NULL,
    group_action TINYTEXT NOT NULL,
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
    ('754a3fd9_594e_45e3_9ff2_5fbc1ee53793','2013112917481385776088','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/saveProblemCheck.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('1376860f_03d0_4530_b164_2a8edb8a7be8','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('96e93a72_c9aa_4247_9706_03d12482ad3a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('1007358b_5612_4e75_aeda_43813c4a8589','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('3a7b7433_6ce6_4e06_a03a_a3175ac73ff6','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('b2ee7905_d453_4b75_a622_209dfd7e640b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('6d24cac4_8d2f_4e7f_a035_12020c43b7d1','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('41025d8e_d897_4116_a4ca_90a33d3c0777','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('33b5bbf6_eb44_4cd6_af36_6e720c516e6c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('385a468f_eb10_46bf_9039_8af2fd4c1b58','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('551e294f_b6e6_45ec_966f_8f57e5f644ea','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('901f4b2f_e940_436b_a30e_728cb50d5f6a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('030c77f4_74a4_4fa0_8ab4_b643ff36ee7d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('95dbdb67_cf57_4d7d_96b1_5ff03183a546','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('bd7e1ae5_31de_4805_bb0b_c78445340c4f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('152ae700_3c10_466a_80c9_89e9dc35626f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('4ac2d2e4_c385_4873_8987_f64ea5c533b5','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('c1327718_0b77_4b9f_89db_1346896e5346','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('e932db57_bb09_42ae_8207_ab8bf50a4fb0','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258'),
    ('c1b6e180_bcac_43e0_a3d0_792060bebbc5','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('8b443bc2_4d2f_480f_b671_f49714e73767','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('c7e87247_7a58_439d_b34b_d7f4b55e4c14','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('9c36bf53_d5fc_429e_abd9_93c27e9b4c46','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('5ebbf9b1_8460_42ff_b6b0_35a3477bed12','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('8d00ab3f_7e8f_4859_964f_cf1f5d180cdd','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('265b2ca2_5093_4dcc_8a0d_8dd061f7bb85','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('0f84d77a_b9c1_4616_aab7_df1b996f12ca','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('bba932ed_7c1c_433a_918a_0c83df2c67cb','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('cd9c5ced_4f2b_4ccc_ad86_2297a06093da','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('8539b1a7_4f9d_48e1_90f4_f4e20a4ee27f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('79857ce8_4bf4_40d5_a3f2_66d0021f3e64','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('1f4acfec_350b_4c9e_8f99_1f1099a76a57','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('b3287a64_3a68_46f1_81a0_6f5af1b77a4e','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('9008bf73_2622_461e_b695_1c6729971bf4','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('3d531c48_0079_4910_8a35_1e5e8153f84b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('c4f43060_f18e_4adb_983c_c253d1ac3943','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('2bc686fe_ae83_41f4_8347_86a9b31a6720','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('6bf6cb7c_b26a_4279_bebd_6c60e1482ef6','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1',''),
    ('a1fb50d9_6306_43ad_a556_7d38d48b508d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1',''),
    ('0558b9f2_bb2e_46f5_80d0_e9fe344ece62','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1',''),
    ('98a9cbbb_c1d2_4abe_b9fd_5082947885b4','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1',''),
    ('32e32cfa_6b5b_41cc_9c49_3a509b7fb6ef','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1',''),
    ('59521134_fcf6_4949_94e9_223dfe1dfd65','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1',''),
    ('fc12d039_5f00_499f_a807_b1ff16eebd2b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1',''),
    ('09652865_98e8_4619_912b_1b77450f8f6f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1',''),
    ('9c9127ac_7b47_49f5_8bec_c105b1fc6f9d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1',''),
    ('434a2252_c348_4699_9ef6_d8d7a636af84','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1',''),
    ('153bccf4_4f24_4766_9e81_779c46a472e2','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1',''),
    ('44461fe4_d80d_4896_a27a_1f0c7ba085bb','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1',''),
    ('ed59053d_6502_4572_9d5a_1574da6c0933','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1',''),
    ('e5c04b57_23e7_4ecd_bd23_383bd54d1002','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1',''),
    ('10e72e08_6fcf_4d15_87ef_4a7eb87e952d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1',''),
    ('87b9f73d_5753_4f80_82ee_6f1fb8815222','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1',''),
    ('0a02980f_500b_4b0d_b6e3_efe870e0dd16','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1',''),
    ('b1deedf5_3704_4573_87d4_90531d964fe7','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('145804b0_dfea_46bb_b968_939b90cbeda8',1,'None','','c1b6e180_bcac_43e0_a3d0_792060bebbc5','','6bf6cb7c_b26a_4279_bebd_6c60e1482ef6'),
    ('14d1497e_2022_44ad_905d_daa047eaeb58',1,'None','','8b443bc2_4d2f_480f_b671_f49714e73767','','a1fb50d9_6306_43ad_a556_7d38d48b508d'),
    ('ac07ea27_8c9e_4716_a540_59de38ccde80',1,'None','','c7e87247_7a58_439d_b34b_d7f4b55e4c14','','0558b9f2_bb2e_46f5_80d0_e9fe344ece62'),
    ('f8fde470_9c01_441a_ae29_7823dc0081e2',1,'None','','9c36bf53_d5fc_429e_abd9_93c27e9b4c46','','98a9cbbb_c1d2_4abe_b9fd_5082947885b4'),
    ('1fb61b05_3cc7_4ed1_b83e_5254bba06bc9',1,'None','','5ebbf9b1_8460_42ff_b6b0_35a3477bed12','','32e32cfa_6b5b_41cc_9c49_3a509b7fb6ef'),
    ('a5028eca_4ced_4467_80b6_b008d4877507',1,'None','','8d00ab3f_7e8f_4859_964f_cf1f5d180cdd','','59521134_fcf6_4949_94e9_223dfe1dfd65'),
    ('0e5f1108_e630_40bd_821e_de28757d9e94',1,'None','','265b2ca2_5093_4dcc_8a0d_8dd061f7bb85','','fc12d039_5f00_499f_a807_b1ff16eebd2b'),
    ('96bb9736_45ae_48ff_842c_6aed61225fb3',1,'None','','0f84d77a_b9c1_4616_aab7_df1b996f12ca','','09652865_98e8_4619_912b_1b77450f8f6f'),
    ('a0e297d3_7293_4991_a827_e29d36aaa353',1,'None','','bba932ed_7c1c_433a_918a_0c83df2c67cb','','9c9127ac_7b47_49f5_8bec_c105b1fc6f9d'),
    ('7f9f2ae1_aaac_4d82_93bb_424bbb9c7e07',1,'None','','cd9c5ced_4f2b_4ccc_ad86_2297a06093da','','434a2252_c348_4699_9ef6_d8d7a636af84'),
    ('104938db_015e_4a0a_8a08_d08a6d7e3f49',1,'None','','8539b1a7_4f9d_48e1_90f4_f4e20a4ee27f','','153bccf4_4f24_4766_9e81_779c46a472e2'),
    ('7082a260_8352_45ac_8f91_644120135bfc',1,'None','','79857ce8_4bf4_40d5_a3f2_66d0021f3e64','','44461fe4_d80d_4896_a27a_1f0c7ba085bb'),
    ('ecfe3a33_0e5e_4ef0_8921_67311221772b',1,'None','','1f4acfec_350b_4c9e_8f99_1f1099a76a57','','ed59053d_6502_4572_9d5a_1574da6c0933'),
    ('973fdf0d_c00d_4a98_b55f_477ef57d6c43',1,'None','','b3287a64_3a68_46f1_81a0_6f5af1b77a4e','','e5c04b57_23e7_4ecd_bd23_383bd54d1002'),
    ('6ce6cecf_fc2c_4ae9_92f2_c1ece4b71731',1,'None','','9008bf73_2622_461e_b695_1c6729971bf4','','10e72e08_6fcf_4d15_87ef_4a7eb87e952d'),
    ('4e2e74d0_25ba_4c8e_b9c3_524c9aaed7fa',1,'None','','3d531c48_0079_4910_8a35_1e5e8153f84b','','87b9f73d_5753_4f80_82ee_6f1fb8815222'),
    ('96852864_de2e_4f59_b674_7847100e3a5a',1,'None','','c4f43060_f18e_4adb_983c_c253d1ac3943','','0a02980f_500b_4b0d_b6e3_efe870e0dd16'),
    ('32fab20f_f190_4fa9_ab16_ac947c2be73f',1,'None','','2bc686fe_ae83_41f4_8347_86a9b31a6720','','b1deedf5_3704_4573_87d4_90531d964fe7');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,anon_screen_name,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    ('e618d547_2e05_4264_aee4_7b381afca35d','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','1376860f_03d0_4530_b164_2a8edb8a7be8','145804b0_dfea_46bb_b968_939b90cbeda8','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('b2e219d2_2af5_43fa_b8ee_dfff25a79f54','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','96e93a72_c9aa_4247_9706_03d12482ad3a','14d1497e_2022_44ad_905d_daa047eaeb58','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('a6e656f9_1db9_47b6_bd61_de7ba324d484','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','1007358b_5612_4e75_aeda_43813c4a8589','ac07ea27_8c9e_4716_a540_59de38ccde80','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('8184737b_3b4b_44db_909b_3d2c44e7081d','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','3a7b7433_6ce6_4e06_a03a_a3175ac73ff6','f8fde470_9c01_441a_ae29_7823dc0081e2','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('5ee1223e_7118_4b9c_8471_2d795090567b','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','b2ee7905_d453_4b75_a622_209dfd7e640b','1fb61b05_3cc7_4ed1_b83e_5254bba06bc9','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('0e8a5c2d_c316_445c_9a97_2162bf7253fa','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','6d24cac4_8d2f_4e7f_a035_12020c43b7d1','a5028eca_4ced_4467_80b6_b008d4877507','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('d3fa32d6_01a4_46d3_85e5_cc02a7a345d8','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','41025d8e_d897_4116_a4ca_90a33d3c0777','0e5f1108_e630_40bd_821e_de28757d9e94','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('7f411a91_1ad6_42a1_b6f0_f25f58cf967a','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','33b5bbf6_eb44_4cd6_af36_6e720c516e6c','96bb9736_45ae_48ff_842c_6aed61225fb3','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('18db995b_1d94_44ce_ba6d_4b57ef61bca6','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','385a468f_eb10_46bf_9039_8af2fd4c1b58','a0e297d3_7293_4991_a827_e29d36aaa353','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('a9fe34ff_152a_44d7_a924_6a1acb9e31f8','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','551e294f_b6e6_45ec_966f_8f57e5f644ea','7f9f2ae1_aaac_4d82_93bb_424bbb9c7e07','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('89c39bbc_2273_497d_ad86_bec1dbbbc948','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','901f4b2f_e940_436b_a30e_728cb50d5f6a','104938db_015e_4a0a_8a08_d08a6d7e3f49','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('1dfadc40_5459_4e42_b87e_50c9a4b04d25','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','030c77f4_74a4_4fa0_8ab4_b643ff36ee7d','7082a260_8352_45ac_8f91_644120135bfc','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('e1851bff_e250_4b6d_8b9e_7dadb86827eb','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','95dbdb67_cf57_4d7d_96b1_5ff03183a546','ecfe3a33_0e5e_4ef0_8921_67311221772b','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('68ef4710_1b2a_4897_828e_374fc2744650','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','bd7e1ae5_31de_4805_bb0b_c78445340c4f','973fdf0d_c00d_4a98_b55f_477ef57d6c43','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('3f3da8c1_87b6_464f_a9f7_ef4e09dfbed0','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','152ae700_3c10_466a_80c9_89e9dc35626f','6ce6cecf_fc2c_4ae9_92f2_c1ece4b71731','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('972ab090_b9e2_4aab_a306_4666c18df820','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','4ac2d2e4_c385_4873_8987_f64ea5c533b5','4e2e74d0_25ba_4c8e_b9c3_524c9aaed7fa','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('c514d345_6407_45dd_94be_beb1e1410c57','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','c1327718_0b77_4b9f_89db_1346896e5346','96852864_de2e_4f59_b674_7847100e3a5a','754a3fd9_594e_45e3_9ff2_5fbc1ee53793'),
    ('495880d2_f1a7_4b58_9c69_126825b2b2be','c822cee7_cf66_4d17_8995_bfdbe35f35e2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','e932db57_bb09_42ae_8207_ab8bf50a4fb0','32fab20f_f190_4fa9_ab16_ac947c2be73f','754a3fd9_594e_45e3_9ff2_5fbc1ee53793');
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
