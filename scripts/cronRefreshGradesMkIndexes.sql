# Creates all necessary indexes on table EdxPrivate.UserGrades
# Uses stored procedure createIndexIfNotExists(), which
# is defined in mysqlProcAndFuncBodies.sql:

USE EdxPrivate; 
CALL createIndexIfNotExists('GradesUIDIdx', 'UserGrades', 'user_int_id', NULL);
CALL createIndexIfNotExists('UserGradesGradeIdx', 'UserGrades', 'grade', NULL);
CALL createIndexIfNotExists('UserGradesCourseIDIdx', 'UserGrades', 'course_id', 255);
CALL createIndexIfNotExists('UserGradesDistinctionIdx', 'UserGrades', 'distinction', NULL);
CALL createIndexIfNotExists('UserGradesStatusIdx', 'UserGrades', 'status', 50);
CALL createIndexIfNotExists('UserGradesNameIdx', 'UserGrades', 'name', 255);
CALL createIndexIfNotExists('UserGradesNameIdx', 'UserGrades', 'screen_name', 255);
