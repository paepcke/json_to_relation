# Creates empty Edx and EdxPrivate databases
# with required empty tables inside.
# CAUTION: deletes dbs Edx and EdxPrivate.
#
# This .sql file is sourced from 
# createEmptyEdxDbs.sh, where an appropriate
# warning is issued before running.

DROP DATABASE IF EXISTS Edx;
DROP DATABASE IF EXISTS EdxPrivate;
DROP DATABASE IF EXISTS EdxForum;
DROP DATABASE IF EXISTS EdxPiazza;

CREATE DATABASE IF NOT EXISTS Edx;
CREATE DATABASE IF NOT EXISTS EdxPrivate;
CREATE DATABASE IF NOT EXISTS EdxForum;
CREATE DATABASE IF NOT EXISTS EdxPiazza;

USE Edx;
CREATE TABLE IF NOT EXISTS Answer (
    answer_id VARCHAR(40) NOT NULL PRIMARY KEY,
    problem_id VARCHAR(255) NOT NULL,
    answer TEXT NOT NULL,
    course_id VARCHAR(255) NOT NULL
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS CorrectMap (
    correct_map_id VARCHAR(40) NOT NULL PRIMARY KEY,
    answer_identifier TEXT NOT NULL,
    correctness VARCHAR(255) NOT NULL,
    npoints INT NOT NULL,
    msg TEXT NOT NULL,
    hint TEXT NOT NULL,
    hintmode VARCHAR(255) NOT NULL,
    queuestate TEXT NOT NULL
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS InputState (
    input_state_id VARCHAR(40) NOT NULL PRIMARY KEY,
    problem_id VARCHAR(255) NOT NULL,
    state TEXT NOT NULL
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS State (
    state_id VARCHAR(40) NOT NULL PRIMARY KEY,
    seed TINYINT NOT NULL,
    done VARCHAR(255) NOT NULL,
    problem_id VARCHAR(255) NOT NULL,
    student_answer VARCHAR(40) NOT NULL,
    correct_map VARCHAR(40) NOT NULL,
    input_state VARCHAR(40) NOT NULL
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS CourseInfo (
    course_display_name varchar(255),
    course_catalog_name varchar(255),
    academic_year int,
    quarter varchar(7),
    num_quarters int,
    is_internal tinyint,
    enrollment_start datetime,
    start_date datetime,
    end_date datetime
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS EdxPrivate.EventIp (
    event_table_id varchar(40) NOT NULL PRIMARY KEY,
    event_ip varchar(16) NOT NULL DEFAULT ''
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS EdxPrivate.Account (
    account_id VARCHAR(40) NOT NULL PRIMARY KEY,
    screen_name TEXT NOT NULL,
    name TEXT NOT NULL,
    anon_screen_name TEXT NOT NULL,
    mailing_address TEXT NOT NULL,
    zipcode VARCHAR(255) NOT NULL,
    country VARCHAR(255) NOT NULL,
    gender VARCHAR(255) NOT NULL,
    year_of_birth TINYINT NOT NULL,
    level_of_education VARCHAR(255) NOT NULL,
    goals TEXT NOT NULL,
    honor_code TINYINT NOT NULL,
    terms_of_service TINYINT NOT NULL,
    course_id TEXT NOT NULL,
    enrollment_action VARCHAR(255) NOT NULL,
    email TEXT NOT NULL,
    receive_emails VARCHAR(255) NOT NULL
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS LoadInfo (
    load_info_id VARCHAR(40) NOT NULL PRIMARY KEY,
    load_date_time DATETIME NOT NULL,
    load_file TEXT NOT NULL
    ) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS EdxTrackEvent (
    _id VARCHAR(40) NOT NULL,
    event_id VARCHAR(40) NOT NULL,
    agent TEXT NOT NULL,
    event_source VARCHAR(255) NOT NULL,
    event_type TEXT NOT NULL,
    ip_country VARCHAR(255) NOT NULL,
    page TEXT NOT NULL,
    session TEXT NOT NULL,
    time DATETIME NOT NULL,
    quarter VARCHAR(255) NOT NULL,
    anon_screen_name TEXT NOT NULL,
    downtime_for DATETIME NOT NULL,
    student_id TEXT NOT NULL,
    instructor_id TEXT NOT NULL,
    course_id VARCHAR(255) NOT NULL,
    course_display_name VARCHAR(255) NOT NULL,
    resource_display_name VARCHAR(255) NOT NULL,
    organization VARCHAR(255) NOT NULL,
    sequence_id VARCHAR(255) NOT NULL,
    goto_from INT NOT NULL,
    goto_dest INT NOT NULL,
    problem_id VARCHAR(255) NOT NULL,
    problem_choice TEXT NOT NULL,
    question_location TEXT NOT NULL,
    submission_id TEXT NOT NULL,
    attempts INT NOT NULL,
    long_answer TEXT NOT NULL,
    student_file TEXT NOT NULL,
    can_upload_file VARCHAR(255) NOT NULL,
    feedback TEXT NOT NULL,
    feedback_response_selected TINYINT NOT NULL,
    transcript_id TEXT NOT NULL,
    transcript_code VARCHAR(255) NOT NULL,
    rubric_selection INT NOT NULL,
    rubric_category INT NOT NULL,
    video_id VARCHAR(255) NOT NULL,
    video_code TEXT NOT NULL,
    video_current_time VARCHAR(255) NOT NULL,
    video_speed VARCHAR(255) NOT NULL,
    video_old_time VARCHAR(255) NOT NULL,
    video_new_time VARCHAR(255) NOT NULL,
    video_seek_type VARCHAR(255) NOT NULL,
    video_new_speed VARCHAR(255) NOT NULL,
    video_old_speed VARCHAR(255) NOT NULL,
    book_interaction_type VARCHAR(255) NOT NULL,
    success VARCHAR(255) NOT NULL,
    answer_id TEXT NOT NULL,
    hint TEXT NOT NULL,
    mode VARCHAR(255) NOT NULL,
    msg TEXT NOT NULL,
    npoints TINYINT NOT NULL,
    queuestate TEXT NOT NULL,
    orig_score INT NOT NULL,
    new_score INT NOT NULL,
    orig_total INT NOT NULL,
    new_total INT NOT NULL,
    event_name VARCHAR(255) NOT NULL,
    group_user VARCHAR(255) NOT NULL,
    group_action VARCHAR(255) NOT NULL,
    position INT NOT NULL,
    badly_formatted TEXT NOT NULL,
    correctMap_fk VARCHAR(40) NOT NULL,
    answer_fk VARCHAR(40) NOT NULL,
    state_fk VARCHAR(40) NOT NULL,
    load_info_fk VARCHAR(40) NOT NULL,
    PRIMARY KEY(_id,quarter)
    ) 
ENGINE=InnoDB
PARTITION BY LIST COLUMNS(quarter) (
    PARTITION pAY2012_Spring VALUES IN ('spring2013'),
    PARTITION pAY2012_Summer VALUES IN ('summer2013'),

    PARTITION pAY2013_Fall VALUES IN ('fall2013'),
    PARTITION pAY2013_Winter VALUES IN ('winter2014'),
    PARTITION pAY2013_Spring VALUES IN ('spring2014'),
    PARTITION pAY2013_Summer VALUES IN ('summer2014'),

    PARTITION pAY2014_Fall VALUES IN ('fall2014'),
    PARTITION pAY2014_Winter VALUES IN ('winter2015'),
    PARTITION pAY2014_Spring VALUES IN ('spring2015'),
    PARTITION pAY2014_Summer VALUES IN ('summer2015'),

    PARTITION pAY2015_Fall VALUES IN ('fall2015'),
    PARTITION pAY2015_Winter VALUES IN ('winter2016'),
    PARTITION pAY2015_Spring VALUES IN ('spring2016'),
    PARTITION pAY2015_Summer VALUES IN ('summer2016'),

    PARTITION pAY2016_Fall VALUES IN ('fall2016'),
    PARTITION pAY2016_Winter VALUES IN ('winter2017'),
    PARTITION pAY2016_Spring VALUES IN ('spring2017'),
    PARTITION pAY2016_Summer VALUES IN ('summer2017'),

    PARTITION pAY2017_Fall VALUES IN ('fall2017'),
    PARTITION pAY2017_Winter VALUES IN ('winter2018'),
    PARTITION pAY2017_Spring VALUES IN ('spring2018'),
    PARTITION pAY2017_Summer VALUES IN ('summer2018')
);

CREATE TABLE IF NOT EXISTS ActivityGrade (
    activity_grade_id      int(11) 	 NOT NULL PRIMARY KEY,
    student_id             int(11) 	 NOT NULL,
    course_display_name    varchar(255)  NOT NULL,
    grade                  double,
    max_grade              double,     
    percent_grade          double        NOT NULL,
    parts_correctness      varchar(50),
    answers                varchar(255)  NOT NULL,
    num_attempts           int(11)       NOT NULL,
    first_submit           datetime,
    last_submit            datetime,
    module_type            varchar(32)   NOT NULL,
    anon_screen_name       varchar(40)   NOT NULL,
    resource_display_name  varchar(255)  NOT NULL,
    module_id              varchar(255)
    ) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `ABExperiment` (
  `event_table_id` varchar(40) NOT NULL,
  `event_type` varchar(255) NOT NULL,
  `anon_screen_name` varchar(40) NOT NULL,
  `group_id` int(11) NOT NULL,
  `group_name` varchar(255) NOT NULL,
  `partition_id` int(11) NOT NULL,
  `partition_name` varchar(255) NOT NULL,
  `child_module_id` varchar(255) NOT NULL,
  `resource_display_name` varchar(255) NOT NULL,
  `cohort_id` INT NOT NULL,
  `cohort_name` varchar(255) NOT NULL,
  PRIMARY KEY (`event_table_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `OpenAssessment` (
  `event_table_id` varchar(40) NOT NULL,
  `event_type` TEXT NOT NULL,
  `anon_screen_name` varchar(40) NOT NULL,
  `score_type` varchar(255) NOT NULL,
  `submission_uuid` varchar(255) NOT NULL,
  `edx_anon_id` TEXT NOT NULL,
  `time` DATETIME NOT NULL,
  `time_aux` DATETIME NOT NULL,
  `course_display_name` varchar(255) NOT NULL,
  `resource_display_name` varchar(255) NOT NULL,
  `resource_id` varchar(255) NOT NULL,
  `submission_text` MEDIUMTEXT NOT NULL,
  `feedback_text` MEDIUMTEXT NOT NULL,
  `comment_text` MEDIUMTEXT NOT NULL,
  `attempt_num` INT NOT NULL,
  `options` varchar(255) NOT NULL,
  `corrections` TEXT NOT NULL,
  `points` TEXT NOT NULL,
  PRIMARY KEY (`event_table_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

USE EdxForum;
CREATE TABLE IF NOT EXISTS contents (
    `forum_post_id` varchar(40) NOT NULL,
    `anon_screen_name` varchar(40),
    `type` varchar(20) NOT NULL,
    `anonymous` varchar(10) NOT NULL,
    `anonymous_to_peers` varchar(10) NOT NULL,
    `at_position_list` varchar(200) NOT NULL,
    `forum_int_id` BIGINT UNSIGNED NOT NULL,
    `body` varchar(2500) NOT NULL,
    `course_display_name` varchar(100) NOT NULL,
    `created_at` datetime NOT NULL,
    `votes` varchar(200) NOT NULL,
    `count` int(11) NOT NULL,
    `down_count` int(11) NOT NULL,
    `up_count` int(11) NOT NULL,
    `up` varchar(200) DEFAULT NULL,
    `down` varchar(200) DEFAULT NULL,
    `comment_thread_id` varchar(255) DEFAULT NULL,
    `parent_id` varchar(255) DEFAULT NULL,
    `parent_ids` varchar(255) DEFAULT NULL,
    `sk` varchar(255) DEFAULT NULL
    ) ENGINE=InnoDB;


USE EdxPiazza;
CREATE TABLE IF NOT EXISTS PiazzaUsers (
    `anon_screen_name` varchar(40) NOT NULL DEFAULT 'anon_screen_name_redacted',
    `user_int_id` int(11) NOT NULL,
    `posts` int(11) NOT NULL DEFAULT 0,
    `asks` int(11) NOT NULL DEFAULT 0,
    `answers` int(11) NOT NULL DEFAULT 0,
    `views` int(11) NOT NULL DEFAULT 0,
    `days` int(11) NOT NULL DEFAULT 0
)  ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS contents (
    `forum_post_id` varchar(40) NOT NULL DEFAULT 'none',
    `anon_screen_name` varchar(40) NOT NULL DEFAULT 'anon_screen_name_redacted',
    `type` varchar(20) NOT NULL,
    `anonymous` varchar(10) NOT NULL,
    `forum_int_id` bigint UNSIGNED NOT NULL,
    `body` varchar(2500) NOT NULL,
    `course_display_name` varchar(100) NOT NULL,
    `created_at` datetime NOT NULL,
    `votes` varchar(200) NOT NULL,
    `count` int(11) NOT NULL,
    `down_count` int(11) NOT NULL,
    `up_count` int(11) NOT NULL,
    `up` varchar(200) DEFAULT NULL,
    `down` varchar(200) DEFAULT NULL,
    `comment_thread_id` varchar(255) DEFAULT NULL,
    `parent_id` varchar(255) DEFAULT NULL,
    `parent_ids` varchar(255) DEFAULT NULL,
    `sk` varchar(255) DEFAULT NULL,
    `confusion` varchar(20) NOT NULL DEFAULT 'none',
    `happiness` varchar(20) NOT NULL DEFAULT 'none'
    ) ENGINE=InnoDB;


USE EdxPrivate;
CREATE TABLE `UserGrade` (
  `name` varchar(255) NOT NULL DEFAULT '',
  `screen_name` varchar(255) NOT NULL DEFAULT '',
  `grade` int(11) NOT NULL DEFAULT '0',
  `course_id` varchar(255) NOT NULL DEFAULT '',
  `distinction` tinyint(4) NOT NULL DEFAULT '0',
  `status` varchar(50) NOT NULL DEFAULT '',
  `user_int_id` int(11) NOT NULL,
  `anon_screen_name` varchar(40) NOT NULL DEFAULT '',
  PRIMARY KEY (`user_int_id`),
  KEY `GradesUIDIdx` (`user_int_id`),
  KEY `UserGradeGradeIdx` (`grade`),
  KEY `UserGradeCourseIDIdx` (`course_id`),
  KEY `UserGradeDistinctionIdx` (`distinction`),
  KEY `UserGradeStatusIdx` (`status`),
  KEY `UserGradeNameIdx` (`name`),
  KEY `GradesAnonIdx` (`anon_screen_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1