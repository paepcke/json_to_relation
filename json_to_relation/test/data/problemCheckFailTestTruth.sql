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
INSERT INTO Answer (answer_id,problem_id,answer) VALUES 
    ('948d7070_5cf4_41e8_b9c4_94b5b4668de0','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1'),
    ('9af87608_3f96_4842_a3c6_5441b1f1443d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3'),
    ('39686137_3d45_4c02_b6ce_2245fe486062','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1'),
    ('555c09a5_7237_46b8_8d9e_cbfda5b5c0ab','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0'),
    ('834a035a_dbd1_4a85_8ce8_050f5db8f177','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4'),
    ('c5cf1d83_0587_42f0_8f98_6624db4185ec','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2'),
    ('92c6701b_72a7_44d3_a413_c04b1c57aa19','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0'),
    ('aab75411_ec0c_4716_907a_d9a3aac33936','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0'),
    ('978a490c_4bb5_4ef7_a828_808f0367d9b7','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','choice_1'),
    ('aaf8ce51_46c1_48be_95d5_6816d7951d3b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','choice_3'),
    ('ec7d9da2_b909_4ed9_9dc3_56fc6092ee2a','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','choice_0,choice_1'),
    ('10cc26c1_7833_458b_97e9_ad3b8ba03454','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','choice_0'),
    ('b37e4c8f_6789_4f14_ab38_e988907c0c67','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','choice_0,choice_1,choice_2,choice_3,choice_4'),
    ('ab97454f_ecd8_4cee_8126_ae1920a63a3b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','choice_2'),
    ('06714077_ed5b_4da4_9667_7023faf76690','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','choice_0'),
    ('10481737_48dc_4699_b2ff_d04ef91cb9e0','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','choice_0');
INSERT INTO CorrectMap (correct_map_id,answer_identifier,correctness,npoints,msg,hint,hintmode,queuestate) VALUES 
    ('f732ae0f_87ce_4ca6_94d4_fa60bab3423d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1','correct',null,'','',null,null),
    ('fd93a030_7a40_41d5_b47d_a69bd36352fc','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1','correct',null,'','',null,null),
    ('238aa0a0_347e_43a6_a267_c724adeab0ae','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1','correct',null,'','',null,null),
    ('a38fba66_9852_4974_8170_5688ebb8a7ab','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1','correct',null,'','',null,null),
    ('53edb831_80f7_43d8_8718_af7c7729390f','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1','incorrect',null,'','',null,null),
    ('e7c555c0_edbb_423a_9cde_fcf61a541087','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1','correct',null,'','',null,null),
    ('e0c18318_68e2_4263_8506_0b942b65e36b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1','correct',null,'','',null,null),
    ('0d5d2012_3e04_4b5f_a800_cf687b6220a8','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1','incorrect',null,'','',null,null);
