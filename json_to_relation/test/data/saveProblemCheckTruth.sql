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
    ('0c098b64_1968_47b0_bc33_45796d9c800c','2013120320221386130958','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/saveProblemCheck.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('97037257_b898_47f1_b13f_336d966392cd','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('384e0785_3215_417c_b417_b1ceb5b018db','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('1fc7e736_0077_4654_95b4_39bb22624951','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('1ca8c462_4518_4d1d_8891_8157e064ff36','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('41247651_8c48_4520_ac0b_299fa28db487','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('7df7f61e_2b85_442f_a751_d388b0348378','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('cb893857_fc93_4434_8047_8f35d0afbb06','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('83a6c5a2_4199_4a13_bb6f_32ef683cfed9','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('00c62160_fb34_4bed_8997_9b6bdceb754f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('d911129e_30d3_4f99_bb36_8e1c174218ae','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('dc79ea7e_10fb_4caa_9cf5_f8a4634ac344','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('80ab1c11_c4ac_4c52_a646_883e9256f2f4','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('8ad14aae_7c37_4f0e_b3bc_3acb365c4962','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('ebd5eb29_6382_44ca_9257_ff29d6d7eca6','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('17fdd275_42cd_4c0d_9e6b_3d12529496a3','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('92bf44de_2660_4624_a7e0_3dcc0f3e24ee','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('b8768f00_0a93_4841_a493_7e95dc1ae779','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('085b95f5_e2a6_4733_bf0f_16702b4dc8bc','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258'),
    ('048a60e5_3f5e_455d_bd7f_8bb632dba845','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('b35262e0_6d09_404d_8a1b_d5a8eb1c5cac','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('bc588b7b_382f_4e75_b289_3176d27d3ace','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('f991fe4a_df4d_493d_b8ba_731108c4480f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('4c6b8c79_ad3b_4051_9c50_d5f2f7227a46','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('dfcf2f09_0aac_4fd9_8827_5e5146527cc9','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('79c75f19_803e_4c0a_bada_86928d4d037e','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('5c090ef4_3e25_4e12_adda_1397568e0a06','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('9e2907a5_de4d_420e_a88d_2ed165a67aa4','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('a68c31c0_9544_4a7b_9d8e_d3a305886709','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('f6d077cd_55ae_4966_9410_cf6094007d32','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('6cabe7f4_f0dc_4de1_a03f_63702ca8af47','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('71ab569a_e42c_41f7_8281_6ae7c63da694','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('6b1aca37_d46e_445e_acf9_2dc851ad7fb4','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('5379e332_0c8a_4686_875d_d010d5c4726b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('883d17a3_917a_432c_9bb8_a5b7b766c95f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('09bb090b_b736_470e_be60_a5b1bdeebebb','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('3aab6d87_b52d_480a_8e66_34a10a5d8a21','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('36234b58_7a55_4f3d_8c54_47f7dbe251de','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1',''),
    ('ec09059a_672a_40e1_b706_25f9b5d29681','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1',''),
    ('842db270_4a7f_48ce_8b1b_bf3db4e97efb','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1',''),
    ('22f71af5_dbfa_404a_b595_f27ef847d470','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1',''),
    ('9b54fb19_1c70_4457_b071_14e0f8c01e29','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1',''),
    ('7e408806_ecd4_4a91_900a_a7e55cb93205','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1',''),
    ('c8146fbb_ac5d_4e1d_8623_3544fe8f7eb5','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1',''),
    ('69670537_8712_485b_aca6_1ff8d1eb3e88','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1',''),
    ('1310b24f_1518_41f1_aca7_d6c30690ecdf','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1',''),
    ('89eacb05_1342_4814_919e_84f12fb54bce','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1',''),
    ('71008546_663a_47ce_8818_9cb2eae86272','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1',''),
    ('9ab8dfc0_a6b2_4394_8edc_9ff25e25677a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1',''),
    ('9b051e8a_750d_4bb8_ba3c_ce46dd797cf8','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1',''),
    ('fdd900b8_d42a_45a5_a746_c9d6aa2b490a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1',''),
    ('861852e5_b0d7_4a88_ad96_f1899520728d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1',''),
    ('6230e17f_cb1a_4393_a27e_78772b5ffa32','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1',''),
    ('4e955237_f320_4055_b836_71767f428f85','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1',''),
    ('f21eebea_9a1f_452c_8909_41333dce886b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('43575030_5bf1_49b9_8e10_74e8c9fde32b',1,'None','','048a60e5_3f5e_455d_bd7f_8bb632dba845','','36234b58_7a55_4f3d_8c54_47f7dbe251de'),
    ('d9dab01c_985f_4b73_be4f_7b5004f44ede',1,'None','','b35262e0_6d09_404d_8a1b_d5a8eb1c5cac','','ec09059a_672a_40e1_b706_25f9b5d29681'),
    ('909c770e_d974_4167_8049_1af6249a5c6a',1,'None','','bc588b7b_382f_4e75_b289_3176d27d3ace','','842db270_4a7f_48ce_8b1b_bf3db4e97efb'),
    ('1575359e_3521_4e26_a3a9_f29c19515fb5',1,'None','','f991fe4a_df4d_493d_b8ba_731108c4480f','','22f71af5_dbfa_404a_b595_f27ef847d470'),
    ('e09c5a69_a1c5_40af_b783_3b7d9b50f7c9',1,'None','','4c6b8c79_ad3b_4051_9c50_d5f2f7227a46','','9b54fb19_1c70_4457_b071_14e0f8c01e29'),
    ('4bb0cfbd_a075_4457_871b_c7802d71b215',1,'None','','dfcf2f09_0aac_4fd9_8827_5e5146527cc9','','7e408806_ecd4_4a91_900a_a7e55cb93205'),
    ('2e1f6c77_3d80_49f1_829c_352cbe07d6c7',1,'None','','79c75f19_803e_4c0a_bada_86928d4d037e','','c8146fbb_ac5d_4e1d_8623_3544fe8f7eb5'),
    ('9e6121e1_0715_4b0d_9c6e_f21051e9a16b',1,'None','','5c090ef4_3e25_4e12_adda_1397568e0a06','','69670537_8712_485b_aca6_1ff8d1eb3e88'),
    ('b9643aa7_1045_45e2_ae58_f0775d14d497',1,'None','','9e2907a5_de4d_420e_a88d_2ed165a67aa4','','1310b24f_1518_41f1_aca7_d6c30690ecdf'),
    ('967c9031_235d_4ec7_bce1_ef94d8714acd',1,'None','','a68c31c0_9544_4a7b_9d8e_d3a305886709','','89eacb05_1342_4814_919e_84f12fb54bce'),
    ('9b7fd3c2_db51_4d91_ba76_a997ad388107',1,'None','','f6d077cd_55ae_4966_9410_cf6094007d32','','71008546_663a_47ce_8818_9cb2eae86272'),
    ('864b75a4_f349_4f88_a719_c8e24fb6d114',1,'None','','6cabe7f4_f0dc_4de1_a03f_63702ca8af47','','9ab8dfc0_a6b2_4394_8edc_9ff25e25677a'),
    ('a479eb37_0d96_4059_aa32_4f3f0d8833e3',1,'None','','71ab569a_e42c_41f7_8281_6ae7c63da694','','9b051e8a_750d_4bb8_ba3c_ce46dd797cf8'),
    ('2e9ac1a2_cdc5_4647_a491_733f70a038ee',1,'None','','6b1aca37_d46e_445e_acf9_2dc851ad7fb4','','fdd900b8_d42a_45a5_a746_c9d6aa2b490a'),
    ('b9b54b73_606f_4e0c_877c_02b3ea81bf80',1,'None','','5379e332_0c8a_4686_875d_d010d5c4726b','','861852e5_b0d7_4a88_ad96_f1899520728d'),
    ('48b0ba9b_77cc_4813_9c67_58bdf6579d02',1,'None','','883d17a3_917a_432c_9bb8_a5b7b766c95f','','6230e17f_cb1a_4393_a27e_78772b5ffa32'),
    ('7094b0bf_b1b5_48f5_8493_d6fc5b31236d',1,'None','','09bb090b_b736_470e_be60_a5b1bdeebebb','','4e955237_f320_4055_b836_71767f428f85'),
    ('c88c0ef4_62ed_4fe7_a6cc_28fdac2058b7',1,'None','','3aab6d87_b52d_480a_8e66_34a10a5d8a21','','f21eebea_9a1f_452c_8909_41333dce886b');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,anon_screen_name,downtime_for,student_id,instructor_id,course_id,course_display_name,resource_display_name,organization,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    ('448db86f_ff63_4004_96c3_27bb98c0b8e4','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','97037257_b898_47f1_b13f_336d966392cd','43575030_5bf1_49b9_8e10_74e8c9fde32b','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('e1d16be1_074f_48d8_9c20_0056cf732ab4','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','384e0785_3215_417c_b417_b1ceb5b018db','d9dab01c_985f_4b73_be4f_7b5004f44ede','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('148522f6_0d20_4ab4_b917_c8926baf93a3','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','1fc7e736_0077_4654_95b4_39bb22624951','909c770e_d974_4167_8049_1af6249a5c6a','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('f2a5df89_c855_4ab5_ad2e_d3304ee8114a','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','1ca8c462_4518_4d1d_8891_8157e064ff36','1575359e_3521_4e26_a3a9_f29c19515fb5','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('f049d549_2557_4acc_987c_62190c93c4f0','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','41247651_8c48_4520_ac0b_299fa28db487','e09c5a69_a1c5_40af_b783_3b7d9b50f7c9','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('69ce917a_1997_47b6_a98d_158e5ebe8ab3','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','7df7f61e_2b85_442f_a751_d388b0348378','4bb0cfbd_a075_4457_871b_c7802d71b215','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('f619ba07_77db_4cff_bc50_7e066bc49338','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','cb893857_fc93_4434_8047_8f35d0afbb06','2e1f6c77_3d80_49f1_829c_352cbe07d6c7','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('fa92f4eb_9cc4_4b36_b2cc_dd12de632cb0','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','83a6c5a2_4199_4a13_bb6f_32ef683cfed9','9e6121e1_0715_4b0d_9c6e_f21051e9a16b','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('0af0ec89_d722_4452_a636_15f06f116469','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','00c62160_fb34_4bed_8997_9b6bdceb754f','b9643aa7_1045_45e2_ae58_f0775d14d497','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('98b653fe_460e_4ec7_8854_0048734e3a7e','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','d911129e_30d3_4f99_bb36_8e1c174218ae','967c9031_235d_4ec7_bce1_ef94d8714acd','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('3c4c0f97_3167_4abe_b21c_2519939fd48e','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','dc79ea7e_10fb_4caa_9cf5_f8a4634ac344','9b7fd3c2_db51_4d91_ba76_a997ad388107','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('86a2f4d2_e56c_4928_9cb7_ddcb799160b6','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','80ab1c11_c4ac_4c52_a646_883e9256f2f4','864b75a4_f349_4f88_a719_c8e24fb6d114','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('7c0488b2_8ab8_452f_aeba_0752a2349a45','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','8ad14aae_7c37_4f0e_b3bc_3acb365c4962','a479eb37_0d96_4059_aa32_4f3f0d8833e3','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('6009e98f_9b8c_41a9_bdc2_88c63b22b723','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','ebd5eb29_6382_44ca_9257_ff29d6d7eca6','2e9ac1a2_cdc5_4647_a491_733f70a038ee','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('c472acf4_6351_4efd_866c_dbea41f07407','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','17fdd275_42cd_4c0d_9e6b_3d12529496a3','b9b54b73_606f_4e0c_877c_02b3ea81bf80','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('1f775689_1132_46c3_a284_d74e1dd68e15','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','92bf44de_2660_4624_a7e0_3dcc0f3e24ee','48b0ba9b_77cc_4813_9c67_58bdf6579d02','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('e261a70e_c777_455c_84e4_fec7c777817a','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','b8768f00_0a93_4841_a493_7e95dc1ae779','7094b0bf_b1b5_48f5_8493_d6fc5b31236d','0c098b64_1968_47b0_bc33_45796d9c800c'),
    ('a41eb5e7_afbb_4c2c_bdd3_81c0d1d319be','b11725b1_9fb2_4a65_bad6_44c60f16270b','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','085b95f5_e2a6_4733_bf0f_16702b4dc8bc','c88c0ef4_62ed_4fe7_a6cc_28fdac2058b7','0c098b64_1968_47b0_bc33_45796d9c800c');
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
