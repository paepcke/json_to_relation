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
    );
CREATE TABLE IF NOT EXISTS CorrectMap (
    correct_map_id VARCHAR(40) NOT NULL PRIMARY KEY,
    answer_identifier TEXT NOT NULL,
    correctness TINYTEXT NOT NULL,
    npoints INT NOT NULL,
    msg TEXT NOT NULL,
    hint TEXT NOT NULL,
    hintmode TINYTEXT NOT NULL,
    queuestate TEXT NOT NULL
    );
CREATE TABLE IF NOT EXISTS InputState (
    input_state_id VARCHAR(40) NOT NULL PRIMARY KEY,
    problem_id TEXT NOT NULL,
    state TEXT NOT NULL
    );
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
    );
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
    );
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
    );
CREATE TABLE IF NOT EXISTS LoadInfo (
    load_info_id INT NOT NULL PRIMARY KEY,
    load_date_time DATETIME NOT NULL,
    load_file TEXT NOT NULL
    );
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
    );
LOCK TABLES `EdxTrackEvent` WRITE, `State` WRITE, `InputState` WRITE, `Answer` WRITE, `CorrectMap` WRITE, `LoadInfo` WRITE, `Account` WRITE;
/*!40000 ALTER TABLE `EdxTrackEvent` DISABLE KEYS */;
/*!40000 ALTER TABLE `State` DISABLE KEYS */;
/*!40000 ALTER TABLE `InputState` DISABLE KEYS */;
/*!40000 ALTER TABLE `Answer` DISABLE KEYS */;
/*!40000 ALTER TABLE `CorrectMap` DISABLE KEYS */;
/*!40000 ALTER TABLE `LoadInfo` DISABLE KEYS */;
/*!40000 ALTER TABLE `Account` DISABLE KEYS */;
INSERT INTO LoadInfo (load_info_id,load_date_time,load_file) VALUES 
    ('779843b2_690f_4326_ad9c_31ecd9608a8f','2013111104351384173336','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/saveProblemCheck.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('41284d80_cc37_4f2d_8546_ebbe48a2dfb8','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('bef06741_6409_4897_9558_b6c21eeb8b2d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('7535cefd_d882_404a_9dce_9c105f2cd921','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('aa9c6efe_4b39_4e64_b455_d199823a8288','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('a72e9a64_e486_4e4a_b105_b247cc69e500','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('b9ed4faa_b295_4c45_ab7d_884425c0975d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('04aa39f4_fa66_4d66_9a52_11bab0574372','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('2f440042_80e6_4085_878b_f2f8a01322f2','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('28dec130_8b03_4290_b743_9e24898226b1','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('c07f8622_930a_48be_a4e7_7a606331d330','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('010fc9a6_f91e_4b22_bbf9_12d90c25c2d4','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('eb977ffc_553e_4596_a385_9ee54d1081dd','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('af255704_9cea_4ce4_8b82_e755cb0a92c8','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('150c18fc_bc28_4a27_bc56_a71fd7c2c4bc','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('a45d9dc0_3c66_4347_96d6_b51fae9f476a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('e6dd93ee_ecb0_4bab_ab09_eb71f0b75268','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('75f49333_ee2a_4187_8978_a3a2c5052172','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('5d66c33b_3abf_4edb_9360_84c932e938ce','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258'),
    ('4ee64c6a_329a_4872_b501_f81013e94db9','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('26910734_d42f_4475_bde0_d9d085f42b73','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('2d9199d9_b5fd_43ee_9eb8_f4e8d32ba4f1','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('848ede96_8c1c_4e64_a3f4_28aa8c1b56ae','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('e28ee10e_5f15_4bf0_8612_027891ba301a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('668d87a2_2430_4364_8c4e_66088dd948d9','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('1a9ede84_5ac6_4a62_9de0_d495d63ff555','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('464e5c2a_6502_487f_b298_556e307b7c58','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('41092034_9516_4bf5_9536_c91f2bd5686b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('5ebdce87_9c96_415e_a7e3_cca4e7594223','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('ec2f17d2_81b0_49dc_abe0_1a5c38ed9c25','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('c9d23c72_2308_4ca4_82ab_e54f4d9d2f29','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('dc0c2504_04b8_407e_8d90_1714c8fb3b62','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('3306f150_37d2_46b5_915d_cf2a9ea9319a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('0ebb294d_5249_4663_8719_01b4f22ff7c6','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('f7a825e4_4449_40c1_bc3b_0913659e9754','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('3b77e3ef_b4b6_4571_a8e6_c0d19be651e2','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('aeb7aca3_2d7f_49da_a44d_52dbce209d49','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('c34b98f4_d904_458d_a899_f35c0c72e2d2','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1',''),
    ('a69f7c16_69e7_479f_bee1_f72416b889e5','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1',''),
    ('c45d1743_83dc_4ebb_a9c3_09d649f63a54','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1',''),
    ('aaa9c34f_b54c_4158_b3b0_b0ee9dcd8f24','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1',''),
    ('10be7956_bbbf_4f64_8e7f_b392d8314b8c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1',''),
    ('f4707bf5_ad0f_45f7_8617_9b66f82e2761','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1',''),
    ('61c89d6d_eaa7_445a_80c6_571fc3b8e874','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1',''),
    ('48a4b0ed_8d57_4b9d_bf71_dc8d5f9aae19','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1',''),
    ('6eafafe9_4e32_4e0f_b667_a0888e7a57b5','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1',''),
    ('a1a823bd_258d_4258_a08a_b7d7d8690f4a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1',''),
    ('9770dcc8_13fb_4872_bbbb_b51a5591958b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1',''),
    ('ded2be22_0412_4a02_82e9_f652b50708ed','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1',''),
    ('8d0b0db0_c838_4c0a_b003_c4fdbe63e022','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1',''),
    ('82c7d9d3_50de_41f9_bbe2_b46113e5fd77','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1',''),
    ('a04b12a8_ea3f_496d_8d4e_d3d2f26aea85','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1',''),
    ('1dc949ee_6a9c_4e02_b68c_8c0d49f8b16d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1',''),
    ('86a9cb72_fab1_4cb5_8f6a_fa8a7a14a466','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1',''),
    ('01faf547_029f_4d83_879c_0b3ab010586f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('9fad192c_2a11_4e70_94ca_4cea3de2dd3a',1,'None','','4ee64c6a_329a_4872_b501_f81013e94db9','','c34b98f4_d904_458d_a899_f35c0c72e2d2'),
    ('9e6eaff7_4a21_4af5_9c41_71a1fd9ff4ee',1,'None','','26910734_d42f_4475_bde0_d9d085f42b73','','a69f7c16_69e7_479f_bee1_f72416b889e5'),
    ('393b6250_d550_433f_b839_9c3ea8a754e7',1,'None','','2d9199d9_b5fd_43ee_9eb8_f4e8d32ba4f1','','c45d1743_83dc_4ebb_a9c3_09d649f63a54'),
    ('a37e9099_2213_4a61_ae5d_8f6366b0245b',1,'None','','848ede96_8c1c_4e64_a3f4_28aa8c1b56ae','','aaa9c34f_b54c_4158_b3b0_b0ee9dcd8f24'),
    ('63a6a077_8006_489b_907a_3f8b65c42bbb',1,'None','','e28ee10e_5f15_4bf0_8612_027891ba301a','','10be7956_bbbf_4f64_8e7f_b392d8314b8c'),
    ('1893b6fd_3a63_4d1a_b389_61d20997b943',1,'None','','668d87a2_2430_4364_8c4e_66088dd948d9','','f4707bf5_ad0f_45f7_8617_9b66f82e2761'),
    ('669c8230_efeb_4771_9c09_ff1d7f7df73c',1,'None','','1a9ede84_5ac6_4a62_9de0_d495d63ff555','','61c89d6d_eaa7_445a_80c6_571fc3b8e874'),
    ('fc071ac4_8865_45e9_b064_800f4cd3217a',1,'None','','464e5c2a_6502_487f_b298_556e307b7c58','','48a4b0ed_8d57_4b9d_bf71_dc8d5f9aae19'),
    ('8baf85ce_a300_4a27_97fb_d25379c01ba4',1,'None','','41092034_9516_4bf5_9536_c91f2bd5686b','','6eafafe9_4e32_4e0f_b667_a0888e7a57b5'),
    ('ba8720e7_bb13_41ba_8f1f_02e1b282376b',1,'None','','5ebdce87_9c96_415e_a7e3_cca4e7594223','','a1a823bd_258d_4258_a08a_b7d7d8690f4a'),
    ('253fedd2_6c57_4e3e_a1f9_d6941bf9bd40',1,'None','','ec2f17d2_81b0_49dc_abe0_1a5c38ed9c25','','9770dcc8_13fb_4872_bbbb_b51a5591958b'),
    ('d5f34bb2_a0fe_41e1_944d_d88e64dd238c',1,'None','','c9d23c72_2308_4ca4_82ab_e54f4d9d2f29','','ded2be22_0412_4a02_82e9_f652b50708ed'),
    ('96469737_89d1_4900_9495_05b238b889be',1,'None','','dc0c2504_04b8_407e_8d90_1714c8fb3b62','','8d0b0db0_c838_4c0a_b003_c4fdbe63e022'),
    ('a54b3ee1_8f35_41b4_8bb8_ad49f6c82c65',1,'None','','3306f150_37d2_46b5_915d_cf2a9ea9319a','','82c7d9d3_50de_41f9_bbe2_b46113e5fd77'),
    ('b4e92067_f1ad_46fc_a45c_d9ec7ab4e780',1,'None','','0ebb294d_5249_4663_8719_01b4f22ff7c6','','a04b12a8_ea3f_496d_8d4e_d3d2f26aea85'),
    ('27436ddf_cc1e_4a98_9771_1b911dbd70d5',1,'None','','f7a825e4_4449_40c1_bc3b_0913659e9754','','1dc949ee_6a9c_4e02_b68c_8c0d49f8b16d'),
    ('9716cf6b_be95_4c03_a540_6de2cc107401',1,'None','','3b77e3ef_b4b6_4571_a8e6_c0d19be651e2','','86a9cb72_fab1_4cb5_8f6a_fa8a7a14a466'),
    ('9a68b399_e432_45f4_b676_d2289bc3a32d',1,'None','','aeb7aca3_2d7f_49da_a44d_52dbce209d49','','01faf547_029f_4d83_879c_0b3ab010586f');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,anon_screen_name,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    ('af4e2c7f_2e6d_48e9_953f_3cca6c14aa0c','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','41284d80_cc37_4f2d_8546_ebbe48a2dfb8','9fad192c_2a11_4e70_94ca_4cea3de2dd3a','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('17a37125_639d_4f66_9454_03ac7912e43a','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','bef06741_6409_4897_9558_b6c21eeb8b2d','9e6eaff7_4a21_4af5_9c41_71a1fd9ff4ee','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('57a2111b_fac4_4872_a123_0e01e0732ca7','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','7535cefd_d882_404a_9dce_9c105f2cd921','393b6250_d550_433f_b839_9c3ea8a754e7','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('591846a4_2cda_4a8d_a859_41bea4d9504c','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','aa9c6efe_4b39_4e64_b455_d199823a8288','a37e9099_2213_4a61_ae5d_8f6366b0245b','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('daf09c1b_78b6_4996_bf6f_7addf77ece4c','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','a72e9a64_e486_4e4a_b105_b247cc69e500','63a6a077_8006_489b_907a_3f8b65c42bbb','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('25c79272_75c8_4eba_a51b_d9ff2a4f27cd','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','b9ed4faa_b295_4c45_ab7d_884425c0975d','1893b6fd_3a63_4d1a_b389_61d20997b943','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('b35078e0_b1aa_4e80_b04f_27ee11761ffc','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','04aa39f4_fa66_4d66_9a52_11bab0574372','669c8230_efeb_4771_9c09_ff1d7f7df73c','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('5bd6a16f_3210_405e_a194_a5d2cb245284','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','2f440042_80e6_4085_878b_f2f8a01322f2','fc071ac4_8865_45e9_b064_800f4cd3217a','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('15fc7be9_c38b_48b3_ab9c_4273ae006401','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','28dec130_8b03_4290_b743_9e24898226b1','8baf85ce_a300_4a27_97fb_d25379c01ba4','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('fa289a30_87a1_41ee_866b_40ccaa37ec93','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','c07f8622_930a_48be_a4e7_7a606331d330','ba8720e7_bb13_41ba_8f1f_02e1b282376b','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('87aba336_0a99_48c7_aa38_0e3afa379298','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','010fc9a6_f91e_4b22_bbf9_12d90c25c2d4','253fedd2_6c57_4e3e_a1f9_d6941bf9bd40','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('c8406327_900d_451f_b1b3_14c883c32f3d','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','eb977ffc_553e_4596_a385_9ee54d1081dd','d5f34bb2_a0fe_41e1_944d_d88e64dd238c','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('77087de7_6bc3_4e96_a1c3_1dd147021ca1','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','af255704_9cea_4ce4_8b82_e755cb0a92c8','96469737_89d1_4900_9495_05b238b889be','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('aee00cda_f7b3_4d26_87a1_7cf8e212b427','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','150c18fc_bc28_4a27_bc56_a71fd7c2c4bc','a54b3ee1_8f35_41b4_8bb8_ad49f6c82c65','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('b4594a58_878c_443f_b4dc_aa578be6f242','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','a45d9dc0_3c66_4347_96d6_b51fae9f476a','b4e92067_f1ad_46fc_a45c_d9ec7ab4e780','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('941bddf2_3d07_4c14_b5c1_7a795685dc6f','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','e6dd93ee_ecb0_4bab_ab09_eb71f0b75268','27436ddf_cc1e_4a98_9771_1b911dbd70d5','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('e752fffe_c1dc_452b_92ad_50683eb5b693','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','75f49333_ee2a_4187_8978_a3a2c5052172','9716cf6b_be95_4c03_a540_6de2cc107401','779843b2_690f_4326_ad9c_31ecd9608a8f'),
    ('fa102e11_d219_4b0a_b9eb_b476793d8491','50fd04f4_c525_4383_97e5_0e7ff134e8c7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','5d66c33b_3abf_4edb_9360_84c932e938ce','9a68b399_e432_45f4_b676_d2289bc3a32d','779843b2_690f_4326_ad9c_31ecd9608a8f');
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
