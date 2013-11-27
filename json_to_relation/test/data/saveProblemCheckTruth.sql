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
    load_info_id VARCHAR(40) NOT NULL PRIMARY KEY,
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
    ('860186cf_a33a_4a73_a3b3_d4991a733321','2013112718511385607066','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/saveProblemCheck.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('82ef7590_81df_47b7_8bdf_2d9c27484cfa','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('32901c5c_775b_46ab_bb0d_a5d9a7353681','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('15e6978a_bb29_4ad8_8a8e_c5b30417ced6','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('88171b38_004d_4bb9_aaa6_07baf12db6e4','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('6372865b_b3c4_4e9b_b660_7e4691c73077','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('ed434d51_96ee_4ee5_85a4_9345cb5df11f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('7786e4c0_42a0_4f8a_8a11_c02f279c0710','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('7ae6ceb0_5e1d_4138_839a_3ad5f4b028c0','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('c055729d_11ec_4502_acd3_a6f866c94310','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('b4aaf672_34da_43ae_b618_095674956136','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('e4b7ea16_a3f2_4ec0_a0e3_81a9a1ea96bb','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('7475d6ba_8cf4_4968_8f85_99f4959578f4','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('d4d8e71d_1309_484e_a8fe_7a0075b61c78','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('02737996_7a08_456b_b377_87cd35b2fc4c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('45c06708_6d46_4514_a32d_e47445532add','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('3ab5944d_c94a_4a6b_8db6_49cf89d8fa8f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('602e1b6e_12d4_4bf4_b574_21636047e655','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('cdcc05ca_8722_448f_8b1a_c908607aa287','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258'),
    ('419c8039_f498_4507_8438_8b30fcace19c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('f70f4430_0fa7_4bb5_befd_da23980ee3ae','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('007c09cd_e418_4c65_91b5_32687007c6d9','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('06f555bf_9a31_4505_95fb_b092e00c4f5f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('0a023ef4_4911_4efa_9ed5_428700f25552','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('e88fdf74_c3a4_41ca_9e8a_589bfbbae497','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('71d93178_8b4e_43e0_a490_137821a26278','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('f8ac888d_d208_45cf_a68e_949c52087a57','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('e3555733_8eca_436f_9b52_e392a14086e4','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('570af369_3ab8_4ff9_86f5_f7daa8e79cd1','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('f01811f1_af83_4e0e_85c7_5904ce927274','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('5f9b8c24_4280_4647_8262_6ad0bc7d8ea0','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('1f26d8d2_b15a_425e_98aa_524631a5533e','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('e49e154e_cc5b_4345_98cb_47060d616c43','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('06666b58_6b5f_4d41_bb35_720bfb51b660','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('6d42f98b_5f02_400f_ab02_704d31868e21','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('4905b61a_4e2a_48c8_ad28_8b77f24089d0','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('f44b4b23_6505_4454_b61f_226a26d48b21','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('550b65eb_b805_4ab8_b705_28c35538a0f9','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1',''),
    ('1177f263_4141_4ae1_871c_95420b8c43f2','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1',''),
    ('bb0336d4_3a44_47d6_a4cf_841787af2392','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1',''),
    ('95c5042d_b81d_4768_8d2d_b701d3757a69','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1',''),
    ('751bf0b5_6aa1_450e_abe1_0580a92c08a1','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1',''),
    ('ca9e8b2c_97e4_45d9_a3e4_b0d5b0de8f02','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1',''),
    ('c05d17b7_7ce9_46c5_84c3_d6aa35cd9e52','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1',''),
    ('b520a01d_64a3_4a29_aea6_e6a3408b2f19','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1',''),
    ('77779f3e_c65e_46c5_9dbc_6f1fd8740219','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1',''),
    ('63036774_87e6_4e35_9a93_42c974de6f2d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1',''),
    ('245bf605_16f0_410b_9925_3ebb8568c3e5','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1',''),
    ('e20bd727_dd99_4c34_b958_b44c52d1c01d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1',''),
    ('c36c9402_0964_42a5_8ea8_3fe4ea74fd71','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1',''),
    ('45034aa0_41ed_46ba_aeaf_fe5b6e2225bb','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1',''),
    ('a964fb87_bcbe_433d_b956_0855deb57149','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1',''),
    ('124a69e0_c996_4439_9d36_bca91881ed12','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1',''),
    ('5e53a617_3311_471e_ab9c_42e0197abd9d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1',''),
    ('52cf0e0b_a470_4a10_9ac2_f04a6395c279','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('3ddde13b_b5c8_4cf5_81a3_782e55c0d9dc',1,'None','','419c8039_f498_4507_8438_8b30fcace19c','','550b65eb_b805_4ab8_b705_28c35538a0f9'),
    ('7976d9e8_e10b_41f3_acbc_559f0b81d573',1,'None','','f70f4430_0fa7_4bb5_befd_da23980ee3ae','','1177f263_4141_4ae1_871c_95420b8c43f2'),
    ('09041171_8eaa_440e_86e5_80bc7378f9a3',1,'None','','007c09cd_e418_4c65_91b5_32687007c6d9','','bb0336d4_3a44_47d6_a4cf_841787af2392'),
    ('875ebea8_35f2_4df7_b85c_bada8544cd66',1,'None','','06f555bf_9a31_4505_95fb_b092e00c4f5f','','95c5042d_b81d_4768_8d2d_b701d3757a69'),
    ('6cd2a6c4_3a70_46c9_b0fa_7e240533d862',1,'None','','0a023ef4_4911_4efa_9ed5_428700f25552','','751bf0b5_6aa1_450e_abe1_0580a92c08a1'),
    ('5561f623_562e_481e_83a5_db22bd5931ac',1,'None','','e88fdf74_c3a4_41ca_9e8a_589bfbbae497','','ca9e8b2c_97e4_45d9_a3e4_b0d5b0de8f02'),
    ('287d12be_3053_4733_a84d_6837c2bdd381',1,'None','','71d93178_8b4e_43e0_a490_137821a26278','','c05d17b7_7ce9_46c5_84c3_d6aa35cd9e52'),
    ('1647c5f5_9d63_4a7a_b701_4b20920e03d4',1,'None','','f8ac888d_d208_45cf_a68e_949c52087a57','','b520a01d_64a3_4a29_aea6_e6a3408b2f19'),
    ('a1732ef0_b387_4df2_b83a_02ddddbad346',1,'None','','e3555733_8eca_436f_9b52_e392a14086e4','','77779f3e_c65e_46c5_9dbc_6f1fd8740219'),
    ('e5142535_ab91_4fb1_a7f2_49334c176905',1,'None','','570af369_3ab8_4ff9_86f5_f7daa8e79cd1','','63036774_87e6_4e35_9a93_42c974de6f2d'),
    ('3a90cad8_6f7a_4cc3_a85a_1f9ac60502a9',1,'None','','f01811f1_af83_4e0e_85c7_5904ce927274','','245bf605_16f0_410b_9925_3ebb8568c3e5'),
    ('86dd19ef_cd26_4994_b048_d928d61a586e',1,'None','','5f9b8c24_4280_4647_8262_6ad0bc7d8ea0','','e20bd727_dd99_4c34_b958_b44c52d1c01d'),
    ('8b484237_a15a_4097_b19f_54af2aa68150',1,'None','','1f26d8d2_b15a_425e_98aa_524631a5533e','','c36c9402_0964_42a5_8ea8_3fe4ea74fd71'),
    ('4739be55_6900_49f3_94c7_54e36ebab9c8',1,'None','','e49e154e_cc5b_4345_98cb_47060d616c43','','45034aa0_41ed_46ba_aeaf_fe5b6e2225bb'),
    ('5b1d26ac_2b25_4ce8_bb3c_d5b0a54cf475',1,'None','','06666b58_6b5f_4d41_bb35_720bfb51b660','','a964fb87_bcbe_433d_b956_0855deb57149'),
    ('99ced425_7a11_450e_a123_740fbc47bb20',1,'None','','6d42f98b_5f02_400f_ab02_704d31868e21','','124a69e0_c996_4439_9d36_bca91881ed12'),
    ('e914ea7c_1d9d_4963_b48e_26e89633af60',1,'None','','4905b61a_4e2a_48c8_ad28_8b77f24089d0','','5e53a617_3311_471e_ab9c_42e0197abd9d'),
    ('b2d37dcd_1822_4c43_bc32_8f684b509a32',1,'None','','f44b4b23_6505_4454_b61f_226a26d48b21','','52cf0e0b_a470_4a10_9ac2_f04a6395c279');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,anon_screen_name,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    ('5a9f1a6e_cb32_435c_b41c_dc7507ddc5ab','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','82ef7590_81df_47b7_8bdf_2d9c27484cfa','3ddde13b_b5c8_4cf5_81a3_782e55c0d9dc','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('258212fa_d045_44ab_bcbb_45438cf5c170','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','32901c5c_775b_46ab_bb0d_a5d9a7353681','7976d9e8_e10b_41f3_acbc_559f0b81d573','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('1d961fab_ead3_4826_b8d8_2ad0d5ab0289','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','15e6978a_bb29_4ad8_8a8e_c5b30417ced6','09041171_8eaa_440e_86e5_80bc7378f9a3','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('7f6ce426_7bfd_4d92_b42f_1376591670f9','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','88171b38_004d_4bb9_aaa6_07baf12db6e4','875ebea8_35f2_4df7_b85c_bada8544cd66','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('72854f8f_fbcd_42c2_b1a9_3d2cf8ea9fd9','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','6372865b_b3c4_4e9b_b660_7e4691c73077','6cd2a6c4_3a70_46c9_b0fa_7e240533d862','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('dcf946ca_2ee5_4196_89ee_89963b109ded','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','ed434d51_96ee_4ee5_85a4_9345cb5df11f','5561f623_562e_481e_83a5_db22bd5931ac','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('ee02da51_38ec_49a4_b047_342a7c45fb02','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','7786e4c0_42a0_4f8a_8a11_c02f279c0710','287d12be_3053_4733_a84d_6837c2bdd381','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('1443c10c_483a_4ec5_9e42_bcbc8a30bcda','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','7ae6ceb0_5e1d_4138_839a_3ad5f4b028c0','1647c5f5_9d63_4a7a_b701_4b20920e03d4','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('f33cac78_e433_4d5d_abae_a1d9c0a87614','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','c055729d_11ec_4502_acd3_a6f866c94310','a1732ef0_b387_4df2_b83a_02ddddbad346','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('a97e9fa8_cca9_4df6_98d5_ed9f5b8f0a80','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','b4aaf672_34da_43ae_b618_095674956136','e5142535_ab91_4fb1_a7f2_49334c176905','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('c83d05ae_a9a3_4fd6_898d_6d0d14e5e959','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','e4b7ea16_a3f2_4ec0_a0e3_81a9a1ea96bb','3a90cad8_6f7a_4cc3_a85a_1f9ac60502a9','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('75b41f65_1877_490c_82f6_a33106e384d5','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','7475d6ba_8cf4_4968_8f85_99f4959578f4','86dd19ef_cd26_4994_b048_d928d61a586e','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('0a698368_c52f_4fbd_8b45_b5ff8c2bc9f9','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','d4d8e71d_1309_484e_a8fe_7a0075b61c78','8b484237_a15a_4097_b19f_54af2aa68150','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('6a1355b8_eb1a_459b_8fa2_0b5897c10b27','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','02737996_7a08_456b_b377_87cd35b2fc4c','4739be55_6900_49f3_94c7_54e36ebab9c8','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('02babdc3_d524_4407_a582_018ca616210b','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','45c06708_6d46_4514_a32d_e47445532add','5b1d26ac_2b25_4ce8_bb3c_d5b0a54cf475','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('2ebd4838_9268_40f4_a2a2_ee3c18612d8e','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','3ab5944d_c94a_4a6b_8db6_49cf89d8fa8f','99ced425_7a11_450e_a123_740fbc47bb20','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('ad64736b_cc1b_4e4e_8718_8eca376eb0f0','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','602e1b6e_12d4_4bf4_b574_21636047e655','e914ea7c_1d9d_4963_b48e_26e89633af60','860186cf_a33a_4a73_a3b3_d4991a733321'),
    ('2933142a_cfd9_4a6b_8d58_a0b1c4809608','60668d5a_3fe0_418c_81a0_c3eea3fe15a7','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','107e1bf723a51dbd4b1f224a736235b82e707ca52e408d03c84440ab','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','cdcc05ca_8722_448f_8b1a_c908607aa287','b2d37dcd_1822_4c43_bc32_8f684b509a32','860186cf_a33a_4a73_a3b3_d4991a733321');
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
