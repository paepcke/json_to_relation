#!/bin/bash

# Delete all OpenEdX indexes in given table.
#
# Optionally given one or more table names in the Edx 
# or EdxPrivate databases, create the indexes that are 
# needed for those tables. If no tables are given,
# will delete the indexes for all tables.

usage="Usage: "`basename $0`" [-u username][-p] [tableName [tableName ...]]"

USERNAME=`whoami`
PASSWD=''
askForPasswd=false

# -------------------  Process Commandline Option -----------------                

# Check whether given -pPassword, i.e. fused -p with a 
# pwd string:

for arg in $@
do
   # The sed -r option enables extended regex, which
   # makes the '+' metachar wor. The -n option
   # says to print only if pattern matches:
   PASSWD=`echo $arg | sed -r -n 's/-p(.+)/\1/p'`
   if [ -z $PASSWD ]
   then
       continue
   else
       #echo "Pwd is:"$PASSWD
       break
   fi
done


# Keep track of number of optional args the user provided:
NEXT_ARG=0
while getopts ":u:p" opt
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
      # If the $PASSWD is set, we *assume* that 
      # the unrecognized option was a
      # -pMyPassword, and don't signal
      # an error. Therefore, if $PASSWD is 
      # set then illegal options are quietly 
      # ignored:
      if [ ! -z $PASSWD ]
      then 
	  continue
      else
	  echo $USAGE
	  exit 1
      fi
      ;;
    :)
      echo $USAGE
      exit 1
      ;;
  esac
done

# Shift past all the optional parms:
shift ${NEXT_ARG}


if $askForPasswd && [ -z $PASSWD ]
then
    # The -s option suppresses echo:
    read -s -p "Password for $USERNAME on MySQL server: " PASSWD
    echo
elif [ -z $PASSWD ]
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
	    PASSWD=`cat $HOME_DIR/.ssh/mysql_root`
	fi
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
fi

# Create the mysql call password option:
if [ -z $PASSWD ]
then
    pwdOption=''
else
    pwdOption='-p'$PASSWD
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
            ["ActivityGrade"]="Edx" \
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
# echo "Password: '"$PASSWD"'"
# echo 'Tables to index: '$tables
# echo "pwdOption: '"$pwdOption"'"
# exit 0
#*****************

