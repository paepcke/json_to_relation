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
    ('28b43c18_b19c_4863_9f4b_d39f0e7d11ab','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1'),
    ('9008493c_44ce_4671_b8b4_e17095f49de7','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3'),
    ('ec568c1a_a93e_4cea_8f63_551d2fe64ac0','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1'),
    ('96bf36b8_052a_47ca_926e_291a8f1eb51d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0'),
    ('d080c499_61c2_4c44_9d0d_fcb8e9d282b5','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4'),
    ('b283460a_d502_4517_aec9_e2d174a56ee5','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2'),
    ('1ec4fe00_fcea_400e_bc97_09e2ac896e43','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0'),
    ('05b1e5ad_48ab_404a_b440_e77b3e7da570','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0'),
    ('07505d63_e353_4fb9_ab25_3f564529c418','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1'),
    ('5f100838_020b_435d_99b1_7ce3d739aa4e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3'),
    ('7302bfcd_d5be_41e7_8c24_89ca41a3e7b2','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1'),
    ('6b10c52c_03de_4342_8b6b_81906c61dea3','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0'),
    ('f89a8d81_35dd_48b9_9bea_7c80f3a09e3b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4'),
    ('c3ae9888_7086_4a46_bac4_103ce820f852','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2'),
    ('9b1b10ea_5dba_459d_93f5_7e4b9d3249e5','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0'),
    ('fa55ed12_2981_40dd_8167_3ad212b7b033','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0');
