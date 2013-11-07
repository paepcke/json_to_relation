USE test;
SET foreign_key_checks = 0;
DROP TABLE IF EXISTS EdxTrackEvent, Answer, InputState, CorrectMap, State, Account, LoadInfo;
SET foreign_key_checks = 1;
CREATE TABLE IF NOT EXISTS Answer (
    answer_id VARCHAR(40) NOT NULL PRIMARY KEY,
    problem_id TEXT,
    answer TEXT,
    course_id TEXT
    );
CREATE TABLE IF NOT EXISTS CorrectMap (
    correct_map_id VARCHAR(40) NOT NULL PRIMARY KEY,
    answer_identifier TEXT,
    correctness TINYTEXT,
    npoints INT,
    msg TEXT,
    hint TEXT,
    hintmode TINYTEXT,
    queuestate TEXT
    );
CREATE TABLE IF NOT EXISTS InputState (
    input_state_id VARCHAR(40) NOT NULL PRIMARY KEY,
    problem_id TEXT,
    state TEXT
    );
CREATE TABLE IF NOT EXISTS State (
    state_id VARCHAR(40) NOT NULL PRIMARY KEY,
    seed TINYINT,
    done TINYINT,
    problem_id TEXT,
    student_answer VARCHAR(40),
    correct_map VARCHAR(40),
    input_state VARCHAR(40),
    FOREIGN KEY(student_answer) REFERENCES Answer(answer_id),
    FOREIGN KEY(correct_map) REFERENCES CorrectMap(correct_map_id),
    FOREIGN KEY(input_state) REFERENCES InputState(input_state_id)
    );
