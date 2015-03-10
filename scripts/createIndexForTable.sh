#!/bin/bash

# NOTE: this script is only used in two situations:
#       1. for repairs when entire
#          tables had to be deleted, and were then loaded
#          (and thereby created) from scratch. In that case
#          all the indexes would be missing. No need to
#          use this script if using manageEdxDb.sh
#       2. when manageEdxDb.py loads new events 
#          it disables indexes to speed up the load.
#          When loading finishes, indexes need to be
#          rebuilt to reflect the additional rows.
#
# Optionally given one or more table names in the Edx 
# or EdxPrivate databases, create the indexes that are 
# needed for those tables. If no tables are given,
# will create the indexes for all tables.

usage="Usage: "`basename $0`" [-h][-u username][-p] [tableName [tableName ...]]"
help="Create indexes for one or more Edx/EdxPrivate tables. No argument: all indexes for all tables."

# Get MySQL version on this machine
MYSQL_VERSION=$(mysql --version | sed -ne 's/.*Distrib \([0-9][.][0-9]\).*/\1/p')
if [[ $MYSQL_VERSION > 5.5 ]]
then 
    MYSQL_VERSION='5.6+'
else 
    MYSQL_VERSION='5.5'
fi

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
    h) # help
      echo $help
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
            ["ABExperiment"]="Edx" \
            ["OpenAssessment"]="Edx" \
            ["Account"]="EdxPrivate" \
            ["UserCountry"]="Edx" \
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

# Build a variable MYSQL_AUTH that depends on
# the MySQL server version. Versions <5.6 use
#   -u $USERNAME $pwdOption
# For newer servers we use --login-path=root 

if [[ $MYSQL_VERSION == '5.6+' ]]
then
    MYSQL_AUTH="--login-path=root"
else
    MYSQL_AUTH="-u $USERNAME $pwdOption"
fi


