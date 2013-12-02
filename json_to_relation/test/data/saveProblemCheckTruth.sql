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
    ('9c0244c3_36d7_41d8_954e_f013e704b40c','2013120221551386050159','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/saveProblemCheck.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('13bd3ee2_f3dc_4f6e_ae6a_73a8e74c2d69','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('d20cf12e_76f6_47ea_9cdb_62ae5bd3539d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('fe89c467_7523_423f_886b_0c2c6684cca7','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('bb5ebe17_a2f3_49cd_8851_fb5cf9e80155','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('3507669a_894e_4b14_a6cb_17474c3a0df0','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('bbf3df38_81fc_434e_9ed3_1dfedc67bca0','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('a704919c_335e_4a07_aede_daa06ba04f9d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('8ac02492_6458_4785_874e_711be1cc5c8a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('458f1907_7fb9_4581_8e2b_cbb23485cf15','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('ee30f648_3218_4089_a8b7_8b7880f040ad','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('b6de9b53_d779_4719_a7e5_5e95d671f6e3','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('ec69346f_a74e_471e_81bc_75a8ac67e802','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('8bd48574_03b2_4e5e_9f49_ce0252bdcfb0','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('18efc1a6_6292_4ada_bbce_c93052df7f5c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('9ab3deaa_0900_4392_8cf8_719faef295b2','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('7dff7c80_0e3a_4d8f_be36_1081ead475c0','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('3ab1524c_5bb6_45eb_91a2_2f298757fff8','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('c8d14c12_3829_427e_a867_de3cd7de204b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258'),
    ('a5038b7b_07e2_4f72_b842_1c32ba202690','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('6eb59692_8351_4c61_beba_4a928c965fe2','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('01f02e87_98c6_4958_a0e5_3a07aa46e313','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('edaa98d2_e3e5_4375_951d_577aa1a724be','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('26a95a4f_8365_4be5_aa6b_d8c915110f90','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('cd9a9614_3955_4b59_aef3_ff80e46ea297','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('23e4d5c0_9eaa_4df8_98ef_122a2df4733d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('ad7925fd_55bb_44ac_96f5_737b92db9d91','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('f1d5dfb6_ed7a_418d_9a73_96d9a39856a7','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('4610b724_f4c6_44cf_8be9_1cc16e1e9766','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('f666f198_e78b_4347_873c_61057093544f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('1c154125_f16d_4ed4_8759_90c61fe1c3af','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('595d710f_5524_468a_9f3b_ea2d992be07c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('0c5d4d08_8e26_4ea1_b7ce_5def4c9f103b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('ab2600f1_3fd3_444e_baa3_c7009a2e7b59','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('16c223bb_c60a_4ec9_9aaa_23ef248012a9','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('759cc580_aca0_42a5_a1b8_9908144bff22','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('dabd21b2_4892_4dca_9ae6_46c8094ab51c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('c7725fad_765e_478c_9762_d3f027567597','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1',''),
    ('e634ffea_dbc5_4ed0_b801_492a77e35342','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1',''),
    ('1b755883_a0da_4513_adab_032e4fffd74b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1',''),
    ('46e8eaa8_534e_472e_8683_e8f20a29b07b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1',''),
    ('583c0ae8_c090_43b5_bded_c3ee1ba10ca1','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1',''),
    ('1d9b5014_4b77_4349_be14_d4264348e6b3','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1',''),
    ('d13d6200_26fe_4784_8a3b_f75fc4ef1962','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1',''),
    ('09712f63_b0e0_4bfc_a4e1_8afc1789b8b9','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1',''),
    ('079a8cfd_7b2a_4720_b976_44748e8f0b4d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1',''),
    ('6589f4d5_4726_4917_99e9_bbece1ebb7e4','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1',''),
    ('3c544222_371d_47d0_abc6_035ba6195d90','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1',''),
    ('d46e71e6_d099_4a83_a8cf_a2ae29920360','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1',''),
    ('0679eecf_ccb1_4585_96f8_8bdeed8ece3f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1',''),
    ('17de8277_4043_41a3_ad62_c9ccd8768411','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1',''),
    ('e02aa897_46b2_4fcb_bb4a_f25e00027aee','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1',''),
    ('4f6628ad_271e_44f3_900c_430fbe150926','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1',''),
    ('2b0da94f_9edb_4513_85da_30c37eef00a1','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1',''),
    ('a73e88b9_ac37_4700_bbeb_ee75aea8c371','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('f8d29851_4eb2_4573_a52b_5de87d7f0fcd',1,'None','','a5038b7b_07e2_4f72_b842_1c32ba202690','','c7725fad_765e_478c_9762_d3f027567597'),
    ('44b2071b_7a95_4834_8bbb_336bb4731460',1,'None','','6eb59692_8351_4c61_beba_4a928c965fe2','','e634ffea_dbc5_4ed0_b801_492a77e35342'),
    ('a8d0136a_b9e5_41fc_a68b_a2ae3aea877e',1,'None','','01f02e87_98c6_4958_a0e5_3a07aa46e313','','1b755883_a0da_4513_adab_032e4fffd74b'),
    ('007a177e_27dc_408c_a646_f6a3dec5810e',1,'None','','edaa98d2_e3e5_4375_951d_577aa1a724be','','46e8eaa8_534e_472e_8683_e8f20a29b07b'),
    ('da73bd5a_7cf9_4797_83d8_f60dc31e3036',1,'None','','26a95a4f_8365_4be5_aa6b_d8c915110f90','','583c0ae8_c090_43b5_bded_c3ee1ba10ca1'),
    ('ec0cdd2a_2ee1_4b09_a17d_7a0e706e9274',1,'None','','cd9a9614_3955_4b59_aef3_ff80e46ea297','','1d9b5014_4b77_4349_be14_d4264348e6b3'),
    ('387c84b8_f5a3_4621_b532_c52c9429cabf',1,'None','','23e4d5c0_9eaa_4df8_98ef_122a2df4733d','','d13d6200_26fe_4784_8a3b_f75fc4ef1962'),
    ('7a55761e_421f_405f_be81_3087087db5c6',1,'None','','ad7925fd_55bb_44ac_96f5_737b92db9d91','','09712f63_b0e0_4bfc_a4e1_8afc1789b8b9'),
    ('f669c00f_816b_4ebe_84a1_4f4259dc0c82',1,'None','','f1d5dfb6_ed7a_418d_9a73_96d9a39856a7','','079a8cfd_7b2a_4720_b976_44748e8f0b4d'),
    ('9a4ec889_68bc_4d62_9ab6_3c0131d9013a',1,'None','','4610b724_f4c6_44cf_8be9_1cc16e1e9766','','6589f4d5_4726_4917_99e9_bbece1ebb7e4'),
    ('93e6995b_fa86_4c0b_a832_931d0305d6dd',1,'None','','f666f198_e78b_4347_873c_61057093544f','','3c544222_371d_47d0_abc6_035ba6195d90'),
    ('4aab8cb9_4526_4e96_85a8_b40e6769c62e',1,'None','','1c154125_f16d_4ed4_8759_90c61fe1c3af','','d46e71e6_d099_4a83_a8cf_a2ae29920360'),
    ('67edfe96_817b_4555_a26c_d002cc837a43',1,'None','','595d710f_5524_468a_9f3b_ea2d992be07c','','0679eecf_ccb1_4585_96f8_8bdeed8ece3f'),
    ('adfb9c0e_2bd9_47c9_9dbc_36dd8eaf1220',1,'None','','0c5d4d08_8e26_4ea1_b7ce_5def4c9f103b','','17de8277_4043_41a3_ad62_c9ccd8768411'),
    ('9a95ca9a_f7fd_4187_9165_827c1b9e9f67',1,'None','','ab2600f1_3fd3_444e_baa3_c7009a2e7b59','','e02aa897_46b2_4fcb_bb4a_f25e00027aee'),
    ('8c67bf28_af32_4ef9_8509_726fc6c4dd0b',1,'None','','16c223bb_c60a_4ec9_9aaa_23ef248012a9','','4f6628ad_271e_44f3_900c_430fbe150926'),
    ('3d81d250_5751_4ede_92c3_e76052ae4091',1,'None','','759cc580_aca0_42a5_a1b8_9908144bff22','','2b0da94f_9edb_4513_85da_30c37eef00a1'),
    ('4a7dbd23_1799_42ea_a984_582c66ef5ee1',1,'None','','dabd21b2_4892_4dca_9ae6_46c8094ab51c','','a73e88b9_ac37_4700_bbeb_ee75aea8c371');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,anon_screen_name,downtime_for,student_id,instructor_id,course_id,course_display_name,resource_display_name,organization,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    ('c9835d0b_cf55_4b79_b71b_366d10aee1b7','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','13bd3ee2_f3dc_4f6e_ae6a_73a8e74c2d69','f8d29851_4eb2_4573_a52b_5de87d7f0fcd','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('d05f879c_43c4_4960_bade_f40281f81ef1','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','d20cf12e_76f6_47ea_9cdb_62ae5bd3539d','44b2071b_7a95_4834_8bbb_336bb4731460','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('93b99937_0c6f_4189_995d_763a47bae5f5','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','fe89c467_7523_423f_886b_0c2c6684cca7','a8d0136a_b9e5_41fc_a68b_a2ae3aea877e','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('6f6c8bf8_a7ac_4075_a795_2463642fa695','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','bb5ebe17_a2f3_49cd_8851_fb5cf9e80155','007a177e_27dc_408c_a646_f6a3dec5810e','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('7586c1f1_b61a_40d6_9759_7f0db6e4a9d1','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','3507669a_894e_4b14_a6cb_17474c3a0df0','da73bd5a_7cf9_4797_83d8_f60dc31e3036','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('602c3d0a_3f32_445f_8193_a4252034cc56','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','bbf3df38_81fc_434e_9ed3_1dfedc67bca0','ec0cdd2a_2ee1_4b09_a17d_7a0e706e9274','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('bfc76597_1abd_433d_ad2c_ed8ca0652e55','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','a704919c_335e_4a07_aede_daa06ba04f9d','387c84b8_f5a3_4621_b532_c52c9429cabf','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('b3745172_4d59_4598_af0c_109fa6a02b61','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','8ac02492_6458_4785_874e_711be1cc5c8a','7a55761e_421f_405f_be81_3087087db5c6','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('85e35ef5_b77f_4834_a9bf_35e1856db5de','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','458f1907_7fb9_4581_8e2b_cbb23485cf15','f669c00f_816b_4ebe_84a1_4f4259dc0c82','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('50692292_0fc5_4c53_bd0e_1830d60cccdf','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','ee30f648_3218_4089_a8b7_8b7880f040ad','9a4ec889_68bc_4d62_9ab6_3c0131d9013a','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('c2080beb_6966_4dba_80f9_112bffd793dd','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','b6de9b53_d779_4719_a7e5_5e95d671f6e3','93e6995b_fa86_4c0b_a832_931d0305d6dd','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('0ae614b0_f422_41cf_8169_da483fa70b75','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','ec69346f_a74e_471e_81bc_75a8ac67e802','4aab8cb9_4526_4e96_85a8_b40e6769c62e','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('99c3d61f_1b13_4d00_8b2d_da65f0818da2','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','8bd48574_03b2_4e5e_9f49_ce0252bdcfb0','67edfe96_817b_4555_a26c_d002cc837a43','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('498374e1_0585_4809_83c1_12bedf7966af','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','18efc1a6_6292_4ada_bbce_c93052df7f5c','adfb9c0e_2bd9_47c9_9dbc_36dd8eaf1220','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('ce283129_e9d4_4935_b985_109e50309bc0','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','9ab3deaa_0900_4392_8cf8_719faef295b2','9a95ca9a_f7fd_4187_9165_827c1b9e9f67','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('334fa2da_9bd8_4532_9082_07cfdc70d51f','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','7dff7c80_0e3a_4d8f_be36_1081ead475c0','8c67bf28_af32_4ef9_8509_726fc6c4dd0b','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('3257c2fe_6e64_48d3_b329_b077127b9ff3','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','3ab1524c_5bb6_45eb_91a2_2f298757fff8','3d81d250_5751_4ede_92c3_e76052ae4091','9c0244c3_36d7_41d8_954e_f013e704b40c'),
    ('6bcd4a81_7b32_4335_bc13_a3083276aa06','1ae4ba7e_3951_4ff0_a9dc_4ff42ef90de2','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','c8d14c12_3829_427e_a867_de3cd7de204b','4a7dbd23_1799_42ea_a984_582c66ef5ee1','9c0244c3_36d7_41d8_954e_f013e704b40c');
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
