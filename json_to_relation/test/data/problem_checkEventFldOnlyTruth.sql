USE test;
SET foreign_key_checks = 0;
DROP TABLE IF EXISTS EdxTrackEvent, Answer, InputState, CorrectMap, State, Account, LoadInfo;
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
    done TINYINT NOT NULL,
    problem_id TEXT NOT NULL,
    student_answer VARCHAR(40) NOT NULL,
    correct_map VARCHAR(40) NOT NULL,
    input_state VARCHAR(40) NOT NULL,
    FOREIGN KEY(student_answer) REFERENCES Answer(answer_id),
    FOREIGN KEY(correct_map) REFERENCES CorrectMap(correct_map_id),
    FOREIGN KEY(input_state) REFERENCES InputState(input_state_id)
    );
CREATE TABLE IF NOT EXISTS Account (
    account_id VARCHAR(40) NOT NULL PRIMARY KEY,
    username TEXT NOT NULL,
    name TEXT NOT NULL,
    mailing_address TEXT NOT NULL,
    zipcode TINYTEXT NOT NULL,
    country TINYTEXT NOT NULL,
    gender TINYTEXT NOT NULL,
    year_of_birth TINYINT NOT NULL,
    level_of_education TINYTEXT NOT NULL,
    goals TEXT NOT NULL,
    honor_code BOOL NOT NULL,
    terms_of_service BOOL NOT NULL,
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
    username TEXT NOT NULL,
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
    attempts TINYINT NOT NULL,
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
    account_fk VARCHAR(40) NOT NULL,
    load_info_fk INT NOT NULL,
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
    ('770a8c17_94f0_4459_94d8_09469cad9657','2013110706481383835703','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/problem_checkEventFldOnly.json');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('04ca04f7_53a2_42b4_89bc_a111a2246a2b','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','correct',null,'','',null,null),
    ('b218619a_ab61_4f40_b089_2c2350ad6a74','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','correct',null,'','',null,null);
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('7d9473d9_2e4b_4d64_aa26_5fc7f44f5481','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','choice_0','my_course'),
    ('2bd979e0_aa4c_4602_a23e_27375c3ecfff','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','choice_3','my_course'),
    ('d772a18b_bd02_4919_b495_c03d0a1f56bf','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','choice_3','my_course'),
    ('59bb7fda_8044_47c4_a046_e9a307ecf79c','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','choice_1','my_course');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('da50b511_b1fd_4efa_8f47_037972fd0482','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','incorrect',null,'','',null,null),
    ('7380c2fd_5fd3_41c0_9ea6_c80ec2106e74','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('fd014c7d_a59b_406a_99c8_58356f38a336','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1',null),
    ('6358d0cb_343b_449b_a4cd_ddd3e17b5491','i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1',null);
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('ffe412b8_0021_42aa_acf3_91a3a3836a7c',1,True,null,'d772a18b_bd02_4919_b495_c03d0a1f56bf','da50b511_b1fd_4efa_8f47_037972fd0482','fd014c7d_a59b_406a_99c8_58356f38a336'),
    ('e26cbb34_a2c2_4fad_a3af_984a3fcd3e8b',1,True,null,'59bb7fda_8044_47c4_a046_e9a307ecf79c','7380c2fd_5fd3_41c0_9ea6_c80ec2106e74','6358d0cb_343b_449b_a4cd_ddd3e17b5491');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,username,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk) VALUES 
    (0,'','','','','','','','00000000000000','','00000000000000','','','','',-1,-1,'i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1','','','',2,'','','','',-1,'','',-1,-1,'','','','','','','','','','','correct','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','04ca04f7_53a2_42b4_89bc_a111a2246a2b','7d9473d9_2e4b_4d64_aa26_5fc7f44f5481','ffe412b8_0021_42aa_acf3_91a3a3836a7c'),
    (0,'','','','','','','','00000000000000','','00000000000000','','','','',-1,-1,'i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1','','','',2,'','','','',-1,'','',-1,-1,'','','','','','','','','','','correct','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','b218619a_ab61_4f40_b089_2c2350ad6a74','2bd979e0_aa4c_4602_a23e_27375c3ecfff','e26cbb34_a2c2_4fad_a3af_984a3fcd3e8b');
