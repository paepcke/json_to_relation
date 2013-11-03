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
    ('2c58b81f_3ecf_41ac_a915_f955dadc0021','input_i4x-Medicine-HRP258-problem-31fcf9829f3d461e92c1f14cbaee1743_2_1_choice_1','correct'),
    ('14619138_2c56_4541_b065_a332056ef7d2','input_i4x-Medicine-HRP258-problem-31fcf9829f3d461e92c1f14cbaee1743_3_1_choice_0','correct');
INSERT INTO Event (eventID,agent,event_source,event_type,ip,page,session,time,username,downtime_for,studentID,instructorID,courseID,seqID,gotoFrom,gotoDest,problemID,problemChoice,questionLocation,submissionID,attempts,longAnswer,studentFile,canUploadFile,feedback,feedbackResponseSelected,transcriptID,transcriptCode,rubricSelection,rubricCategory,videoID,videoCode,videoCurrentTime,videoSpeed,videoOldTime,videoNewTime,videoSeekType,videoNewSpeed,videoOldSpeed,bookInteractionType,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badlyFormatted,correctMapFK,answerFK) VALUES 
    ('1f745060_5ecd_4230_9f16_ff36a221658c','browser','browser','problem_graded','203.81.72.81',null,'adf0f47a40c885298669b7b96ae52f02','2013-08-16T13:38:49.951627+00:00','YiYi','0:00:00',null,null,null,null,null,null,'input_i4x-Medicine-HRP258-problem-31fcf9829f3d461e92c1f14cbaee1743_2_1_choice_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'2c58b81f_3ecf_41ac_a915_f955dadc0021'),
    ('1f745060_5ecd_4230_9f16_ff36a221658c','browser','browser','problem_graded','203.81.72.81',null,'adf0f47a40c885298669b7b96ae52f02','2013-08-16T13:38:49.951627+00:00','YiYi','0:00:00',null,null,null,null,null,null,'input_i4x-Medicine-HRP258-problem-31fcf9829f3d461e92c1f14cbaee1743_3_1_choice_0',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'14619138_2c56_4541_b065_a332056ef7d2');
COMMIT;
SET foreign_key_checks=1;
SET unique_checks=1;
