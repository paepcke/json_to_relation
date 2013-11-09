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
    ('aacd4924_fa70_4ca8_a74c_0277eebedbe0','2013110907251384010735','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/saveProblemCheck.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('465f5216_86cf_4f72_b599_e50f0a4d36d4','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('cdae55fb_f744_4a21_a46e_d14a994f466a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('3c4f27eb_d0e3_4d6f_aab1_895e91eb14f5','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('5e5775c3_f782_4ed0_9266_13ad01411e96','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('86091003_67e5_4505_bbf6_7e3d85dd9fdc','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('512a1b17_dcad_409e_a1ed_6d4469417852','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('2ff71f69_3908_4ce0_a532_c00de8fc5a7f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('6280f49e_f02b_4ea5_976f_96ebacea437c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('1b404ad9_5217_48d3_8a29_a97d357c6f2c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('a12b21f9_dcd4_439c_ae83_03596af6e082','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('cd78f1f9_3355_4b35_8313_1233b3628a2f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('5dbbb46c_9de7_4f0f_a0fa_f21cb54c9541','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('0f642075_49b1_479b_855d_e53513f3bd0e','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('4123e14b_cb7c_4109_9ba0_b29048e1a03e','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('430cee88_a655_4333_ba06_496553b092bb','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('fed95140_f3bd_4616_8f14_0ea042050fd7','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('35c39735_061e_4950_a430_28bf4505a370','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('a4da3a52_189f_4483_b801_7b1bcb721b41','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258'),
    ('795ce42b_a05a_4b44_9aca_32a5c954e494','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('5a70910d_fa56_44df_981c_9880339609fb','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('3efbb68f_bc90_49e7_8e68_5bb17607b949','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('ad1e75d4_c9ee_4a08_ad60_0571026e5047','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('efce4dd7_111f_4d62_9877_106e29962cfb','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('c3e95813_77d6_4b8a_8887_ed78f2378cbc','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('9cc89d9e_0038_4090_aa96_47aeb7f4869f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('86211ab5_5b29_4bad_9635_5b62e0a2e6e2','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('38f217e3_80a5_49d3_bf9f_b75e934da4c4','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('6046ea4c_beff_42f9_a031_789f7a00d15c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('3929b954_e555_499c_8a68_81001448a363','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('4415f07e_3078_4428_8e28_8a6820a01f3b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('e2465323_9cfb_4700_8ebf_356f87d0f390','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('948ebfb5_018f_4e4e_bbea_a4ebcc274a80','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('194502ec_1b30_4c57_af36_98fb70e8965e','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('0a0c5c9a_4b54_4720_b0e4_21821bf2e14e','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('1cfc9b1c_4cb2_4591_bca3_35612b55761e','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('812fc9bc_73a5_4e25_aa2c_daae4c56cd7b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('25c6480a_da7c_4c7d_8a73_668e609e6ce1','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1',''),
    ('d382b453_2df9_40a4_96d6_abc002f3215e','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1',''),
    ('94e6a475_2110_4cfc_b744_a1e1dd659339','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1',''),
    ('4bfd095b_3288_440e_bf47_b03b37a21e13','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1',''),
    ('2587a595_aa8f_4f4a_b0b3_3ff3764f88bc','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1',''),
    ('18664d38_284b_45f0_bfa3_bb16ccd9f0a4','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1',''),
    ('a9fe9c0c_2f98_49d0_a249_3db4965390fc','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1',''),
    ('e63818d9_72cd_4b75_8127_89943ea6a124','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1',''),
    ('26e870e5_0dac_4384_b31e_53fb77065449','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1',''),
    ('52854d93_1b7f_4315_8cf1_464a4e56907f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1',''),
    ('aac1f2f5_211f_41f1_b9a8_e3af6704053a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1',''),
    ('fdc5cf41_b4d5_44c9_8358_2a98720dc6ef','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1',''),
    ('f60c210d_9dc0_4a01_9d32_4a13fa640f8c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1',''),
    ('a84edf93_11cd_422f_99de_2055127f8d48','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1',''),
    ('bff073f4_ad33_450c_a8b4_2d8b039fc293','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1',''),
    ('311ef062_28f7_4314_8284_c184b94aefb9','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1',''),
    ('bf7efaf2_b08f_414e_a3f4_6fd872469ef9','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1',''),
    ('249d1e3a_394a_44dc_9b94_7714e048e7a7','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('c0c26a46_9255_498a_a667_ed50af9160a8',1,'None','','795ce42b_a05a_4b44_9aca_32a5c954e494','','25c6480a_da7c_4c7d_8a73_668e609e6ce1'),
    ('e6d86fc6_4e61_4cab_8973_3d8bb3a97e62',1,'None','','5a70910d_fa56_44df_981c_9880339609fb','','d382b453_2df9_40a4_96d6_abc002f3215e'),
    ('3a7ece7d_2437_4958_a47a_964bcafaeb55',1,'None','','3efbb68f_bc90_49e7_8e68_5bb17607b949','','94e6a475_2110_4cfc_b744_a1e1dd659339'),
    ('76ecf2df_7e9e_463b_8b9c_11024b570005',1,'None','','ad1e75d4_c9ee_4a08_ad60_0571026e5047','','4bfd095b_3288_440e_bf47_b03b37a21e13'),
    ('55352e9f_db11_49fe_9f5d_c7a30d267a6c',1,'None','','efce4dd7_111f_4d62_9877_106e29962cfb','','2587a595_aa8f_4f4a_b0b3_3ff3764f88bc'),
    ('0cff56b5_fad1_49d0_992b_dfbcc3841823',1,'None','','c3e95813_77d6_4b8a_8887_ed78f2378cbc','','18664d38_284b_45f0_bfa3_bb16ccd9f0a4'),
    ('213a63cf_393b_446b_b69d_4278870a396c',1,'None','','9cc89d9e_0038_4090_aa96_47aeb7f4869f','','a9fe9c0c_2f98_49d0_a249_3db4965390fc'),
    ('9056c357_cdae_47b6_a834_6b953fc23920',1,'None','','86211ab5_5b29_4bad_9635_5b62e0a2e6e2','','e63818d9_72cd_4b75_8127_89943ea6a124'),
    ('d95e59a8_e709_4a5e_a9a0_12b7e8e82335',1,'None','','38f217e3_80a5_49d3_bf9f_b75e934da4c4','','26e870e5_0dac_4384_b31e_53fb77065449'),
    ('21c09b34_94c0_4e47_abe2_f5e460c98a0c',1,'None','','6046ea4c_beff_42f9_a031_789f7a00d15c','','52854d93_1b7f_4315_8cf1_464a4e56907f'),
    ('31c0ff86_6e07_46fa_a732_bd708d51d754',1,'None','','3929b954_e555_499c_8a68_81001448a363','','aac1f2f5_211f_41f1_b9a8_e3af6704053a'),
    ('a7b683fb_15e2_4a1e_9893_942a57590d24',1,'None','','4415f07e_3078_4428_8e28_8a6820a01f3b','','fdc5cf41_b4d5_44c9_8358_2a98720dc6ef'),
    ('c2e10728_1131_4170_a1a0_64e3535b418a',1,'None','','e2465323_9cfb_4700_8ebf_356f87d0f390','','f60c210d_9dc0_4a01_9d32_4a13fa640f8c'),
    ('57dd5e5e_eb83_437d_b189_0d97b19cb1ca',1,'None','','948ebfb5_018f_4e4e_bbea_a4ebcc274a80','','a84edf93_11cd_422f_99de_2055127f8d48'),
    ('c44efa62_17ec_446b_a5a5_6256f9154810',1,'None','','194502ec_1b30_4c57_af36_98fb70e8965e','','bff073f4_ad33_450c_a8b4_2d8b039fc293'),
    ('f28a7781_17c8_492e_9d6b_94b747abdd53',1,'None','','0a0c5c9a_4b54_4720_b0e4_21821bf2e14e','','311ef062_28f7_4314_8284_c184b94aefb9'),
    ('8fb828c3_03f6_4cb1_9884_1871bdbfec7c',1,'None','','1cfc9b1c_4cb2_4591_bca3_35612b55761e','','bf7efaf2_b08f_414e_a3f4_6fd872469ef9'),
    ('24c58099_da11_439e_8fad_7459fb93fd4b',1,'None','','812fc9bc_73a5_4e25_aa2c_daae4c56cd7b','','249d1e3a_394a_44dc_9b94_7714e048e7a7');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,anon_screen_name,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    ('5a37a8b3_36b9_484d_884d_2d84b816e674','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','465f5216_86cf_4f72_b599_e50f0a4d36d4','c0c26a46_9255_498a_a667_ed50af9160a8','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('f46ea584_c1e6_4dd5_b1b2_3f86a29d02da','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','cdae55fb_f744_4a21_a46e_d14a994f466a','e6d86fc6_4e61_4cab_8973_3d8bb3a97e62','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('23d35364_1d06_491c_812d_60728400d5e6','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','3c4f27eb_d0e3_4d6f_aab1_895e91eb14f5','3a7ece7d_2437_4958_a47a_964bcafaeb55','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('c95c2b6e_dda4_47e2_8f83_d4029e92e4d0','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','5e5775c3_f782_4ed0_9266_13ad01411e96','76ecf2df_7e9e_463b_8b9c_11024b570005','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('7a86005c_168c_4c0b_a256_a17925a415f4','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','86091003_67e5_4505_bbf6_7e3d85dd9fdc','55352e9f_db11_49fe_9f5d_c7a30d267a6c','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('e4c086da_72ad_4f46_8b6c_7ff1af590804','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','512a1b17_dcad_409e_a1ed_6d4469417852','0cff56b5_fad1_49d0_992b_dfbcc3841823','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('b51701d0_fad4_45cb_a65e_b4118fd49b39','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','2ff71f69_3908_4ce0_a532_c00de8fc5a7f','213a63cf_393b_446b_b69d_4278870a396c','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('1703d597_580f_4bc6_b80b_ecc443338201','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','6280f49e_f02b_4ea5_976f_96ebacea437c','9056c357_cdae_47b6_a834_6b953fc23920','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('199aa87e_4e75_4996_8616_11b43e856794','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','1b404ad9_5217_48d3_8a29_a97d357c6f2c','d95e59a8_e709_4a5e_a9a0_12b7e8e82335','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('1a12d8d5_2490_419f_9467_bedb9a1b7ccc','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','a12b21f9_dcd4_439c_ae83_03596af6e082','21c09b34_94c0_4e47_abe2_f5e460c98a0c','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('dff00f99_4a89_4bdc_b93b_8e9fe1e65af6','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','cd78f1f9_3355_4b35_8313_1233b3628a2f','31c0ff86_6e07_46fa_a732_bd708d51d754','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('7892cd9a_3d76_4ee0_8157_de01609c9ad0','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','5dbbb46c_9de7_4f0f_a0fa_f21cb54c9541','a7b683fb_15e2_4a1e_9893_942a57590d24','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('c23c9835_6a5b_4ab9_adb5_d5f5c5869f28','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','0f642075_49b1_479b_855d_e53513f3bd0e','c2e10728_1131_4170_a1a0_64e3535b418a','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('c24c25c6_adf6_4b6e_b78d_33155eb3ca1e','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','4123e14b_cb7c_4109_9ba0_b29048e1a03e','57dd5e5e_eb83_437d_b189_0d97b19cb1ca','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('4e05c3be_2fc9_4d9a_9a05_ce5183f4a9c4','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','430cee88_a655_4333_ba06_496553b092bb','c44efa62_17ec_446b_a5a5_6256f9154810','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('127a1b9b_34dc_4cf2_8358_0f281d9481b5','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','fed95140_f3bd_4616_8f14_0ea042050fd7','f28a7781_17c8_492e_9d6b_94b747abdd53','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('7f93d0db_561a_40e3_88ca_e6e32882c831','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','35c39735_061e_4950_a430_28bf4505a370','8fb828c3_03f6_4cb1_9884_1871bdbfec7c','aacd4924_fa70_4ca8_a74c_0277eebedbe0'),
    ('4ccd44a1_3925_4185_a0c3_ae5b1ff2d4f3','4c6564e4_b345_4c04_961e_d59e913abb50','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','a4da3a52_189f_4483_b801_7b1bcb721b41','24c58099_da11_439e_8fad_7459fb93fd4b','aacd4924_fa70_4ca8_a74c_0277eebedbe0');
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
