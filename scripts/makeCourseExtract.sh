#!/bin/bash

# Takes a course name substring from the command line. Creates a new table
# in db 'Extracts' that contains rows from EdxTrackEvents whose
# course_display_name contains the command line argument as 
# a substring. The destination database (default Extracts) can be controlled via
# the -d option. The new table is called Extracts.<commandLineArg>,
# and is indexed on the same columns as EdxTrackEvent. The database
# 'Extracts', or the one named in the -d option is created if it 
# does not exist. If the table does exists, and error is indicated,
# and the script exists without having changed anything.
# If default user under which the necessary mysql calls are made
# is the current user as returned by whoami. If the -p option is given, 
# the user is prompted for a pwd. If the -p option is not given, the
# mysql user's home directory is searched for a file called mysql
# in subdirectory .ssh. If such a file is found, its contents are taken
# as the pwd for mysql. If such a file does not exist, the mysql calls
# will be attempted without a password, and will fail if a pwd is required.

USAGE="Usage: makeCourseExtract.sh [-u userName][-p] courseNameSubstring"

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

# Keep track of number of optional args the user provided:
NEXT_ARG=0
while getopts "u:d:p" opt
do
  case $opt in
    u)
      USERNAME=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    p)
      needPasswd=true
      NEXT_ARG=$((NEXT_ARG + 1))
      ;;
    d)
      DB_NAME=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    \?)
      # Illegal option; the getopts provided the error message
      echo $USAGE
      exit 1
      ;;
    :)
      # Not reliable: a -u w/o a username would swallow the db name.
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Shift past all the optional parms:
shift ${NEXT_ARG}

COURSE_SUBSTR=$1

if $needPasswd
then
    # The -s option suppresses echo:
    read -s -p "Password for user '$USERNAME' on MySQL server: " PASSWD
    echo
else
    # Get home directory of whichever user will
    # log into MySQL:
    HOME_DIR=$(getent passwd $USERNAME | cut -d: -f6)
    # If the home dir has a readable file called mysql in its .ssh
    # subdir, then pull the pwd from there:
    if test -f $HOME_DIR/.ssh/mysql && -r $HOME_DIR/.ssh/mysql
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
# exit
#*************


TABLE_NAME="$COURSE_SUBSTR"

CREATION_CMD="CREATE DATABASE IF NOT EXISTS $DB_NAME; \
  CREATE TABLE $DB_NAME.$TABLE_NAME \
  SELECT * \
  FROM Edx.EdxTrackEvent \
  WHERE course_display_name LIKE '%$TABLE_NAME%';"

#***************
#echo "$CREATION_CMD"
#exit
#***************

INDEXING_CMD="ALTER TABLE $DB_NAME.$TABLE_NAME \
    ADD PRIMARY KEY(_id), \
    ADD INDEX (answer_id(255)), \
    ADD INDEX (event_type(255)), \
    ADD INDEX (anon_screen_name(255)), \
    ADD INDEX (course_id(255)), \
    ADD INDEX (course_display_name(255)), \
    ADD INDEX (resource_display_name(255)), \
    ADD INDEX (sequence_id(255)), \
    ADD INDEX (problem_id(255)), \
    ADD INDEX (video_id(255)), \
    ADD INDEX (answer_id(255)), \
    ADD INDEX (success(15)), \
    ADD INDEX (time);"

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
	                AND table_name = '$TABLE_NAME' LIMIT 1;" | mysql -u $USERNAME -p$PASSWD| grep 1`
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
