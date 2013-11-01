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
    eventID VARCHAR(40),
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
    submissionID TEXT,
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
    videoCurrentTime TINYTEXT,
    videoSpeed TINYTEXT,
    videoOldTime TINYTEXT,
    videoNewTime TINYTEXT,
    videoSeekType TINYTEXT,
    videoNewSpeed TINYTEXT,
    videoOldSpeed TINYTEXT,
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
    correctMapFK VARCHAR(40),
    answerFK VARCHAR(40),
    stateFK VARCHAR(40),
    accountFK VARCHAR(40),
    FOREIGN KEY(correctMapFK) REFERENCES CorrectMap(correct_map_id),
    FOREIGN KEY(answerFK) REFERENCES Answer(answer_id),
    FOREIGN KEY(stateFK) REFERENCES State(state_id),
    FOREIGN KEY(accountFK) REFERENCES Account(account_id)
    );
SET foreign_key_checks=0;
SET unique_checks=0;
SET autocommit=0;
INSERT INTO Answer (answer_id,problem_id,answer) VALUES 
    ('7cf9f1c4_651e_424c_a4ed_423a2abc938f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1'),
    ('ff8d6c5b_1949_4cca_b726_9f3d8312948c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3'),
    ('3707e5d1_2e78_437a_b95e_0b1330e357c8','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1'),
    ('ea85e923_582b_4793_9fcd_6b0f93ed2953','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0'),
    ('adb41b97_b749_4987_ab56_d19d5bafb22a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4'),
    ('d621cabb_97be_4cc1_b452_bfff824aaacc','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2'),
    ('db47c084_b4d7_4c60_937b_e527af69ed25','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0'),
    ('b17f6532_7fdf_4c9f_9d8f_132c171d3bdc','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0'),
    ('52c4909f_b4b0_421a_9f91_d1a346575912','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1'),
    ('6164c50e_7333_47d6_89ac_24ec284dbb9b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3'),
    ('347687f0_ad2b_46cb_8806_d9cad4308ec2','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1'),
    ('7b45e6ab_c39b_4931_b753_3f38fa3cb096','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0'),
    ('329f5918_ff21_49f2_81b4_19c468eaca79','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4'),
    ('ed1243b8_ade0_430a_b3a3_7c002fd0160e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2'),
    ('d704e6ca_ca5e_407f_b0aa_e1e7e65b602f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0'),
    ('a7f27ca9_f3f6_457c_bb9a_3170465e6c6d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('5f21d5b3_e052_41cf_ab90_d68c1fcfc813','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','correct',null,'','',null,null),
    ('d21e25bb_715a_4031_b485_573ecc873abb','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','correct',null,'','',null,null),
    ('60749488_3fbc_4185_a067_53782fe4f7d2','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','correct',null,'','',null,null),
    ('90710bdd_8053_409b_a988_42ac987caee5','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','correct',null,'','',null,null),
    ('d2c23ed7_21af_4e8c_b342_70fe56e38ff3','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','incorrect',null,'','',null,null),
    ('2c4a2368_5d05_42cd_8d06_1f0f673378e4','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','correct',null,'','',null,null),
    ('485e91ad_f7ca_4db3_a3e0_50597ef7db81','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','correct',null,'','',null,null),
    ('938ebf55_7129_4191_abf4_83a0c62de7c7','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('18d1f93b_536b_4fb6_b4da_fbd54f232ffe','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',null),
    ('5245b459_b6b2_4334_86b4_9351139015cc','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',null),
    ('42247393_7781_4baf_807e_6e7187daab4e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',null),
    ('4cdfef3d_723b_4892_b594_7680e2a6e254','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',null),
    ('0f85a5b5_cbb6_483a_a044_7ea4ae57c2b4','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',null),
    ('14469171_8ccf_4d49_a216_959f247d9071','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',null),
    ('0a9cd617_d572_4891_994b_dbf6cb152d89','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',null),
    ('6e1493d1_6ebd_45ad_8dc6_a08358db146e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null);
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('62e7ad87_0e63_43c6_a465_83a7f75d1c88',1,True,null,'52c4909f_b4b0_421a_9f91_d1a346575912','5f21d5b3_e052_41cf_ab90_d68c1fcfc813','18d1f93b_536b_4fb6_b4da_fbd54f232ffe'),
    ('59316673_2b2f_4989_abb6_9c84799e7153',1,True,null,'6164c50e_7333_47d6_89ac_24ec284dbb9b','d21e25bb_715a_4031_b485_573ecc873abb','5245b459_b6b2_4334_86b4_9351139015cc'),
    ('ced04733_7426_4762_a0c7_f9b874f960c1',1,True,null,'347687f0_ad2b_46cb_8806_d9cad4308ec2','60749488_3fbc_4185_a067_53782fe4f7d2','42247393_7781_4baf_807e_6e7187daab4e'),
    ('2984fb53_75a4_413e_92ac_f24ecf5dd6da',1,True,null,'7b45e6ab_c39b_4931_b753_3f38fa3cb096','90710bdd_8053_409b_a988_42ac987caee5','4cdfef3d_723b_4892_b594_7680e2a6e254'),
    ('a456e953_dfd1_43d0_b8b7_dedcd45f2dc0',1,True,null,'329f5918_ff21_49f2_81b4_19c468eaca79','d2c23ed7_21af_4e8c_b342_70fe56e38ff3','0f85a5b5_cbb6_483a_a044_7ea4ae57c2b4'),
    ('146ea36f_43ab_43e9_b262_e1596f01b3c5',1,True,null,'ed1243b8_ade0_430a_b3a3_7c002fd0160e','2c4a2368_5d05_42cd_8d06_1f0f673378e4','14469171_8ccf_4d49_a216_959f247d9071'),
    ('a50f67a5_94d0_4b25_b1b3_4712dd14142b',1,True,null,'d704e6ca_ca5e_407f_b0aa_e1e7e65b602f','485e91ad_f7ca_4db3_a3e0_50597ef7db81','0a9cd617_d572_4891_994b_dbf6cb152d89'),
    ('94ce6c43_8d2b_4268_ab9e_f5f02afb80f1',1,True,null,'a7f27ca9_f3f6_457c_bb9a_3170465e6c6d','938ebf55_7129_4191_abf4_83a0c62de7c7','6e1493d1_6ebd_45ad_8dc6_a08358db146e');
INSERT INTO Event (eventID,agent,event_source,event_type,ip,page,session,time,username,downtime_for,studentID,instructorID,courseID,seqID,gotoFrom,gotoDest,problemID,problemChoice,questionLocation,submissionID,attempts,longAnswer,studentFile,canUploadFile,feedback,feedbackResponseSelected,transcriptID,transcriptCode,rubricSelection,rubricCategory,videoID,videoCode,videoCurrentTime,videoSpeed,videoOldTime,videoNewTime,videoSeekType,videoNewSpeed,videoOldSpeed,bookInteractionType,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badlyFormatted,correctMapFK,answerFK,stateFK) VALUES 
    ('d1a059be_3baf_493a_95d0_1e776cb7518e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'7cf9f1c4_651e_424c_a4ed_423a2abc938f','62e7ad87_0e63_43c6_a465_83a7f75d1c88'),
    ('d1a059be_3baf_493a_95d0_1e776cb7518e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'ff8d6c5b_1949_4cca_b726_9f3d8312948c','59316673_2b2f_4989_abb6_9c84799e7153'),
    ('d1a059be_3baf_493a_95d0_1e776cb7518e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'3707e5d1_2e78_437a_b95e_0b1330e357c8','ced04733_7426_4762_a0c7_f9b874f960c1'),
    ('d1a059be_3baf_493a_95d0_1e776cb7518e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'ea85e923_582b_4793_9fcd_6b0f93ed2953','2984fb53_75a4_413e_92ac_f24ecf5dd6da'),
    ('d1a059be_3baf_493a_95d0_1e776cb7518e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'adb41b97_b749_4987_ab56_d19d5bafb22a','a456e953_dfd1_43d0_b8b7_dedcd45f2dc0'),
    ('d1a059be_3baf_493a_95d0_1e776cb7518e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'d621cabb_97be_4cc1_b452_bfff824aaacc','146ea36f_43ab_43e9_b262_e1596f01b3c5'),
    ('d1a059be_3baf_493a_95d0_1e776cb7518e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'db47c084_b4d7_4c60_937b_e527af69ed25','a50f67a5_94d0_4b25_b1b3_4712dd14142b'),
    ('d1a059be_3baf_493a_95d0_1e776cb7518e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'b17f6532_7fdf_4c9f_9d8f_132c171d3bdc','94ce6c43_8d2b_4268_ab9e_f5f02afb80f1'),
    ('d1a059be_3baf_493a_95d0_1e776cb7518e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'b17f6532_7fdf_4c9f_9d8f_132c171d3bdc','94ce6c43_8d2b_4268_ab9e_f5f02afb80f1');
COMMIT;
SET foreign_key_checks=1;
SET unique_checks=1;
