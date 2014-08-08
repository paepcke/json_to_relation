#!/bin/bash

# Specific to Stanford installation.
# Refreshes the EdxPrivate.UserGrade table. Logs into edxprod via
# goldengate.class.stanford.edu, and retrieves a subset of
# columns from tables auth_user and certificates_generatedcertificate. Drops
# the local EdxPrivate.UserGrade table, and recreates it empty.
# Loads the auth_user/certificates_generatedcertificate excerpt into 
# the local MySQL's EdxPrivate.UserGrade table, and creates
# indexes.
#
# To figure out what all the preliminary sections do,
# uncomment the lines between '#***********'; then
# invoke the script with various combinations of 
# user ids and pwds on the commandline.

USAGE='Usage: '`basename $0`' [-u localMySQLUser][-s remoteMySQLUser][-p][-pLocalMySQLPwd][-r][-rRemoteMySQLPwd]'

# If option -p is provided, script will request password for
# local MySQL db.
# if option -r is provided, script will request password for
# remote edxprod repository off goldengate.

MYSQL_PWD=''
LOG_FILE=/home/dataman/Data/EdX/NonTransformLogs/refreshActivityGradeTable.log
USERNAME=`whoami`
needLocalPasswd=false
# Get directory in which this script is running,
# and where its support scripts therefore live:
currScriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -f $LOG_FILE ]
then
    # Create directories to log file as needed:
    DIR_PART_LOG_FILE=`dirname $LOG_FILE`
    mkdir --parents $DIR_PART_LOG_FILE
    touch $LOG_FILE
fi

# ------------------ Process Commandline Options -------------------

# Check whether given -pPassword, i.e. fused -p with a 
# pwd string:

for arg in $@
do
   # The sed -r option enables extended regex, which
   # makes the '+' metachar wor. The -n option
   # says to print only if pattern matches:
   MYSQL_PWD=`echo $arg | sed -r -n 's/-p(.+)/\1/p'`
   if [ -z $MYSQL_PWD ]
   then
       continue
   else
       #echo "MYSQL_PWD is:"$MYSQL_PWD
       break
   fi
done

# Now check for '-p' and '-r' without explicit pwd;
# the leading colon in options causes wrong options
# to drop into \? branch:
NEXT_ARG=0

while getopts ":pu:" opt
do
  case $opt in
    p)
      needLocalPasswd=true
      NEXT_ARG=$((NEXT_ARG + 1))
      ;;
    u)
      USERNAME=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    \?)
      # If $MYSQL_PWD is set, we *assume* that 
      # the unrecognized option was a
      # -pMyPassword and don't signal
      # an error. Therefore, if $MYSQL_PWD is set
      # and *then* an illegal option
      # is on the command line, it is quietly
      # ignored:
      if [ ! -z $MYSQL_PWD ]
      then 
	  continue
      else
	  echo $USAGE
	  exit 1
      fi
      ;;
  esac
done

# Shift past all the optional parms:
shift ${NEXT_ARG}

# ------------------ Ask for Passwords if Requested on CL -------------------

# Ask for local pwd, unless was given
# a fused -pLocalPWD:
if $needLocalPasswd && [ -z $MYSQL_PWD ]
then
    # The -s option suppresses echo:
    read -s -p "Password for "$USERNAME" on local MySQL server: " MYSQL_PWD
    echo
elif [ -z $MYSQL_PWD ]
then
    # Get home directory of whichever user will
    # log into MySQL:
    HOME_DIR=$(getent passwd $USERNAME | cut -d: -f6)
    # If the home dir has a readable file called mysql_root in its .ssh
    # subdir, then pull the pwd from there:
    if test -f $HOME_DIR/.ssh/mysql && test -r $HOME_DIR/.ssh/mysql
    then
	MYSQL_PWD=`cat $HOME_DIR/.ssh/mysql`
    fi
fi

#**********
# echo 'Local MySQL uid: '$USERNAME
# echo 'Local MySQL pwd: '$MYSQL_PWD
# exit 0
#**********

# ------------------ Signin -------------------
echo `date`": Start updating table ActivityGrade..."  | tee --append $LOG_FILE

# ----------------- Find Newest Entry in Local ActivityGrade Table ------------------

