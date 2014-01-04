# Creates all necessary indexes on table EdxPrivate.UserGrade
# Uses stored procedure createIndexIfNotExists(), which
# is defined in mysqlProcAndFuncBodies.sql:

USE EdxPrivate; 
CALL createIndexIfNotExists('GradesUIDIdx', 'UserGrade', 'user_int_id', NULL);
CALL createIndexIfNotExists('UserGradeGradeIdx', 'UserGrade', 'grade', NULL);
CALL createIndexIfNotExists('UserGradeCourseIDIdx', 'UserGrade', 'course_id', 255);
CALL createIndexIfNotExists('UserGradeDistinctionIdx', 'UserGrade', 'distinction', NULL);
CALL createIndexIfNotExists('UserGradeStatusIdx', 'UserGrade', 'status', 50);
CALL createIndexIfNotExists('UserGradeNameIdx', 'UserGrade', 'name', 255);
CALL createIndexIfNotExists('UserGradeNameIdx', 'UserGrade', 'screen_name', 255);
CALL createIndexIfNotExists('GradesAnonIdx', 'UserGrade', 'anon_screen_name', 40);
