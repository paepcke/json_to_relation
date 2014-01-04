# Stored procedures used for administering the Edx
# tracking log database and others.

# NOTE: these functions and procedures need to be
#       defined in both the Edx and EdxPrivate
#       databases. I tried defining them once
#       in Edx, and then replicating a row
#       in mysql.proc, changing only the database
#       column content. But it got to crufty, and
#       vulnerable to future MySQL version mods.
#
#       Instead this file is 'source'ed into 
#       MySQL twice by defineMySQLProcedures.sh.

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


# Restore standard delimiter:
delimiter ;