if [ ! -z $MYSQL_PWD ]
then
    mysql -u $USERNAME -p$MYSQL_PWD < $currScriptsDir/cronRefreshActivityGradeCrTable.sql
    LATEST_DATE=`mysql -u $USERNAME -p$MYSQL_PWD --silent --skip-column-names Edx -e \
	  "SELECT MAX(last_submit) FROM ActivityGrade;"`
else
    mysql -u $USERNAME  < $currScriptsDir/cronRefreshActivityGradeCrTable.sql
    LATEST_DATE=`mysql -u $USERNAME --silent --skip-column-names Edx -e \
	  "SELECT MAX(last_submit) FROM ActivityGrade;"`
fi

if [ $LATEST_DATE = NULL ]
then
    # No dated entry in ActivityGrade at all (likely table is empty):
    LATEST_DATE='0000-00-00 00:00:00'
fi

#****************
echo "LATEST_DATE in current ActivityGrade: '$LATEST_DATE'" | tee --append $LOG_FILE
#exit 0
#****************

# ------------------ Retrieve courseware_studentmodule Excerpt  -------------------

# NOTE: two places rely on the sequence of column names
#       in the following SELECT to be constant:
#     o cronRefreshActivityGradeCrTable.sql and
#     o addAnonToActivityGradeTable.py
      
echo `date`": About to query for courseware_studentmodule"  | tee --append $LOG_FILE

# Create a temporary table to hold the result;
# the table's name 'StudentmoduleExcerpt' is significant;
# script addAnonToActivityGradeTable.py assumes
# this name:

tmpTableCmd="SET @emptyStr:=''; \
SET @floatPlaceholder:=-1.0; \
SET @intPlaceholder:=-1; \
USE edxprod; \
DROP TABLE StudentmoduleExcerpt; \
CREATE TABLE StudentmoduleExcerpt \
SELECT id AS activity_grade_id, \
       student_id, \
       course_id AS course_display_name, \
       grade, \
       max_grade, \
       @floatPlaceholder AS percent_grade, \
       state AS parts_correctness, \
       @emptyStr AS answers, \
       @intPlaceholder AS num_attempts, \
       created AS first_submit, \
       modified AS last_submit, \
       module_type, \
       @emptyStr AS anon_screen_name, \
       @emptyStr AS resource_display_name, \
       module_id
FROM edxprod.courseware_studentmodule \
WHERE modified > '"$LATEST_DATE"'; "

echo `date`": About to create auxiliary table StudentmoduleExcerpt in prep of addAnonToActivityGradeTable.py..."  | tee --append $LOG_FILE
if [ -z $MYSQL_PWD ]
then
    mysql -u $USERNAME -e "$tmpTableCmd"
else
    mysql -u $USERNAME -p$MYSQL_PWD -e "$tmpTableCmd"
fi

echo `date`": Done creating auxiliary table."  | tee --append $LOG_FILE

# ----------------- Fill in the Module IDs' Human Readable Names and  anon_screen_name  Columns ----------

echo `date`": About to add percent_grade, resolve resource id, add anon_screen_name, and module_id..."  | tee --append $LOG_FILE

if [ ! -z $MYSQL_PWD ]
then
    $currScriptsDir/addAnonToActivityGradeTable.py -u $USERNAME -w $MYSQL_PWD
else
    $currScriptsDir/addAnonToActivityGradeTable.py -u $USERNAME
fi

echo `date`": Done adding percent_grade, ..."  | tee --append $LOG_FILE

# ------------------ Cleanup -------------------

# Commented block below removes the now no longer needed
# auxiliary table edxprod.StudentmoduleExcerpt. Keeping
# the table around for debugging or post mortem. It's
# dropped earlier in this script when it needs to be gone.

# echo `date`": Cleanup: dropping auxiliary table edxprod.StudentmoduleExcerpt."  | tee --append $LOG_FILE
# dropCmd="DROP TABLE StudentmoduleExcerpt;"
# if [ -z $MYSQL_PWD ]
# then
#     mysql -u $USERNAME edxprod -e "$dropCmd"
# else
#     mysql -u $USERNAME -p$MYSQL_PWD edxprod -e "$dropCmd"
# fi

# ------------------ Signout -------------------
echo `date`": Finished updating table ActivityGrade."  | tee --append $LOG_FILE
echo "----------"  | tee --append $LOG_FILE

