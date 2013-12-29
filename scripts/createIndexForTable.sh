#!/bin/bash

# NOTE: this script is only used for repairs when entire
#       tables had to be deleted, and were then loaded
#       (and thereby created) from scratch. In that case
#       all the indexes would be missing. No need to
#       use this script after using manageEdxDb.sh
# Optionally given one or more table names in the Edx 
# or EdxPrivate databases, create the indexes that are 
# needed for those tables. If no tables are given,
# will create the indexes for all tables.

usage="Usage: `basename $0` [-u username][-p] [tableName [tableName ...]]"

USERNAME=`whoami`
askForPasswd=false

# Keep track of number of optional args the user provided:
NEXT_ARG=0
while getopts "u:p" opt
do
  case $opt in
    u) # look in given user's HOME/.ssh/ for mysql_root
      USERNAME=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    p) # ask for mysql root pwd
      askForPasswd=true
      NEXT_ARG=$((NEXT_ARG + 1))
      ;;
    \?)
      # Illegal option; the getopts provided the error message
      echo $USAGE
      exit 1
      ;;
    :)
      echo $USAGE
      exit 1
      ;;
  esac
done

# Shift past all the optional parms:
shift ${NEXT_ARG}


if $askForPasswd
then
    # The -s option suppresses echo:
    read -s -p "Password for $USERNAME on MySQL server: " password
    echo
elif [ -z $password ]
then
    if [ $USERNAME == "root" ]
    then
        # Get home directory of whichever user will
        # log into MySQL:
	HOME_DIR=$(getent passwd `whoami` | cut -d: -f6)
        # If the home dir has a readable file called mysql_root in its .ssh
        # subdir, then pull the pwd from there:
	if test -f $HOME_DIR/.ssh/mysql_root && test -r $HOME_DIR/.ssh/mysql_root
	then
	    password=`cat $HOME_DIR/.ssh/mysql_root`
	fi
    else
        # Get home directory of whichever user will
        # log into MySQL:
	HOME_DIR=$(getent passwd $USERNAME | cut -d: -f6)

        # If the home dir has a readable file called mysql in its .ssh
        # subdir, then pull the pwd from there:
	if test -f $HOME_DIR/.ssh/mysql && test -r $HOME_DIR/.ssh/mysql
	then
	    password=`cat $HOME_DIR/.ssh/mysql`
	fi
    fi
fi

# Create the mysql call password option:
if [ -z $password ]
then
    pwdOption=''
else
    pwdOption='-p$password'
fi

# Dict of tables and the db names in which they reside.
# Use a bash associative array (like a Python dict):
declare -A allTables
allTables=( ["EdxTrackEvent"]="Edx" \
            ["Answer"]="Edx" \
            ["CorrectMap"]="Edx" \
            ["InputState"]="Edx" \
            ["LoadInfo"]="Edx" \
            ["State"]="Edx" \
            ["Account"]="EdxPrivate" \
    )

# If no table name was given, create the appropriate indexes
# for all the tables:

if [ $# -lt 1 ]
then
    # No tables provided on CL; use the keys of
    # the tables dict (the ! chooses 'all keys';
    # without the ! would choose all values):
    tables=${!allTables[@]}
else
    tables=$@
fi

#*****************
# echo 'UID: '$USERNAME
# echo "Password: '"$password"'"
# echo 'Tables to index: '$tables
# echo "pwdOption: '"$pwdOption"'"
# exit 0
#*****************

for table in ${tables[@]}
do
    if [ $table == 'EdxTrackEvent' ]
    then
	# The '${allTables["$table"]}' parts below resolve to the database in which the respective table resides:
	echo "Creating index on EdxTrackEvent(event_type) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxEvType', '"${allTables[$table]}".EdxTrackEvent', 'event_type', 255);"
	echo "Creating index on EdxTrackEvent(anon_screen_name) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxIdxUname', '"${allTables[$table]}".EdxTrackEvent', 'anon_screen_name', 255);"
	echo "Creating index on EdxTrackEvent(course_id) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxCourseID', '"${allTables[$table]}".EdxTrackEvent', 'course_id', 255);"
	echo "Creating index on EdxTrackEvent(course_display_name) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxCourseDisplayName', '"${allTables[$table]}".EdxTrackEvent', 'course_display_name', 255);"
	echo "Creating index on EdxTrackEvent(resource_display_name) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxResourceDisplayName', '"${allTables[$table]}".EdxTrackEvent', 'resource_display_name', 255);"
	echo "Creating index on EdxTrackEvent(success) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxSuccess', '"${allTables[$table]}".EdxTrackEvent', 'success', 15);"
	echo "Creating index on EdxTrackEvent(time) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxTime', '"${allTables[$table]}".EdxTrackEvent', 'time', NULL);"
	echo "Creating index on EdxTrackEvent(ip) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxIP', '"${allTables[$table]}".EdxTrackEvent', 'ip', 16);"
    elif [ $table == 'Answer' ]
    then
	echo "Creating index on Answer(answer) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('AnswerIdxAns', '"${allTables[$table]}".Answer', 'answer', 255);"
	echo "Creating index on Answer(course_id) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('AnswerIdxCourseID', '"${allTables[$table]}".Answer', 'course_id', 255);"
    elif [ $table == 'Account' ]
    then
	echo "Creating index on Account(screen_name) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('AccountIdxUname', '"${allTables[$table]}".Account', 'screen_name', 255);"
	echo "Creating index on Account(anon_screen_name) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('AccountIdxAnonUname', '"${allTables[$table]}".Account', 'anon_screen_name', 255);"
	echo "Creating index on Account(zipcode) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('AccountIdxZip', '"${allTables[$table]}".Account', 'zipcode', 10);"
	echo "Creating index on Account(country) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('AccountIdxCoun', '"${allTables[$table]}".Account', 'country', 255);"
	echo "Creating index on Account(gender) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('AccountIdxGen', '"${allTables[$table]}".Account', 'gender', 6);"
	echo "Creating index on Account(year_of_birth'.."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('AccountIdxDOB', '"${allTables[$table]}".Account', 'year_of_birth', NULL);"
	echo "Creating index on Account(level_of_education) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('AccountIdxEdu', '"${allTables[$table]}".Account', 'level_of_education', 10);"
	echo "Creating index on Account(course_id) if needed..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CALL createIndexIfNotExists('AccountIdxCouID', '"${allTables[$table]}".Account', 'course_id', 255);"
    fi
done
