#!/bin/bash

# Takes a course name substring from the command line. Creates a new
# table in db 'Extracts' that contains rows from EdxTrackEvents whose
# course_display_name contains the command line argument as a
# substring. Use MySQL type wildcards.
#
# The destination database (default 'Extracts') can be controlled via
# the -d option. The database is created if it does not exist.
#
# The new table is called <Database>.<commandLineArgWithoutWildcard>,
# unless the -t option specifies a specific table name.  The new table
# is indexed on the same columns as EdxTrackEvent. If the table
# already exists, an error is indicated, and the script exists without
# having changed anything.  
#
# The default user under which the necessary mysql calls are made is
# the current user as returned by 'whoami'. If the -p option is given,
# that option's value is used as the MySQL uid. 
#
# If no password is provided, the script examines the current user's
# $HOME/.ssh directory for a file named 'mysql'. If that file exists, 
# its content is used as a MySQL password, else no password is used 
# for running MySQL.
#
# If the -p option is provided, the scripts requests a MySQL pwd on
# the command line.
#
# If the -a (--all-columns) option is provided, extracted table wil contain 
# all EdxTrackEvent columns plus any 'answer' field in the Answer table
# (left join EdxTrackEvent with Answer on EdxTrackEvent.answer_fk=Answer.answer_id)
# 
# Without the -a option, the new table will contain:
#    o anon_screen_name
#    o event_type
#    o ip
#    o time
#    o course_display_name
#    o resource_display_name
#    o success
#    o goto_from
#    o goto_dest
#    o attempts
#    o video_code
#    o video_current_time
#    o video_new_speed
#    o video_old_speed
#    o video_seek_type

USAGE="makeCourseExtract.sh [-u uid][-p][-d dbName][-t tableName][-a] courseNamePattern"

if [ $# -lt 1 ]
then
    echo $USAGE
    exit 1
fi

USERNAME=`whoami`
PASSWD=''
COURSE_SUBSTR=''
DB_NAME='Extracts'
needPasswd=false
TABLE_NAME=''
ALL_COLS=''

# Execute getopt
ARGS=`getopt -o "u:pd:t:a" -l "user:,password,database:,table:,all-columns" \
      -n "getopt.sh" -- "$@"`
 
#Bad arguments
if [ $? -ne 0 ];
then
  exit 1
fi
 
# A little magic
eval set -- "$ARGS"
 
# Now go through all the options
while true;
do
  case "$1" in
    -u|--user)
      shift
      # Grab the option value:
      if [ -n "$1" ]
      then
        USERNAME=$1
        shift
      fi;;
 
    -p|--password)
      needPasswd=true
      shift;;
 
    -d|--database)
      shift
      # Grab the option value:
      if [ -n "$1" ]
      then
        DB_NAME=$1
        shift
      fi;;

    -t|--table)
      shift
      # Grab the option value:
      if [ -n "$1" ]
      then
        TABLE_NAME=$1
        shift
      fi;;

    -a|--all-columns)
      ALL_COLS=true
      shift;;
 
    --)
      shift
      break;;
  esac
done

# Make sure one arg is left after
# all the shifting above: the search
# pattern for the course name:

if [ -z $1 ]
then
  echo $USAGE
  exit 1
fi
COURSE_SUBSTR=$1

if [ -z $TABLE_NAME ]
then
    TABLE_NAME=`echo "$COURSE_SUBSTR" | sed "s/[_%]//g"`
fi

if $needPasswd
then
    # The -s option suppresses echo:
    read -s -p "Password for user '$USERNAME' on `hostname`'s MySQL server: " PASSWD
    echo
else
    # Get home directory of whichever user will
    # log into MySQL:
    HOME_DIR=$(getent passwd $USERNAME | cut -d: -f6)
    # If the home dir has a readable file called mysql in its .ssh
    # subdir, then pull the pwd from there:
    if test -f $HOME_DIR/.ssh/mysql && test -r $HOME_DIR/.ssh/mysql
    then
	PASSWD=`cat $HOME_DIR/.ssh/mysql`
    fi
fi

#*************
# echo "Course substr: '$COURSE_SUBSTR'"
# echo "User: $USERNAME"
# echo "PWD: '$PASSWD'"
# echo "DB_NAME: '$DB_NAME'"
# if [ -z $PASSWD ]
# then
#     echo "PWD empty"
# else
#     echo "PWD full"
# fi
# echo "TABLE_NAME: $TABLE_NAME"
# if [ -n $ALL_COLS ]
# then
#   echo "ALL_COLS: only subset"
# else
#   echo "ALL_COLS: all"
# fi

