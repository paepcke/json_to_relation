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
    answer_id TEXT,
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
    correctMapFK VARCHAR(40),
    answerFK VARCHAR(40),
    stateFK VARCHAR(40),
    accountFK VARCHAR(40),
    FOREIGN KEY(correctMapFK) REFERENCES CorrectMap(correct_map_id),
    FOREIGN KEY(answerFK) REFERENCES Answer(answer_id),
    FOREIGN KEY(stateFK) REFERENCES State(state_id),
    FOREIGN KEY(accountFK) REFERENCES Account(account_id)
    );
START TRANSACTION;
INSERT INTO Answer (answer_id,problem_id,answer) VALUES 
    ('3632b588_818b_4a22_8d4e_87015f352fb1','i4x-HMC-MyCS-problem-d457165577d34e5aac6fbb55c8b7ad33_2_1','choice_2');
INSERT INTO CorrectMap (correct_map_id,answer_id,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('682f3fc9_b839_40af_84d1_587615bbbf7d','i4x-HMC-MyCS-problem-d457165577d34e5aac6fbb55c8b7ad33_2_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('d4b5c32e_20d5_4849_8882_48f80da5fcce','i4x-HMC-MyCS-problem-d457165577d34e5aac6fbb55c8b7ad33_2_1',null);
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('8416cb4b_24ba_4a47_af16_7d9c2b485e15',811,True,null,'3632b588_818b_4a22_8d4e_87015f352fb1','682f3fc9_b839_40af_84d1_587615bbbf7d','d4b5c32e_20d5_4849_8882_48f80da5fcce');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('a548f11d_a837_47e5_ad17_e079625c24ab','i4x-HMC-MyCS-problem-d457165577d34e5aac6fbb55c8b7ad33_2_1',null);
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('a941f5d1_b855_49f5_be58_76743632b9cb',93,False,null,null,null,'a548f11d_a837_47e5_ad17_e079625c24ab');
INSERT INTO Event (eventID,agent,event_source,event_type,ip,page,session,time,username,downtime_for,studentID,instructorID,courseID,seqID,gotoFrom,gotoDest,problemID,problemChoice,questionLocation,submissionID,attempts,longAnswer,studentFile,canUploadFile,feedback,feedbackResponseSelected,transcriptID,transcriptCode,rubricSelection,rubricCategory,videoID,videoCode,videoCurrentTime,videoSpeed,videoOldTime,videoNewTime,videoSeekType,videoNewSpeed,videoOldSpeed,bookInteractionType,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badlyFormatted,correctMapFK,answerFK,stateFK) VALUES 
    ('edd7399d_52bb_40a0_b18a_065a70fb1fb3','Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','reset_problem','24.43.226.3','x_module',null,'2013-06-12T21:54:33.936342','gloria','0:00:00',null,null,null,null,null,null,'i4x://HMC/MyCS/problem/d457165577d34e5aac6fbb55c8b7ad33',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'8416cb4b_24ba_4a47_af16_7d9c2b485e15'),
    ('edd7399d_52bb_40a0_b18a_065a70fb1fb3','Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','reset_problem','24.43.226.3','x_module',null,'2013-06-12T21:54:33.936342','gloria','0:00:00',null,null,null,null,null,null,'i4x://HMC/MyCS/problem/d457165577d34e5aac6fbb55c8b7ad33',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'a941f5d1_b855_49f5_be58_76743632b9cb'),
    ('edd7399d_52bb_40a0_b18a_065a70fb1fb3','Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','reset_problem','24.43.226.3','x_module',null,'2013-06-12T21:54:33.936342','gloria','0:00:00',null,null,null,null,null,null,'i4x://HMC/MyCS/problem/d457165577d34e5aac6fbb55c8b7ad33',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'a941f5d1_b855_49f5_be58_76743632b9cb');
COMMIT;
