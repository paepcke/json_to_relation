# Creates all necessary indexes on table Edx.ActivityGrade
# Uses stored procedure createIndexIfNotExists(), which
# is defined in mysqlProcAndFuncBodies.sql:

USE Edx; 
CALL createIndexIfNotExists('ActivityGradeCrsIDIdx', 'ActivityGrade', 'course_display_name', 255);
CALL createIndexIfNotExists('ActivityGradeGradeIdx', 'ActivityGrade', 'grade', NULL);
CALL createIndexIfNotExists('ActivityGradeMaxGrdIdx', 'ActivityGrade', 'max_grade', NULL);
CALL createIndexIfNotExists('ActivityGradePercGrdIdx', 'ActivityGrade', 'percent_grade', NULL);
CALL createIndexIfNotExists('ActivityGradeModTypeIdx', 'ActivityGrade', 'module_type', 32);
CALL createIndexIfNotExists('ActivityGradeRsrcDispIdx', 'ActivityGrade', 'resource_display_name', 255);
CALL createIndexIfNotExists('ActivityGradeAnonNmIdx', 'ActivityGrade', 'anon_screen_name', 40);
CALL createIndexIfNotExists('ActivityGradeModIdIdx', 'ActivityGrade', 'module_id', 255);
