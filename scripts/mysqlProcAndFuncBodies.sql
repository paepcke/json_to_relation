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
#       Instead this file is 'source'ed 
#       by defineMySQLProcedures.sh. into 
#       MySQL for each database where they are
#       to be used 

# NOTE: any function that should only exist in EdxPrivate
#       has a DROP...<DB>.funcName  statement at the bottom
#       of this file. There, <DB> is any db where 
#       this file might be sourced.

# ------------- Grant EXECUTE Privileges for User Level Functions -----

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
# functionExists
#----------------

# Given a fully qualified function name, return 1 if 
# the function exists in the respective db, else returns 0.
# Example: SELECT functionExists('Edx.idInt2Anon');

DROP FUNCTION IF EXISTS functionExists//
CREATE FUNCTION functionExists(fully_qualified_funcname varchar(255))
RETURNS BOOL
BEGIN
    SELECT SUBSTRING_INDEX(fully_qualified_funcname,'.',1) INTO @the_db_name;
    SELECT SUBSTRING_INDEX(fully_qualified_funcname,'.',-1) INTO @the_func_name;
    IF ((SELECT COUNT(*)
         FROM information_schema.routines
         WHERE ROUTINE_TYPE = 'FUNCTION'
           AND ROUTINE_SCHEMA = @the_db_name 
    	   AND ROUTINE_NAME = @the_func_name) > 0)
   THEN
       RETURN 1;
   ELSE
       RETURN 0;
   END IF;
END//

#--------------------------
# grantExecuteIfExists
#---------------------

# Given a fully qualified function name, check whether
# the function exists. If it does, grant EXECUTE on it for
# everyone. Example: CALL grantExecuteIfExists('Edx.idInt2Anon');

DROP PROCEDURE IF EXISTS grantExecuteIfExists//
CREATE PROCEDURE grantExecuteIfExists(IN fully_qual_func_name varchar(255))
BEGIN
   IF functionExists(fully_qual_func_name)
   THEN
      SELECT CONCAT('GRANT EXECUTE ON FUNCTION ', fully_qual_func_name, " TO '%'@'%'")
        INTO @stmt;
      PREPARE stmt FROM @stmt;
      EXECUTE stmt;
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
# idInt2Forum
#------------

# Given a user_int_id, as used to id users
# in the platform tables, return 
# the corresponding user ID as used
# in the forum table.
# This function should live in EdxPrivate.

DROP FUNCTION IF EXISTS idInt2Forum//

CREATE FUNCTION idInt2Forum(intId int(11))
RETURNS varchar(40)
BEGIN
    DECLARE forumUid varchar(255);
    if @forumKey IS NULL
    THEN
       SELECT forumKey FROM EdxPrivate.Keys INTO @forumKey;
    END IF;
    SELECT HEX(AES_ENCRYPT(intId,@forumKey)) INTO forumUid;
    return forumUid;
END//

#--------------------------
# idForum2Anon
#-----------

# Given a Forum uid,  return 
# the corresponding user ID as used
# in tables other than the forum contents tbl.
# This function should live in EdxPrivate.

DROP FUNCTION IF EXISTS idForum2Anon//

CREATE FUNCTION idForum2Anon(forumId varchar(255))
RETURNS varchar(40)
BEGIN
    DECLARE theIntId INT;
    DECLARE anonId varchar(255);
    if @forumKey IS NULL
    THEN
       SELECT forumKey FROM EdxPrivate.Keys INTO @forumKey;
    END IF;
    SELECT AES_DECRYPT(UNHEX(forumId),@forumKey) INTO theIntId;
    SELECT idInt2Anon(theIntId) INTO anonId;
    return anonId;
END//

#--------------------------
# idForum2Int
#-----------

# Given a Forum uid,  return 
# the user int ID as used
# in platform tables.
# This function should live in EdxPrivate.

DROP FUNCTION IF EXISTS idForum2Int//

CREATE FUNCTION idForum2Int(forumId varchar(255))
RETURNS varchar(40)
BEGIN
    DECLARE theIntId INT;
    DECLARE anonId varchar(255);
    if @forumKey IS NULL
    THEN
       SELECT forumKey FROM EdxPrivate.Keys INTO @forumKey;
    END IF;
    SELECT AES_DECRYPT(UNHEX(forumId),@forumKey) INTO theIntId;
    return theIntId;
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
    DECLARE anonId varchar(255);
    SELECT anon_screen_name
    FROM EdxPrivate.UserGrade
    WHERE user_int_id  = intId
    INTO anonId;
    return anonId;
END//


#--------------------------
# idExt2Anon
#-----------

# Given the 32 char anonymized UID used
# for outside services, such as Qualtrix
# or Piazza, return the corresponding
# anon_screen_name. The 32 char uids are
# LTI: learning technology interchange.

DROP FUNCTION IF EXISTS idExt2Anon//

