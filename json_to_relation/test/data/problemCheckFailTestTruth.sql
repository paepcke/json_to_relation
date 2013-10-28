USE test;
SET foreign_key_checks = 0;
DROP TABLE IF EXISTS Event, Answer, InputState, CorrectMap, State, Account;
SET foreign_key_checks = 1;
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
CREATE TABLE IF NOT EXISTS Account (
    account_id VARCHAR(32) NOT NULL Primary Key,
    username TEXT,
    name TEXT,
    mailing_address TEXT,
    gender TINYTEXT,
    year_of_birth TINYINT,
    level_of_education TINYTEXT,
    goals TEXT,
    honor_code BOOL,
    terms_of_service BOOL,
    course_id TEXT,
    enrollment_action TINYTEXT,
    email TEXT
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
    longAnswer TEXT,
    studentFile TEXT,
    canUploadFile TINYTEXT,
    feedback TEXT,
    feedbackResponseSelected TINYINT,
    transcriptID TEXT,
    transcriptCode TINYTEXT,
    rubricSelection INT,
    rubricCategory INT,
    videoID TEXT,
    videoCode TEXT,
    videoCurrentTime FLOAT,
    videoSpeed TINYTEXT,
    videoOldTime FLOAT,
    videoNewTime FLOAT,
    videoSeekType TINYTEXT,
    videoNewSpeed FLOAT,
    videoOldSpeed FLOAT,
    bookInteractionType TINYTEXT,
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
    badlyFormatted TEXT,
    correctMapFK VARCHAR(32),
    answerFK VARCHAR(32),
    stateFK VARCHAR(32),
    accountFK VARCHAR(32),
    FOREIGN KEY(correctMapFK) REFERENCES CorrectMap(correct_map_id),
    FOREIGN KEY(answerFK) REFERENCES Answer(answer_id),
    FOREIGN KEY(stateFK) REFERENCES State(state_id),
    FOREIGN KEY(accountFK) REFERENCES Account(account_id)
    );
START TRANSACTION;
INSERT INTO Answer (answer_id,problem_id,answer) VALUES 
    ('5a75ff46_581e_4d77_aca0_2703c94e2506','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1'),
    ('f81a48dd_f969_4cfa_a584_ff2d1192a4de','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3'),
    ('7fcbd31a_e88a_4654_a6d3_db2f86f6c526','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1'),
    ('cd384bc4_c6e0_4925_94ed_f031ed19ac24','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0'),
    ('46961a91_4777_4558_a6ae_80866d28822c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4'),
    ('d3cfe292_0e36_4b38_80df_d196741e4ff6','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2'),
    ('00b057b2_d277_4280_8295_bdf5740c942f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0'),
    ('60ffbee2_2c29_436a_b799_717caab84035','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0'),
    ('fabc3568_59b2_4170_a139_81a65d1fd29a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1'),
    ('c45a61b0_f483_4ec5_a424_319011fcbfd3','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3'),
    ('c7f8059e_4928_45c7_b996_a21617a7908c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1'),
    ('dec345de_e1af_49dd_a158_c5d07294f39a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0'),
    ('52ebd2c3_f003_47cb_8125_14e65f462507','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4'),
    ('9ae0a65e_aa91_400d_b768_0ce9674bca04','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2'),
    ('160760ec_1cbb_406e_9c95_4ecb2e3c5b63','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0'),
    ('49740184_f6e8_4fdf_b2ce_e4634e5982c3','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0');
