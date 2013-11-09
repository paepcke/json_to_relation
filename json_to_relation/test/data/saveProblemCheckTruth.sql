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
    ('0a8458b3_240c_44e1_86e2_8c1e441bc18e','2013110919261384053990','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/saveProblemCheck.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('0e88f3ba_a666_467c_9839_83463bf8597a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('c165479c_b9fe_462f_ab03_ecb938841af1','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('813e7057_6ef8_49de_9b9d_06b7c134d133','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('d662e802_3882_4da5_aaec_83f6b3bded51','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('92270dd1_dacc_4e41_ab99_218e523c1844','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('f047097d_1086_4ec6_bfb7_3fdd4e674e8d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('edfe31db_aaa8_4ec8_94f7_e5b910f2650a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('1d86e032_3ae5_4b67_8330_15f99c9203c6','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('797e1a2a_abfd_4b9c_a1c5_ad6cac9a0658','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('7d04982b_956d_45ec_82f4_fb9fd1528094','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('d530aabc_2497_49db_9da0_1755808fe02b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('1ea1f0f9_dfae_4d1e_99f4_c5519e576bc7','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('c1e5b759_9521_4832_92dc_05686d70cb12','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('308b260f_dda8_4101_aa2b_b2db549b3b40','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('bf5989b0_9090_44ec_857d_032cea9aa140','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('e660a811_0ee6_49a0_99da_566cddd745b5','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('7e06a23f_9c1c_46f2_893a_df0d7006c99a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('74866998_9f78_40e3_9311_db56a9457020','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258'),
    ('8af0e647_5d3b_4c7b_a84e_216ab2bb7d62','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('ab376e9d_09f2_4b4b_b8b5_16bd249bd4c6','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('9ec47118_ec18_4fa1_8af4_69cf35e57aa8','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('ffa0be51_de25_42d8_92af_8a6d022d8e68','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('13edd9b4_0d73_4026_b1ba_1d0cf0c3f407','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('443fc92a_e5a3_4db5_b78b_d3301af3c319','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('fdb73afc_7d34_413d_8506_b55fea3c1c3b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('a98b6952_4b7f_46a0_b4ba_674350336d8f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('94e43054_49ce_4127_b1cf_0a6bfee1a50b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('7bcf815d_709e_4720_8937_06539c7ee0cc','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('96cb912c_1218_476c_a763_3ccb5b474e00','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('0cb15ff5_e608_4ced_b9fd_8f7ee0c12322','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('736681be_dd31_4f94_926b_47dc6e120efa','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('99efc206_1936_4f3f_819a_438d72ef3cf3','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('727e4be1_9780_4fa7_ba60_dde6dbe6b63f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('9555dcf8_582b_45bf_a60d_05910559bc97','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('4a827848_668d_45ee_b402_6d2558290df8','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('b7686a85_f990_42ad_9903_960db2f379a7','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('cd93c4ab_11d8_45b6_9180_0f89affeada9','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1',''),
    ('8d3594db_6baa_4944_a61f_cb55bd523f48','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1',''),
    ('7e5cde74_ae6d_45c7_81b4_be01c79ae2be','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1',''),
    ('c8ee66d0_7beb_4506_8460_ce190edac8ca','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1',''),
    ('ed22fa96_073a_4c6b_ba75_c2fdb3428fc2','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1',''),
    ('ac1140c1_41b4_46a6_bfd9_5ee93750a07b','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1',''),
    ('089608e4_62a7_41ae_90d5_c499a3270c7a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1',''),
    ('136cc4f9_5c63_4de0_ab7d_1a6ddf0f35b9','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1',''),
    ('9180f043_f185_4b34_862a_8284e33ffcba','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1',''),
    ('0aa2ff61_0a1f_4260_a847_36741dec4170','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1',''),
    ('6b3e42fc_8dc9_42a7_af6d_02ba1eff8bda','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1',''),
    ('5b41c397_7620_488b_a683_bb40717ed8de','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1',''),
    ('fa722812_f236_4ab5_bd9c_b520af2d5021','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1',''),
    ('38e1a920_6d36_4e08_b3db_229d42753992','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1',''),
    ('f2cab5e5_99ef_4add_9d4b_75fb14b1a991','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1',''),
    ('a88c5633_b2f1_48ae_a7d2_1d3156330f11','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1',''),
    ('4b605ea1_05c6_4f1e_816e_631a1c322023','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1',''),
    ('1ba19951_218e_4018_9545_c832ccce3642','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('d33429df_35dd_4f7e_9775_f7c0a83f93af',1,'None','','8af0e647_5d3b_4c7b_a84e_216ab2bb7d62','','cd93c4ab_11d8_45b6_9180_0f89affeada9'),
    ('dc8a11e8_7ce5_40d8_b86e_9c54c9babadd',1,'None','','ab376e9d_09f2_4b4b_b8b5_16bd249bd4c6','','8d3594db_6baa_4944_a61f_cb55bd523f48'),
    ('fe05470c_86c3_4943_a164_3ccca608cfd1',1,'None','','9ec47118_ec18_4fa1_8af4_69cf35e57aa8','','7e5cde74_ae6d_45c7_81b4_be01c79ae2be'),
    ('aa8aae3e_f6f7_4ceb_b7f1_97bfca369d47',1,'None','','ffa0be51_de25_42d8_92af_8a6d022d8e68','','c8ee66d0_7beb_4506_8460_ce190edac8ca'),
    ('815b09fd_06bc_468e_aa73_4ccb565e62b2',1,'None','','13edd9b4_0d73_4026_b1ba_1d0cf0c3f407','','ed22fa96_073a_4c6b_ba75_c2fdb3428fc2'),
    ('f6832518_8da5_4bbf_ac1d_95d83e37cee2',1,'None','','443fc92a_e5a3_4db5_b78b_d3301af3c319','','ac1140c1_41b4_46a6_bfd9_5ee93750a07b'),
    ('1e032029_71d7_47d6_9db0_53c83067da46',1,'None','','fdb73afc_7d34_413d_8506_b55fea3c1c3b','','089608e4_62a7_41ae_90d5_c499a3270c7a'),
    ('eb90d871_948c_4159_a16e_69b90b6e30bc',1,'None','','a98b6952_4b7f_46a0_b4ba_674350336d8f','','136cc4f9_5c63_4de0_ab7d_1a6ddf0f35b9'),
    ('1cca19ca_8917_4204_a1f0_25ad8dc578e2',1,'None','','94e43054_49ce_4127_b1cf_0a6bfee1a50b','','9180f043_f185_4b34_862a_8284e33ffcba'),
    ('5184deee_9e53_41c8_b884_a7671aa776f8',1,'None','','7bcf815d_709e_4720_8937_06539c7ee0cc','','0aa2ff61_0a1f_4260_a847_36741dec4170'),
    ('81fff230_58b8_42fc_8b8c_763b4e8ae136',1,'None','','96cb912c_1218_476c_a763_3ccb5b474e00','','6b3e42fc_8dc9_42a7_af6d_02ba1eff8bda'),
    ('2d6ac244_b368_4723_a859_73353af3e065',1,'None','','0cb15ff5_e608_4ced_b9fd_8f7ee0c12322','','5b41c397_7620_488b_a683_bb40717ed8de'),
    ('20b93982_bc55_4035_8454_78d3e0aab08b',1,'None','','736681be_dd31_4f94_926b_47dc6e120efa','','fa722812_f236_4ab5_bd9c_b520af2d5021'),
    ('18c774a1_ecd5_4c2a_84ed_6b3e7d0d81c3',1,'None','','99efc206_1936_4f3f_819a_438d72ef3cf3','','38e1a920_6d36_4e08_b3db_229d42753992'),
    ('a177dafd_85e6_4446_966a_6ae030ac7bff',1,'None','','727e4be1_9780_4fa7_ba60_dde6dbe6b63f','','f2cab5e5_99ef_4add_9d4b_75fb14b1a991'),
    ('070ee8a8_3505_41dd_a143_b51baba50925',1,'None','','9555dcf8_582b_45bf_a60d_05910559bc97','','a88c5633_b2f1_48ae_a7d2_1d3156330f11'),
    ('eff531db_c59e_43e4_8aae_b8d1831a73e3',1,'None','','4a827848_668d_45ee_b402_6d2558290df8','','4b605ea1_05c6_4f1e_816e_631a1c322023'),
    ('c3448aef_b8ed_4351_a5d2_d7f9158bb516',1,'None','','b7686a85_f990_42ad_9903_960db2f379a7','','1ba19951_218e_4018_9545_c832ccce3642');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,anon_screen_name,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    ('ed1bf326_71fe_4829_8838_05566dadcbf0','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','0e88f3ba_a666_467c_9839_83463bf8597a','d33429df_35dd_4f7e_9775_f7c0a83f93af','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('02027ea7_bf8d_421d_a324_a0a12d3366e4','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','c165479c_b9fe_462f_ab03_ecb938841af1','dc8a11e8_7ce5_40d8_b86e_9c54c9babadd','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('72adb08d_66bc_4f7e_87fb_7f1c3ab8392c','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','813e7057_6ef8_49de_9b9d_06b7c134d133','fe05470c_86c3_4943_a164_3ccca608cfd1','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('f45bfff1_a328_47d1_bed7_fd36dd844142','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','d662e802_3882_4da5_aaec_83f6b3bded51','aa8aae3e_f6f7_4ceb_b7f1_97bfca369d47','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('76c4cf53_e9b7_4b00_925e_33d73a5bbe4e','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','92270dd1_dacc_4e41_ab99_218e523c1844','815b09fd_06bc_468e_aa73_4ccb565e62b2','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('cb01d991_87a1_47ff_926e_7bd763fa6c88','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','f047097d_1086_4ec6_bfb7_3fdd4e674e8d','f6832518_8da5_4bbf_ac1d_95d83e37cee2','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('6cfa3ae3_a0fb_4c45_a717_26b422e50278','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','edfe31db_aaa8_4ec8_94f7_e5b910f2650a','1e032029_71d7_47d6_9db0_53c83067da46','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('bb58f95c_5567_4294_9649_1363547b37fe','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','1d86e032_3ae5_4b67_8330_15f99c9203c6','eb90d871_948c_4159_a16e_69b90b6e30bc','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('2f766a92_f879_41c1_a03d_4f155f3b4dc3','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','797e1a2a_abfd_4b9c_a1c5_ad6cac9a0658','1cca19ca_8917_4204_a1f0_25ad8dc578e2','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('aaa1e0e9_6af0_46c1_bb0c_ec2c37db8ac8','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','7d04982b_956d_45ec_82f4_fb9fd1528094','5184deee_9e53_41c8_b884_a7671aa776f8','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('11dc0120_afb6_4dca_9493_e77aecbe6a3c','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','d530aabc_2497_49db_9da0_1755808fe02b','81fff230_58b8_42fc_8b8c_763b4e8ae136','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('7a519602_4c0e_40a9_8727_da42298b5059','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','1ea1f0f9_dfae_4d1e_99f4_c5519e576bc7','2d6ac244_b368_4723_a859_73353af3e065','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('e02b2c9a_56cb_48bc_b15f_bdb74d201ee7','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','c1e5b759_9521_4832_92dc_05686d70cb12','20b93982_bc55_4035_8454_78d3e0aab08b','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('9d4eb533_bee6_4a52_92e3_925321c5c4a8','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','308b260f_dda8_4101_aa2b_b2db549b3b40','18c774a1_ecd5_4c2a_84ed_6b3e7d0d81c3','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('0df524f3_cea5_4dcb_83cc_0cf243848f56','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','bf5989b0_9090_44ec_857d_032cea9aa140','a177dafd_85e6_4446_966a_6ae030ac7bff','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('9d484a28_7603_406f_9dfd_491a6255f1d0','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','e660a811_0ee6_49a0_99da_566cddd745b5','070ee8a8_3505_41dd_a143_b51baba50925','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('c0fc012b_66af_4aab_8645_2fcf90598b01','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','7e06a23f_9c1c_46f2_893a_df0d7006c99a','eff531db_c59e_43e4_8aae_b8d1831a73e3','0a8458b3_240c_44e1_86e2_8c1e441bc18e'),
    ('77e53daf_bf8d_4837_b367_517d47b0b6b9','55cc4bef_5dea_43a6_8467_8973d10d8405','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','74866998_9f78_40e3_9311_db56a9457020','c3448aef_b8ed_4351_a5d2_d7f9158bb516','0a8458b3_240c_44e1_86e2_8c1e441bc18e');
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
