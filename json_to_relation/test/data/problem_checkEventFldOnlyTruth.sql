USE test;
SET foreign_key_checks = 0;
DROP TABLE IF EXISTS EdxTrackEvent, Answer, InputState, CorrectMap, State, Account;
SET foreign_key_checks = 1;
CREATE TABLE IF NOT EXISTS Answer (
    answer_id VARCHAR(32) NOT NULL Primary Key,
    problem_id TEXT,
    answer TEXT
    );
CREATE TABLE IF NOT EXISTS CorrectMap (
    correct_map_id VARCHAR(32) NOT NULL Primary Key,
    answer_id TEXT,
    correctness BOOL,
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
CREATE TABLE IF NOT EXISTS EdxTrackEvent (
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
    orig_score INT,
    new_score INT,
    orig_total INT,
    new_total INT,
    event_name TINYTEXT,
    group_user TINYTEXT,
    group_action TINYTEXT,
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
INSERT INTO CorrectMap (correct_map_id,answer_id,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('83552ed0_8bdb_4fdd_9f4e_9bf162a630d8','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','correct',null,'','',null,null),
    ('bf033fef_b220_4f69_8d56_27cfcf4e82f9','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','correct',null,'','',null,null);
INSERT INTO Answer (answer_id,problem_id,answer) VALUES 
    ('8c1e79df_a863_4371_98ce_fc9b5b0b478a','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','choice_0'),
    ('e3dfc629_4562_4260_b001_789132b2c6b6','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','choice_3'),
    ('70725a11_403f_400a_b63e_84c6d132aa8e','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','choice_3'),
    ('5be1502d_0f53_4cee_8676_a74539569e02','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','choice_1');
INSERT INTO CorrectMap (correct_map_id,answer_id,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('e4c46632_137c_470f_8009_fb91619d5a0d','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','incorrect',null,'','',null,null),
    ('ace84468_a40a_4504_ab67_f84c2c1fa631','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('1adee9ea_4be0_419b_a2ce_7f570b66cd04','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1',{}),
    ('2a077c63_1e13_442a_b1cb_225e98acde92','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1',{});
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('6ee97dbe_8447_4420_bc1b_eff461f9d327',1,True,null,'70725a11_403f_400a_b63e_84c6d132aa8e','e4c46632_137c_470f_8009_fb91619d5a0d','1adee9ea_4be0_419b_a2ce_7f570b66cd04'),
    ('6ee97dbe_8447_4420_bc1b_eff461f9d327',1,True,null,'5be1502d_0f53_4cee_8676_a74539569e02','ace84468_a40a_4504_ab67_f84c2c1fa631','2a077c63_1e13_442a_b1cb_225e98acde92');
INSERT INTO Event (eventID,agent,event_source,event_type,ip,page,session,time,username,downtime_for,studentID,instructorID,courseID,seqID,gotoFrom,gotoDest,problemID,problemChoice,questionLocation,attempts,feedback,feedbackResponseSelected,rubricSelection,rubricCategory,videoID,videoCode,videoCurrentTime,videoSpeed,bookInteractionType,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,correctMapFK,answerFK,stateFK,orig_score,new_score,orig_total,new_total) VALUES 
    (null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,2,null,null,null,null,null,null,null,null,null,'correct',null,null,null,null,null,null,null,'83552ed0_8bdb_4fdd_9f4e_9bf162a630d8','8c1e79df_a863_4371_98ce_fc9b5b0b478a','6ee97dbe_8447_4420_bc1b_eff461f9d327'),
    (null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,2,null,null,null,null,null,null,null,null,null,'correct',null,null,null,null,null,null,null,'bf033fef_b220_4f69_8d56_27cfcf4e82f9','e3dfc629_4562_4260_b001_789132b2c6b6',null);
