USE test;
CREATE TABLE IF NOT EXISTS Answer (
    answer_id VARCHAR(32) NOT NULL Primary Key,
    problem_id TEXT,
    answer TEXT
    );
CREATE TABLE IF NOT EXISTS CorrectMap (
    correct_map_id VARCHAR(32) NOT NULL Primary Key,
    answer_id TEXT,
    correctness TINYTEXT,
    npoints INT,
    msg TEXT,
    hint TEXT,
    hintmode TINYTEXT,
    queuestate TEXT
    );
CREATE TABLE IF NOT EXISTS InputState (
    input_state_id VARCHAR(32) NOT NULL Primary Key,
    problem_id TEXT,
    state TEXT
    );
CREATE TABLE IF NOT EXISTS State (
    state_id VARCHAR(32) NOT NULL Primary Key,
    seed TINYINT,
    done BOOL,
    problem_id TEXT,
    student_answer VARCHAR(32),
    correct_map VARCHAR(32),
    input_state VARCHAR(32),
    FOREIGN KEY(student_answer) REFERENCES Answer(answer_id),
    FOREIGN KEY(correct_map) REFERENCES CorrectMap(correct_map_id),
    FOREIGN KEY(input_state) REFERENCES InputState(input_state_id)
    );
CREATE TABLE IF NOT EXISTS Event (
    eventID VARCHAR(32),
    agent TEXT,
    event_source TINYTEXT,
    event_type TEXT,
    ip TINYTEXT,
    page TEXT,
    session TEXT,
    time DATETIME,
    username TEXT,
    downtime_for DATETIME,
    studentID TEXT,
    instructorID TEXT,
    courseID TEXT,
    seqID TEXT,
    gotoFrom INT,
    gotoDest INT,
    problemID TEXT,
    problemChoice TEXT,
    questionLocation TEXT,
    attempts TINYINT,
    feedback TEXT,
    feedbackResponseSelected TINYINT,
    rubricSelection INT,
    rubricCategory INT,
    videoID TEXT,
    videoCode TEXT,
    videoCurrentTime FLOAT,
    videoSpeed TINYTEXT,
    bookInteractionType TINYTEXT,
    success TINYTEXT,
    answer_id TEXT,
    hint TEXT,
    hintmode TINYTEXT,
    correctness TINYTEXT,
    msg TEXT,
    npoints TINYINT,
    queuestate TEXT,
    correctMapFK VARCHAR(32),
    answerFK VARCHAR(32),
    stateFK VARCHAR(32),
    orig_score INT,
    new_score INT,
    orig_total INT,
    new_total INT,
    FOREIGN KEY(correctMapFK) REFERENCES CorrectMap(correct_map_id),
    FOREIGN KEY(answerFK) REFERENCES Answer(answer_id),
    FOREIGN KEY(stateFK) REFERENCES State(state_id)
    );
START TRANSACTION;
INSERT INTO Answer (answer_id,problem_id,answer) VALUES 
    ('e36953e5_d2bd_4ec7_9f6b_f80b7c9d8257','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1'),
    ('24da35a3_7332_447c_9a87_0be7cc9021eb','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3'),
    ('849d7681_b6be_445b_a59a_6bbfbcd95e40','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',[u'choice_0', u'choice_1']),
    ('dbabba10_9399_4ca2_98c0_215b5d48183a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0'),
    ('2849f43b_f88b_446d_af71_115da389136c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',[u'choice_0', u'choice_1', u'choice_2', u'choice_3', u'choice_4']),
    ('5a925c39_f3ee_4104_b393_f718ba102c50','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2'),
    ('4fdfde49_4949_4b59_af17_7922fbb8b866','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0'),
    ('ab9ca952_6128_44db_81d8_a4a92460dad1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0'),
    ('9ae81ea7_09f7_43c3_ad3d_437ef98bbbab','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1'),
    ('794d843b_1a8a_4a00_af1e_07c5ced7787a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3'),
    ('f071710b_7680_4472_a658_f7b2436dc280','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',[u'choice_0', u'choice_1']),
    ('29a58741_dce3_47cb_a5b2_4726ff78c626','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0'),
    ('e32e7adf_43ac_4e20_afae_234401d0a57e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',[u'choice_0', u'choice_1', u'choice_2', u'choice_3', u'choice_4']),
    ('0e0dedc1_ba93_4543_9abc_0d5e7e1bfcc5','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2'),
    ('a84f7705_06b8_42d3_b2fc_40fc5cc87caf','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0'),
    ('81c583f0_8528_4070_9844_801dcc2a045c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0');
