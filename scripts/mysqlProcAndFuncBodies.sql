# Stored procedures used for administering the Edx
# tracking log database and others.

# NOTE: these functions and procedures need to be
#       defined in all the databases where they
#       are needed. I tried defining them once
#       in Edx, and then replicating a row
#       in mysql.proc, changing only the database
#       column content. But it got to crufty, and
#       vulnerable to future MySQL version mods.
#
#       Instead this file is 'source'ed into 
#       MySQL twice by defineMySQLProcedures.sh.

# NOTE: any function that should only exist in EdxPrivate
#       has a DROP...<DB>.funcName  statement right after 
#       its definition. Where <DB> is any db where 
#       this file might be sourced.

# Set the statement delimiter to something other than ';'
# so the procedure can use ';':
delimiter //

#--------------------------
# createIndexIfNotExists
#-----------

# Create index if it does not exist yet.
# Parameter the_prefix_len can be set to NULL if not needed

DROP PROCEDURE IF EXISTS createIndexIfNotExists //
CREATE PROCEDURE createIndexIfNotExists (IN the_index_name varchar(255),
     		 			 IN the_table_name varchar(255),
					 IN the_col_name   varchar(255),
					 IN the_prefix_len INT)
BEGIN
      IF ((SELECT COUNT(*) AS index_exists 
           FROM information_schema.statistics 
           WHERE TABLE_SCHEMA = DATABASE() 
             AND table_name = the_table_name 
    	 AND index_name = the_index_name)  
          = 0)
      THEN
          # Different CREATE INDEX statement depending on whether
          # a prefix length is required:
          IF the_prefix_len IS NULL
          THEN
          	  SET @s = CONCAT('CREATE INDEX ' , 
          	                  the_index_name , 
          			  ' ON ' , 
          			  the_table_name, 
          			  '(', the_col_name, ')');
          ELSE
          	  SET @s = CONCAT('CREATE INDEX ' , 
          	                  the_index_name , 
 			          ' ON ' , 
          			  the_table_name, 
          			  '(', the_col_name, '(',the_prefix_len,'))');
         END IF;
         PREPARE stmt FROM @s;
         EXECUTE stmt;
      END IF;
END//

#--------------------------
# dropIndexIfExists
#-----------

DROP PROCEDURE IF EXISTS dropIndexIfExists //
CREATE PROCEDURE dropIndexIfExists (IN the_table_name varchar(255),
   		 	            IN the_col_name varchar(255))
BEGIN
    DECLARE indx_name varchar(255);
    IF ((SELECT COUNT(*) AS index_exists
         FROM information_schema.statistics 
         WHERE TABLE_SCHEMA = DATABASE() 
           AND table_name = the_table_name 
  	   AND column_name = the_col_name)  
        > 0)
    THEN
        SELECT index_name INTO @indx_name
	FROM information_schema.statistics
	WHERE TABLE_SCHEMA = DATABASE() 
 	   AND table_name = the_table_name 
 	   AND column_name = the_col_name;
        SET @s = CONCAT('DROP INDEX `' ,
                        @indx_name ,
  		        '` ON ' ,
        		the_table_name
        		);
       PREPARE stmt FROM @s;
       EXECUTE stmt;
    END IF;
END//

#--------------------------
# addPrimaryIfNotExists
#----------------------

# Add primary key if it does not exist yet.

DROP PROCEDURE IF EXISTS addPrimaryIfNotExists //
CREATE PROCEDURE addPrimaryIfNotExists (IN the_table_name varchar(255),
					IN the_col_name   varchar(255))
BEGIN
      IF ((SELECT COUNT(*) AS index_exists 
           FROM information_schema.statistics 
           WHERE TABLE_SCHEMA = DATABASE() 
             AND table_name = the_table_name 
    	 AND index_name = 'PRIMARY')  
         = 0)
      THEN
          # 'IGNORE' will refuse to add duplicates:
      	  SET @s = CONCAT('ALTER IGNORE TABLE ' , 
      			  the_table_name, 
			  ' ADD PRIMARY KEY ( ',
      			  the_col_name, 
			  ' )'
			  );
          PREPARE stmt FROM @s;
 	  EXECUTE stmt;
      END IF;
END//

#--------------------------
# dropPrimaryIfExists
#-----------