for table in ${tables[@]}
do
    if [ $table == 'EdxTrackEvent' ]
    then
	# The '${allTables["$table"]}' parts below resolve to the database in which the respective table resides:

	# If creating indexes on an already populated table, you would
	# use the following for increased efficiency (one statement for
	# all indexes). But if any of the index(es) exists, I think 
	# this statement would bomb. So we instead use the form below,
	# with one statement per index. On an empty table this is perfectly
	# fast:
	    # echo "Creating index on EdxTrackEvent(event_type) if needed..."
	    # mysql -u $USERNAME $pwdOption Edx -e "ALTER TABLE EdxTrackEvent
	    #   ADD INDEX EdxTrackEventIdxEvType (event_type(255)),
	    #   ADD INDEX EdxTrackEventIdxIdxUname (anon_screen_name(40)),
	    #   ADD INDEX EdxTrackEventIdxCourseDisplayName (course_display_name(255)),
	    #   ADD INDEX EdxTrackEventIdxResourceDisplayName (resource_display_name(255)),
	    #   ADD INDEX EdxTrackEventIdxSuccess (success(15)),
	    #   ADD INDEX EdxTrackEventIdxTime (time),
	    #   ADD INDEX EdxTrackEventIdxIP (ip_country(3)),
	    #   ADD INDEX EdxTrackEventIdxCourseNameTime (course_display_name,time),
	    #   ADD INDEX EdxTrackEventIdxVideoId (video_id(255));
	    # COMMIT;"

	echo "Creating index on EdxTrackEvent(event_type) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxEvType', 'EdxTrackEvent', 'event_type', 255);"
	echo "Creating index on EdxTrackEvent(anon_screen_name) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxIdxUname', 'EdxTrackEvent', 'anon_screen_name', 40);"
	echo "Creating index on EdxTrackEvent(course_display_name) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxCourseDisplayName', 'EdxTrackEvent', 'course_display_name', 255);"
	echo "Creating index on EdxTrackEvent(resource_display_name) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxResourceDisplayName', 'EdxTrackEvent', 'resource_display_name', 255);"
	echo "Creating index on EdxTrackEvent(success) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxSuccess', 'EdxTrackEvent', 'success', 15);"
	echo "Creating index on EdxTrackEvent(time) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxTime', 'EdxTrackEvent', 'time', NULL);"
	echo "Creating index on EdxTrackEvent(quarter) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxQuarter', 'EdxTrackEvent', 'quarter', NULL);"
	echo "Creating index on EdxTrackEvent(ip) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxIP', 'EdxTrackEvent', 'ip_country', 3);"
	echo "Creating index on EdxTrackEvent(course_display_name,time) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxCourseNameTime', 'EdxTrackEvent', 'course_display_name,time', NULL);"
	echo "Creating index on EdxTrackEvent(video_id) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxVideoId', 'EdxTrackEvent', 'video_id', 255);"
	echo "Creating index on EdxTrackEvent(video_code) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('EdxTrackEventIdxVideoCode', 'EdxTrackEvent', 'video_code', 255);"

    elif [ $table == 'Answer' ]
    then
	echo "Creating index on Answer(answer) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('AnswerIdxAns', 'Answer', 'answer', 255);"
	echo "Creating index on Answer(course_id) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('AnswerIdxCourseID', 'Answer', 'course_id', 255);"

    elif [ $table == 'Account' ]
    then
	echo "Creating index on Account(screen_name) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE EdxPrivate; CALL createIndexIfNotExists('AccountIdxUname', 'Account', 'screen_name', 255);"
	echo "Creating index on Account(anon_screen_name) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE EdxPrivate; CALL createIndexIfNotExists('AccountIdxAnonUname', 'Account', 'anon_screen_name', 40);"
	echo "Creating index on Account(zipcode) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE EdxPrivate; CALL createIndexIfNotExists('AccountIdxZip', 'Account', 'zipcode', 10);"
	echo "Creating index on Account(country) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE EdxPrivate; CALL createIndexIfNotExists('AccountIdxCoun', 'Account', 'country', 255);"
	echo "Creating index on Account(gender) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE EdxPrivate; CALL createIndexIfNotExists('AccountIdxGen', 'Account', 'gender', 6);"
	echo "Creating index on Account(year_of_birth'..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE EdxPrivate; CALL createIndexIfNotExists('AccountIdxDOB', 'Account', 'year_of_birth', NULL);"
	echo "Creating index on Account(level_of_education) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE EdxPrivate; CALL createIndexIfNotExists('AccountIdxEdu', 'Account', 'level_of_education', 10);"
	echo "Creating index on Account(course_id) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE EdxPrivate; CALL createIndexIfNotExists('AccountIdxCouID', 'Account', 'course_id', 255);"

    elif [ $table == 'ActivityGrade' ]
    then
	echo "Creating index on ActivityGrade(last_submit) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('activityGradeLast_submitIdx', 'ActivityGrade', 'last_submit', NULL);"
	echo "Creating index on ActivityGrade(ActGrdAnonSNIdx) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('ActGrdAnonSNIdx', 'ActivityGrade', 'anon_screen_name', 40);"
	echo "Creating index on ActivityGrade(course_display_name) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('ActGrdCourseDisNmIdx', 'ActivityGrade', 'course_display_name', 255);"
	echo "Creating index on ActivityGrade(module_id) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('ActGrdModIdIdx', 'ActivityGrade', 'module_id', 255);"
	echo "Creating index on ActivityGrade(resource_display_name) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('ActGrdResDispNmIdx', 'ActivityGrade', 'resource_display_name', 255);"
	echo "Creating index on ActivityGrade(num_attempts) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('ActGrdNumAttemptsIdx', 'ActivityGrade', 'num_attempts', NULL);"
    elif [ $table == 'ABExperiment' ]	
    then
	echo "Creating index on ABExperiment(event_type) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('ABExpEventTypeIdx', 'ABExperiment', 'event_type', NULL);"
	echo "Creating index on ABExperiment(group_id) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('ABExpGrpIdIdx', 'ABExperiment', 'group_id', NULL);"
	echo "Creating index on ABExperiment(course_display_name) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('ABExpGrpNmIdx', 'ABExperiment', 'group_name', 255);"
	echo "Creating index on ABExperiment(module_id) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('ABExpPartIdIdx', 'ABExperiment', 'partition_id', NULL);"
	echo "Creating index on ABExperiment(resource_display_name) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('ABExpPartNmIdx', 'ABExperiment', 'partition_name', 255);"
	echo "Creating index on ABExperiment(num_attempts) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('ABExpChldModIdIdx', 'ABExperiment', 'child_module_id', 255);"

    elif [ $table == 'OpenAssessment' ]	
    then
	echo "Creating index on OpenAssessment(event_type) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('OpAssEvTypeIdx', 'OpenAssessment', 'event_type', 255);"
	echo "Creating index on OpenAssessment(anon_screen_name) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('OpAssAnonScNmIdx', 'OpenAssessment', 'anon_screen_name', 40);"
	echo "Creating index on OpenAssessment(score_type) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('OpAssScoreTpIdx', 'OpenAssessment', 'score_type', 255);"
	echo "Creating index on OpenAssessment(time) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('OpAssTimeIdx', 'OpenAssessment', 'time', NULL);"
	echo "Creating index on OpenAssessment(submission_uuid) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('OpAssSubmIdIdx', 'OpenAssessment', 'submission_uuid', 40);"
	echo "Creating index on OpenAssessment(edx_anon_id) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('OpAssEdxAnonIdx', 'OpenAssessment', 'edx_anon_id', 40);"
	echo "Creating index on OpenAssessment(course_display_name) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('OpAssCrsNmIdx', 'OpenAssessment', 'course_display_name', 255);"
	echo "Creating index on OpenAssessment(resource_display_name) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('OpAssRrcDispNmIdx', 'OpenAssessment', 'resource_display_name', 255);"
	echo "Creating index on OpenAssessment(resource_id) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('OpAssRscIdIdx', 'OpenAssessment', 'resource_id', 255);"
	echo "Creating index on OpenAssessment(attempt_num) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('OpAssAttNumNmIdx', 'OpenAssessment', 'attempt_num', NULL);"
	echo "Creating index on OpenAssessment(options) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('OpAssOptsIdx', 'OpenAssessment', 'options', 255);"
	echo "Creating index on OpenAssessment(corrections) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('OpAssCorrIdx', 'OpenAssessment', 'corrections', 40);"
	echo "Creating index on OpenAssessment(points) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('OpAssPtsidx', 'OpenAssessment', 'points', 40);"

    elif [ $table == 'UserCountry' ]
    then
	echo "Creating index on UserCountry(anon_screen_name) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('UserCountryIdxAnon', 'UserCountry', 'anon_screen_name', 40);"
	echo "Creating index on UserCountry(three_letter_country) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('UserCountryIdx3LtrCntry', 'UserCountry', 'three_letter_country', 3);"
	echo "Creating index on UserCountry(two_letter_country) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('UserCountryIdx2LtrCntry', 'UserCountry', 'two_letter_country', 2);"
	echo "Creating index on UserCountry(country) if needed..."
	mysql $MYSQL_AUTH --silent --skip-column-names -e "USE Edx; CALL createIndexIfNotExists('UserCountryIdxCntry', 'UserCountry', 'country', 255);"

	# Three fulltext indexes are created (if needed) here
	# as opposed to using function createIndexIfNotExists()
	# b/c that function isn't written to consider fulltext
	# indexing:

	# MySQL complains that FULLTEXT not available for MyISAM:
	# indxExists=$(mysql --silent $MYSQL_AUTH -e "USE Edx; SELECT indexExists('OpenAssessment','submission_text');")
	# if [[ $indxExists == 0 ]]
	# then
	#     echo "Creating index on OpenAssessment(submission_text) (fulltext)..."
	#     mysql $MYSQL_AUTH -e "USE Edx; CREATE FULLTEXT INDEX OpAssSubmTxtIdx ON OpenAssessment(submission_text);"
	# fi
	# indxExists=$(mysql --silent $MYSQL_AUTH -e "USE Edx; SELECT indexExists('OpenAssessment','feedback_text');")
	# if [[ $indxExists == 0 ]]
	# then
	#     echo "Creating index on OpenAssessment(feedback_text) (fulltext)..."
	#     mysql $MYSQL_AUTH -e "USE Edx; CREATE FULLTEXT INDEX OpAssFeedbkTxtIdx ON OpenAssessment(feedback_text);"
        # fi
	# indxExists=$(mysql --silent $MYSQL_AUTH -e "USE Edx; SELECT indexExists('OpenAssessment','comment_text');")
	# if [[ $indxExists == 0 ]]
	# then
	#     echo "Creating index on OpenAssessment(comment_text) (fulltext)..."
	#     mysql $MYSQL_AUTH -e "USE Edx; CREATE FULLTEXT INDEX OpAssCommentTxtIdx ON OpenAssessment(comment_text);"
        # fi
    fi
done
