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
    account_id VARCHAR(40) NOT NULL PRIMARY KEY,
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
    ('7ed97f3f_3959_46f1_9495_beb951f3b8ac','2013110703261383823616','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/problemCheckFailTest.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('8300a3bf_8476_4aa1_af45_4459cb219cb1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('cf07c76c_68e9_4bd8_9ef9_3d22f0ad7646','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('62658eda_23ab_4d6f_8cac_05d005ce5c6d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('8725d7cc_ec8f_4247_a3d7_ce93dabf9456','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('ac11be20_9354_4e87_a64b_b0ab5c55a98c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('16874481_aec7_4252_a6a1_b0f9a64aa653','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('0a1dc9c4_7479_4d37_bcb6_57af80011091','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('76b9b272_c304_468b_bbed_bfa2589ec42a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258'),
    ('219ab80d_004b_4f59_ac5b_e878e776d30b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('7abcadb7_6e68_4a95_96bd_e1b32f49d521','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('07ec50ab_4019_41d7_8ff0_980a1de1285d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('188dc8c1_962c_483a_adb8_dfc8689be3e9','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('4afdaf08_2bd5_4705_ac31_fb8d72c542e1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('c159e2d0_5091_48ba_84ac_c03dac31aaa9','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('97c86f35_96c6_4005_bc53_fb1fc483aa3f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('457154ad_2430_4ce5_b8c3_91bfb980e753','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('d50274cc_e6ae_40af_a39d_65314291d58e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','correct',null,'','',null,null),
    ('995678ca_cf0c_4320_a8d5_b1b552ee90c4','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','correct',null,'','',null,null),
    ('d7e85264_3ad3_4c9b_9126_6259b07fb955','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','correct',null,'','',null,null),
    ('984fdc51_07f7_4faf_b871_a5cb77dcfd95','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','correct',null,'','',null,null),
    ('44267928_e423_41e5_83c7_b2c8119928c9','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','incorrect',null,'','',null,null),
    ('cfc05384_b6a3_4676_a7bb_d6b75292bd02','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','correct',null,'','',null,null),
    ('c1849cb8_9818_48f1_9e56_a638ebfceb12','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','correct',null,'','',null,null),
    ('a218a140_bcf7_4f4c_a9f0_f34f3c4e52d8','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('be9515e6_4952_49f3_9df6_f4797357e72a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',null),
    ('a41ca760_3a01_433f_8d07_42ac24ecf4c3','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',null),
    ('ef31c72a_eb4e_4b79_81f5_a165bb3d7e05','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',null),
    ('132a97f6_6aee_4a33_aa39_d829070b0cec','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',null),
    ('4eb13cfe_da73_466a_aebe_56e734313a8c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',null),
    ('4b33c5ff_895a_41ed_b0ae_059e9bc1cc0a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',null),
    ('0da2eb7a_dd4c_4fe2_8a51_ba2d6aefea61','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',null),
    ('fdb3dbd8_9fbd_4156_aa36_25173db189d4','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null);
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('d5e268f0_49a8_4957_b2e3_b83b2565c8c9',1,True,null,'219ab80d_004b_4f59_ac5b_e878e776d30b','d50274cc_e6ae_40af_a39d_65314291d58e','be9515e6_4952_49f3_9df6_f4797357e72a'),
    ('9042b807_6853_49fb_843d_36c4b5e36d4c',1,True,null,'7abcadb7_6e68_4a95_96bd_e1b32f49d521','995678ca_cf0c_4320_a8d5_b1b552ee90c4','a41ca760_3a01_433f_8d07_42ac24ecf4c3'),
    ('2ee186bf_3056_43f3_bc93_34374dc271dc',1,True,null,'07ec50ab_4019_41d7_8ff0_980a1de1285d','d7e85264_3ad3_4c9b_9126_6259b07fb955','ef31c72a_eb4e_4b79_81f5_a165bb3d7e05'),
    ('979e19ef_a264_4c4a_be58_8a79c05f86cb',1,True,null,'188dc8c1_962c_483a_adb8_dfc8689be3e9','984fdc51_07f7_4faf_b871_a5cb77dcfd95','132a97f6_6aee_4a33_aa39_d829070b0cec'),
    ('dab08d99_4320_46e6_b2ac_4c79b44d555d',1,True,null,'4afdaf08_2bd5_4705_ac31_fb8d72c542e1','44267928_e423_41e5_83c7_b2c8119928c9','4eb13cfe_da73_466a_aebe_56e734313a8c'),
    ('db559e46_1743_4c6b_b1ec_bd493aa731fb',1,True,null,'c159e2d0_5091_48ba_84ac_c03dac31aaa9','cfc05384_b6a3_4676_a7bb_d6b75292bd02','4b33c5ff_895a_41ed_b0ae_059e9bc1cc0a'),
    ('c1434eea_5e68_4805_8605_d9c6c19c15b8',1,True,null,'97c86f35_96c6_4005_bc53_fb1fc483aa3f','c1849cb8_9818_48f1_9e56_a638ebfceb12','0da2eb7a_dd4c_4fe2_8a51_ba2d6aefea61'),
    ('4da56f63_ef00_4d1e_b11e_4212516447ad',1,True,null,'457154ad_2430_4ce5_b8c3_91bfb980e753','a218a140_bcf7_4f4c_a9f0_f34f3c4e52d8','fdb3dbd8_9fbd_4156_aa36_25173db189d4');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,username,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,account_fk,load_info_fk) VALUES 
    (null,'46fe5c38_ff3a_4d84_9a3d_de054cc10c43','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,'Medicine-HRP258',null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'8300a3bf_8476_4aa1_af45_4459cb219cb1','d5e268f0_49a8_4957_b2e3_b83b2565c8c9',null,'7ed97f3f_3959_46f1_9495_beb951f3b8ac'),
    (null,'46fe5c38_ff3a_4d84_9a3d_de054cc10c43','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,'Medicine-HRP258',null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'cf07c76c_68e9_4bd8_9ef9_3d22f0ad7646','9042b807_6853_49fb_843d_36c4b5e36d4c',null,'7ed97f3f_3959_46f1_9495_beb951f3b8ac'),
    (null,'46fe5c38_ff3a_4d84_9a3d_de054cc10c43','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,'Medicine-HRP258',null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'62658eda_23ab_4d6f_8cac_05d005ce5c6d','2ee186bf_3056_43f3_bc93_34374dc271dc',null,'7ed97f3f_3959_46f1_9495_beb951f3b8ac'),
    (null,'46fe5c38_ff3a_4d84_9a3d_de054cc10c43','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,'Medicine-HRP258',null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'8725d7cc_ec8f_4247_a3d7_ce93dabf9456','979e19ef_a264_4c4a_be58_8a79c05f86cb',null,'7ed97f3f_3959_46f1_9495_beb951f3b8ac'),
    (null,'46fe5c38_ff3a_4d84_9a3d_de054cc10c43','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,'Medicine-HRP258',null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'ac11be20_9354_4e87_a64b_b0ab5c55a98c','dab08d99_4320_46e6_b2ac_4c79b44d555d',null,'7ed97f3f_3959_46f1_9495_beb951f3b8ac'),
    (null,'46fe5c38_ff3a_4d84_9a3d_de054cc10c43','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,'Medicine-HRP258',null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'16874481_aec7_4252_a6a1_b0f9a64aa653','db559e46_1743_4c6b_b1ec_bd493aa731fb',null,'7ed97f3f_3959_46f1_9495_beb951f3b8ac'),
    (null,'46fe5c38_ff3a_4d84_9a3d_de054cc10c43','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,'Medicine-HRP258',null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'0a1dc9c4_7479_4d37_bcb6_57af80011091','c1434eea_5e68_4805_8605_d9c6c19c15b8',null,'7ed97f3f_3959_46f1_9495_beb951f3b8ac'),
    (null,'46fe5c38_ff3a_4d84_9a3d_de054cc10c43','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,'Medicine-HRP258',null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'76b9b272_c304_468b_bbed_bfa2589ec42a','4da56f63_ef00_4d1e_b11e_4212516447ad',null,'7ed97f3f_3959_46f1_9495_beb951f3b8ac'),
    (null,'46fe5c38_ff3a_4d84_9a3d_de054cc10c43','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,'Medicine-HRP258',null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'76b9b272_c304_468b_bbed_bfa2589ec42a','4da56f63_ef00_4d1e_b11e_4212516447ad',null,'7ed97f3f_3959_46f1_9495_beb951f3b8ac');
COMMIT;
SET foreign_key_checks=1;
SET unique_checks=1;