for table in ${tables[@]}
do
    if [ $table == 'EdxTrackEvent' ]
    then
	echo "Creating empty tbl shaped like EdxTrackEvent..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CREATE TABLE EdxTrackEvent_New LIKE EdxTrackEvent;"
	echo "Dropping all indexes in new, empty table..."

	echo "Dropping index  EdxTrackEvent(event_type)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX EdxTrackEventIdxEvType ON EdxTrackEvent_New;"
	echo "Dropping index  EdxTrackEvent(anon_screen_name)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX EdxTrackEventIdxIdxUname ON EdxTrackEvent_New;"
	echo "Dropping index  EdxTrackEvent(course_id)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX EdxTrackEventIdxCourseID ON EdxTrackEvent_New;"
	echo "Dropping index  EdxTrackEvent(course_display_name)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX EdxTrackEventIdxCourseDisplayName ON EdxTrackEvent_New;"
	echo "Dropping index  EdxTrackEvent(resource_display_name)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX EdxTrackEventIdxResourceDisplayName ON EdxTrackEvent_New;"
	echo "Dropping index  EdxTrackEvent(success)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX EdxTrackEventIdxSuccess ON EdxTrackEvent_New;"

	echo "Dropping index  EdxTrackEvent(time)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX EdxTrackEventIdxTime ON EdxTrackEvent_New;"
	echo "Dropping index  EdxTrackEvent(quarter)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX EdxTrackEventIdxQuarter ON EdxTrackEvent_New;"
	echo "Dropping index  EdxTrackEvent(ip)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX EdxTrackEventIdxIP ON EdxTrackEvent_New;"
	echo "Dropping index  EdxTrackEvent(course_display_name,time)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX EdxTrackEventIdxCourseNameTime ON EdxTrackEvent_New;"
	echo "Dropping index  EdxTrackEvent(video_id)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX EdxTrackEventIdxVideoId ON EdxTrackEvent_New;"

	echo "Copying old EdxTrackEvent content to EdxTrackEvent_New..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; INSERT INTO EdxTrackEvent_New SELECT * FROM EdxTrackEvent;"

	echo "Dropping old EdxTrackEvent..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP TABLE EdxTrackEvent;"
	
	echo "Renaming EdxTrackEvent_New to EdxTrackEvent..."
	mysql -u $USERNAME $pwdOption -e "USE Edx;  ALTER TABLE EdxTrackEvent_New RENAME TO EdxTrackEvent;"

	echo "Deleted all indexes from EdxTrackEvent..."
	

    elif [ $table == 'Answer' ]
    then
	echo "Creating empty tbl shaped like Answer..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CREATE TABLE Answer_New LIKE Answer;"
	echo "Dropping all indexes in new, empty table..."

	echo "Dropping index  Answer(answer)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX AnswerIdxAns ON Answer_New;"
	echo "Dropping index  Answer(course_id)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX AnswerIdxCourseID ON Answer_New;"

	echo "Copying old Answer content to Answer_New..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; INSERT INTO Answer_New SELECT * FROM Answer;"

	echo "Dropping old Answer..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP TABLE Answer;"
	
	echo "Renaming Answer_New to Answer..."
	mysql -u $USERNAME $pwdOption -e "USE Edx;  ALTER TABLE Answer_New RENAME TO Answer;"

	echo "Deleted all indexes from Answer..."


    elif [ $table == 'Account' ]
    then

	echo "Creating empty tbl shaped like Account..."
	mysql -u $USERNAME $pwdOption -e "USE EdxPrivate; CREATE TABLE Account_New LIKE Account;"
	echo "Dropping all indexes in new, empty table..."

	echo "Dropping index  Account(screen_name)..."
	mysql -u $USERNAME $pwdOption -e "USE EdxPrivate; DROP INDEX AccountIdxUname ON Account_New;"
	echo "Dropping index  Account(anon_screen_name)..."
	mysql -u $USERNAME $pwdOption -e "USE EdxPrivate; DROP INDEX AccountIdxAnonUname ON Account_New;"
	echo "Dropping index  Account(zipcode)..."
	mysql -u $USERNAME $pwdOption -e "USE EdxPrivate; DROP INDEX AccountIdxZip ON Account_New;"
	echo "Dropping index  Account(country)..."
	mysql -u $USERNAME $pwdOption -e "USE EdxPrivate; DROP INDEX AccountIdxCoun ON Account_New;"
	echo "Dropping index  Account(gender)..."
	mysql -u $USERNAME $pwdOption -e "USE EdxPrivate; DROP INDEX AccountIdxGen ON Account_New;"
	echo "Dropping index  Account(year_of_birth'.."
	mysql -u $USERNAME $pwdOption -e "USE EdxPrivate; DROP INDEX AccountIdxDOB ON Account_New;"
	echo "Dropping index  Account(level_of_education)..."
	mysql -u $USERNAME $pwdOption -e "USE EdxPrivate; DROP INDEX AccountIdxEdu ON Account_New;"
	echo "Dropping index  Account(course_id)..."
	mysql -u $USERNAME $pwdOption -e "USE EdxPrivate; DROP INDEX AccountIdxCouID ON Account_New;"

	echo "Copying old Account content to Account_New..."
	mysql -u $USERNAME $pwdOption -e "USE EdxPrivate; INSERT INTO Account_New SELECT * FROM Account;"

	echo "Dropping old Account..."
	mysql -u $USERNAME $pwdOption -e "USE EdxPrivate; DROP TABLE Account;"
	
	echo "Renaming Account_New to Account..."
	mysql -u $USERNAME $pwdOption -e "USE EdxPrivate;  ALTER TABLE Account_New RENAME TO Account;"

	echo "Deleted all indexes from Account..."


    elif [ $table == 'ActivityGrade' ]
    then

	echo "Creating empty tbl shaped like ActivityGrade..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; CREATE TABLE ActivityGrade_New LIKE ActivityGrade;"
	echo "Dropping all indexes in new, empty table..."

	echo "Dropping index ActivityGrade(anon_screen_name)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX ActGrdAnonSNIdx ON ActivityGrade_New;"
	echo "Dropping index ActivityGrade(course_display_name)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX ActGrdCourseDisNmIdx  ON ActivityGrade_New;"
	echo "Dropping index ActivityGrade(module_id)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX ActGrdModIdIdx ON ActivityGrade_New;"
	echo "Dropping index ActivityGrade(resource_display_name)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX ActGrdResDispNmIdx ON ActivityGrade_New;"
	echo "Dropping index ActivityGrade(last_submit)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX ActGrdLastSubmitIdx ON ActivityGrade_New;"
	echo "Dropping index ActivityGrade(num_attempts)..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP INDEX ActGrdNumAttemptsIdx ON ActivityGrade_New;"

	echo "Copying old ActivityGrade content to ActivityGrade_New..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; INSERT INTO ActivityGrade_New SELECT * FROM ActivityGrade;"

	echo "Dropping old ActivityGrade..."
	mysql -u $USERNAME $pwdOption -e "USE Edx; DROP TABLE ActivityGrade;"
	
	echo "Renaming ActivityGrade_New to ActivityGrade..."
	mysql -u $USERNAME $pwdOption -e "USE Edx;  ALTER TABLE ActivityGrade_New RENAME TO ActivityGrade;"

	echo "Deleted all indexes from ActivityGrade..."

    fi
done
