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
    FOREIGN KEY(correctMapFK) REFERENCES CorrectMap(correct_map_id),
    FOREIGN KEY(answerFK) REFERENCES Answer(answer_id),
    FOREIGN KEY(stateFK) REFERENCES State(state_id)
    );
START TRANSACTION;
INSERT INTO CorrectMap (correct_map_id,answer_id,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    (83552ed0-8bdb-4fdd-9f4e-9bf162a630d8,'i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','correct',null,'','',null,null),
    (bf033fef-b220-4f69-8d56-27cfcf4e82f9,'i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','correct',null,'','',null,null);
INSERT INTO Answer (answer_id,problem_id,answer) VALUES 
    (8c1e79df-a863-4371-98ce-fc9b5b0b478a,'i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','choice_0'),
    (e3dfc629-4562-4260-b001-789132b2c6b6,'i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','choice_3'),
    (70725a11-403f-400a-b63e-84c6d132aa8e,'i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','choice_3'),
    (5be1502d-0f53-4cee-8676-a74539569e02,'i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','choice_1');
INSERT INTO CorrectMap (correct_map_id,answer_id,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    (e4c46632-137c-470f-8009-fb91619d5a0d,'i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','incorrect',null,'','',null,null),
    (ace84468-a40a-4504-ab67-f84c2c1fa631,'i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    (1adee9ea-4be0-419b-a2ce-7f570b66cd04,'i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1',{}),
    (2a077c63-1e13-442a-b1cb-225e98acde92,'i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1',{});
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    (6ee97dbe-8447-4420-bc1b-eff461f9d327,1,True,null,70725a11-403f-400a-b63e-84c6d132aa8e,e4c46632-137c-470f-8009-fb91619d5a0d,1adee9ea-4be0-419b-a2ce-7f570b66cd04),
    (6ee97dbe-8447-4420-bc1b-eff461f9d327,1,True,null,5be1502d-0f53-4cee-8676-a74539569e02,ace84468-a40a-4504-ab67-f84c2c1fa631,2a077c63-1e13-442a-b1cb-225e98acde92);
INSERT INTO Event (eventID,agent,event_source,event_type,ip,page,session,time,username,downtime_for,studentID,instructorID,courseID,seqID,gotoFrom,gotoDest,problemID,problemChoice,questionLocation,attempts,feedback,feedbackResponseSelected,rubricSelection,rubricCategory,videoID,videoCode,videoCurrentTime,videoSpeed,bookInteractionType,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,correctMapFK,answerFK,stateFK) VALUES 
    (null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,2,null,null,null,null,null,null,null,null,null,'correct',null,null,null,null,null,null,null,83552ed0-8bdb-4fdd-9f4e-9bf162a630d8,8c1e79df-a863-4371-98ce-fc9b5b0b478a,6ee97dbe-8447-4420-bc1b-eff461f9d327),
    (null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,2,null,null,null,null,null,null,null,null,null,'correct',null,null,null,null,null,null,null,bf033fef-b220-4f69-8d56-27cfcf4e82f9,e3dfc629-4562-4260-b001-789132b2c6b6,null);
