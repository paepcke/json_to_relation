USE test;
SET foreign_key_checks = 0;
DROP TABLE IF EXISTS Event, Answer, InputState, CorrectMap, State, Account;
SET foreign_key_checks = 1;
CREATE TABLE IF NOT EXISTS Answer (
    answer_id VARCHAR(40) NOT NULL Primary Key,
    problem_id TEXT,
    answer TEXT
    );
CREATE TABLE IF NOT EXISTS CorrectMap (
    correct_map_id VARCHAR(40) NOT NULL Primary Key,
    answer_identifier TEXT,
    correctness TINYTEXT,
    npoints INT,
    msg TEXT,
    hint TEXT,
    hintmode TINYTEXT,
    queuestate TEXT
    );
CREATE TABLE IF NOT EXISTS InputState (
    input_state_id VARCHAR(40) NOT NULL Primary Key,
    problem_id TEXT,
    state TEXT
    );
CREATE TABLE IF NOT EXISTS State (
    state_id VARCHAR(40) NOT NULL Primary Key,
    seed TINYINT,
    done BOOL,
    problem_id TEXT,
    student_answer VARCHAR(40),
    correct_map VARCHAR(40),
    input_state VARCHAR(40),
    FOREIGN KEY(student_answer) REFERENCES Answer(answer_id),
    FOREIGN KEY(correct_map) REFERENCES CorrectMap(correct_map_id),
    FOREIGN KEY(input_state) REFERENCES InputState(input_state_id)
    );
CREATE TABLE IF NOT EXISTS Account (
    account_id VARCHAR(40) NOT NULL Primary Key,
    username TEXT,
    name TEXT,
    mailing_address TEXT,
    zipCode TINYTEXT,
    country TINYTEXT,
    gender TINYTEXT,
    year_of_birth TINYINT,
    level_of_education TINYTEXT,
    goals TEXT,
    honor_code BOOL,
    terms_of_service BOOL,
    course_id TEXT,
    enrollment_action TINYTEXT,
    email TEXT,
    receive_emails TINYTEXT
    );
CREATE TABLE IF NOT EXISTS Event (
    event_id VARCHAR(40),
    agent TEXT,
    event_source TINYTEXT,
    event_type TEXT,
    ip TINYTEXT,
    page TEXT,
    session TEXT,
    time DATETIME,
    username TEXT,
    downtime_for DATETIME,
    student_id TEXT,
    instructor_id TEXT,
    course_id TEXT,
    sequence_id TEXT,
    goto_from INT,
    goto_dest INT,
    problem_id TEXT,
    problem_choice TEXT,
    question_location TEXT,
    submission_id TEXT,
    attempts TINYINT,
    long_answer TEXT,
    student_file TEXT,
    can_upload_file TINYTEXT,
    feedback TEXT,
    feedback_response_selected TINYINT,
    transcript_id TEXT,
    transcript_code TINYTEXT,
    rubric_selection INT,
    rubric_category INT,
    video_id TEXT,
    video_code TEXT,
    video_current_time TINYTEXT,
    video_speed TINYTEXT,
    video_old_time TINYTEXT,
    video_new_time TINYTEXT,
    video_seek_type TINYTEXT,
    video_new_speed TINYTEXT,
    video_old_speed TINYTEXT,
    book_interaction_type TINYTEXT,
    success TINYTEXT,
    answer_id TEXT,
    hint TEXT,
    hintmode TINYTEXT,
    correctness TINYTEXT,
    msg TEXT,
    npoints TINYINT,
    queuestate TEXT,
    orig_score INT,
    new_score INT,
    orig_total INT,
    new_total INT,
    event_name TINYTEXT,
    group_user TINYTEXT,
    group_action TINYTEXT,
    position INT,
    badly_formatted TEXT,
    correctMap_fk VARCHAR(40),
    answer_fk VARCHAR(40),
    state_fk VARCHAR(40),
    account_fk VARCHAR(40),
    FOREIGN KEY(correctMap_fk) REFERENCES CorrectMap(correct_map_id),
    FOREIGN KEY(answer_fk) REFERENCES Answer(answer_id),
    FOREIGN KEY(state_fk) REFERENCES State(state_id),
    FOREIGN KEY(account_fk) REFERENCES Account(account_id)
    );
