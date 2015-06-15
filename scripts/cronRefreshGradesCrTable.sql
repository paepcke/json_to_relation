CREATE DATABASE IF NOT EXISTS EdxPrivate;
USE EdxPrivate;
CREATE TABLE IF NOT EXISTS EdxPrivate.UserGrade (
    name VARCHAR(255) NOT NULL DEFAULT '',
    screen_name VARCHAR(255) NOT NULL DEFAULT '',
    grade double NOT NULL DEFAULT 0.0,
    course_id VARCHAR(255) NOT NULL DEFAULT '',
    distinction TINYINT NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT '',
    user_int_id int NOT NULL PRIMARY KEY,
    anon_screen_name varchar(40) NOT NULL DEFAULT ''
    ) engine = MyISAM;
