-- Note: if you change order or content of the
--       col names, match that in addAnonToActivityGradeTable.py,
--       and in testAddAnonToActivityGradeTable.py
CREATE DATABASE IF NOT EXISTS Edx;
USE Edx;
CREATE TABLE IF NOT EXISTS Edx.ActivityGrade (
    activity_grade_id int(11),
    student_id int(11) NOT NULL,
    course_display_name varchar(255) NOT NULL,
    grade double,
    max_grade double,
    percent_grade double,
    parts_correctness varchar(50),
    answers varchar(255),
    num_attempts int,
    first_submit datetime,
    last_submit datetime,
    module_type varchar(32) NOT NULL,
    anon_screen_name varchar(40) NOT NULL DEFAULT '',
    resource_display_name varchar(255) NOT NULL DEFAULT '',
    module_id varchar(255)
    );
