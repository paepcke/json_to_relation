CREATE DATABASE IF NOT EXISTS EdxPrivate;
USE EdxPrivate;
CREATE TABLE IF NOT EXISTS EdxPrivate.Grades (
    user_id int NOT NULL PRIMARY KEY,
    grade int NOT NULL,
    course_id VARCHAR(255) NOT NULL,
    distinction TINYINT NOT NULL,
    status VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL
    );
