USE test;
SET foreign_key_checks = 0;
DROP TABLE IF EXISTS EdxTrackEvent, Answer, InputState, CorrectMap, State, Account, LoadInfo;
SET foreign_key_checks = 1;
CREATE TABLE IF NOT EXISTS Answer (
    answer_id VARCHAR(40) NOT NULL PRIMARY KEY,
    problem_id TEXT,
    answer TEXT,
    course_id TEXT
    );
CREATE TABLE IF NOT EXISTS CorrectMap (
    correct_map_id VARCHAR(40) NOT NULL PRIMARY KEY,
    answer_identifier TEXT,
    correctness TINYTEXT,
    npoints INT,
    msg TEXT,
    hint TEXT,
    hintmode TINYTEXT,
    queuestate TEXT
    );
CREATE TABLE IF NOT EXISTS InputState (
    input_state_id VARCHAR(40) NOT NULL PRIMARY KEY,
    problem_id TEXT,
    state TEXT
    );
CREATE TABLE IF NOT EXISTS State (
    state_id VARCHAR(40) NOT NULL PRIMARY KEY,
    seed TINYINT,
    done TINYINT,
    problem_id TEXT,
    student_answer VARCHAR(40),
    correct_map VARCHAR(40),
    input_state VARCHAR(40),
    FOREIGN KEY(student_answer) REFERENCES Answer(answer_id),
    FOREIGN KEY(correct_map) REFERENCES CorrectMap(correct_map_id),
    FOREIGN KEY(input_state) REFERENCES InputState(input_state_id)
    );
CREATE TABLE IF NOT EXISTS Account (
    account_id VARCHAR(40) NOT NULL PRIMARY KEY,
    username TEXT,
    name TEXT,
    mailing_address TEXT,
    zipcode TINYTEXT,
    country TINYTEXT,
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
CREATE TABLE IF NOT EXISTS LoadInfo (
    load_info_id INT NOT NULL PRIMARY KEY,
    load_date_time DATETIME,
    load_file TEXT
    );
CREATE TABLE IF NOT EXISTS EdxTrackEvent (
    _id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    event_id VARCHAR(40),
    agent TEXT,
    event_source TINYTEXT,
    event_type TEXT,
    ip TINYTEXT,
    page TEXT,
    session TEXT,
    time DATETIME,
    username TEXT,
    downtime_for DATETIME,
    student_id TEXT,
    instructor_id TEXT,
    course_id TEXT,
    sequence_id TEXT,
    goto_from INT,
    goto_dest INT,
    problem_id TEXT,
    problem_choice TEXT,
    question_location TEXT,
    submission_id TEXT,
    attempts TINYINT,
    long_answer TEXT,
    student_file TEXT,
    can_upload_file TINYTEXT,
    feedback TEXT,
    feedback_response_selected TINYINT,
    transcript_id TEXT,
    transcript_code TINYTEXT,
    rubric_selection INT,
    rubric_category INT,
    video_id TEXT,
    video_code TEXT,
    video_current_time TINYTEXT,
    video_speed TINYTEXT,
    video_old_time TINYTEXT,
    video_new_time TINYTEXT,
    video_seek_type TINYTEXT,
    video_new_speed TINYTEXT,
    video_old_speed TINYTEXT,
    book_interaction_type TINYTEXT,
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
    badly_formatted TEXT,
    correctMap_fk VARCHAR(40),
    answer_fk VARCHAR(40),
    state_fk VARCHAR(40),
    account_fk VARCHAR(40),
    load_info_fk INT,
    FOREIGN KEY(correctMap_fk) REFERENCES CorrectMap(correct_map_id),
    FOREIGN KEY(answer_fk) REFERENCES Answer(answer_id),
    FOREIGN KEY(state_fk) REFERENCES State(state_id),
    FOREIGN KEY(account_fk) REFERENCES Account(account_id),
    FOREIGN KEY(load_info_fk) REFERENCES LoadInfo(load_info_id)
    );
SET foreign_key_checks=0;
SET unique_checks=0;
SET autocommit=0;
INSERT INTO LoadInfo (load_info_id,load_date_time,load_file) VALUES 
    ('59e5d4b5_604b_431d_8546_ad1dc8523cca','2013110705101383829838','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/resetProblemTest.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('d3999322_60f5_4cc7_9e53_e8964288f778','i4x-HMC-MyCS-problem-d457165577d34e5aac6fbb55c8b7ad33_2_1','choice_2',null);
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('170ecdc7_035f_4ba0_b93e_3a9ae07a02b3','i4x-HMC-MyCS-problem-d457165577d34e5aac6fbb55c8b7ad33_2_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('b237aa20_72e0_43a9_b169_bc4fcd5e5a4f','i4x-HMC-MyCS-problem-d457165577d34e5aac6fbb55c8b7ad33_2_1',null);
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('cc23d329_c841_4f3b_befb_a541f8ea33b5',811,True,null,'d3999322_60f5_4cc7_9e53_e8964288f778','170ecdc7_035f_4ba0_b93e_3a9ae07a02b3','b237aa20_72e0_43a9_b169_bc4fcd5e5a4f');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('2229bef5_27ce_4fcd_970c_285c12a69a4f','i4x-HMC-MyCS-problem-d457165577d34e5aac6fbb55c8b7ad33_2_1',null);
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('7e65bbaa_ae2a_4314_b6c7_3389536d6acb',93,False,null,null,null,'2229bef5_27ce_4fcd_970c_285c12a69a4f');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,username,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,account_fk,load_info_fk) VALUES 
    (0,'5871e294_8c9a_4754_81f6_a55a6e136d83','Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','reset_problem','24.43.226.3','x_module','','2013-06-12T21:54:33.936342','gloria','0:00:00','','','','',-1,-1,'i4x://HMC/MyCS/problem/d457165577d34e5aac6fbb55c8b7ad33','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','','cc23d329_c841_4f3b_befb_a541f8ea33b5','','59e5d4b5_604b_431d_8546_ad1dc8523cca'),
    (0,'5871e294_8c9a_4754_81f6_a55a6e136d83','Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','reset_problem','24.43.226.3','x_module','','2013-06-12T21:54:33.936342','gloria','0:00:00','','','','',-1,-1,'i4x://HMC/MyCS/problem/d457165577d34e5aac6fbb55c8b7ad33','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','','7e65bbaa_ae2a_4314_b6c7_3389536d6acb','','59e5d4b5_604b_431d_8546_ad1dc8523cca'),
    (0,'5871e294_8c9a_4754_81f6_a55a6e136d83','Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36','server','reset_problem','24.43.226.3','x_module','','2013-06-12T21:54:33.936342','gloria','0:00:00','','','','',-1,-1,'i4x://HMC/MyCS/problem/d457165577d34e5aac6fbb55c8b7ad33','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','','7e65bbaa_ae2a_4314_b6c7_3389536d6acb','','59e5d4b5_604b_431d_8546_ad1dc8523cca');
COMMIT;
SET foreign_key_checks=1;
SET unique_checks=1;
