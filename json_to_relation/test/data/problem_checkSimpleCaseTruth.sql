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
    ('3f39c2eb_075f_42ec_927a_c1f4c6e2f1ab','2013110806081383919693','file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/problem_checkSimpleCase.json');
INSERT INTO Answer (answer_id,problem_id,answer,course_id) VALUES 
    ('4055cd71_fc1f_406d_bb96_6f0990a5e3d9','input_i4x-Medicine-HRP258-problem-7451f8fe15a642e1820767db411a4a3e_2_1','choice_2','Medicine/HRP258/Statistics_in_Medicine'),
    ('74570988_dec8_4ed7_9eb5_3c52bee1bf70','input_i4x-Medicine-HRP258-problem-7451f8fe15a642e1820767db411a4a3e_3_1','choice_2','Medicine/HRP258/Statistics_in_Medicine');
INSERT INTO EdxTrackEvent (_id,event_id,agent,event_source,event_type,ip,page,session,time,anon_screen_name,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk,load_info_fk) VALUES 
    (0,'104e5fed_a97d_4030_8985_f3dc00392622','Mozilla/5.0 (Windows NT 6.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.95 Safari/537.36','browser','problem_check','66.172.116.216','https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/de472d1448a74e639a41fa584c49b91e/ed52812e4f96445383bfc556d15cb902/','75a8c9042ba10156301728f61e487414','2013-08-04T06:27:13.660689+00:00','','0:00:00','','','Medicine/HRP258/Statistics_in_Medicine','',-1,-1,'input_i4x-Medicine-HRP258-problem-7451f8fe15a642e1820767db411a4a3e_2_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','4055cd71_fc1f_406d_bb96_6f0990a5e3d9','','3f39c2eb_075f_42ec_927a_c1f4c6e2f1ab'),
    (0,'104e5fed_a97d_4030_8985_f3dc00392622','Mozilla/5.0 (Windows NT 6.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.95 Safari/537.36','browser','problem_check','66.172.116.216','https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/de472d1448a74e639a41fa584c49b91e/ed52812e4f96445383bfc556d15cb902/','75a8c9042ba10156301728f61e487414','2013-08-04T06:27:13.660689+00:00','','0:00:00','','','Medicine/HRP258/Statistics_in_Medicine','',-1,-1,'input_i4x-Medicine-HRP258-problem-7451f8fe15a642e1820767db411a4a3e_3_1','','','',-1,'','','','',-1,'','',-1,-1,'','','','','','','','','','','','','','','','',-1,'',-1,-1,-1,-1,'','','',-1,'','','74570988_dec8_4ed7_9eb5_3c52bee1bf70','','3f39c2eb_075f_42ec_927a_c1f4c6e2f1ab');
COMMIT;
SET foreign_key_checks=1;
SET unique_checks=1;