CREATE FUNCTION idExt2Anon(extId varchar(32)) 
RETURNS varchar(40)
BEGIN
      DECLARE anonId varchar(255);
      SELECT user_id INTO @int_id
      FROM edxprod.student_anonymoususerid
      WHERE anonymous_user_id = extId;

      SELECT idInt2Anon(@int_id) INTO anonId;
      return anonId;
END//


#--------------------------
# idAnon2Ext
#-----------

# External user ids are LTI based IDs used by
# the OpenEdX platform when participants are involved
# in Qualtrix or Piazza. In some cases, the platform
# creates one LTI for each participant, in other cases
# a separate LTI is created for each course the participant
# takes. Therefore there are two facilities for converting
# anon_screen_names to LTI (a.k.a. 'External') user ids:
# Function idAnon2Ext() takes an anon_screen_name, and 
# a course_display_name, and returns an external Id.
#
# Procedure idAnon2Exts() instead just takes an anon_screen_name,
# and fills a temporary memory table with all external uid/course name
# pairs.
#
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
#   SELECT idAnon2Ext('0686bef338f8c6f0696cc7d4b0650daf2473f59d', 'Engineering/CVX101/Winter2014');
#   should be: 5cbdc8b38171f3641845cb17784de87b

DROP FUNCTION IF EXISTS idAnon2Ext//
CREATE FUNCTION idAnon2Ext(the_anon_id varchar(255), course_display_name varchar(255))
RETURNS varchar(32)
BEGIN
      SELECT -1 INTO @int_id;
      SELECT user_int_id INTO @int_id
      FROM EdxPrivate.UserGrade
      WHERE anon_screen_name = the_anon_id;

      IF @int_id >= 0
      THEN
          SELECT anonymous_user_id AS extId INTO @extId
          FROM edxprod.student_anonymoususerid
          WHERE user_id = @int_id
	    AND course_id = course_display_name;
          RETURN @extId;
      ELSE
          RETURN null;
      END IF;

END//

#--------------------------
# idAnon2Exts
#------------

# External user ids are LTI based IDs used by
# the OpenEdX platform when participants are involved
# in Qualtrix or Piazza. In some cases, the platform
# creates one LTI for each participant, in other cases
# a separate LTI is created for each course the participant
# takes. Therefore there are two facilities for converting
# anon_screen_names to LTI (a.k.a. 'External') user ids:
# Function idAnon2Ext() takes an anon_screen_name, and 
# a course_display_name, and returns an external Id.
#
# Procedure idAnon2Exts() instead just takes an anon_screen_name,
# and fills a temporary memory table with all external uid/course name
# pairs. The procedure creates a temporary in-memory table of
# two columns:
#
#      ext_id, course_display_name
#
# The table is called ExtCourseTable, and is available after
# the procedure call returns. The table is wiped and renewed with
# every course. Each MySQL connection has its own temp table name space,
# so no collision with other connections occurs.
#
# This is a *procedure*, so syntax is:
#
#    CALL idAnon2Exts(anon_screen_name);
#
# NOTE: the procedure does print its result. But this result cannot
#       be used for further processing (a MySQL limitation). In particular
#       the following does NOT work: SELECT ext_id FROM (CALL idAnon2Exts(...));

DROP PROCEDURE IF EXISTS idAnon2Exts//
CREATE PROCEDURE idAnon2Exts(the_anon_id varchar(255))
BEGIN
      DROP TEMPORARY TABLE IF EXISTS ExtCourseTable;      

      SELECT -1 INTO @int_id;
      SELECT user_int_id INTO @int_id
      FROM EdxPrivate.UserGrade
      WHERE anon_screen_name = the_anon_id;

      IF @int_id >= 0
      THEN
          CREATE TEMPORARY TABLE ExtCourseTable engine=memory
          SELECT anonymous_user_id AS extId, course_id as course_display_name
          FROM edxprod.student_anonymoususerid
          WHERE user_id = @int_id;
      END IF;
 
      SELECT * FROM ExtCourseTable;

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

#--------------------------
# wordcount
#----------

# Returns number of words in argument. Usage example
#   SELECT SUM(wordcount(myCol)) FROM (SELECT myCol FROM myTable) AS Contents;
# returns the number of words in an entire text column.
# Taken from http://stackoverflow.com/questions/748276/using-sql-to-determine-word-count-stats-of-a-text-field

CREATE FUNCTION wordcount(str TEXT)
       RETURNS INT
       DETERMINISTIC
       SQL SECURITY INVOKER
       NO SQL
  BEGIN
    DECLARE wordCnt, idx, maxIdx INT DEFAULT 0;
    DECLARE currChar, prevChar BOOL DEFAULT 0;
    SET maxIdx=char_length(str);
    WHILE idx < maxIdx DO
        SET currChar=SUBSTRING(str, idx, 1) RLIKE '[[:alnum:]]';
        IF NOT prevChar AND currChar THEN
            SET wordCnt=wordCnt+1;
        END IF;
        SET prevChar=currChar;
        SET idx=idx+1;
    END WHILE;
    RETURN wordCnt;
  END
