CREATE DATABASE IF NOT EXISTS Edx;
CREATE DATABASE IF NOT EXISTS EdxPrivate;
USE test;
SET foreign_key_checks = 0;
DROP TABLE IF EXISTS EdxTrackEvent, Answer, InputState, CorrectMap, State, EdxPrivate.Account, LoadInfo;
SET foreign_key_checks = 1;
CREATE TABLE IF NOT EXISTS Answer (
    answer_id VARCHAR(40) NOT NULL PRIMARY KEY,
    problem_id TEXT NOT NULL,
    answer TEXT NOT NULL,
    course_id TEXT NOT NULL
    );
CREATE TABLE IF NOT EXISTS CorrectMap (
    correct_map_id VARCHAR(40) NOT NULL PRIMARY KEY,
    answer_identifier TEXT NOT NULL,
    correctness TINYTEXT NOT NULL,
    npoints INT NOT NULL,
    msg TEXT NOT NULL,
    hint TEXT NOT NULL,
    hintmode TINYTEXT NOT NULL,
    queuestate TEXT NOT NULL
    );
CREATE TABLE IF NOT EXISTS InputState (
    input_state_id VARCHAR(40) NOT NULL PRIMARY KEY,
    problem_id TEXT NOT NULL,
    state TEXT NOT NULL
    );
CREATE TABLE IF NOT EXISTS State (
    state_id VARCHAR(40) NOT NULL PRIMARY KEY,
    seed TINYINT NOT NULL,
    done TINYTEXT NOT NULL,
    problem_id TEXT NOT NULL,
    student_answer VARCHAR(40) NOT NULL,
    correct_map VARCHAR(40) NOT NULL,
    input_state VARCHAR(40) NOT NULL,
    FOREIGN KEY(student_answer) REFERENCES Answer(answer_id) ON DELETE CASCADE,
    FOREIGN KEY(correct_map) REFERENCES CorrectMap(correct_map_id) ON DELETE CASCADE,
    FOREIGN KEY(input_state) REFERENCES InputState(input_state_id) ON DELETE CASCADE
    );
CREATE TABLE IF NOT EXISTS EdxPrivate.Account (
    account_id VARCHAR(40) NOT NULL PRIMARY KEY,
    screen_name TEXT NOT NULL,
    name TEXT NOT NULL,
    anon_screen_name TEXT NOT NULL,
    mailing_address TEXT NOT NULL,
    zipcode TINYTEXT NOT NULL,
    country TINYTEXT NOT NULL,
    gender TINYTEXT NOT NULL,
    year_of_birth TINYINT NOT NULL,
    level_of_education TINYTEXT NOT NULL,
    goals TEXT NOT NULL,
    honor_code TINYINT NOT NULL,
    terms_of_service TINYINT NOT NULL,
    course_id TEXT NOT NULL,
    enrollment_action TINYTEXT NOT NULL,
    email TEXT NOT NULL,
    receive_emails TINYTEXT NOT NULL
    );
CREATE TABLE IF NOT EXISTS LoadInfo (
    load_info_id INT NOT NULL PRIMARY KEY,
    load_date_time DATETIME NOT NULL,
    load_file TEXT NOT NULL
    );