# Given a table name, drop its primary index
# if it exists.

DROP PROCEDURE IF EXISTS dropPrimaryIfExists //
CREATE PROCEDURE dropPrimaryIfExists (IN the_table_name varchar(255))
BEGIN
    IF ((SELECT COUNT(*) AS index_exists 
         FROM information_schema.statistics 
         WHERE TABLE_SCHEMA = DATABASE() 
           AND table_name = the_table_name 
  	   AND index_name = 'PRIMARY')  
        > 0)
    THEN
        SET @s = CONCAT('ALTER TABLE ' ,
        		the_table_name,
			' DROP PRIMARY KEY;'
        		);
       PREPARE stmt FROM @s;
       EXECUTE stmt;
    END IF;
END//

#--------------------------
# indexExists
#-----------

# Given a table and column name, return 1 if 
# an index exists on that column, else returns 0.

DROP FUNCTION IF EXISTS indexExists//
CREATE FUNCTION indexExists(the_table_name varchar(255),
       		 	    the_col_name varchar(255))
RETURNS BOOL
BEGIN
    IF ((SELECT COUNT(*)
         FROM information_schema.statistics 
         WHERE TABLE_SCHEMA = DATABASE() 
           AND table_name = the_table_name 
    	   AND column_name = the_col_name) > 0)
   THEN
       RETURN 1;
   ELSE
       RETURN 0;
   END IF;
END//

#--------------------------
# anyIndexExists
#---------------

# Given a table return 1 if any non-PRIMARY
# index exists on that table, else returns 0.

DROP FUNCTION IF EXISTS anyIndexExists//
CREATE FUNCTION anyIndexExists(the_table_name varchar(255))
RETURNS BOOL
BEGIN
    IF ((SELECT COUNT(*)
         FROM information_schema.statistics 
         WHERE TABLE_SCHEMA = DATABASE() 
           AND table_name = the_table_name 
    	   AND Index_name != 'Primary') > 0)
   THEN
       RETURN 1;
   ELSE
       RETURN 0;
   END IF;
END//


#--------------------------
# latestLog
#----------

# Return the load date, and log collection date of the 
# most recent tracking log that has been loaded 
# into Edx.
#
# Returns the load date and the date when the 
# log was collected.
#
# Uses the load_file name field of the LoadInfo table.
# Entries there look like this:
#
#    file:///home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsTests/tracking/app10/tracking.log-20130610.gz
#
# The hairy SELECT below works like this:
#    1. Get the location of "log-" towards the end of the file name: LOCATE('log-', load_file)
#    2. Adjust that location to point past the "log-" to the start of the load date: +4
#    3. Use that pointer into the file name as the second arg
#       in the call SUBSTR(str,startPos,len): The "8" is the length
#       of the file names date part.
#
# Returns string of form: Loaded: 2013-12-30 13:20:57; Collected: 20130610 

DROP FUNCTION IF EXISTS latestLog//

CREATE FUNCTION latestLog()
RETURNS varchar(50)
BEGIN
    # See header comment for explanation of this SELECT
    SELECT load_date_time, 
           MAX(SUBSTR(load_file, LOCATE('log-', load_file)+4, 8)) AS log_date
    FROM Edx.LoadInfo
    INTO @loadDateTime, @collectDate;
    return CONCAT('Loaded: ',
                  @loadDateTime,
		  '; collected: ',
		  @collectDate);
END//

#--------------------------
# earliestLog
#------------

# Return the load date, and log collection date of the 
# oldest tracking log that has been loaded 
# into Edx.
#
# Returns (load date, date when log was collected)
#
# Uses the load_file name field of the LoadInfo table.
# Entries there look like this:
#
#    file:///home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsTests/tracking/app10/tracking.log-20130610.gz
#
# The hairy SELECT below works like this:
#    1. Get the location of "log-" towards the end of the file name: LOCATE('log-', load_file)
#    2. Adjust that location to point past the "log-" to the start of the load date: +4
#    3. Use that pointer into the file name as the second arg
#       in the call SUBSTR(str,startPos,len): The "8" is the length
#       of the file names date part.
#
# Returns string of form: Loaded: 2013-12-30 13:20:57; Collected: 20130610 