INSERT INTO InputState (input_state_id,problem_id,state) VALUES 
    ('dc9b4bbc_7b6e_44e2_a86e_3602bb67fa18','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',null),
    ('6f2566c8_06e9_424d_a60b_9d96dce048d1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',null),
    ('68bb0dd2_87c3_4abd_9256_2b8c8a60cb4b','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',null),
    ('41dc0028_3291_403d_9755_035ceeb128f1','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',null),
    ('107f3a36_637b_4bf8_a56f_51346e92bcab','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',null),
    ('5e7c7238_7dd1_4a9d_b8e4_663806ad4505','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',null),
    ('c93599fe_9ed9_4518_92d7_fff50ebc2415','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',null),
    ('5b97117a_e917_4e54_ac43_901edd6e983d','i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null);
INSERT INTO State (state_id,seed,done,problem_id,student_answer,correct_map,input_state) VALUES 
    ('590f09da_2d4d_46da_a68f_66f05e9c98ef',1,True,null,'978a490c_4bb5_4ef7_a828_808f0367d9b7','f732ae0f_87ce_4ca6_94d4_fa60bab3423d','dc9b4bbc_7b6e_44e2_a86e_3602bb67fa18'),
    ('25a93d6a_33c8_45e7_9bbf_797dde512553',1,True,null,'aaf8ce51_46c1_48be_95d5_6816d7951d3b','fd93a030_7a40_41d5_b47d_a69bd36352fc','6f2566c8_06e9_424d_a60b_9d96dce048d1'),
    ('4c2516bb_c1fc_46f0_8269_ed479e98bd38',1,True,null,'ec7d9da2_b909_4ed9_9dc3_56fc6092ee2a','238aa0a0_347e_43a6_a267_c724adeab0ae','68bb0dd2_87c3_4abd_9256_2b8c8a60cb4b'),
    ('2620a303_e4e9_4a63_9fdb_7ae339d2b036',1,True,null,'10cc26c1_7833_458b_97e9_ad3b8ba03454','a38fba66_9852_4974_8170_5688ebb8a7ab','41dc0028_3291_403d_9755_035ceeb128f1'),
    ('cfc5af09_2719_4234_9297_391ade86555d',1,True,null,'b37e4c8f_6789_4f14_ab38_e988907c0c67','53edb831_80f7_43d8_8718_af7c7729390f','107f3a36_637b_4bf8_a56f_51346e92bcab'),
    ('d35e15f8_8273_4e55_b7a5_9bf222e1a1be',1,True,null,'ab97454f_ecd8_4cee_8126_ae1920a63a3b','e7c555c0_edbb_423a_9cde_fcf61a541087','5e7c7238_7dd1_4a9d_b8e4_663806ad4505'),
    ('1aa63a9d_0b22_4ca9_aba8_80ffc549a243',1,True,null,'06714077_ed5b_4da4_9667_7023faf76690','e0c18318_68e2_4263_8506_0b942b65e36b','c93599fe_9ed9_4518_92d7_fff50ebc2415'),
    ('906a07a8_ebb9_4ee9_a580_6f7317e1469d',1,True,null,'10481737_48dc_4699_b2ff_d04ef91cb9e0','0d5d2012_3e04_4b5f_a800_cf687b6220a8','5b97117a_e917_4e54_ac43_901edd6e983d');
INSERT INTO Event (event_id,agent,event_source,event_type,ip,page,session,time,username,downtime_for,student_id,instructor_id,course_id,sequence_id,goto_from,goto_dest,problem_id,problem_choice,question_location,submission_id,attempts,long_answer,student_file,can_upload_file,feedback,feedback_response_selected,transcript_id,transcript_code,rubric_selection,rubric_category,video_id,video_code,video_current_time,video_speed,video_old_time,video_new_time,video_seek_type,video_new_speed,video_old_speed,book_interaction_type,success,answer_id,hint,hintmode,correctness,msg,npoints,queuestate,orig_score,new_score,orig_total,new_total,event_name,group_user,group_action,position,badly_formatted,correctMap_fk,answer_fk,state_fk) VALUES 
    ('cbbdf02d_c583_431d_9b8f_5682fd61cf1e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'948d7070_5cf4_41e8_b9c4_94b5b4668de0','590f09da_2d4d_46da_a68f_66f05e9c98ef'),
    ('cbbdf02d_c583_431d_9b8f_5682fd61cf1e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'9af87608_3f96_4842_a3c6_5441b1f1443d','25a93d6a_33c8_45e7_9bbf_797dde512553'),
    ('cbbdf02d_c583_431d_9b8f_5682fd61cf1e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'39686137_3d45_4c02_b6ce_2245fe486062','4c2516bb_c1fc_46f0_8269_ed479e98bd38'),
    ('cbbdf02d_c583_431d_9b8f_5682fd61cf1e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'555c09a5_7237_46b8_8d9e_cbfda5b5c0ab','2620a303_e4e9_4a63_9fdb_7ae339d2b036'),
    ('cbbdf02d_c583_431d_9b8f_5682fd61cf1e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'834a035a_dbd1_4a85_8ce8_050f5db8f177','cfc5af09_2719_4234_9297_391ade86555d'),
    ('cbbdf02d_c583_431d_9b8f_5682fd61cf1e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_5_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'c5cf1d83_0587_42f0_8f98_6624db4185ec','d35e15f8_8273_4e55_b7a5_9bf222e1a1be'),
    ('cbbdf02d_c583_431d_9b8f_5682fd61cf1e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_4_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'92c6701b_72a7_44d3_a413_c04b1c57aa19','1aa63a9d_0b22_4ca9_aba8_80ffc549a243'),
    ('cbbdf02d_c583_431d_9b8f_5682fd61cf1e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'aab75411_ec0c_4716_907a_d9a3aac33936','906a07a8_ebb9_4ee9_a580_6f7317e1469d'),
    ('cbbdf02d_c583_431d_9b8f_5682fd61cf1e','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1','server','problem_check_fail','58.108.173.32','x_module',null,'2013-06-26T06:25:22.710746+00:00','RobbieH','0:00:00',null,null,null,null,null,null,'i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_3_1',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'closed',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'aab75411_ec0c_4716_907a_d9a3aac33936','906a07a8_ebb9_4ee9_a580_6f7317e1469d');
COMMIT;
SET foreign_key_checks=1;
SET unique_checks=1;
