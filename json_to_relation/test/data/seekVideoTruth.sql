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
CREATE TABLE IF NOT EXISTS Event (
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
    FOREIGN KEY(correctMap_fk) REFERENCES CorrectMap(correct_map_id),
    FOREIGN KEY(answer_fk) REFERENCES Answer(answer_id),
    FOREIGN KEY(state_fk) REFERENCES State(state_id),
    FOREIGN KEY(account_fk) REFERENCES Account(account_id)
    );
SET foreign_key_checks=0;
SET unique_checks=0;
SET autocommit=0;
INSERT INTO Event (event_id,agent,event_source,event_type,ip,page,session,time,username,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type) VALUES 
    ('689b60c5_a4fb_4f8d_af80_25f818e1ef0f','Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.94 Safari/537.36','browser','seek_video','184.90.151.219','https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/8016c68f703d4b888e444e97481b6830/d7bf74e84cdc438ea9f04a201410a00e/','0ba915e0d89c28a05c11f5cd9674fa1d','2013-06-11T16:23:16.899531','Bgisi','0:00:00',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'i4x-Medicine-HRP258-videoalpha-413d6a45b82848339ab5fd3836dfb928','html5',null,null,'308.506103516','290','slide_seek');
COMMIT;
SET foreign_key_checks=1;
SET unique_checks=1;