CREATE TABLE IF NOT EXISTS Account (
    account_id VARCHAR(40) NOT NULL PRIMARY KEY,
    username TEXT,
    name TEXT,
    mailing_address TEXT,
    zipcode TINYTEXT,
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
CREATE TABLE IF NOT EXISTS LoadInfo (
    load_info_id INT NOT NULL PRIMARY KEY,
    load_date_time DATETIME,
    load_file TEXT
    );
CREATE TABLE IF NOT EXISTS EdxTrackEvent (
    _id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
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
    load_info_fk INT,
    FOREIGN KEY(correctMap_fk) REFERENCES CorrectMap(correct_map_id),
    FOREIGN KEY(answer_fk) REFERENCES Answer(answer_id),
    FOREIGN KEY(state_fk) REFERENCES State(state_id),
    FOREIGN KEY(account_fk) REFERENCES Account(account_id),
    FOREIGN KEY(load_info_fk) REFERENCES LoadInfo(load_info_id)
    );
SET foreign_key_checks=0;
SET unique_checks=0;
SET autocommit=0;
INSERT INTO LoadInfo (load_info_id,load_date_time,load_file) VALUES 
    ('eb1338f0_f410_475f_b857_efe396ce1dba','2013110705101383829837','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/problemCheckFailTest.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('925e5f3e_17f3_4556_ac3b_be49f92177d8','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('582c6704_d718_4c22_896a_e1a65b8d675f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('693e4321_fccf_49d5_892d_9608c3f91afd','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('24fc2bc5_ad10_47bf_83a5_654791a459b6','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('1f434f21_19bf_4d2d_a57d_52ee327a7a9d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('4c16566d_9702_450d_a98b_a86fceaca4b5','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('34a8cb3f_5cce_49d3_a68e_ce43661217fc','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('45c955bd_3cb6_4609_addc_e08b906057b0','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258'),
    ('c3caaed0_dadc_42aa_b6fa_ba0f5acb859e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('e3822c13_a5ee_4aec_906d_b7afb4a7b542','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('d2702a02_3339_4c37_b5a9_1656776400f2','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('21882676_acef_45a5_a4db_6d1991faa581','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('12db0996_a9e7_46d7_9e2c_0d2d6b8f47d5','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('7431cae8_c1fc_4d26_b788_7dbe9bd17973','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('3a704add_5a94_4d2c_a06b_0eabd7c10665','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('00caa6fe_9a72_463c_b618_75f7112741d2','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('7139e5d4_ed04_4761_a53d_cd7501ed30dc','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','correct',null,'','',null,null),
    ('96cb6b96_2c14_412c_af54_8fc11da082bb','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','correct',null,'','',null,null),
    ('bcf14cef_f9d0_4484_a976_17f5e9c7004a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','correct',null,'','',null,null),
    ('3b32294b_218a_4dd6_9e61_ba200a41ea5e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','correct',null,'','',null,null),
    ('d16d7562_a4d5_459f_9282_37959a7a0b0c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','incorrect',null,'','',null,null),
    ('1367cb6a_c354_4290_8539_7a63644ce785','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','correct',null,'','',null,null),
    ('3f18d55b_5b3c_4504_81f8_0d2049cc2405','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','correct',null,'','',null,null),
    ('880b413e_9442_47b4_9356_b8fc8ceaef5c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('000c2c8f_a7a9_4086_8ad3_5708adc18e1c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',null),
    ('de14e88c_3c7d_4d8a_9b18_cb9af32c30db','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',null),
    ('b1a3053c_6f28_43df_8766_51184d62c0a6','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',null),
    ('ec2c411a_4916_46f2_9dfc_090c8a8549b0','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',null),
    ('110a866a_09c7_4f72_b01a_83db8a49259e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',null),
    ('8ed01079_e026_4f02_8158_7027974483b3','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',null),
    ('774c6090_2563_4c7c_9f09_34553b65c847','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',null),
    ('b29701a1_19f2_4a8e_942b_bdeb7543785f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null);
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('d3b25251_7400_4ccf_b45c_615158b9b470',1,True,null,'c3caaed0_dadc_42aa_b6fa_ba0f5acb859e','7139e5d4_ed04_4761_a53d_cd7501ed30dc','000c2c8f_a7a9_4086_8ad3_5708adc18e1c'),
    ('eba0cdd2_79fe_4060_bc47_7258465ae620',1,True,null,'e3822c13_a5ee_4aec_906d_b7afb4a7b542','96cb6b96_2c14_412c_af54_8fc11da082bb','de14e88c_3c7d_4d8a_9b18_cb9af32c30db'),
    ('b5238f47_954b_442c_b393_c61f6b8a367a',1,True,null,'d2702a02_3339_4c37_b5a9_1656776400f2','bcf14cef_f9d0_4484_a976_17f5e9c7004a','b1a3053c_6f28_43df_8766_51184d62c0a6'),
    ('dd552976_1ef9_4ec5_b732_0eac2fadcc4e',1,True,null,'21882676_acef_45a5_a4db_6d1991faa581','3b32294b_218a_4dd6_9e61_ba200a41ea5e','ec2c411a_4916_46f2_9dfc_090c8a8549b0'),
    ('249a5de9_8c06_4695_804f_a14e9454f577',1,True,null,'12db0996_a9e7_46d7_9e2c_0d2d6b8f47d5','d16d7562_a4d5_459f_9282_37959a7a0b0c','110a866a_09c7_4f72_b01a_83db8a49259e'),
    ('c37dc918_fb15_4b1d_bb08_64451ffb66a4',1,True,null,'7431cae8_c1fc_4d26_b788_7dbe9bd17973','1367cb6a_c354_4290_8539_7a63644ce785','8ed01079_e026_4f02_8158_7027974483b3'),
    ('1eb1de7b_e6a8_4f28_bc61_e9ae6c4d9307',1,True,null,'3a704add_5a94_4d2c_a06b_0eabd7c10665','3f18d55b_5b3c_4504_81f8_0d2049cc2405','774c6090_2563_4c7c_9f09_34553b65c847'),
    ('ae9d559e_449e_4a53_b742_f0f1def7c3fb',1,True,null,'00caa6fe_9a72_463c_b618_75f7112741d2','880b413e_9442_47b4_9356_b8fc8ceaef5c','b29701a1_19f2_4a8e_942b_bdeb7543785f');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,username,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,account_fk,load_info_fk) VALUES 
    (0,'cabb15ba_2ef0_4f97_af3a_a2c3d5ce1be7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','925e5f3e_17f3_4556_ac3b_be49f92177d8','d3b25251_7400_4ccf_b45c_615158b9b470','','eb1338f0_f410_475f_b857_efe396ce1dba'),
    (0,'cabb15ba_2ef0_4f97_af3a_a2c3d5ce1be7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','582c6704_d718_4c22_896a_e1a65b8d675f','eba0cdd2_79fe_4060_bc47_7258465ae620','','eb1338f0_f410_475f_b857_efe396ce1dba'),
    (0,'cabb15ba_2ef0_4f97_af3a_a2c3d5ce1be7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','693e4321_fccf_49d5_892d_9608c3f91afd','b5238f47_954b_442c_b393_c61f6b8a367a','','eb1338f0_f410_475f_b857_efe396ce1dba'),
    (0,'cabb15ba_2ef0_4f97_af3a_a2c3d5ce1be7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','24fc2bc5_ad10_47bf_83a5_654791a459b6','dd552976_1ef9_4ec5_b732_0eac2fadcc4e','','eb1338f0_f410_475f_b857_efe396ce1dba'),
    (0,'cabb15ba_2ef0_4f97_af3a_a2c3d5ce1be7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','1f434f21_19bf_4d2d_a57d_52ee327a7a9d','249a5de9_8c06_4695_804f_a14e9454f577','','eb1338f0_f410_475f_b857_efe396ce1dba'),
    (0,'cabb15ba_2ef0_4f97_af3a_a2c3d5ce1be7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','4c16566d_9702_450d_a98b_a86fceaca4b5','c37dc918_fb15_4b1d_bb08_64451ffb66a4','','eb1338f0_f410_475f_b857_efe396ce1dba'),
    (0,'cabb15ba_2ef0_4f97_af3a_a2c3d5ce1be7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','34a8cb3f_5cce_49d3_a68e_ce43661217fc','1eb1de7b_e6a8_4f28_bc61_e9ae6c4d9307','','eb1338f0_f410_475f_b857_efe396ce1dba'),
    (0,'cabb15ba_2ef0_4f97_af3a_a2c3d5ce1be7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','45c955bd_3cb6_4609_addc_e08b906057b0','ae9d559e_449e_4a53_b742_f0f1def7c3fb','','eb1338f0_f410_475f_b857_efe396ce1dba'),
    (0,'cabb15ba_2ef0_4f97_af3a_a2c3d5ce1be7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','45c955bd_3cb6_4609_addc_e08b906057b0','ae9d559e_449e_4a53_b742_f0f1def7c3fb','','eb1338f0_f410_475f_b857_efe396ce1dba');
COMMIT;
SET foreign_key_checks=1;
SET unique_checks=1;
