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
    ('758d4846_eeea_4731_bc61_446bdabb1db5','input_i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1','13.5'),
    ('b08e292e_78e6_4879_86ce_b1cd46d14a42','input_i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1','1.59+breaths+per+minute'),
    ('8a3b4eef_bfda_434a_afa2_cbc02465a578','input_i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1','13.4+breaths+per+minute'),
    ('438cc96d_c8c8_4e14_9338_b34d4e9d1800','input_i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1','');
INSERT INTO Event (eventID,agent,event_source,event_type,ip,page,session,time,username,downtime_for,studentID,instructorID,courseID,seqID,gotoFrom,gotoDest,problemID,problemChoice,questionLocation,attempts,longAnswer,studentFile,canUploadFile,feedback,feedbackResponseSelected,transcriptID,transcriptCode,rubricSelection,rubricCategory,videoID,videoCode,videoCurrentTime,videoSpeed,videoOldTime,videoNewTime,videoSeekType,bookInteractionType,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,correctMapFK,answerFK) VALUES 
    ('652bd5da_8620_46ee_8e14_90c80254333c','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML\, like Gecko) Chrome/27.0.1453.110 Safari/537.36','browser','problem_save','149.171.125.90','https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/ac6d006c4bc84fc1a9cec412734fd5ca/bd89d1a5da594e908b98aca72ef1e83e/','a7e396b28a361e7b5637c59864013f5b','2013-06-12T08:30:53.458627','Dawson','0:00:00',null,null,null,null,null,null,'input_i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_18_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'438cc96d_c8c8_4e14_9338_b34d4e9d1800');
COMMIT;