DROP FUNCTION IF EXISTS earliestLog//

CREATE FUNCTION earliestLog()
RETURNS varchar(50)
BEGIN
    # See header comment for explanation of this SELECT
    SELECT load_date_time, 
           MIN(SUBSTR(load_file, LOCATE('log-', load_file)+4, 8)) AS log_date
    FROM Edx.LoadInfo
    INTO @loadDateTime, @collectDate;
    return CONCAT('Loaded: ',
                  @loadDateTime,
		  '; collected: ',
		  @collectDate);
END//

#--------------------------
# idAnon2Int
#-----------

# Given user ID hash as used in Edx, return 
# the corresponding row number that is used
# in some edxprod tables.

DROP FUNCTION IF EXISTS idAnon2Int//

CREATE FUNCTION idAnon2Int(anonId varchar(40))
RETURNS int(11)
BEGIN
    SELECT user_int_id 
    FROM EdxPrivate.UserGrade
    WHERE anon_screen_name = anonId
    INTO @intId;
    return @intId;
END//


#--------------------------
# idInt2Anon
#-----------

# Given an integer user ID as used in 
# some edxprod tables, return 
# the corresponding hash-type user ID
# that is used in Edx and EdxPrivate

DROP FUNCTION IF EXISTS idInt2Anon//

CREATE FUNCTION idInt2Anon(intId int(11))
RETURNS varchar(40)
BEGIN
    SELECT anon_screen_name
    FROM EdxPrivate.UserGrade
    WHERE user_int_id  = intId
    INTO @anonId;
    return @anonId;
END//


#--------------------------
# idExt2Anon
#-----------

# Given the 32 char anonymized UID used
# for outside services, such as Qualtrix
# or Piazza, return the corresponding
# anon_screen_name.
#
# We drop this function from the public
# part of the database by DROPping it
# from Edx, EdxForum, and EdxPiazza right
# after the definition. This way this file
# can be sourced anywhere.

DROP FUNCTION IF EXISTS idExt2Anon//

CREATE FUNCTION idExt2Anon(extId varchar(32)) 
RETURNS varchar(40)
BEGIN
      SELECT user_id INTO @int_id
      FROM edxprod.student_anonymoususerid
      WHERE anonymous_user_id = extId;

      SELECT idInt2Anon(@int_id) INTO @anon_id;
      return @anon_id;
END//

DROP FUNCTION IF EXISTS Edx.idExt2Anon//
DROP FUNCTION IF EXISTS EdxForum.idExt2Anon//
#DROP FUNCTION IF EXISTS EdxPiazza.idExt2Anon//


#--------------------------
# idAnon2Ext
#-----------

# Given the 40 char anon_screen_name, return
# the corresponding anonymized UID used by
# outside services, such as Qualtrix or Piazza
# For testing:
#Testing idAnon2Ext():
#
#   one row of student_anonuserid:
#   284347 | 5cbdc8b38171f3641845cb17784de87b | Engineering/CVX101/Winter2014
#
#   Using idInt2Anon():
#   284347 int = 0686bef338f8c6f0696cc7d4b0650daf2473f59d anon
# 
#   idAnon2Ext('0686bef338f8c6f0696cc7d4b0650daf2473f59d', 'Engineering/CVX101/Winter2014')
#   should be: 5cbdc8b38171f3641845cb17784de87b

DROP FUNCTION IF EXISTS idAnon2Ext//

CREATE FUNCTION idAnon2Ext(the_anon_id varchar(42))
RETURNS varchar(32)
BEGIN
      SELECT -1 INTO @int_id;
      SELECT user_int_id INTO @int_id
      FROM EdxPrivate.UserGrade
      WHERE anon_screen_name = the_anon_id;

      IF @int_id < 0
      THEN 
          RETURN null;
      END IF;
        
      SELECT anonymous_user_id INTO @ext_id
      FROM edxprod.student_anonymoususerid
      WHERE user_id = @int_id
        AND CHAR_LENGTH(course_id) = 0;

      return @ext_id;
      
END//

#--------------------------
# isUserEvent
#-----------

# Returns 1 if given user event was generated
# by the class participant, rather than the server
# or instructor. Some events are in fact emitted
# by the server, but are an indication that participant
# took an action. Ex.: problem_graded.

