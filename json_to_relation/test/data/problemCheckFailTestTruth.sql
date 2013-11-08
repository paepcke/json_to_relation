CREATE DATABASE IF NOT EXISTS Edx;
CREATE DATABASE IF NOT EXISTS EdxPrivate;
USE test;
SET foreign_key_checks = 0;
DROP TABLE IF EXISTS EdxTrackEvent, Answer, InputState, CorrectMap, State, EdxPrivate.Account, LoadInfo;
SET foreign_key_checks = 1;
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
    _id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
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
SET foreign_key_checks=0;
SET unique_checks=0;
SET autocommit=0;
INSERT INTO LoadInfo (load_info_id,load_date_time,load_file) VALUES 
    ('fef45101_9132_4a11_88a8_365fcb1d9174','2013110806081383919693','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/problemCheckFailTest.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('32464c02_be90_4ed7_9be9_e37825b6123c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('5f6e5c78_bec8_4ad1_a58f_b3d43b4c2454','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('25311a07_fe37_4624_867e_e43f643f8b0b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('ff808898_72f9_4036_a8cc_738a300e2b1f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('7d123e6f_94e8_4c9c_aa0f_91b8a52d3506','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('0d6f831c_fdcf_4b51_b9cd_59a67c7cd72d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('2e120276_8b45_4115_ab51_c15997928266','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('f3363900_796b_4fcd_9c3b_251470343dad','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258'),
    ('4b8745ba_b171_4d09_9e5d_218f1b5ccc7c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('d128c1b5_5c27_49cd_8923_0f537f40a82c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('2001b138_0ce0_4641_93df_cfe15f3ce51e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('6ebaad43_a93d_4c8f_92db_fb8e8dedc7a1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('5b6b2505_1417_4b24_a56f_f0152beee5b9','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('962f4b2e_9819_4615_9386_7d63dda2b891','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('8f3168b5_087f_486b_ae71_b71c3023dd35','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('cb81172e_875b_40fc_9d0a_a7907fb45019','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('77c36ab8_55bb_40db_8cd0_030cea542530','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','correct',-1,'','','',''),
    ('e68694e0_b016_4ab9_90b7_2c6af92ff859','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','correct',-1,'','','',''),
    ('3aee5eb1_cb20_4ceb_b669_bdbfa908a2fe','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','correct',-1,'','','',''),
    ('1d45a484_2c10_4934_ab34_ddf55ba9cea9','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','correct',-1,'','','',''),
    ('fad6f2bf_485f_46fe_9f3e_9ad46aea75f6','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','incorrect',-1,'','','',''),
    ('5755a122_f3dc_41ba_a7cf_15df13965e5c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','correct',-1,'','','',''),
    ('421e4d16_a8d6_4e93_9d79_248c2e9ed076','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','correct',-1,'','','',''),
    ('e1399bf5_7450_4dbe_bf51_1387fe0c15fc','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','incorrect',-1,'','','','');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('dd8e7dbd_9bf8_4aaa_b34c_a2047750b1df','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',''),
    ('980d9b28_dbc6_4681_9890_38386aee7d2a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',''),
    ('a3103911_d66f_4448_acad_bc52f9c58142','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',''),
    ('e8a62f09_b39d_4abb_8788_4405e1fad2a9','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',''),
    ('ea8eb0dd_b224_4f32_9436_f73a125765ae','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',''),
    ('a2c608f6_5428_4123_b227_7d47df9f9fe0','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',''),
    ('ab4eee6f_3f7b_446a_a401_8bbb200620d6','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',''),
    ('1d6f224f_8d7d_4803_bf13_abd0a5dae707','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('6e721e63_5b36_40b8_8a94_1ed92a3a4dbb',1,'True','','4b8745ba_b171_4d09_9e5d_218f1b5ccc7c','77c36ab8_55bb_40db_8cd0_030cea542530','dd8e7dbd_9bf8_4aaa_b34c_a2047750b1df'),
    ('e898c3a1_70fc_44fa_a282_120c8f159dd5',1,'True','','d128c1b5_5c27_49cd_8923_0f537f40a82c','e68694e0_b016_4ab9_90b7_2c6af92ff859','980d9b28_dbc6_4681_9890_38386aee7d2a'),
    ('995a2d60_f945_463b_85cb_9b68597d9721',1,'True','','2001b138_0ce0_4641_93df_cfe15f3ce51e','3aee5eb1_cb20_4ceb_b669_bdbfa908a2fe','a3103911_d66f_4448_acad_bc52f9c58142'),
    ('ca5ab3a3_5777_41a5_8cb5_13084740c100',1,'True','','6ebaad43_a93d_4c8f_92db_fb8e8dedc7a1','1d45a484_2c10_4934_ab34_ddf55ba9cea9','e8a62f09_b39d_4abb_8788_4405e1fad2a9'),
    ('aea92585_9b6f_4cde_938b_763ceae376e1',1,'True','','5b6b2505_1417_4b24_a56f_f0152beee5b9','fad6f2bf_485f_46fe_9f3e_9ad46aea75f6','ea8eb0dd_b224_4f32_9436_f73a125765ae'),
    ('72d2cd68_6650_4c73_9f21_1ec6d914d40c',1,'True','','962f4b2e_9819_4615_9386_7d63dda2b891','5755a122_f3dc_41ba_a7cf_15df13965e5c','a2c608f6_5428_4123_b227_7d47df9f9fe0'),
    ('b5c310d0_8fca_4167_8d39_68eaeb07eacb',1,'True','','8f3168b5_087f_486b_ae71_b71c3023dd35','421e4d16_a8d6_4e93_9d79_248c2e9ed076','ab4eee6f_3f7b_446a_a401_8bbb200620d6'),
    ('1005d2de_6c08_444e_8894_d58e5469c164',1,'True','','cb81172e_875b_40fc_9d0a_a7907fb45019','e1399bf5_7450_4dbe_bf51_1387fe0c15fc','1d6f224f_8d7d_4803_bf13_abd0a5dae707');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,anon_screen_name,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    (0,'ab68962f_c42b_489c_8037_163814a91fd4','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','32464c02_be90_4ed7_9be9_e37825b6123c','6e721e63_5b36_40b8_8a94_1ed92a3a4dbb','fef45101_9132_4a11_88a8_365fcb1d9174'),
    (0,'ab68962f_c42b_489c_8037_163814a91fd4','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','5f6e5c78_bec8_4ad1_a58f_b3d43b4c2454','e898c3a1_70fc_44fa_a282_120c8f159dd5','fef45101_9132_4a11_88a8_365fcb1d9174'),
    (0,'ab68962f_c42b_489c_8037_163814a91fd4','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','25311a07_fe37_4624_867e_e43f643f8b0b','995a2d60_f945_463b_85cb_9b68597d9721','fef45101_9132_4a11_88a8_365fcb1d9174'),
    (0,'ab68962f_c42b_489c_8037_163814a91fd4','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','ff808898_72f9_4036_a8cc_738a300e2b1f','ca5ab3a3_5777_41a5_8cb5_13084740c100','fef45101_9132_4a11_88a8_365fcb1d9174'),
    (0,'ab68962f_c42b_489c_8037_163814a91fd4','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','7d123e6f_94e8_4c9c_aa0f_91b8a52d3506','aea92585_9b6f_4cde_938b_763ceae376e1','fef45101_9132_4a11_88a8_365fcb1d9174'),
    (0,'ab68962f_c42b_489c_8037_163814a91fd4','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','0d6f831c_fdcf_4b51_b9cd_59a67c7cd72d','72d2cd68_6650_4c73_9f21_1ec6d914d40c','fef45101_9132_4a11_88a8_365fcb1d9174'),
    (0,'ab68962f_c42b_489c_8037_163814a91fd4','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','2e120276_8b45_4115_ab51_c15997928266','b5c310d0_8fca_4167_8d39_68eaeb07eacb','fef45101_9132_4a11_88a8_365fcb1d9174'),
    (0,'ab68962f_c42b_489c_8037_163814a91fd4','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','f3363900_796b_4fcd_9c3b_251470343dad','1005d2de_6c08_444e_8894_d58e5469c164','fef45101_9132_4a11_88a8_365fcb1d9174'),
    (0,'ab68962f_c42b_489c_8037_163814a91fd4','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','f3363900_796b_4fcd_9c3b_251470343dad','1005d2de_6c08_444e_8894_d58e5469c164','fef45101_9132_4a11_88a8_365fcb1d9174');
COMMIT;
SET foreign_key_checks=1;
SET unique_checks=1;
