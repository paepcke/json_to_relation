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
    ('0a0fd6ed_aef4_42c8_9763_2eeb651381ab','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1'),
    ('203bf78c_5435_4161_ba5f_3748fb05b46c','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3'),
    ('94c26626_8955_4de5_9679_3407b782fc96','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1'),
    ('292037ca_d768_42ed_9267_a364c39d8ceb','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0'),
    ('8c625c24_cf1d_480d_a157_7dcf59938b80','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4'),
    ('c006ffcd_2316_4d01_865c_103580bf7848','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2'),
    ('b610b89c_59d9_4dd6_b4ba_53987c277cbb','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0'),
    ('44921d0a_202f_4c82_b295_51fccbc70ac6','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0'),
    ('f1a24b38_2ee7_4ffa_8c28_f9237de15054','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1'),
    ('e00f4e18_8547_489c_b3ef_b44d9deb6752','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3'),
    ('9d9dc755_c156_4171_b682_430fcf8f38ce','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1'),
    ('67a8a023_dcdf_4487_8f75_01893a5c5bbc','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0'),
    ('2111324b_9df7_4755_befe_952856b67abe','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4'),
    ('4024cecb_c71a_4de1_b0e5_9b889ec67a52','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2'),
    ('220c8755_558f_45a3_8ebe_891efd3bcd3a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0'),
    ('1e4a6b58_af5f_4f13_adb4_a255d0dfde6e','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('f8b27a2e_e088_4a25_8e73_4849bd357dc3','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','correct',null,'','',null,null),
    ('fde1aebd_0fc2_46b6_8e22_c2b5ba861815','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','correct',null,'','',null,null),
    ('081fa973_7c4c_446b_af72_89f626ea4b08','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','correct',null,'','',null,null),
    ('1742082a_d1ad_474b_86d7_d1ea7e2e67d3','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','correct',null,'','',null,null),
    ('11d888a8_35ad_4cbe_a591_1a1d9b266df8','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','incorrect',null,'','',null,null),
    ('8653f323_2e91_4bd1_be8b_384383102800','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','correct',null,'','',null,null),
    ('27c38954_c9e4_40ee_adf9_457970f10542','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','correct',null,'','',null,null),
    ('1d9968b8_3a46_4e82_800c_488817668c0b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('885e454b_a4c2_4958_9e9c_3953bd8a64f4','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',null),
    ('82bdd96f_588a_4c9e_8502_86c591ca02d8','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',null),
    ('f38a38aa_c68a_4f34_8eda_30599bc81b42','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',null),
    ('a299ffa1_bba6_4ecb_bdfd_481259a87fbc','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',null),
    ('cabfb8cd_3d20_4ad4_bb8b_797aea9f9763','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',null),
    ('c9e3a386_922c_45f4_852b_be691ddbf07d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',null),
    ('2bf7dffe_ad5a_4a61_a897_5f1719f0a678','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',null),
    ('94911b28_6056_473e_9b2c_d51a949e44e8','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null);
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('c58244c3_461e_487f_9a13_027d756d72e9',1,True,null,'f1a24b38_2ee7_4ffa_8c28_f9237de15054','f8b27a2e_e088_4a25_8e73_4849bd357dc3','885e454b_a4c2_4958_9e9c_3953bd8a64f4'),
    ('bd7c0016_5bb8_4466_8898_d27e081257a2',1,True,null,'e00f4e18_8547_489c_b3ef_b44d9deb6752','fde1aebd_0fc2_46b6_8e22_c2b5ba861815','82bdd96f_588a_4c9e_8502_86c591ca02d8'),
    ('57fa5957_0fca_49f5_874d_3ea33d212aab',1,True,null,'9d9dc755_c156_4171_b682_430fcf8f38ce','081fa973_7c4c_446b_af72_89f626ea4b08','f38a38aa_c68a_4f34_8eda_30599bc81b42'),
    ('acf5e200_ce1b_4f84_95c1_5c9dfc9d0d3f',1,True,null,'67a8a023_dcdf_4487_8f75_01893a5c5bbc','1742082a_d1ad_474b_86d7_d1ea7e2e67d3','a299ffa1_bba6_4ecb_bdfd_481259a87fbc'),
    ('ccbfe665_7fc4_4f8d_a6be_6296912e82bc',1,True,null,'2111324b_9df7_4755_befe_952856b67abe','11d888a8_35ad_4cbe_a591_1a1d9b266df8','cabfb8cd_3d20_4ad4_bb8b_797aea9f9763'),
    ('b22fe161_0bb6_416a_9b83_f4d7b7827913',1,True,null,'4024cecb_c71a_4de1_b0e5_9b889ec67a52','8653f323_2e91_4bd1_be8b_384383102800','c9e3a386_922c_45f4_852b_be691ddbf07d'),
    ('6dc1e532_7670_4d51_8bf5_cdf2eb01b132',1,True,null,'220c8755_558f_45a3_8ebe_891efd3bcd3a','27c38954_c9e4_40ee_adf9_457970f10542','2bf7dffe_ad5a_4a61_a897_5f1719f0a678'),
    ('2ea5d4e7_d6e6_4e1a_9e6a_a463e3001f65',1,True,null,'1e4a6b58_af5f_4f13_adb4_a255d0dfde6e','1d9968b8_3a46_4e82_800c_488817668c0b','94911b28_6056_473e_9b2c_d51a949e44e8');
INSERT INTO Event (eventID,agent,event_source,event_type,ip,page,session,time,username,downtime_for,studentID,instructorID,courseID,seqID,gotoFrom,gotoDest,problemID,problemChoice,questionLocation,submissionID,attempts,longAnswer,studentFile,canUploadFile,feedback,feedbackResponseSelected,transcriptID,transcriptCode,rubricSelection,rubricCategory,videoID,videoCode,videoCurrentTime,videoSpeed,videoOldTime,videoNewTime,videoSeekType,videoNewSpeed,videoOldSpeed,bookInteractionType,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badlyFormatted,correctMapFK,answerFK,stateFK) VALUES 
    ('44d9d080_1447_450f_b5f1_ff49b9ed0525','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'0a0fd6ed_aef4_42c8_9763_2eeb651381ab','c58244c3_461e_487f_9a13_027d756d72e9'),
    ('44d9d080_1447_450f_b5f1_ff49b9ed0525','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'203bf78c_5435_4161_ba5f_3748fb05b46c','bd7c0016_5bb8_4466_8898_d27e081257a2'),
    ('44d9d080_1447_450f_b5f1_ff49b9ed0525','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'94c26626_8955_4de5_9679_3407b782fc96','57fa5957_0fca_49f5_874d_3ea33d212aab'),
    ('44d9d080_1447_450f_b5f1_ff49b9ed0525','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'292037ca_d768_42ed_9267_a364c39d8ceb','acf5e200_ce1b_4f84_95c1_5c9dfc9d0d3f'),
    ('44d9d080_1447_450f_b5f1_ff49b9ed0525','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'8c625c24_cf1d_480d_a157_7dcf59938b80','ccbfe665_7fc4_4f8d_a6be_6296912e82bc'),
    ('44d9d080_1447_450f_b5f1_ff49b9ed0525','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'c006ffcd_2316_4d01_865c_103580bf7848','b22fe161_0bb6_416a_9b83_f4d7b7827913'),
    ('44d9d080_1447_450f_b5f1_ff49b9ed0525','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'b610b89c_59d9_4dd6_b4ba_53987c277cbb','6dc1e532_7670_4d51_8bf5_cdf2eb01b132'),
    ('44d9d080_1447_450f_b5f1_ff49b9ed0525','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'44921d0a_202f_4c82_b295_51fccbc70ac6','2ea5d4e7_d6e6_4e1a_9e6a_a463e3001f65'),
    ('44d9d080_1447_450f_b5f1_ff49b9ed0525','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'44921d0a_202f_4c82_b295_51fccbc70ac6','2ea5d4e7_d6e6_4e1a_9e6a_a463e3001f65');
COMMIT;
SET foreign_key_checks=1;
SET unique_checks=1;