DROP FUNCTION IF EXISTS isUserEvent //
CREATE FUNCTION isUserEvent (an_event_type varchar(255))
RETURNS BOOL
BEGIN
    IF 	 an_event_type = 'book' OR 
	 an_event_type = 'fullscreen' OR 
	 an_event_type = 'hide_transcript' OR 
	 an_event_type = 'hide_transcript' OR 
	 an_event_type = 'load_video' OR 
	 an_event_type = 'not_fullscreen' OR 
	 an_event_type = 'oe_feedback_response_selected' OR 
	 an_event_type = 'oe_hide_question' OR 
	 an_event_type = 'oe_show_question' OR 
	 an_event_type = 'oe_show_full_feedback' OR 
	 an_event_type = 'oe_show_respond_to_feedback' OR 
	 an_event_type = 'page_close' OR 
	 an_event_type = 'pause_video' OR 
	 an_event_type = 'peer_grading_hide_question' OR 
	 an_event_type = 'peer_grading_show_question' OR 
	 an_event_type = 'play_video' OR 
	 an_event_type = 'problem_check' OR 
	 an_event_type = 'problem_graded' OR 
	 an_event_type = 'problem_fail' OR 
	 an_event_type = 'problem_reset' OR 
	 an_event_type = 'problem_save' OR 
	 an_event_type = 'problem_show' OR 
	 an_event_type = 'rubric_select' OR 
	 an_event_type = 'seek_video' OR 
	 an_event_type = 'seq_goto' OR 
	 an_event_type = 'seq_next' OR 
	 an_event_type = 'seq_prev' OR 
	 an_event_type = 'show_transcript' OR 
	 an_event_type = 'speed_change_video' OR 
	 an_event_type = 'staff_grading_hide_question' OR 
	 an_event_type = 'staff_grading_show_question'

   THEN
       RETURN 1;
   ELSE
       RETURN 0;
   END IF;
END;//

#--------------------------
# isEngagementEvent
#-----------

# Returns 1 if given event was generated
# by the class participant during interaction
# with a class element: video, a problem, or
# work with peer grading.

DROP FUNCTION IF EXISTS isEngagementEvent //
CREATE FUNCTION isEngagementEvent (an_event_type varchar(255))
RETURNS BOOL
BEGIN
    IF 	 an_event_type = 'load_video' OR 
	 an_event_type = 'oe_feedback_response_selected' OR 
	 an_event_type = 'pause_video' OR 
	 an_event_type = 'peer_grading_hide_question' OR 
	 an_event_type = 'peer_grading_show_question' OR 
	 an_event_type = 'play_video' OR 
	 an_event_type = 'problem_check' OR 
	 an_event_type = 'problem_graded' OR 
	 an_event_type = 'problem_save' OR 
	 an_event_type = 'seek_video' OR 
	 an_event_type = 'speed_change_video' OR 
	 an_event_type = 'staff_grading_hide_question' OR 
	 an_event_type = 'staff_grading_show_question'

   THEN
       RETURN 1;
   ELSE
       RETURN 0;
   END IF;
END;//


#--------------------------
# createExtIdMapByCourse
#-----------

# Procedure to create a table of mappings between anon_screen_name,
# and the external anon id used for Qualtrix and Piazza. The mapping
# will contain all students of a given course specification.
# Course specification is course name that can contain MySQL 
# wildcards.
#
# Example: createExtIdMapByCourse('Engineering/Solar/Fall2013', 'myTable')
#
# If the table already exists: error
#
# Input: course name spec, and name of table to dump to.

DROP PROCEDURE IF EXISTS createExtIdMapByCourse;
CREATE PROCEDURE `createExtIdMapByCourse`(IN the_course_name varchar(255), IN tblName varchar(255))
BEGIN
    SET @the_table_name := tblName;

    SET @tblFilling = CONCAT(
       
    ' CREATE TABLE ',tblName, 
    ' SELECT idInt2Anon(user_int_id) AS anon_screen_name,'
    '        student_anonymoususerid.anonymous_user_id AS ext_anon_name '
    ' FROM EdxPrivate.UserGrade '
    'JOIN edxprod.student_anonymoususerid '
    '   ON EdxPrivate.UserGrade.user_int_id = edxprod.student_anonymoususerid.user_id '
    'WHERE EdxPrivate.UserGrade.course_id LIKE \'',the_course_name,'\'; '
    );

