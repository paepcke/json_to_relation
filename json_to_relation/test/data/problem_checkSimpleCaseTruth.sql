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
INSERT INTO Answer (answer_id,problem_id,answer) VALUES 
    ('692235bf_b9a1_4d59_82d0_77eda63f22d5','input_i4x-Medicine-HRP258-problem-7451f8fe15a642e1820767db411a4a3e_2_1','choice_2'),
    ('0f2282d0_fd66_40cf_809c_92446bb9669f','input_i4x-Medicine-HRP258-problem-7451f8fe15a642e1820767db411a4a3e_3_1','choice_2');
INSERT INTO Event (eventID,agent,event_source,event_type,ip,page,session,time,username,downtime_for,studentID,instructorID,courseID,seqID,gotoFrom,gotoDest,problemID,problemChoice,questionLocation,attempts,feedback,feedbackResponseSelected,rubricSelection,rubricCategory,videoID,videoCode,videoCurrentTime,videoSpeed,bookInteractionType,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,correctMapFK,answerFK,stateFK) VALUES 
    ('1019d032_2a75_4c50_a140_59c2981e6644','Mozilla/5.0 (Windows NT 6.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.95 Safari/537.36','browser','problem_check','66.172.116.216','https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/de472d1448a74e639a41fa584c49b91e/ed52812e4f96445383bfc556d15cb902/','75a8c9042ba10156301728f61e487414','2013-08-04T06:27:13.660689+00:00','trobinspire','0:00:00',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'692235bf_b9a1_4d59_82d0_77eda63f22d5'),
    ('1019d032_2a75_4c50_a140_59c2981e6644','Mozilla/5.0 (Windows NT 6.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.95 Safari/537.36','browser','problem_check','66.172.116.216','https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/de472d1448a74e639a41fa584c49b91e/ed52812e4f96445383bfc556d15cb902/','75a8c9042ba10156301728f61e487414','2013-08-04T06:27:13.660689+00:00','trobinspire','0:00:00',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'0f2282d0_fd66_40cf_809c_92446bb9669f');
COMMIT;
