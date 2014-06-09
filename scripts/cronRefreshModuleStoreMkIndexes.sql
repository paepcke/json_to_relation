# Creates all necessary indexes on table Edx.CourseInfo
# Uses stored procedure createIndexIfNotExists(), which
# is defined in mysqlProcAndFuncBodies.sql:

USE Edx; 
CALL createIndexIfNotExists('CourseInfoCrsIDIdx', 'CourseInfo', 'course_display_name', 255);
CALL createIndexIfNotExists('CourseInfoAcaYrIdx', 'CourseInfo', 'academic_year', NULL);
CALL createIndexIfNotExists('CourseInfoQuarterIdx', 'CourseInfo', 'quarter', 7);
CALL createIndexIfNotExists('CourseInfoIsInternalIdx', 'CourseInfo', 'is_internal', NULL);
CALL createIndexIfNotExists('CourseInfoStartIdx', 'CourseInfo', 'start_date', NULL);
CALL createIndexIfNotExists('CourseInfoEndIdx', 'CourseInfo', 'end_date', NULL);
