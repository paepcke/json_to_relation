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
    ('e3482f42_deaf_4b52_8e56_3af3407ab18a','2013110907251384010734','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/problemCheckFailTest.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('1da38ed0_db3b_48f7_92bd_dd58e617920b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('10cd3796_c137_4e61_a37b_20688e29b549','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('119a9253_2e85_4f03_b58b_972415f18b00','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('3516b8f6_dfb1_47a8_8d4b_b5b955be687d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('a8479ae1_17fe_4432_8376_8252035213d1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('4063b323_d182_4f06_91df_5ff4c4847c03','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('7de57a00_e86b_4c3e_8a80_2bf5208e8236','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('306d237c_ecc9_4d9b_8a92_961edde7a4dd','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258'),
    ('05477649_1298_47f2_b72f_02dcbd6eff37','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('5184be8e_fe18_440f_a44d_a1a47bdfa1f8','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('7b3288d1_0291_44ac_8773_d6d26a39da2b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('1b946899_70e3_4543_8838_4633ddaa0bd6','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('0d9496b5_bf42_4743_a473_5a2dde99b56e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('44e21f1a_6eae_4ddb_b4b8_a0554e5e307e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('68e3d692_3587_4ed9_b4fe_671488f64c75','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('0dcc4220_e225_4604_ab0c_7836bff06ef2','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('3d078bb1_a2be_4ac9_b014_2272795c7738','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','correct',-1,'','','',''),
    ('5cd05d8e_f826_4284_9ef0_fdc92f5880c3','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','correct',-1,'','','',''),
    ('aa258d4d_3f30_462c_af34_d8c2330ded37','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','correct',-1,'','','',''),
    ('d13c849e_26e1_4bc9_8591_3bc29dc2f9d2','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','correct',-1,'','','',''),
    ('b301c472_62a2_4559_8db8_5284252aed17','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','incorrect',-1,'','','',''),
    ('9aa793f7_7b24_4493_b1d9_cb85730ed22b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','correct',-1,'','','',''),
    ('a42049b5_5361_4946_8ce0_07a44eda5e5f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','correct',-1,'','','',''),
    ('d708896c_cd27_453e_9dbc_9d016fdc2a95','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','incorrect',-1,'','','','');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('d1feaaa6_e12b_47ac_958e_4aba685ea9d6','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',''),
    ('3b8c2cd3_95a0_4f24_9dac_7f379cc60002','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',''),
    ('7ce5e44a_29fa_410b_8bfb_309b8caa6bfe','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',''),
    ('1cc5b1ec_3d4b_4876_8436_9a0abb4d4ee6','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',''),
    ('d5c0d389_6f0a_4b6c_aad6_30d3960070e1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',''),
    ('fabf0951_f925_4ec0_928c_8c74e32c5d9c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',''),
    ('24ec74b5_a06e_410e_85ec_7e0978151e24','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',''),
    ('f004ca5d_fc63_4b7a_8ed6_13fcda3e8006','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('fcfc8819_8565_45d6_bc6e_1be4feca10e8',1,'True','','05477649_1298_47f2_b72f_02dcbd6eff37','3d078bb1_a2be_4ac9_b014_2272795c7738','d1feaaa6_e12b_47ac_958e_4aba685ea9d6'),
    ('246db69f_9651_4ee8_9d91_207fba2bd295',1,'True','','5184be8e_fe18_440f_a44d_a1a47bdfa1f8','5cd05d8e_f826_4284_9ef0_fdc92f5880c3','3b8c2cd3_95a0_4f24_9dac_7f379cc60002'),
    ('2d5d77f2_673b_4008_a46d_f4a15f9523c2',1,'True','','7b3288d1_0291_44ac_8773_d6d26a39da2b','aa258d4d_3f30_462c_af34_d8c2330ded37','7ce5e44a_29fa_410b_8bfb_309b8caa6bfe'),
    ('d06f4ca6_cdc8_4fcd_91d8_25d8d3979aef',1,'True','','1b946899_70e3_4543_8838_4633ddaa0bd6','d13c849e_26e1_4bc9_8591_3bc29dc2f9d2','1cc5b1ec_3d4b_4876_8436_9a0abb4d4ee6'),
    ('53bcb314_58fb_4016_9923_9ee5dc334106',1,'True','','0d9496b5_bf42_4743_a473_5a2dde99b56e','b301c472_62a2_4559_8db8_5284252aed17','d5c0d389_6f0a_4b6c_aad6_30d3960070e1'),
    ('92604b37_5b43_49e7_a9a5_9c7212f54f71',1,'True','','44e21f1a_6eae_4ddb_b4b8_a0554e5e307e','9aa793f7_7b24_4493_b1d9_cb85730ed22b','fabf0951_f925_4ec0_928c_8c74e32c5d9c'),
    ('54f7495f_ec16_4558_9b5f_3aff495c882b',1,'True','','68e3d692_3587_4ed9_b4fe_671488f64c75','a42049b5_5361_4946_8ce0_07a44eda5e5f','24ec74b5_a06e_410e_85ec_7e0978151e24'),
    ('6bc3d28a_3ab9_4b29_93a7_fd0875343ac6',1,'True','','0dcc4220_e225_4604_ab0c_7836bff06ef2','d708896c_cd27_453e_9dbc_9d016fdc2a95','f004ca5d_fc63_4b7a_8ed6_13fcda3e8006');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,anon_screen_name,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    ('4782c4cf_e012_4584_a31b_7c1930eb6069','6ff98a1e_bc54_4f52_84ce_b85d8d42f0db','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','1da38ed0_db3b_48f7_92bd_dd58e617920b','fcfc8819_8565_45d6_bc6e_1be4feca10e8','e3482f42_deaf_4b52_8e56_3af3407ab18a'),
    ('1af7f2d3_78aa_4663_bcce_b16ca8311890','6ff98a1e_bc54_4f52_84ce_b85d8d42f0db','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','10cd3796_c137_4e61_a37b_20688e29b549','246db69f_9651_4ee8_9d91_207fba2bd295','e3482f42_deaf_4b52_8e56_3af3407ab18a'),
    ('87556ad6_608b_4936_b02c_cb944e467085','6ff98a1e_bc54_4f52_84ce_b85d8d42f0db','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','119a9253_2e85_4f03_b58b_972415f18b00','2d5d77f2_673b_4008_a46d_f4a15f9523c2','e3482f42_deaf_4b52_8e56_3af3407ab18a'),
    ('1da01b71_51e5_45f4_8721_264ed37b3f2c','6ff98a1e_bc54_4f52_84ce_b85d8d42f0db','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','3516b8f6_dfb1_47a8_8d4b_b5b955be687d','d06f4ca6_cdc8_4fcd_91d8_25d8d3979aef','e3482f42_deaf_4b52_8e56_3af3407ab18a'),
    ('af8556e0_34ef_42b8_b5f9_399f5967d863','6ff98a1e_bc54_4f52_84ce_b85d8d42f0db','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','a8479ae1_17fe_4432_8376_8252035213d1','53bcb314_58fb_4016_9923_9ee5dc334106','e3482f42_deaf_4b52_8e56_3af3407ab18a'),
    ('bfa08e2a_ba57_487e_9900_324e66c4bc76','6ff98a1e_bc54_4f52_84ce_b85d8d42f0db','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','4063b323_d182_4f06_91df_5ff4c4847c03','92604b37_5b43_49e7_a9a5_9c7212f54f71','e3482f42_deaf_4b52_8e56_3af3407ab18a'),
    ('69fe1229_0caa_4f5f_8c1f_efcaa43b4b88','6ff98a1e_bc54_4f52_84ce_b85d8d42f0db','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','7de57a00_e86b_4c3e_8a80_2bf5208e8236','54f7495f_ec16_4558_9b5f_3aff495c882b','e3482f42_deaf_4b52_8e56_3af3407ab18a'),
    ('c1b070a1_65ae_446b_b94b_df15cb6cd5a5','6ff98a1e_bc54_4f52_84ce_b85d8d42f0db','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','306d237c_ecc9_4d9b_8a92_961edde7a4dd','6bc3d28a_3ab9_4b29_93a7_fd0875343ac6','e3482f42_deaf_4b52_8e56_3af3407ab18a'),
    ('116f3afb_0927_447b_b82e_8db2e24d1028','6ff98a1e_bc54_4f52_84ce_b85d8d42f0db','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','b328bfbc9a5846f98a8edbd6107d52f4b94c5653','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','306d237c_ecc9_4d9b_8a92_961edde7a4dd','6bc3d28a_3ab9_4b29_93a7_fd0875343ac6','e3482f42_deaf_4b52_8e56_3af3407ab18a');
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