INSERT INTO CorrectMap (correct_map_id,answer_id,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('b854463c_bb5e_4961_8294_ab27522d312a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','correct',null,'','',null,null),
    ('feab55ae_fd40_4ffb_b8f9_98ab1112b137','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','correct',null,'','',null,null),
    ('4b31b567_db79_4f9d_a23b_353e36c144ba','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','correct',null,'','',null,null),
    ('1c09ba43_00fb_41b2_9fad_cedbded40fe0','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','correct',null,'','',null,null),
    ('17522565_9ac5_44af_b507_9c8917ac54b3','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','incorrect',null,'','',null,null),
    ('c9feb6e8_0da2_49f8_90fd_9cc8487bf316','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','correct',null,'','',null,null),
    ('9a94756e_67bc_4300_aaed_c9a5a2e3843b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','correct',null,'','',null,null),
    ('24f7b876_b853_43d4_b1f8_a960baa4611f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('8984e2d9_dfe9_4000_afb4_279834a0c2b1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',null),
    ('027998cd_110a_4757_873a_0d4ffc4d51e5','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',null),
    ('cdb0c3a0_d240_4b02_b1e5_d823f9b1750b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',null),
    ('dd19837d_e24e_43fa_afbb_abf5b1b0872b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',null),
    ('98cd9764_9506_4401_938d_f6d00e91478c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',null),
    ('29c60714_7433_45d5_9ba7_0c543e726c47','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',null),
    ('ef9fd051_3c36_4064_af79_b2296bc01eff','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',null),
    ('f6842648_388e_4b96_9c44_53df306288fe','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null);
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('82c98e54_2ed1_4420_af3b_404636679b5c',1,True,null,'07505d63_e353_4fb9_ab25_3f564529c418','b854463c_bb5e_4961_8294_ab27522d312a','8984e2d9_dfe9_4000_afb4_279834a0c2b1'),
    ('2e6a143f_df58_40b4_81f6_4fbc4ba0c50e',1,True,null,'5f100838_020b_435d_99b1_7ce3d739aa4e','feab55ae_fd40_4ffb_b8f9_98ab1112b137','027998cd_110a_4757_873a_0d4ffc4d51e5'),
    ('455184b9_734e_4a6d_a0ec_ff94cda256d4',1,True,null,'7302bfcd_d5be_41e7_8c24_89ca41a3e7b2','4b31b567_db79_4f9d_a23b_353e36c144ba','cdb0c3a0_d240_4b02_b1e5_d823f9b1750b'),
    ('5a23f024_0683_4554_8d4c_60c3eb25f15a',1,True,null,'6b10c52c_03de_4342_8b6b_81906c61dea3','1c09ba43_00fb_41b2_9fad_cedbded40fe0','dd19837d_e24e_43fa_afbb_abf5b1b0872b'),
    ('f3bf9b01_f486_454e_9f93_c7ba8e8e87bb',1,True,null,'f89a8d81_35dd_48b9_9bea_7c80f3a09e3b','17522565_9ac5_44af_b507_9c8917ac54b3','98cd9764_9506_4401_938d_f6d00e91478c'),
    ('8e8b6711_a7c3_4da0_9641_1224894bd357',1,True,null,'c3ae9888_7086_4a46_bac4_103ce820f852','c9feb6e8_0da2_49f8_90fd_9cc8487bf316','29c60714_7433_45d5_9ba7_0c543e726c47'),
    ('3abba7b4_7d91_4e46_8813_ab04d7bcd976',1,True,null,'9b1b10ea_5dba_459d_93f5_7e4b9d3249e5','9a94756e_67bc_4300_aaed_c9a5a2e3843b','ef9fd051_3c36_4064_af79_b2296bc01eff'),
    ('ce8dcf92_08d0_41d6_a63d_18787025bdd6',1,True,null,'fa55ed12_2981_40dd_8167_3ad212b7b033','24f7b876_b853_43d4_b1f8_a960baa4611f','f6842648_388e_4b96_9c44_53df306288fe');
INSERT INTO Event (eventID,agent,event_source,event_type,ip,page,session,time,username,downtime_for,studentID,instructorID,courseID,seqID,gotoFrom,gotoDest,problemID,problemChoice,questionLocation,attempts,longAnswer,studentFile,canUploadFile,feedback,feedbackResponseSelected,transcriptID,transcriptCode,rubricSelection,rubricCategory,videoID,videoCode,videoCurrentTime,videoSpeed,videoOldTime,videoNewTime,videoSeekType,bookInteractionType,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,correctMapFK,answerFK,stateFK) VALUES 
    ('e365ef11_6562_469f_9d23_dfbed2d52979','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'28b43c18_b19c_4863_9f4b_d39f0e7d11ab','82c98e54_2ed1_4420_af3b_404636679b5c'),
    ('e365ef11_6562_469f_9d23_dfbed2d52979','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'9008493c_44ce_4671_b8b4_e17095f49de7','2e6a143f_df58_40b4_81f6_4fbc4ba0c50e'),
    ('e365ef11_6562_469f_9d23_dfbed2d52979','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'ec568c1a_a93e_4cea_8f63_551d2fe64ac0','455184b9_734e_4a6d_a0ec_ff94cda256d4'),
    ('e365ef11_6562_469f_9d23_dfbed2d52979','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'96bf36b8_052a_47ca_926e_291a8f1eb51d','5a23f024_0683_4554_8d4c_60c3eb25f15a'),
    ('e365ef11_6562_469f_9d23_dfbed2d52979','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'d080c499_61c2_4c44_9d0d_fcb8e9d282b5','f3bf9b01_f486_454e_9f93_c7ba8e8e87bb'),
    ('e365ef11_6562_469f_9d23_dfbed2d52979','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'b283460a_d502_4517_aec9_e2d174a56ee5','8e8b6711_a7c3_4da0_9641_1224894bd357'),
    ('e365ef11_6562_469f_9d23_dfbed2d52979','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'1ec4fe00_fcea_400e_bc97_09e2ac896e43','3abba7b4_7d91_4e46_8813_ab04d7bcd976'),
    ('e365ef11_6562_469f_9d23_dfbed2d52979','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'05b1e5ad_48ab_404a_b440_e77b3e7da570','ce8dcf92_08d0_41d6_a63d_18787025bdd6'),
    ('e365ef11_6562_469f_9d23_dfbed2d52979','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML\, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'05b1e5ad_48ab_404a_b440_e77b3e7da570','ce8dcf92_08d0_41d6_a63d_18787025bdd6');
COMMIT;