INSERT INTO CorrectMap (correct_map_id,answer_id,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('4ac7fa3f_a531_4356_a982_daf42df29432','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','correct',null,'','',null,null),
    ('daaa7459_f27b_4538_aec4_53374bf2c62e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','correct',null,'','',null,null),
    ('b9481cde_a33c_4202_b505_d0dd1ba07c06','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','correct',null,'','',null,null),
    ('80684808_eed7_4520_bac8_e053fe329ae7','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','correct',null,'','',null,null),
    ('3efa266b_a052_433f_8348_dde7520a9dfd','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','incorrect',null,'','',null,null),
    ('4f2fa133_6efd_4785_b47f_b9a376056997','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','correct',null,'','',null,null),
    ('d9b77fd3_f154_4315_9d85_b41c6af8195d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','correct',null,'','',null,null),
    ('a858d85d_7672_429c_9e8f_05f8fdb9ec6a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('803dce9f_cd3b_4a65_bed3_bd43fda9005e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',null),
    ('7ad4acb1_75c6_4d39_a2ed_3fb87600fc59','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',null),
    ('61bc2ead_ee61_4ca0_b243_d22fc7ab1752','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',null),
    ('d1fec995_08cc_46e4_bf72_24dbaf54c033','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',null),
    ('5692e6b6_0748_4720_bd50_a347931c45e4','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',null),
    ('e28e06c9_63fa_463b_bd45_4c70c80be32a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',null),
    ('c8c8575e_9bad_489a_b8ec_d82dce458481','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',null),
    ('365ac9c5_963f_4bbb_b1f6_dc46e88c679f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null);
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('3fa46ac4_08af_481f_8ba6_34f0b67823a9',1,True,null,'fabc3568_59b2_4170_a139_81a65d1fd29a','4ac7fa3f_a531_4356_a982_daf42df29432','803dce9f_cd3b_4a65_bed3_bd43fda9005e'),
    ('ed877646_c72d_4eb6_897e_3885da661c22',1,True,null,'c45a61b0_f483_4ec5_a424_319011fcbfd3','daaa7459_f27b_4538_aec4_53374bf2c62e','7ad4acb1_75c6_4d39_a2ed_3fb87600fc59'),
    ('71073a9b_90ff_4422_837c_4db93a01f184',1,True,null,'c7f8059e_4928_45c7_b996_a21617a7908c','b9481cde_a33c_4202_b505_d0dd1ba07c06','61bc2ead_ee61_4ca0_b243_d22fc7ab1752'),
    ('71d6a2f3_5874_41b3_be21_09cf0b58fb5e',1,True,null,'dec345de_e1af_49dd_a158_c5d07294f39a','80684808_eed7_4520_bac8_e053fe329ae7','d1fec995_08cc_46e4_bf72_24dbaf54c033'),
    ('79d00f06_f340_4d99_96c8_dbe64728da3b',1,True,null,'52ebd2c3_f003_47cb_8125_14e65f462507','3efa266b_a052_433f_8348_dde7520a9dfd','5692e6b6_0748_4720_bd50_a347931c45e4'),
    ('7f31c31c_3779_4e2c_92f2_75306ab0970e',1,True,null,'9ae0a65e_aa91_400d_b768_0ce9674bca04','4f2fa133_6efd_4785_b47f_b9a376056997','e28e06c9_63fa_463b_bd45_4c70c80be32a'),
    ('b6b88170_a085_4968_87c9_5e39a86db292',1,True,null,'160760ec_1cbb_406e_9c95_4ecb2e3c5b63','d9b77fd3_f154_4315_9d85_b41c6af8195d','c8c8575e_9bad_489a_b8ec_d82dce458481'),
    ('f3abb0f5_96dd_4e4a_b85e_d50a2811285b',1,True,null,'49740184_f6e8_4fdf_b2ce_e4634e5982c3','a858d85d_7672_429c_9e8f_05f8fdb9ec6a','365ac9c5_963f_4bbb_b1f6_dc46e88c679f');
INSERT INTO Event (eventID,agent,event_source,event_type,ip,page,session,time,username,downtime_for,studentID,instructorID,courseID,seqID,gotoFrom,gotoDest,problemID,problemChoice,questionLocation,attempts,longAnswer,studentFile,canUploadFile,feedback,feedbackResponseSelected,transcriptID,transcriptCode,rubricSelection,rubricCategory,videoID,videoCode,videoCurrentTime,videoSpeed,videoOldTime,videoNewTime,videoSeekType,videoNewSpeed,videoOldSpeed,bookInteractionType,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badlyFormatted,correctMapFK,answerFK,stateFK) VALUES 
    ('18759474_6bfb_492f_90b2_882c3b91bcc7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'5a75ff46_581e_4d77_aca0_2703c94e2506','3fa46ac4_08af_481f_8ba6_34f0b67823a9'),
    ('18759474_6bfb_492f_90b2_882c3b91bcc7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'f81a48dd_f969_4cfa_a584_ff2d1192a4de','ed877646_c72d_4eb6_897e_3885da661c22'),
    ('18759474_6bfb_492f_90b2_882c3b91bcc7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'7fcbd31a_e88a_4654_a6d3_db2f86f6c526','71073a9b_90ff_4422_837c_4db93a01f184'),
    ('18759474_6bfb_492f_90b2_882c3b91bcc7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'cd384bc4_c6e0_4925_94ed_f031ed19ac24','71d6a2f3_5874_41b3_be21_09cf0b58fb5e'),
    ('18759474_6bfb_492f_90b2_882c3b91bcc7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'46961a91_4777_4558_a6ae_80866d28822c','79d00f06_f340_4d99_96c8_dbe64728da3b'),
    ('18759474_6bfb_492f_90b2_882c3b91bcc7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'d3cfe292_0e36_4b38_80df_d196741e4ff6','7f31c31c_3779_4e2c_92f2_75306ab0970e'),
    ('18759474_6bfb_492f_90b2_882c3b91bcc7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'00b057b2_d277_4280_8295_bdf5740c942f','b6b88170_a085_4968_87c9_5e39a86db292'),
    ('18759474_6bfb_492f_90b2_882c3b91bcc7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'60ffbee2_2c29_436a_b799_717caab84035','f3abb0f5_96dd_4e4a_b85e_d50a2811285b'),
    ('18759474_6bfb_492f_90b2_882c3b91bcc7','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'60ffbee2_2c29_436a_b799_717caab84035','f3abb0f5_96dd_4e4a_b85e_d50a2811285b');
COMMIT;