INSERT INTO CorrectMap (correct_map_id,answer_id,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('f8041e18_14c0_46fc_9944_89aa1feb4b66','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','correct',null,'','',null,null),
    ('a321b906_c9ca_4654_add8_2b0443df2872','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','correct',null,'','',null,null),
    ('a2894024_907f_4056_a44d_22d31016fee9','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','correct',null,'','',null,null),
    ('2e94222c_23d2_4cfe_b99d_586a0d63f32d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','correct',null,'','',null,null),
    ('bf657d28_eb72_4f03_8fe9_b660c9946e94','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','incorrect',null,'','',null,null),
    ('1dfe8ec3_f9f1_427a_a8e6_7d3ad949a09b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','correct',null,'','',null,null),
    ('95b7a615_6271_4038_a86e_9a402ffa1dab','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','correct',null,'','',null,null),
    ('225756d2_8102_40c4_8a3e_1a310bf072a8','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('a4a48be1_aeb8_493e_ad2b_71f963272db0','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',{}),
    ('f817f5f4_4a5a_40ee_a60c_6e79bb17bb86','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',{}),
    ('49174daa_0d38_4d64_99cc_7cc9778d8c87','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',{}),
    ('65f56cd5_2410_4c98_8371_7342b9327f0b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',{}),
    ('38dd84f5_082b_47fb_bc07_7824fce63d48','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',{}),
    ('2a0cbe48_b7c0_438c_9cc9_1f2cfb6a9ec2','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',{}),
    ('ea6d6458_ac3b_4f2d_a959_5677a7419fc1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',{}),
    ('63c1a024_b779_4a1d_a211_782a2d76497f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',{});
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('85d70f2e_c417_40f4_9e11_111acaf06515',1,True,null,'9ae81ea7_09f7_43c3_ad3d_437ef98bbbab','f8041e18_14c0_46fc_9944_89aa1feb4b66','a4a48be1_aeb8_493e_ad2b_71f963272db0'),
    ('85d70f2e_c417_40f4_9e11_111acaf06515',1,True,null,'794d843b_1a8a_4a00_af1e_07c5ced7787a','a321b906_c9ca_4654_add8_2b0443df2872','f817f5f4_4a5a_40ee_a60c_6e79bb17bb86'),
    ('85d70f2e_c417_40f4_9e11_111acaf06515',1,True,null,'f071710b_7680_4472_a658_f7b2436dc280','a2894024_907f_4056_a44d_22d31016fee9','49174daa_0d38_4d64_99cc_7cc9778d8c87'),
    ('85d70f2e_c417_40f4_9e11_111acaf06515',1,True,null,'29a58741_dce3_47cb_a5b2_4726ff78c626','2e94222c_23d2_4cfe_b99d_586a0d63f32d','65f56cd5_2410_4c98_8371_7342b9327f0b'),
    ('85d70f2e_c417_40f4_9e11_111acaf06515',1,True,null,'e32e7adf_43ac_4e20_afae_234401d0a57e','bf657d28_eb72_4f03_8fe9_b660c9946e94','38dd84f5_082b_47fb_bc07_7824fce63d48'),
    ('85d70f2e_c417_40f4_9e11_111acaf06515',1,True,null,'0e0dedc1_ba93_4543_9abc_0d5e7e1bfcc5','1dfe8ec3_f9f1_427a_a8e6_7d3ad949a09b','2a0cbe48_b7c0_438c_9cc9_1f2cfb6a9ec2'),
    ('85d70f2e_c417_40f4_9e11_111acaf06515',1,True,null,'a84f7705_06b8_42d3_b2fc_40fc5cc87caf','95b7a615_6271_4038_a86e_9a402ffa1dab','ea6d6458_ac3b_4f2d_a959_5677a7419fc1'),
    ('85d70f2e_c417_40f4_9e11_111acaf06515',1,True,null,'81c583f0_8528_4070_9844_801dcc2a045c','225756d2_8102_40c4_8a3e_1a310bf072a8','63c1a024_b779_4a1d_a211_782a2d76497f');
INSERT INTO Event (eventID,agent,event_source,event_type,ip,page,session,time,username,downtime_for,studentID,instructorID,courseID,seqID,gotoFrom,gotoDest,problemID,problemChoice,questionLocation,attempts,feedback,feedbackResponseSelected,rubricSelection,rubricCategory,videoID,videoCode,videoCurrentTime,videoSpeed,bookInteractionType,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,correctMapFK,answerFK,stateFK) VALUES 
    ('4e16ea65_b478_4af1_84c5_857d62624a4e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x://Medicine/HRP258/problem/4cd47ea861f542488a20691ac424a002',null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,'e36953e5_d2bd_4ec7_9f6b_f80b7c9d8257','85d70f2e_c417_40f4_9e11_111acaf06515'),
    ('4e16ea65_b478_4af1_84c5_857d62624a4e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x://Medicine/HRP258/problem/4cd47ea861f542488a20691ac424a002',null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,'24da35a3_7332_447c_9a87_0be7cc9021eb',null),
    ('4e16ea65_b478_4af1_84c5_857d62624a4e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x://Medicine/HRP258/problem/4cd47ea861f542488a20691ac424a002',null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,'849d7681_b6be_445b_a59a_6bbfbcd95e40',null),
    ('4e16ea65_b478_4af1_84c5_857d62624a4e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x://Medicine/HRP258/problem/4cd47ea861f542488a20691ac424a002',null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,'dbabba10_9399_4ca2_98c0_215b5d48183a',null),
    ('4e16ea65_b478_4af1_84c5_857d62624a4e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x://Medicine/HRP258/problem/4cd47ea861f542488a20691ac424a002',null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,'2849f43b_f88b_446d_af71_115da389136c',null),
    ('4e16ea65_b478_4af1_84c5_857d62624a4e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x://Medicine/HRP258/problem/4cd47ea861f542488a20691ac424a002',null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,'5a925c39_f3ee_4104_b393_f718ba102c50',null),
    ('4e16ea65_b478_4af1_84c5_857d62624a4e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x://Medicine/HRP258/problem/4cd47ea861f542488a20691ac424a002',null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,'4fdfde49_4949_4b59_af17_7922fbb8b866',null),
    ('4e16ea65_b478_4af1_84c5_857d62624a4e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x://Medicine/HRP258/problem/4cd47ea861f542488a20691ac424a002',null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,'ab9ca952_6128_44db_81d8_a4a92460dad1',null),
    ('4e16ea65_b478_4af1_84c5_857d62624a4e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x://Medicine/HRP258/problem/4cd47ea861f542488a20691ac424a002',null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,'ab9ca952_6128_44db_81d8_a4a92460dad1',null);
COMMIT;