# echo "COURSE_SUBSTR: $COURSE_SUBSTR"
#*************


if [ -n $ALL_COLS ]
then
  CREATION_CMD="CREATE DATABASE IF NOT EXISTS $DB_NAME; \
    CREATE TABLE $DB_NAME.$TABLE_NAME \
    SELECT Edx.EdxTrackEvent.anon_screen_name, \
	   Edx.EdxTrackEvent.event_type, \
	   Edx.EdxTrackEvent.ip, \
	   Edx.EdxTrackEvent.time, \
	   Edx.EdxTrackEvent.course_display_name, \
	   Edx.EdxTrackEvent.resource_display_name, \
	   Edx.EdxTrackEvent.success, \
	   Edx.EdxTrackEvent.goto_from, \
	   Edx.EdxTrackEvent.goto_dest, \
	   Edx.EdxTrackEvent.attempts, \
	   Edx.EdxTrackEvent.video_code, \
	   Edx.EdxTrackEvent.video_current_time, \
	   Edx.EdxTrackEvent.video_new_speed, \
	   Edx.EdxTrackEvent.video_old_speed, \
	   Edx.EdxTrackEvent.video_seek_type, \
           Edx.Answer.answer AS answer \
    FROM Edx.EdxTrackEvent \
    LEFT JOIN Edx.Answer \
    ON Edx.EdxTrackEvent.answer_fk=Edx.Answer.answer_id \
    WHERE Edx.EdxTrackEvent.course_display_name LIKE '$COURSE_SUBSTR';"
else
  CREATION_CMD="CREATE DATABASE IF NOT EXISTS $DB_NAME; \
    CREATE TABLE $DB_NAME.$TABLE_NAME \
    SELECT Edx.EdxTrackEvent.*, Edx.Answer.answer AS answer \
    FROM Edx.EdxTrackEvent \
    LEFT JOIN Edx.Answer \
    ON Edx.EdxTrackEvent.answer_fk=Edx.Answer.answer_id \
    WHERE Edx.EdxTrackEvent.course_display_name LIKE '$COURSE_SUBSTR';"
fi

#***************
#echo "$CREATION_CMD"
#exit
#***************

INDEXING_CMD="ALTER TABLE $DB_NAME.$TABLE_NAME \
    ADD PRIMARY KEY(_id), \
    ADD INDEX (anon_screen_name(40)), \
    ADD INDEX (event_type(255)), \
    ADD INDEX (ip(16)), \
    ADD INDEX (course_display_name(255)), \
    ADD INDEX (resource_display_name(255)), \
    ADD INDEX (success(15)), \
    ADD INDEX (time);
    ADD INDEX (answer);
    ADD INDEX (video_seek_type(32));"


#***************
#echo "$INDEXING_CMD"
#exit
#***************

#***************
###echo "TableExists?:$TABLE_EXISTS_TEST_WITH_PWD"
#echo "TableExists?:$TABLE_EXISTS_TEST_NO_PWD"
#exit
#***************

echo "Creating extract $DB_NAME.$TABLE_NAME ..."
# If the pwd is empty, don't issue -p to mysql:
if [ -z $PASSWD ]
then
    # Password empty...
    # Check whether the target table already exists, and
    # quit if so:
    TABLE_EXISTS=`echo "SELECT COUNT(*) FROM information_schema.tables \
  	                WHERE table_schema = '$DB_NAME' \
	                AND table_name = '$TABLE_NAME' LIMIT 1;" | mysql -u $USERNAME | grep 1`
    if [ "$TABLE_EXISTS" = "1" ]
    then
	echo "Table $DB_NAME.$TABLE_NAME already exists; aborting."
	exit 1
    fi
    echo "$CREATION_CMD" | mysql -u $USERNAME
    echo "Building indexes on the new extract..."
    echo "$INDEXING_CMD"  | mysql -u $USERNAME
else
    # Password not empty ...
    TABLE_EXISTS=`echo "SELECT COUNT(*) FROM information_schema.tables \
  	                WHERE table_schema = '$DB_NAME' \
	                AND table_name = '$TABLE_NAME' LIMIT 1;" | mysql -u $USERNAME -p$PASSWD | grep 1`
    if [ "$TABLE_EXISTS" = "1" ]
    then
	echo "Table $DB_NAME.$TABLE_NAME already exists; aborting."
	exit 1
    fi
    echo "$CREATION_CMD" | mysql -u $USERNAME -p$PASSWD
    echo "Building indexes on the new extract..."
    echo "$INDEXING_CMD"  | mysql -u $USERNAME -p$PASSWD
fi

echo "Done building $DB_NAME.$TABLE_NAME"