SET foreign_key_checks=0;
SET unique_checks=0;
SET autocommit=0;
INSERT INTO Answer (answer_id,problem_id,answer) VALUES 
    ('00b6f49e_fea4_451d_9c47_58b0304e7991','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1'),
    ('8705375e_f847_43a2_a14f_b92f77174c18','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3'),
    ('b9cab664_2d8e_4307_863f_1b0221128f03','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1'),
    ('314745c7_08e8_4348_b319_60a779337d2c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0'),
    ('64f0ac6b_b837_49df_ba9a_ca2c0a32b0da','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4'),
    ('84919ae0_b38e_4a94_b320_4b84feab9af6','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2'),
    ('b5b3ed79_d405_4399_9ce4_61449adc0058','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0'),
    ('8dc09f32_cf2d_431a_82dc_0b4aab25df84','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0'),
    ('12340abe_993a_4e22_a146_c213483e2c43','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1'),
    ('29ef41da_24a2_48c2_aa0c_dee1c5d25c23','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3'),
    ('01a401c8_4127_4bf6_b00f_13295ead80dd','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1'),
    ('1f41e8d8_9646_4f57_ae2c_b831c7b9c9d1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0'),
    ('5d49f276_96eb_4929_85af_833fd1f6d551','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4'),
    ('b9a5db7a_47e0_40b7_b409_35771116f4a4','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2'),
    ('ba0d3ec7_2097_4688_aa87_054a1a6073c0','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0'),
    ('498ff7e7_8b47_4edb_a39b_9151c9aba461','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('d4b3228c_6faa_4985_95a6_ba6346323536','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','correct',null,'','',null,null),
    ('8623e5fd_abba_436f_b322_82647c3e33a4','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','correct',null,'','',null,null),
    ('f083081f_8e9b_4796_bf78_6cb1ce073b5f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','correct',null,'','',null,null),
    ('36545d7a_9d16_4e9f_a27d_46e2972af75b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','correct',null,'','',null,null),
    ('24900a41_984e_4731_87f3_711d50b89543','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','incorrect',null,'','',null,null),
    ('0b79b650_3474_441a_a242_1d1429265dd1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','correct',null,'','',null,null),
    ('828f9c20_ca2b_42f5_ba5d_c079ffbcc03b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','correct',null,'','',null,null),
    ('36616e06_76fb_4da5_bca6_fa424675e60f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('b4ae46c4_277c_4269_b734_43e200140f33','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',null),
    ('c14d7660_c267_4cf4_8abb_f3f61552a8da','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',null),
    ('5d1ac5a8_71ce_4fa3_b986_ccc00ddf8cca','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',null),
    ('df3e07fc_2e12_41b2_a724_4be2796c4cbf','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',null),
    ('6e50ded8_d7e3_4742_95c5_da0770ddcc13','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',null),
    ('be83861e_8480_48ba_bf5d_0b2ce25bf3fe','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',null),
    ('b1589712_2533_4ab0_bf95_d6ba148cad38','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',null),
    ('ba3c7e9d_1d2f_426b_a532_88fd918f5ba3','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null);
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('8687f9d0_843a_468f_978d_9d91842d26e7',1,True,null,'12340abe_993a_4e22_a146_c213483e2c43','d4b3228c_6faa_4985_95a6_ba6346323536','b4ae46c4_277c_4269_b734_43e200140f33'),
    ('649f5bd8_9f1d_4197_880e_ec03e234a283',1,True,null,'29ef41da_24a2_48c2_aa0c_dee1c5d25c23','8623e5fd_abba_436f_b322_82647c3e33a4','c14d7660_c267_4cf4_8abb_f3f61552a8da'),
    ('e9226f00_25a9_4d71_b6c8_f3d6509fb681',1,True,null,'01a401c8_4127_4bf6_b00f_13295ead80dd','f083081f_8e9b_4796_bf78_6cb1ce073b5f','5d1ac5a8_71ce_4fa3_b986_ccc00ddf8cca'),
    ('0f428093_e557_498c_9ca2_dbdfa97fe7aa',1,True,null,'1f41e8d8_9646_4f57_ae2c_b831c7b9c9d1','36545d7a_9d16_4e9f_a27d_46e2972af75b','df3e07fc_2e12_41b2_a724_4be2796c4cbf'),
    ('d48e2026_486b_4407_84c5_b95ccc5517bf',1,True,null,'5d49f276_96eb_4929_85af_833fd1f6d551','24900a41_984e_4731_87f3_711d50b89543','6e50ded8_d7e3_4742_95c5_da0770ddcc13'),
    ('504a64cb_d9ab_49e9_a8e4_16afe2546058',1,True,null,'b9a5db7a_47e0_40b7_b409_35771116f4a4','0b79b650_3474_441a_a242_1d1429265dd1','be83861e_8480_48ba_bf5d_0b2ce25bf3fe'),
    ('c668c14b_f437_4752_ab98_886d2a3d9be1',1,True,null,'ba0d3ec7_2097_4688_aa87_054a1a6073c0','828f9c20_ca2b_42f5_ba5d_c079ffbcc03b','b1589712_2533_4ab0_bf95_d6ba148cad38'),
    ('26f9d842_19b5_4d1e_baa2_20887ea15dd0',1,True,null,'498ff7e7_8b47_4edb_a39b_9151c9aba461','36616e06_76fb_4da5_bca6_fa424675e60f','ba3c7e9d_1d2f_426b_a532_88fd918f5ba3');
INSERT INTO Event (event_id,agent,event_source,event_type,ip,page,session,time,username,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk) VALUES 
    ('2d89254f_d744_4f82_b176_fb4a9c628bf7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'00b6f49e_fea4_451d_9c47_58b0304e7991','8687f9d0_843a_468f_978d_9d91842d26e7'),
    ('2d89254f_d744_4f82_b176_fb4a9c628bf7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'8705375e_f847_43a2_a14f_b92f77174c18','649f5bd8_9f1d_4197_880e_ec03e234a283'),
    ('2d89254f_d744_4f82_b176_fb4a9c628bf7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'b9cab664_2d8e_4307_863f_1b0221128f03','e9226f00_25a9_4d71_b6c8_f3d6509fb681'),
    ('2d89254f_d744_4f82_b176_fb4a9c628bf7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'314745c7_08e8_4348_b319_60a779337d2c','0f428093_e557_498c_9ca2_dbdfa97fe7aa'),
    ('2d89254f_d744_4f82_b176_fb4a9c628bf7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'64f0ac6b_b837_49df_ba9a_ca2c0a32b0da','d48e2026_486b_4407_84c5_b95ccc5517bf'),
    ('2d89254f_d744_4f82_b176_fb4a9c628bf7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'84919ae0_b38e_4a94_b320_4b84feab9af6','504a64cb_d9ab_49e9_a8e4_16afe2546058'),
    ('2d89254f_d744_4f82_b176_fb4a9c628bf7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'b5b3ed79_d405_4399_9ce4_61449adc0058','c668c14b_f437_4752_ab98_886d2a3d9be1'),
    ('2d89254f_d744_4f82_b176_fb4a9c628bf7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'8dc09f32_cf2d_431a_82dc_0b4aab25df84','26f9d842_19b5_4d1e_baa2_20887ea15dd0'),
    ('2d89254f_d744_4f82_b176_fb4a9c628bf7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'8dc09f32_cf2d_431a_82dc_0b4aab25df84','26f9d842_19b5_4d1e_baa2_20887ea15dd0');
COMMIT;
SET foreign_key_checks=1;
SET unique_checks=1;
