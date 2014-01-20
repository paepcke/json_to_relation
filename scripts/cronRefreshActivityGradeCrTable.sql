-- Note: cols resource_display_name and anon_screen_name
--       need to stay at their positions at the end
--       for addAnonToActivityGrade.py to do the right
--       thing:
CREATE DATABASE IF NOT EXISTS Edx;
USE Edx;
CREATE TABLE IF NOT EXISTS Edx.ActivityGrade (
    activity_grade_id int(11) PRIMARY KEY,
    student_id int(11) NOT NULL,
    course_display_name varchar(255) NOT NULL,
    grade double,
    max_grade double,
    percent_grade double,
    parts_correctness varchar(50),
    wrong_answers varchar(255),
    numAttempts int,
    first_submit datetime,
    last_submit datetime,
    module_type varchar(32) NOT NULL,
    resource_display_name varchar(255) NOT NULL DEFAULT '',
    anon_screen_name varchar(40) NOT NULL DEFAULT ''
    );