--    SELECT @tblFilling;

    PREPARE filling_stmt FROM @tblFilling;
    EXECUTE filling_stmt;
    DEALLOCATE PREPARE filling_stmt;

END//

# Restore standard delimiter:
delimiter ;

# -----------------------------------------  Views -------------------------------

#--------------------------
# EventXtract
#-------------

DROP VIEW IF EXiSTS EventXtract;
CREATE VIEW EventXtract AS
   SELECT anon_screen_name,
	  event_type,
	  ip,
	  time,
	  course_display_name,
	  resource_display_name,
	  success,
	  video_code,
	  video_current_time,
	  video_speed,
	  video_old_time,
	  video_new_time,
	  video_seek_type,
	  video_new_speed,
	  video_old_speed,
	  goto_from,
	  goto_dest
  FROM Edx.EdxTrackEvent;

#--------------------------
# Performance
#------------

DROP VIEW IF EXiSTS Performance;
CREATE VIEW Performance AS
SELECT anon_screen_name, 
       course_display_name,
       SUM(percent_grade)/COUNT(percent_grade) AS avg_grade
FROM Edx.ActivityGrade
GROUP BY anon_screen_name, course_display_name;

#--------------------------
# FinalGrade 
#-----------

DROP VIEW IF EXiSTS FinalGrade;
CREATE VIEW FinalGrade AS
SELECT anon_screen_name,
       course_id,
       grade,
       distinction
FROM EdxPrivate.UserGrade;

#--------------------------
# VideoInteraction
#-----------------

DROP VIEW IF EXISTS VideoInteraction;
CREATE VIEW VideoInteraction AS
SELECT event_type,
       resource_display_name,
       video_current_time,
       video_speed,
       video_new_speed,
       video_old_speed,
       video_new_time,
       video_old_time,
       video_seek_type,
       video_code,
       time,
       course_display_name,
       anon_screen_name,
       video_id
FROM Edx.EdxTrackEvent
WHERE  CHAR_LENGTH(video_code) > 0 OR
       CHAR_LENGTH(video_current_time) > 0 OR
       CHAR_LENGTH(video_speed) > 0 OR
       CHAR_LENGTH(video_old_time) > 0 OR
       CHAR_LENGTH(video_new_time) > 0 OR
       CHAR_LENGTH(video_seek_type) > 0 OR
       CHAR_LENGTH(video_new_speed) > 0 OR
       CHAR_LENGTH(video_old_speed) > 0;

#--------------------------
# Demographics
#------------

# View over edxprod.auth_userprofile. Provides
# gender, year of birth, dynamically computed
# age at time of SELECT, and level of education.
# Each row is for one anon_screen_name.

DROP VIEW IF EXiSTS Demographics;
CREATE VIEW Demographics AS
SELECT EdxPrivate.UserGrade.anon_screen_name, 
       gender,
       year_of_birth,
       Year(CURDATE())-year_of_birth AS curr_age,
       CASE level_of_education 
          WHEN 'p' THEN 'Doctorate'
	  WHEN 'm' THEN 'Masters or professional degree'
	  WHEN 'b' THEN 'Bachelors'
	  WHEN 'a' THEN 'Associates'
	  WHEN 'hs' THEN 'Secondary/High School'
	  WHEN 'jhs' THEN 'Junior secondary/junior high/middle School'
	  WHEN 'el'  THEN 'Elementary/Primary School'
	  WHEN 'none' THEN 'None'
	  WHEN 'other' THEN 'Other'
	  WHEN ''      THEN 'User withheld'
	  WHEN 'NULL'  THEN 'Signup before level collected'
       END AS level_of_education,
       Edx.UserCountry.three_letter_country AS country_three_letters,
       Edx.UserCountry.country AS country_name
       
FROM edxprod.auth_userprofile
 JOIN EdxPrivate.UserGrade
   ON EdxPrivate.UserGrade.user_int_id = edxprod.auth_userprofile.user_id
 LEFT JOIN Edx.UserCountry
   ON Edx.UserCountry.anon_screen_name = EdxPrivate.UserGrade.anon_screen_name;
