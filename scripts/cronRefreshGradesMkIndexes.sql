# Creates all necessary indexes on table EdxPrivate.Grades
# Uses stored procedure createIndexIfNotExists(), which
# is defined in mysqlProcAndFuncBodies.sql:

USE EdxPrivate; 
CALL createIndexIfNotExists('GradesUIDIdx', 'Grades', 'user_id', NULL);
CALL createIndexIfNotExists('GradesGradeIdx', 'Grades', 'grade', NULL);
CALL createIndexIfNotExists('GradesCourseIDIdx', 'Grades', 'course_id', 255);
CALL createIndexIfNotExists('GradesDistinctionIdx', 'Grades', 'distinction', NULL);
CALL createIndexIfNotExists('GradesStatusIdx', 'Grades', 'status', 50);
CALL createIndexIfNotExists('GradesNameIdx', 'Grades', 'name', 255);
