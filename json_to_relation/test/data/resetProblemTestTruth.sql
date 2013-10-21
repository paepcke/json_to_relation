USE test;
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
    ('82609c1b_7b5c_4883_9aa0_f50b5f381375','i4x-HMC-MyCS-problem-d457165577d34e5aac6fbb55c8b7ad33_2_1','choice_2');
INSERT INTO CorrectMap (correct_map_id,answer_id,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('173f48b3_c639_4315_826a_e0e7a7556b01','i4x-HMC-MyCS-problem-d457165577d34e5aac6fbb55c8b7ad33_2_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('d1b74251_9f45_4200_96b8_398f5b44ac85','i4x-HMC-MyCS-problem-d457165577d34e5aac6fbb55c8b7ad33_2_1',{});
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('9897acd4_f71d_4882_b4fc_dbe5eb78c0e3',811,True,null,'82609c1b_7b5c_4883_9aa0_f50b5f381375','173f48b3_c639_4315_826a_e0e7a7556b01','d1b74251_9f45_4200_96b8_398f5b44ac85');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('bd40f758_0fef_457c_ad2f_248a849e4f05','i4x-HMC-MyCS-problem-d457165577d34e5aac6fbb55c8b7ad33_2_1',{});
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('6dcc7abc_5f99_4c13_baac_3beb736df443',93,False,null,null,null,'bd40f758_0fef_457c_ad2f_248a849e4f05');
INSERT INTO Event (eventID,agent,event_source,event_type,ip,page,session,time,username,downtime_for,studentID,instructorID,courseID,seqID,gotoFrom,gotoDest,problemID,problemChoice,questionLocation,attempts,feedback,feedbackResponseSelected,rubricSelection,rubricCategory,videoID,videoCode,videoCurrentTime,videoSpeed,bookInteractionType,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,correctMapFK,answerFK,stateFK) VALUES 
    ('20ff211c_c263_4e01_a913_ee0261448660','Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','reset_problem','24.43.226.3','x_module',null,'2013-06-12T21:54:33.936342','gloria','0:00:00',null,null,null,null,null,null,'i4x://HMC/MyCS/problem/d457165577d34e5aac6fbb55c8b7ad33',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'9897acd4_f71d_4882_b4fc_dbe5eb78c0e3'),
    ('20ff211c_c263_4e01_a913_ee0261448660','Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','reset_problem','24.43.226.3','x_module',null,'2013-06-12T21:54:33.936342','gloria','0:00:00',null,null,null,null,null,null,'i4x://HMC/MyCS/problem/d457165577d34e5aac6fbb55c8b7ad33',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'6dcc7abc_5f99_4c13_baac_3beb736df443'),
    ('20ff211c_c263_4e01_a913_ee0261448660','Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','reset_problem','24.43.226.3','x_module',null,'2013-06-12T21:54:33.936342','gloria','0:00:00',null,null,null,null,null,null,'i4x://HMC/MyCS/problem/d457165577d34e5aac6fbb55c8b7ad33',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'6dcc7abc_5f99_4c13_baac_3beb736df443');
COMMIT;