CREATE TABLE IF NOT EXISTS EdxTrackEvent (
    _id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    event_id VARCHAR(40) NOT NULL,
    agent TEXT NOT NULL,
    event_source TINYTEXT NOT NULL,
    event_type TEXT NOT NULL,
    ip TINYTEXT NOT NULL,
    page TEXT NOT NULL,
    session TEXT NOT NULL,
    time DATETIME NOT NULL,
    anon_screen_name TEXT NOT NULL,
    downtime_for DATETIME NOT NULL,
    student_id TEXT NOT NULL,
    instructor_id TEXT NOT NULL,
    course_id TEXT NOT NULL,
    sequence_id TEXT NOT NULL,
    goto_from INT NOT NULL,
    goto_dest INT NOT NULL,
    problem_id TEXT NOT NULL,
    problem_choice TEXT NOT NULL,
    question_location TEXT NOT NULL,
    submission_id TEXT NOT NULL,
    attempts INT NOT NULL,
    long_answer TEXT NOT NULL,
    student_file TEXT NOT NULL,
    can_upload_file TINYTEXT NOT NULL,
    feedback TEXT NOT NULL,
    feedback_response_selected TINYINT NOT NULL,
    transcript_id TEXT NOT NULL,
    transcript_code TINYTEXT NOT NULL,
    rubric_selection INT NOT NULL,
    rubric_category INT NOT NULL,
    video_id TEXT NOT NULL,
    video_code TEXT NOT NULL,
    video_current_time TINYTEXT NOT NULL,
    video_speed TINYTEXT NOT NULL,
    video_old_time TINYTEXT NOT NULL,
    video_new_time TINYTEXT NOT NULL,
    video_seek_type TINYTEXT NOT NULL,
    video_new_speed TINYTEXT NOT NULL,
    video_old_speed TINYTEXT NOT NULL,
    book_interaction_type TINYTEXT NOT NULL,
    success TINYTEXT NOT NULL,
    answer_id TEXT NOT NULL,
    hint TEXT NOT NULL,
    hintmode TINYTEXT NOT NULL,
    correctness TINYTEXT NOT NULL,
    msg TEXT NOT NULL,
    npoints TINYINT NOT NULL,
    queuestate TEXT NOT NULL,
    orig_score INT NOT NULL,
    new_score INT NOT NULL,
    orig_total INT NOT NULL,
    new_total INT NOT NULL,
    event_name TINYTEXT NOT NULL,
    group_user TINYTEXT NOT NULL,
    group_action TINYTEXT NOT NULL,
    position INT NOT NULL,
    badly_formatted TEXT NOT NULL,
    correctMap_fk VARCHAR(40) NOT NULL,
    answer_fk VARCHAR(40) NOT NULL,
    state_fk VARCHAR(40) NOT NULL,
    load_info_fk INT NOT NULL,
    FOREIGN KEY(correctMap_fk) REFERENCES CorrectMap(correct_map_id) ON DELETE CASCADE,
    FOREIGN KEY(answer_fk) REFERENCES Answer(answer_id) ON DELETE CASCADE,
    FOREIGN KEY(state_fk) REFERENCES State(state_id) ON DELETE CASCADE,
    FOREIGN KEY(load_info_fk) REFERENCES LoadInfo(load_info_id) ON DELETE CASCADE
    );
SET foreign_key_checks=0;
SET unique_checks=0;
SET autocommit=0;
INSERT INTO LoadInfo (load_info_id,load_date_time,load_file) VALUES 
    ('49b0074e_4291_401f_b998_b51e3e0ef9d6','2013110806081383919693','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/problem_checkEventFldOnly.json');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('0d539af2_2294_4923_bdc3_acd699c75efd','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','correct',-1,'','','',''),
    ('1f37fe8f_a6e7_4005_a0dc_e13b7544a9a7','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','correct',-1,'','','','');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('ce2d9b55_31da_458c_a099_06e0b0b7a474','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','choice_0','my_course'),
    ('512c46c3_2c1f_4108_9d69_63826de4bcc1','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','choice_3','my_course'),
    ('5c31a4aa_5889_4c6f_a001_a80657b72b34','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','choice_3','my_course'),
    ('a13f1809_b894_4c7b_9f58_b83b044f3cf3','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','choice_1','my_course');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('c934b89f_1c75_4117_aaf8_a35c27e6927d','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','incorrect',-1,'','','',''),
    ('346cd7b2_85fc_46c5_8970_d18b91b437f9','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','incorrect',-1,'','','','');
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('6e1d2b01_83b7_4720_b34b_b141691861dd','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1',''),
    ('08e54c4d_90dd_48d3_9ed7_36d7cbabd3b6','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','');
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('f63c5465_56fe_4e07_b301_9c06dc80f091',1,'True','','5c31a4aa_5889_4c6f_a001_a80657b72b34','c934b89f_1c75_4117_aaf8_a35c27e6927d','6e1d2b01_83b7_4720_b34b_b141691861dd'),
    ('a7e022a9_1322_4f21_bfe0_946edef894e1',1,'True','','a13f1809_b894_4c7b_9f58_b83b044f3cf3','346cd7b2_85fc_46c5_8970_d18b91b437f9','08e54c4d_90dd_48d3_9ed7_36d7cbabd3b6');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,anon_screen_name,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk) VALUES 
    (0,'','','','','','','','00000000000000','','00000000000000','','','','',-1,-1,'i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','','','',2,'','','','',-1,'','',-1,-1,'','','','','','','','','','','correct','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','0d539af2_2294_4923_bdc3_acd699c75efd','ce2d9b55_31da_458c_a099_06e0b0b7a474','f63c5465_56fe_4e07_b301_9c06dc80f091'),
    (0,'','','','','','','','00000000000000','','00000000000000','','','','',-1,-1,'i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','','','',2,'','','','',-1,'','',-1,-1,'','','','','','','','','','','correct','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','1f37fe8f_a6e7_4005_a0dc_e13b7544a9a7','512c46c3_2c1f_4108_9d69_63826de4bcc1','a7e022a9_1322_4f21_bfe0_946edef894e1');