//

#--------------------------
# isTrueCourseName
#-----------------

# Takes a course_display_name, and returns 1 if the name is
# likely to be a true OpenEdX course name. Else returns 0.
# Filters out names that start with a digit, that contain the
# word 'text' as an element in a name triplet: foo/test/bar.
# Filters all known Stanford platform, team methods for 
# polluting the course name space. 
#
# Intended to be one of 'only' three places where this filter must
# be maintained. The other is open_edx_class_export/scripts/filterCourseNames.sh,
# which is used a filter in a Linux shell pipe, and 
# json_to_relation/scripts/modulestoreJavaScriptUtilsTest.js.

DROP FUNCTION IF EXISTS isTrueCourseName//
CREATE FUNCTION isTrueCourseName(course_display_name varchar(255))
RETURNS BOOL
BEGIN
    # Name starts with a zero?
    IF ((SELECT course_display_name REGEXP '^[0-9]') = 1)
    THEN
        RETURN 0; 
    END IF;
    SELECT LOWER(course_display_name) INTO @courseIDLowCase;
    IF ((SELECT @courseIDLowCase REGEXP 'jbau|janeu|sefu|davidu|caitlynx|josephtest|nickdupuniversity|nathanielu|gracelyou|sandbox|demo|sampleuniversity|.*zzz.*|/test/|joeU') = 1)
    THEN
        RETURN 0;
    END IF;
    RETURN 1;
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
	  ip_country,
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




# ------------- Drop Functions that are only for EdxPrivate DB -----

DROP FUNCTION IF EXISTS EdxPiazza.idForum2Anon;
DROP FUNCTION IF EXISTS EdxForum.idForum2Anon;
DROP FUNCTION IF EXISTS Edx.idForum2Anon;

DROP FUNCTION IF EXISTS EdxPiazza.idForum2Int;
DROP FUNCTION IF EXISTS EdxForum.idForum2Int;
DROP FUNCTION IF EXISTS Edx.idForum2Int;

# ------------- Grant EXECUTE Privileges for User Level Functions -----

CALL grantExecuteIfExists('Edx.idInt2Anon');
CALL grantExecuteIfExists('Edx.idAnon2Int');
CALL grantExecuteIfExists('Edx.idExt2Anon');
CALL grantExecuteIfExists('Edx.idAnon2Ext');
CALL grantExecuteIfExists('Edx.latestLog');
CALL grantExecuteIfExists('Edx.earliestLog');
CALL grantExecuteIfExists('Edx.isUserEvent');

CALL grantExecuteIfExists('EdxPrivate.idInt2Anon');
CALL grantExecuteIfExists('EdxPrivate.idAnon2Int');
CALL grantExecuteIfExists('EdxPrivate.idExt2Anon');
CALL grantExecuteIfExists('EdxPrivate.idAnon2Ext');
CALL grantExecuteIfExists('EdxPrivate.latestLog');
CALL grantExecuteIfExists('EdxPrivate.earliestLog');
CALL grantExecuteIfExists('EdxPrivate.isUserEvent');

CALL grantExecuteIfExists('EdxForum.idInt2Anon');
CALL grantExecuteIfExists('EdxForum.idAnon2Int');
CALL grantExecuteIfExists('EdxForum.idExt2Anon');
CALL grantExecuteIfExists('EdxForum.idAnon2Ext');
CALL grantExecuteIfExists('EdxForum.latestLog');
CALL grantExecuteIfExists('EdxForum.earliestLog');
CALL grantExecuteIfExists('EdxForum.isUserEvent');

CALL grantExecuteIfExists('EdxPiazza.idInt2Anon');
CALL grantExecuteIfExists('EdxPiazza.idAnon2Int');
CALL grantExecuteIfExists('EdxPiazza.idExt2Anon');
CALL grantExecuteIfExists('EdxPiazza.idAnon2Ext');
CALL grantExecuteIfExists('EdxPiazza.latestLog');
CALL grantExecuteIfExists('EdxPiazza.earliestLog');
CALL grantExecuteIfExists('EdxPiazza.isUserEvent');

CALL grantExecuteIfExists('unittest.idInt2Anon');
CALL grantExecuteIfExists('unittest.idAnon2Int');
CALL grantExecuteIfExists('unittest.idExt2Anon');
CALL grantExecuteIfExists('unittest.idAnon2Ext');
CALL grantExecuteIfExists('unittest.latestLog');
CALL grantExecuteIfExists('unittest.earliestLog');
CALL grantExecuteIfExists('unittest.isUserEvent');
