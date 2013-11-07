USE test;
SET foreign_key_checks = 0;
DROP TABLE IF EXISTS EdxTrackEvent, Answer, InputState, CorrectMap, State, Account, LoadInfo;
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
    done TINYINT NOT NULL,
    problem_id TEXT NOT NULL,
    student_answer VARCHAR(40) NOT NULL,
    correct_map VARCHAR(40) NOT NULL,
    input_state VARCHAR(40) NOT NULL,
    FOREIGN KEY(student_answer) REFERENCES Answer(answer_id),
    FOREIGN KEY(correct_map) REFERENCES CorrectMap(correct_map_id),
    FOREIGN KEY(input_state) REFERENCES InputState(input_state_id)
    );
CREATE TABLE IF NOT EXISTS Account (
    account_id VARCHAR(40) NOT NULL PRIMARY KEY,
    username TEXT NOT NULL,
    name TEXT NOT NULL,
    mailing_address TEXT NOT NULL,
    zipcode TINYTEXT NOT NULL,
    country TINYTEXT NOT NULL,
    gender TINYTEXT NOT NULL,
    year_of_birth TINYINT NOT NULL,
    level_of_education TINYTEXT NOT NULL,
    goals TEXT NOT NULL,
    honor_code BOOL NOT NULL,
    terms_of_service BOOL NOT NULL,
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
    username TEXT NOT NULL,
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
    attempts TINYINT NOT NULL,
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
    account_fk VARCHAR(40) NOT NULL,
    load_info_fk INT NOT NULL,
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
    ('7cb7a40e_12ad_4298_9543_07c02820f865','2013110706481383835703','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/problemCheckFailTest.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('5f5f8d99_4600_4d1e_8a1c_0f9f40d895ae','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('1e67ab7f_52ed_4949_a9e7_5d61f0d4bfd1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('add25f2e_25c1_4ab6_a928_d24b0735e002','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('b36379e8_4b0e_4889_8a45_1db1b369b76b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('7da3f139_0ea8_42d2_97ab_2af5caad4949','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('9fabc6ce_9e7e_4829_92ec_5b88826454ef','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('edb2cd13_7ec7_42a4_a5c8_8279a43fcdc4','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('dbf53724_bc66_43eb_b180_2fcaf0033086','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258'),
    ('9a88b07a_e181_4d29_8ccd_cb986e92798f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1','Medicine-HRP258'),
    ('5d9a948f_4686_4556_bae2_ff5a44f7d450','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3','Medicine-HRP258'),
    ('d9765b5b_ae96_4a38_b943_de62b862d50c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1','Medicine-HRP258'),
    ('6a95cb72_4c7b_44f6_aa9b_708b1df56242','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0','Medicine-HRP258'),
    ('6a1941f4_49d8_40ad_ba4d_e5f105797fc1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4','Medicine-HRP258'),
    ('d15e673b_ecb7_4a57_8ab8_0c858b444c78','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2','Medicine-HRP258'),
    ('ff33f0cb_5cc0_4ea9_8bc2_b9624cb48fcc','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0','Medicine-HRP258'),
    ('eec8e921_75ec_488a_99c1_342aa93a307f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0','Medicine-HRP258');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('3ef25555_baab_4c95_869a_8a98ca421f40','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','correct',null,'','',null,null),
    ('bef79777_08d2_4101_959b_0cdaf76e4420','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','correct',null,'','',null,null),
    ('68dd9744_2767_43a0_b7e7_ac5eac7b2681','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','correct',null,'','',null,null),
    ('1139d490_12f2_4d9e_b523_283d24217fdf','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','correct',null,'','',null,null),
    ('1a516a6b_34bd_49b1_b672_5db9a45449ba','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','incorrect',null,'','',null,null),
    ('424755dd_eba7_4c3f_9cdc_da45696eec5d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','correct',null,'','',null,null),
    ('195aa1bd_3c40_4687_8b08_fa64e185dc17','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','correct',null,'','',null,null),
    ('075d2b91_6ed8_46b2_a209_cbf76568d06c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('b317b2f7_a71d_4146_9052_d07e20bda076','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',null),
    ('598fd255_4930_4266_a13e_6c315cd6d292','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',null),
    ('9830878d_c3f8_4670_b381_c02d8f0ae496','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',null),
    ('efb341ae_1f2b_44e6_9186_594d974045ba','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',null),
    ('7a33cede_82e3_41eb_b638_1119bb7d13bb','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',null),
    ('4760336f_6106_41c8_885a_b65dc6ad3031','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',null),
    ('25fe7db0_957f_4251_8702_7477b7ef3e26','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',null),
    ('4bc3f7e1_3295_4065_82d2_41f7b79881bd','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null);
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('d08db382_0dca_4815_93fe_be957d876590',1,True,null,'9a88b07a_e181_4d29_8ccd_cb986e92798f','3ef25555_baab_4c95_869a_8a98ca421f40','b317b2f7_a71d_4146_9052_d07e20bda076'),
    ('9db817cb_c157_45d3_b558_4ae1f4221be9',1,True,null,'5d9a948f_4686_4556_bae2_ff5a44f7d450','bef79777_08d2_4101_959b_0cdaf76e4420','598fd255_4930_4266_a13e_6c315cd6d292'),
    ('49abdbc6_1734_4ad2_9e16_d65d199b2d34',1,True,null,'d9765b5b_ae96_4a38_b943_de62b862d50c','68dd9744_2767_43a0_b7e7_ac5eac7b2681','9830878d_c3f8_4670_b381_c02d8f0ae496'),
    ('41e24f03_7ef7_4482_a7fb_ab3ff6fa6baf',1,True,null,'6a95cb72_4c7b_44f6_aa9b_708b1df56242','1139d490_12f2_4d9e_b523_283d24217fdf','efb341ae_1f2b_44e6_9186_594d974045ba'),
    ('6e40ee5a_52b7_4562_a60f_76c79b0aec2b',1,True,null,'6a1941f4_49d8_40ad_ba4d_e5f105797fc1','1a516a6b_34bd_49b1_b672_5db9a45449ba','7a33cede_82e3_41eb_b638_1119bb7d13bb'),
    ('de28e8a2_84e8_4af2_a541_fbd9155064b7',1,True,null,'d15e673b_ecb7_4a57_8ab8_0c858b444c78','424755dd_eba7_4c3f_9cdc_da45696eec5d','4760336f_6106_41c8_885a_b65dc6ad3031'),
    ('42036c7f_8998_4809_ba94_3e5f0506ebbe',1,True,null,'ff33f0cb_5cc0_4ea9_8bc2_b9624cb48fcc','195aa1bd_3c40_4687_8b08_fa64e185dc17','25fe7db0_957f_4251_8702_7477b7ef3e26'),
    ('9e57fc9b_8c92_43d3_991e_849a82f79b2f',1,True,null,'eec8e921_75ec_488a_99c1_342aa93a307f','075d2b91_6ed8_46b2_a209_cbf76568d06c','4bc3f7e1_3295_4065_82d2_41f7b79881bd');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,username,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,account_fk,load_info_fk) VALUES 
    (0,'e073e6ab_f920_4863_8ac6_da9f3971790b','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','5f5f8d99_4600_4d1e_8a1c_0f9f40d895ae','d08db382_0dca_4815_93fe_be957d876590','','7cb7a40e_12ad_4298_9543_07c02820f865'),
    (0,'e073e6ab_f920_4863_8ac6_da9f3971790b','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','1e67ab7f_52ed_4949_a9e7_5d61f0d4bfd1','9db817cb_c157_45d3_b558_4ae1f4221be9','','7cb7a40e_12ad_4298_9543_07c02820f865'),
    (0,'e073e6ab_f920_4863_8ac6_da9f3971790b','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','add25f2e_25c1_4ab6_a928_d24b0735e002','49abdbc6_1734_4ad2_9e16_d65d199b2d34','','7cb7a40e_12ad_4298_9543_07c02820f865'),
    (0,'e073e6ab_f920_4863_8ac6_da9f3971790b','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','b36379e8_4b0e_4889_8a45_1db1b369b76b','41e24f03_7ef7_4482_a7fb_ab3ff6fa6baf','','7cb7a40e_12ad_4298_9543_07c02820f865'),
    (0,'e073e6ab_f920_4863_8ac6_da9f3971790b','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','7da3f139_0ea8_42d2_97ab_2af5caad4949','6e40ee5a_52b7_4562_a60f_76c79b0aec2b','','7cb7a40e_12ad_4298_9543_07c02820f865'),
    (0,'e073e6ab_f920_4863_8ac6_da9f3971790b','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','9fabc6ce_9e7e_4829_92ec_5b88826454ef','de28e8a2_84e8_4af2_a541_fbd9155064b7','','7cb7a40e_12ad_4298_9543_07c02820f865'),
    (0,'e073e6ab_f920_4863_8ac6_da9f3971790b','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','edb2cd13_7ec7_42a4_a5c8_8279a43fcdc4','42036c7f_8998_4809_ba94_3e5f0506ebbe','','7cb7a40e_12ad_4298_9543_07c02820f865'),
    (0,'e073e6ab_f920_4863_8ac6_da9f3971790b','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','dbf53724_bc66_43eb_b180_2fcaf0033086','9e57fc9b_8c92_43d3_991e_849a82f79b2f','','7cb7a40e_12ad_4298_9543_07c02820f865'),
    (0,'e073e6ab_f920_4863_8ac6_da9f3971790b','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module','','2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00','','','Medicine-HRP258','',-1,-1,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','closed','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','dbf53724_bc66_43eb_b180_2fcaf0033086','9e57fc9b_8c92_43d3_991e_849a82f79b2f','','7cb7a40e_12ad_4298_9543_07c02820f865');
COMMIT;
SET foreign_key_checks=1;
SET unique_checks=1;
