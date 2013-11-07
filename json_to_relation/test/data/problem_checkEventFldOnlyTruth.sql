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
    ('4e05d0e6_cdf7_44d3_beb1_86da792df2a0','2013110705101383829837','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/problem_checkEventFldOnly.json');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('94bdf9c8_0c7f_41d7_81c4_3590fdd05c14','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','correct',null,'','',null,null),
    ('de2a3bb8_4f46_4d28_bd87_ace74e6f828d','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','correct',null,'','',null,null);
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('07ced889_9b35_410f_b613_396fd5307a8b','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','choice_0','my_course'),
    ('0d25dcf6_fc10_4c8e_9db5_0fbf10156e80','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','choice_3','my_course'),
    ('677b2d76_5e12_4369_a1d0_d69affd17e20','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','choice_3','my_course'),
    ('610a087b_ea73_4830_8faf_341785c1e914','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','choice_1','my_course');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('b52d8baa_6f76_49aa_8ded_a1f186690a26','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','incorrect',null,'','',null,null),
    ('f9eb61c8_c3d9_4ff9_abb3_6a5ab4cba9c4','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('4c889388_9846_479c_96c0_424880d39db1','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1',null),
    ('5bb7540a_ab7d_477e_bf36_ac9a828c0516','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1',null);
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('4ac66b3b_eed2_4296_bb4d_b307cdfb040b',1,True,null,'677b2d76_5e12_4369_a1d0_d69affd17e20','b52d8baa_6f76_49aa_8ded_a1f186690a26','4c889388_9846_479c_96c0_424880d39db1'),
    ('bdcfe511_2d23_479f_ad9e_2f91cedc467f',1,True,null,'610a087b_ea73_4830_8faf_341785c1e914','f9eb61c8_c3d9_4ff9_abb3_6a5ab4cba9c4','5bb7540a_ab7d_477e_bf36_ac9a828c0516');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,username,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk) VALUES 
    (0,'','','','','','','','00000000000000','','00000000000000','','','','',-1,-1,'i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','','','',2,'','','','',-1,'','',-1,-1,'','','','','','','','','','','correct','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','94bdf9c8_0c7f_41d7_81c4_3590fdd05c14','07ced889_9b35_410f_b613_396fd5307a8b','4ac66b3b_eed2_4296_bb4d_b307cdfb040b'),
    (0,'','','','','','','','00000000000000','','00000000000000','','','','',-1,-1,'i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','','','',2,'','','','',-1,'','',-1,-1,'','','','','','','','','','','correct','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','de2a3bb8_4f46_4d28_bd87_ace74e6f828d','0d25dcf6_fc10_4c8e_9db5_0fbf10156e80','bdcfe511_2d23_479f_ad9e_2f91cedc467f');
