CREATE TABLE Answer (
    answer_id VARCHAR(32) NOT NULL Primary Key,
    problem_id TEXT,
    answer TEXT
    );
CREATE TABLE CorrectMap (
    correct_map_id VARCHAR(32) NOT NULL Primary Key,
    answer_id TEXT,
    correctness BOOL,
    npoints INT,
    msg TEXT,
    hint TEXT,
    hintmode TINYTEXT,
    queuestate TEXT
    );
CREATE TABLE InputState (
    input_state_id VARCHAR(32) NOT NULL Primary Key,
    problem_id TEXT,
    state TEXT
    );
CREATE TABLE State (
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
CREATE TABLE Main (
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
INSERT INTO Main (eventID,agent,event_source,event_type,ip,page,session,time,username,downtime_for) VALUES 
    ('aebf6f3b-f5b2-4cbd-a5ab-677407aa1832','ELB-HealthChecker/1.0','server','/heartbeat','127.0.0.1',None,None,'2013-07-18T08:43:32.573390+00:00','','0:00:00'),
    ('cd0355d6-0cd8-4d9e-bdc1-387e76488122','ELB-HealthChecker/1.0','server','/heartbeat','127.0.0.1',None,None,'2013-07-18T09:45:37.573390+00:00','','1:02:05');
