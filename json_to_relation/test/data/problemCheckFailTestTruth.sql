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
    ('5cc15dc0_4f8b_4808_9306_3a00e4b619ab','2013112718511385607065','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/problemCheckFailTest.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('50821b9a_1dff_4c44_a9b2_70c22f9cdb84','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('63d0d580_7d38_4672_91bf_f1e5bdfbe52f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('2a00b59e_aad1_47ca_a173_d89ddeb89758','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('29d65b61_b2c3_4061_9fdb_2b926b01e18b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('0924f8f0_12de_424e_b7ef_70ab5c9d4930','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('8bd86df4_2544_4522_94f4_e22bc9c48a71','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('33bd2386_b5ff_4914_8799_dd2651c24c05','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('a1cdd0d4_087b_447e_9b3a_09bc5b7ee0e1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258'),
    ('00984273_e1a2_4fdc_9e63_4f9ebaab2597','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('5ce39256_b72d_4185_9d81_e1982a259097','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('18611aa9_b938_4e78_a7e6_ac3ab8610b31','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('eefe895d_1a43_42f7_bf2e_3470f023de86','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('7b895d31_42fe_4175_abf7_cc890caa9f01','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('9babc1a6_8cbd_43b3_bf1b_9c580eb24bd0','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('46c3f489_b2c6_4332_ae47_f849ded22555','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('e452fe4d_db06_4e3b_83a6_ee06f4591e81','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('c0230e08_f38c_4b86_8a8c_a509396fddc0','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','correct',-1,'','','',''),
    ('fc170a74_613e_410d_921c_ca8d125fa617','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','correct',-1,'','','',''),
    ('c23e4c02_190f_4d60_b696_d6b028b8baab','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','correct',-1,'','','',''),
    ('08a8f1bc_fbd5_48a3_b280_eee880af91d1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','correct',-1,'','','',''),
    ('c6ac9761_a767_49c3_a1f8_fe2304e9eb08','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','incorrect',-1,'','','',''),
    ('09de19d2_996c_447a_b17c_2b8fc97df43c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','correct',-1,'','','',''),
    ('edd32d57_e965_4a01_a5d2_87bb73fbdd74','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','correct',-1,'','','',''),
    ('f65161a2_d16b_468c_bb94_eb9fabe817cf','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','incorrect',-1,'','','','');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('70865f0d_2792_4ce2_9dc5_1e9a719d3c0a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',''),
    ('4dd733bb_5038_4aec_a6bd_f36da6a0bf29','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',''),
    ('8747469a_dbfb_4ca0_8d17_fb2b78e23137','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',''),
    ('23b4f8c4_1bea_49e8_9480_cb0f2041d45e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',''),
    ('79f87fc3_469c_4832_a2fd_4bf13d22a568','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',''),
    ('14460841_3180_4f1e_b77f_83722e8874f1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',''),
    ('021923cd_cca4_4e12_93d5_9cdc111de9c1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',''),
    ('7062304c_7025_4f09_97f2_db06846ed432','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('6c967859_902c_46f8_a36a_5bcf02bb00b3',1,'True','','00984273_e1a2_4fdc_9e63_4f9ebaab2597','c0230e08_f38c_4b86_8a8c_a509396fddc0','70865f0d_2792_4ce2_9dc5_1e9a719d3c0a'),
    ('d0dbb415_d88d_476a_94c0_c014004c199e',1,'True','','5ce39256_b72d_4185_9d81_e1982a259097','fc170a74_613e_410d_921c_ca8d125fa617','4dd733bb_5038_4aec_a6bd_f36da6a0bf29'),
    ('ea26e651_9397_430a_95e0_4653ca0b3faf',1,'True','','18611aa9_b938_4e78_a7e6_ac3ab8610b31','c23e4c02_190f_4d60_b696_d6b028b8baab','8747469a_dbfb_4ca0_8d17_fb2b78e23137'),
    ('eba5eddf_2617_40ec_a164_7b72e64f0f2b',1,'True','','eefe895d_1a43_42f7_bf2e_3470f023de86','08a8f1bc_fbd5_48a3_b280_eee880af91d1','23b4f8c4_1bea_49e8_9480_cb0f2041d45e'),
    ('7c15f2f0_81cf_4624_be29_70785c736198',1,'True','','7b895d31_42fe_4175_abf7_cc890caa9f01','c6ac9761_a767_49c3_a1f8_fe2304e9eb08','79f87fc3_469c_4832_a2fd_4bf13d22a568'),
    ('407e2c86_9901_4669_91f3_8d6ed05fc9f6',1,'True','','9babc1a6_8cbd_43b3_bf1b_9c580eb24bd0','09de19d2_996c_447a_b17c_2b8fc97df43c','14460841_3180_4f1e_b77f_83722e8874f1'),
    ('ab9c9d40_4aa1_4a58_a0f5_3aa22978ef26',1,'True','','46c3f489_b2c6_4332_ae47_f849ded22555','edd32d57_e965_4a01_a5d2_87bb73fbdd74','021923cd_cca4_4e12_93d5_9cdc111de9c1'),
    ('a0de2f99_7570_49fa_a044_2437d97efa33',1,'True','','e452fe4d_db06_4e3b_83a6_ee06f4591e81','f65161a2_d16b_468c_bb94_eb9fabe817cf','7062304c_7025_4f09_97f2_db06846ed432');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,anon_screen_name,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    ('ac66a5a9_9b6f_4cec_ade6_10b5fefe0929','3a6259bf_f5ed_4f23_8357_761efb945386','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','0132acbb6cf5d98798b44b16e0a1cd4ebbad3dae74cb45fbbfbea20f','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','50821b9a_1dff_4c44_a9b2_70c22f9cdb84','6c967859_902c_46f8_a36a_5bcf02bb00b3','5cc15dc0_4f8b_4808_9306_3a00e4b619ab'),
    ('1ed03134_67ea_4ba7_8ba2_8d6c113c4b44','3a6259bf_f5ed_4f23_8357_761efb945386','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','0132acbb6cf5d98798b44b16e0a1cd4ebbad3dae74cb45fbbfbea20f','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','63d0d580_7d38_4672_91bf_f1e5bdfbe52f','d0dbb415_d88d_476a_94c0_c014004c199e','5cc15dc0_4f8b_4808_9306_3a00e4b619ab'),
    ('e95133bc_9599_44e5_9960_32e3cb8c82f3','3a6259bf_f5ed_4f23_8357_761efb945386','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','0132acbb6cf5d98798b44b16e0a1cd4ebbad3dae74cb45fbbfbea20f','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','2a00b59e_aad1_47ca_a173_d89ddeb89758','ea26e651_9397_430a_95e0_4653ca0b3faf','5cc15dc0_4f8b_4808_9306_3a00e4b619ab'),
    ('58f47a05_a03b_48eb_ae1d_f99416168d3f','3a6259bf_f5ed_4f23_8357_761efb945386','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','0132acbb6cf5d98798b44b16e0a1cd4ebbad3dae74cb45fbbfbea20f','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','29d65b61_b2c3_4061_9fdb_2b926b01e18b','eba5eddf_2617_40ec_a164_7b72e64f0f2b','5cc15dc0_4f8b_4808_9306_3a00e4b619ab'),
    ('e94910a2_f7c6_4845_ae50_52b47b596c98','3a6259bf_f5ed_4f23_8357_761efb945386','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','0132acbb6cf5d98798b44b16e0a1cd4ebbad3dae74cb45fbbfbea20f','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','0924f8f0_12de_424e_b7ef_70ab5c9d4930','7c15f2f0_81cf_4624_be29_70785c736198','5cc15dc0_4f8b_4808_9306_3a00e4b619ab'),
    ('b0704f43_79e4_4f39_a005_4c4a0b18718f','3a6259bf_f5ed_4f23_8357_761efb945386','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','0132acbb6cf5d98798b44b16e0a1cd4ebbad3dae74cb45fbbfbea20f','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','8bd86df4_2544_4522_94f4_e22bc9c48a71','407e2c86_9901_4669_91f3_8d6ed05fc9f6','5cc15dc0_4f8b_4808_9306_3a00e4b619ab'),
    ('9e862fc5_1206_48bc_a676_86af89ebb3be','3a6259bf_f5ed_4f23_8357_761efb945386','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','0132acbb6cf5d98798b44b16e0a1cd4ebbad3dae74cb45fbbfbea20f','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','33bd2386_b5ff_4914_8799_dd2651c24c05','ab9c9d40_4aa1_4a58_a0f5_3aa22978ef26','5cc15dc0_4f8b_4808_9306_3a00e4b619ab'),
    ('d9d05a21_f942_4d47_9d23_6db8e3585707','3a6259bf_f5ed_4f23_8357_761efb945386','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','0132acbb6cf5d98798b44b16e0a1cd4ebbad3dae74cb45fbbfbea20f','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','a1cdd0d4_087b_447e_9b3a_09bc5b7ee0e1','a0de2f99_7570_49fa_a044_2437d97efa33','5cc15dc0_4f8b_4808_9306_3a00e4b619ab'),
    ('33a81aa5_ccb6_4d8a_8393_4de223e6ba5e','3a6259bf_f5ed_4f23_8357_761efb945386','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','0132acbb6cf5d98798b44b16e0a1cd4ebbad3dae74cb45fbbfbea20f','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','a1cdd0d4_087b_447e_9b3a_09bc5b7ee0e1','a0de2f99_7570_49fa_a044_2437d97efa33','5cc15dc0_4f8b_4808_9306_3a00e4b619ab');
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
