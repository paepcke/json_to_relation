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
    ('e6b7215f_971c_400a_894b_949d17a7da1a','2013120302351386066930','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/saveProblemCheck.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('64a8586d_6f4e_4edd_9b2c_12a61ccc3689','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('8bdc49bb_d69d_4fc7_abfb_d9c85ed2c4bd','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('1f0e6499_dda8_4c95_958c_3e93627fd547','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('f5cf01bf_4113_4a79_b034_f8b7891f7062','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('f0adc9b0_fff5_4071_aa7e_9313cdb14ebc','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('06f24060_7af7_4676_b3ec_901525b12e8d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('f7ee0e4a_a473_4bea_817c_e69a934e1a10','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('76b610ee_22de_4724_b290_748d2177c5cc','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('2cc09da4_803e_4d71_bb48_6b0b7472136d','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('9a75bb38_9649_4789_b9dd_f37f23136d83','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('88f0df13_aea9_4c3c_82d2_7b57cb89188a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('56ace647_bcbb_4da8_b908_7d5dc4c2d68e','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('9e2ee321_b10f_48fb_ad5e_2d0745f489fd','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('8fb44718_d427_4a4a_bc40_1cc5f793bb3e','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('c393e30f_271b_4df3_81d7_57244a4c4a51','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('6faba674_4693_448f_a2e8_7ec255dcf034','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('0ddba420_7c61_42a3_9560_c88213ba4416','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('58e97d43_9418_4293_b785_2d285592d0df','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258'),
    ('c947e7d2_af53_409f_a4a3_f57b9d278ca4','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','66.3','Medicine-HRP258'),
    ('fa055da3_cad7_4cf1_b33f_db90ef84d166','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.58','Medicine-HRP258'),
    ('1dffd1cb_13ed_45cd_9a1c_beb450b7e729','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','Binary','Medicine-HRP258'),
    ('3021c0b2_ca86_45ab_a768_36b23cd68827','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','choice_2','Medicine-HRP258'),
    ('f4693ae9_431d_4637_801b_32db4c65fff3','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','73.9','Medicine-HRP258'),
    ('2b132160_8f42_4845_9366_6e8f66a14d67','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4','Medicine-HRP258'),
    ('546c7c7a_bea0_4f8e_b650_aedfd3424f4a','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','53','Medicine-HRP258'),
    ('ca6b4b14_2cb8_40d6_bf90_e8ac2650a1ce','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','choice_3','Medicine-HRP258'),
    ('b33aede3_e202_45da_b362_9f63daa94868','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','choice_0','Medicine-HRP258'),
    ('29a041f4_0e99_4dd4_a8f0_650697259101','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','3','Medicine-HRP258'),
    ('ea4ab264_435a_460a_861f_c821550ccb36','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','1','Medicine-HRP258'),
    ('81bd9283_8f1c_4921_a14c_c0582e502d61','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','choice_2','Medicine-HRP258'),
    ('65a6ab63_f84d_4f6a_98e6_6484d966c8fe','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','0.25','Medicine-HRP258'),
    ('5587218e_9493_449a_bab3_39d8d0f84978','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','81','Medicine-HRP258'),
    ('39872300_93ef_4bb0_816c_71759975d760','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','14','Medicine-HRP258'),
    ('01115bea_9cec_4b78_ac99_4788a0630dd0','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','Nominal','Medicine-HRP258'),
    ('ab4c1fbc_4902_424b_b694_d54f01226e50','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','20','Medicine-HRP258'),
    ('6b8321cc_e07d_4f07_9858_56e25fc90573','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','0.47','Medicine-HRP258');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('87af2e92_3457_410a_b2bb_86f80b33db76','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1',''),
    ('7c43c134_dcfe_473c_a5ec_e5cdbf857e04','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1',''),
    ('d18011b4_46d9_4946_88d3_71d614cf63b5','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1',''),
    ('13587002_dc3b_4c46_a173_e0c075f0ae8f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1',''),
    ('586f0c5e_c059_4436_b432_ca7c306a1dd3','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1',''),
    ('678ef048_556b_461b_a629_c5423317bdeb','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1',''),
    ('2645092e_9334_4ae4_ab04_b96937c1a8dc','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1',''),
    ('d43d0b8f_5ece_4e8a_b702_dd687f0805fe','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1',''),
    ('ab6b3c8b_fb48_4b84_9cde_c4e15ae07d31','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1',''),
    ('2cd28cd2_89ff_4ac0_ac2e_170fb64adddd','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1',''),
    ('872e457e_d876_41ac_b246_32b340d1375e','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1',''),
    ('13a73b64_b12c_4da0_93f7_8504c9995bed','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1',''),
    ('8d56fb7b_1202_4b42_a3d1_f59d0a95c7dd','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1',''),
    ('f0f497c7_bf33_4d91_a753_7c5a77054d78','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1',''),
    ('be1c0b5c_f783_4db7_ac9d_dbb8ac339f8f','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1',''),
    ('f7bd286f_65e3_4ec5_9975_f3f700b2ab61','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1',''),
    ('0550e38a_6424_425b_ad07_360e1da0e37e','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1',''),
    ('fdc94dbb_6ff2_467c_ab6f_2b9a010e509c','i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('243a1836_fb3c_45fa_bd04_d76e48824bed',1,'None','','c947e7d2_af53_409f_a4a3_f57b9d278ca4','','87af2e92_3457_410a_b2bb_86f80b33db76'),
    ('8233caca_7e23_4261_b155_c60e56f6d4ab',1,'None','','fa055da3_cad7_4cf1_b33f_db90ef84d166','','7c43c134_dcfe_473c_a5ec_e5cdbf857e04'),
    ('ef324b52_550a_4afb_9776_9585ff4bccd7',1,'None','','1dffd1cb_13ed_45cd_9a1c_beb450b7e729','','d18011b4_46d9_4946_88d3_71d614cf63b5'),
    ('226ca87b_5dfa_4c98_a432_7be6290ebc22',1,'None','','3021c0b2_ca86_45ab_a768_36b23cd68827','','13587002_dc3b_4c46_a173_e0c075f0ae8f'),
    ('574e71df_bbcf_4eb4_bd63_e437289bf42d',1,'None','','f4693ae9_431d_4637_801b_32db4c65fff3','','586f0c5e_c059_4436_b432_ca7c306a1dd3'),
    ('99ddc99a_4b0e_4e9b_b2e7_0e73f1fe77f3',1,'None','','2b132160_8f42_4845_9366_6e8f66a14d67','','678ef048_556b_461b_a629_c5423317bdeb'),
    ('9802af4f_5460_4520_b88d_9901401af488',1,'None','','546c7c7a_bea0_4f8e_b650_aedfd3424f4a','','2645092e_9334_4ae4_ab04_b96937c1a8dc'),
    ('c7da74d3_86e7_4937_b9cc_50ba6c8cd86d',1,'None','','ca6b4b14_2cb8_40d6_bf90_e8ac2650a1ce','','d43d0b8f_5ece_4e8a_b702_dd687f0805fe'),
    ('94b2c0e3_90e7_4bac_b138_8916c664de58',1,'None','','b33aede3_e202_45da_b362_9f63daa94868','','ab6b3c8b_fb48_4b84_9cde_c4e15ae07d31'),
    ('d5828a7c_d38c_4dd6_bb1e_5498037be03d',1,'None','','29a041f4_0e99_4dd4_a8f0_650697259101','','2cd28cd2_89ff_4ac0_ac2e_170fb64adddd'),
    ('b86be180_f01d_4978_bb94_1bc3ab9d4348',1,'None','','ea4ab264_435a_460a_861f_c821550ccb36','','872e457e_d876_41ac_b246_32b340d1375e'),
    ('fe956b17_2b7e_474c_9cba_ee83f96b5c40',1,'None','','81bd9283_8f1c_4921_a14c_c0582e502d61','','13a73b64_b12c_4da0_93f7_8504c9995bed'),
    ('bc9c20f4_54d2_4820_81f5_6618b7b85cce',1,'None','','65a6ab63_f84d_4f6a_98e6_6484d966c8fe','','8d56fb7b_1202_4b42_a3d1_f59d0a95c7dd'),
    ('4c03617e_ec00_4182_91c1_574869d01f55',1,'None','','5587218e_9493_449a_bab3_39d8d0f84978','','f0f497c7_bf33_4d91_a753_7c5a77054d78'),
    ('1b45e3f5_8103_4f96_b552_083c3514c74c',1,'None','','39872300_93ef_4bb0_816c_71759975d760','','be1c0b5c_f783_4db7_ac9d_dbb8ac339f8f'),
    ('c0b55310_4512_4d14_9718_aca7e99ffc8b',1,'None','','01115bea_9cec_4b78_ac99_4788a0630dd0','','f7bd286f_65e3_4ec5_9975_f3f700b2ab61'),
    ('7eab6d7d_28c0_4ead_b3fc_c045a5fff598',1,'None','','ab4c1fbc_4902_424b_b694_d54f01226e50','','0550e38a_6424_425b_ad07_360e1da0e37e'),
    ('c44b6ef5_3e04_46ca_acc9_ed42a727bd98',1,'None','','6b8321cc_e07d_4f07_9858_56e25fc90573','','fdc94dbb_6ff2_467c_ab6f_2b9a010e509c');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,anon_screen_name,downtime_for,student_id,instructor_id,course_id,course_display_name,resource_display_name,organization,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    ('f17f6d11_897a_4d68_842d_43bc94fd08cb','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_16_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','64a8586d_6f4e_4edd_9b2c_12a61ccc3689','243a1836_fb3c_45fa_bd04_d76e48824bed','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('4570a9f4_2a36_445a_9976_1bc041182248','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','8bdc49bb_d69d_4fc7_abfb_d9c85ed2c4bd','8233caca_7e23_4261_b155_c60e56f6d4ab','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('3b86bfbb_0382_453e_b6a1_f8b151fd29bd','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_12_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','1f0e6499_dda8_4c95_958c_3e93627fd547','ef324b52_550a_4afb_9776_9585ff4bccd7','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('cf2200da_4376_46e7_8e18_be9eed164d82','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','f5cf01bf_4113_4a79_b034_f8b7891f7062','226ca87b_5dfa_4c98_a432_7be6290ebc22','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('414fc87b_0411_4e36_8f5e_3fff7f0c6e0c','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_17_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','f0adc9b0_fff5_4071_aa7e_9313cdb14ebc','574e71df_bbcf_4eb4_bd63_e437289bf42d','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('d7d26f89_d9f9_4257_bd37_063722e7f600','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','06f24060_7af7_4676_b3ec_901525b12e8d','99ddc99a_4b0e_4e9b_b2e7_0e73f1fe77f3','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('4c0b3740_3486_4f66_9efc_3ce7a86ff2d7','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','f7ee0e4a_a473_4bea_817c_e69a934e1a10','9802af4f_5460_4520_b88d_9901401af488','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('c1083439_f127_4e04_b359_b362e1e9bd3e','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_14_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','76b610ee_22de_4724_b290_748d2177c5cc','c7da74d3_86e7_4937_b9cc_50ba6c8cd86d','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('fa2e833c_6e1e_4b8a_b770_b560cac0d783','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_13_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','2cc09da4_803e_4d71_bb48_6b0b7472136d','94b2c0e3_90e7_4bac_b138_8916c664de58','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('653babd8_0474_421a_88a1_5af2bfeae01c','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','9a75bb38_9649_4789_b9dd_f37f23136d83','d5828a7c_d38c_4dd6_bb1e_5498037be03d','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('9e59e72e_2d97_4bff_8f31_b096d77c49d5','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_10_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','88f0df13_aea9_4c3c_82d2_7b57cb89188a','b86be180_f01d_4978_bb94_1bc3ab9d4348','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('4957e116_c2d8_4111_85be_2248476b6f9b','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_19_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','56ace647_bcbb_4da8_b908_7d5dc4c2d68e','fe956b17_2b7e_474c_9cba_ee83f96b5c40','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('7c78b88a_0a59_43c7_8b33_c8ca3fa32f0a','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','9e2ee321_b10f_48fb_ad5e_2d0745f489fd','bc9c20f4_54d2_4820_81f5_6618b7b85cce','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('2274d822_ae95_42c9_8d17_13e2cb6fd03a','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_15_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','8fb44718_d427_4a4a_bc40_1cc5f793bb3e','4c03617e_ec00_4182_91c1_574869d01f55','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('60be1eca_eadc_4a34_aebb_2cfb7421234b','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','c393e30f_271b_4df3_81d7_57244a4c4a51','1b45e3f5_8103_4f96_b552_083c3514c74c','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('80788002_a55b_461a_b57c_5367d9290685','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_11_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','6faba674_4693_448f_a2e8_7ec255dcf034','c0b55310_4512_4d14_9718_aca7e99ffc8b','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('55af703d_d62a_4cb0_a838_d67420628c63','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','0ddba420_7c61_42a3_9560_c88213ba4416','7eab6d7d_28c0_4ead_b3fc_c045a5fff598','e6b7215f_971c_400a_894b_949d17a7da1a'),
    ('b2b0d934_4798_44ed_b5bd_99219e63f695','9d0bd37a_69a1_4d4c_a15a_7d27d191704e','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','save_problem_check','147.32.84.59','x_module','','2013-06-12T09:19:41.439185','8572dbca8357a1c40f1314953176960fb75c5d8d','0:00:00','','','Medicine-HRP258','','','','',-1,-1,'i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','incorrect','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','58e97d43_9418_4293_b785_2d285592d0df','c44b6ef5_3e04_46ca_acc9_ed42a727bd98','e6b7215f_971c_400a_894b_949d17a7da1a');
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
