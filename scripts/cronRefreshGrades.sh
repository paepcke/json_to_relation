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

USAGE='Usage: '`basename $0`' [-u localMySQLUser][-p][-pLocalMySQLPwd]'

# If option -p is provided, script will request password for
# local MySQL db.

LOG_FILE=/home/dataman/Data/EdX/NonTransformLogs/refreshUserGradeTable.log
LOCAL_MYSQL_PASSWD=''
targetFile=$HOME/MySQLTmp/userTable.tsv
LOCAL_USERNAME=`whoami`
needLocalPasswd=false

# ------------------ Process Commandline Options -------------------

# Check whether given -pPassword, i.e. fused -p with a 
# pwd string:

for arg in $@
do
   # The sed -r option enables extended regex, which
   # makes the '+' metachar wor. The -n option
   # says to print only if pattern matches:
   LOCAL_MYSQL_PASSWD=`echo $arg | sed -r -n 's/-p(.+)/\1/p'`
   if [ -z $LOCAL_MYSQL_PASSWD ]
   then
       continue
   else
       #echo "LOCAL_MYSQL_PASSWD is:"$LOCAL_MYSQL_PASSWD
       break
   fi
done

# Now check for '-p' without explicit pwd;
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
      LOCAL_USERNAME=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    \?)
      # If $LOCAL_MYSQL_PASSWD is
      # set, we *assume* that 
      # the unrecognized option was a
      # -pMyPassword or -rMyPassword, and don't signal
      # an error. Therefore, if either of those
      # are set, and *then* an illegal option
      # is on the command line, it is quietly
      # ignored:
      if [ ! -z $LOCAL_MYSQL_PASSWD ]
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
if $needLocalPasswd && [ -z $LOCAL_MYSQL_PASSWD ]
then
    # The -s option suppresses echo:
    read -s -p "Password for "$LOCAL_USERNAME" on local MySQL server: " LOCAL_MYSQL_PASSWD
    echo
elif [ -z $LOCAL_MYSQL_PASSWD ]
then
    # Get home directory of whichever user will
    # log into MySQL:
    HOME_DIR=$(getent passwd $LOCAL_USERNAME | cut -d: -f6)
    # If the home dir has a readable file called mysql_root in its .ssh
    # subdir, then pull the pwd from there:
    if test -f $HOME_DIR/.ssh/mysql && test -r $HOME_DIR/.ssh/mysql
    then
	LOCAL_MYSQL_PASSWD=`cat $HOME_DIR/.ssh/mysql`
    fi
fi

#**********
# echo 'Local MySQL uid: '$LOCAL_USERNAME
# echo 'Local MySQL pwd: '$LOCAL_MYSQL_PASSWD
# exit 0
#**********

# ------------------ Signin -------------------
echo `date`": Start updating table UserGrade..." | tee --append $LOG_FILE

# ------------------ Retrieve certificates_generatedcertificate Excerpt from S3 as TSV -------------------

# Ensure all directories to the target
# file exist:
mkdir -p $(dirname ${targetFile})

# SSH to remote machine, log into MySQL from
# there, do the query, and redirect the result
# into a *local* file.

# NOTE: script addAnonToUserGrade.py relies on
#       auth_user.username, i.e. the screen_name
#       being in a known place, origin 0. If
#       you change the position in the SELECT
#       below, then change the following constant:
SCREEN_NAME_POS=1

echo `date`": About to construct amalgam of certificates_generatedcertificate and auth_user into "$targetFile"..." | tee --append $LOG_FILE

tmpTableCmd="USE edxprod; \
             SELECT name, auth_user.username as screen_name, grade, \
                    course_id, distinction, status, \
                    auth_user.id as user_int_id \
             INTO OUTFILE '"$targetFile"' \
             FROM certificates_generatedcertificate RIGHT OUTER JOIN auth_user \
             ON certificates_generatedcertificate.user_id = auth_user.id;"

if [ -z $MYSQL_PWD ]
then
    mysql -u $LOCAL_USERNAME edxprod -e "$tmpTableCmd"
else
    mysql -u $LOCAL_USERNAME -p$MYSQL_PWD edxprod -e "$tmpTableCmd"
fi

echo `date`": Done constructing amalgam from certificates_generatedcertificate and auth_user." | tee --append $LOG_FILE

# ----------------- Fill in the Screen Name Hash Column anon_screen_name ----------

# Get directory in which this script is running,
# and where its support scripts therefore live:
currScriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# The TSV file does not yet have values for the
# anon_screen_name column. The following adds
# those values to the end of each TSV row:

echo `date`": About to add anon_screen_name to UserGrade TSV..." | tee --append $LOG_FILE

if [ ! -z $LOCAL_MYSQL_PASSWD ]
then
    $currScriptsDir/addAnonToUserGradeTable.py -u $LOCAL_USERNAME -w $LOCAL_MYSQL_PASSWD $targetFile $SCREEN_NAME_POS
else
    $currScriptsDir/addAnonToUserGradeTable.py -u $LOCAL_USERNAME $targetFile $SCREEN_NAME_POS
fi

echo `date`": Done adding anon_screen_name to UserGrade TSV..." | tee --append $LOG_FILE

# ------------------ Load TSV Into Local MySQL -------------------

# Construct the TSV load command for
# use below:
MYSQL_LOAD_CMD="LOAD DATA LOCAL INFILE '$targetFile' IGNORE INTO TABLE UserGrade FIELDS TERMINATED BY '\t' IGNORE 1 LINES;"

# Distinguish between MySQL pwd known, vs. unspecified.
# If $LOCAL_MYSQL_PASSWD is empty, then don't provide
# the -p option to MySQL, otherwise the two branches
# below are identical:

if [ ! -z $LOCAL_MYSQL_PASSWD ]
then
    echo `date`": About to drop UserGrade table..." | tee --append $LOG_FILE
    # Drop UserGrade table if it exists:
    mysql -u $LOCAL_USERNAME -p$LOCAL_MYSQL_PASSWD -e "USE EdxPrivate; DROP TABLE IF EXISTS UserGrade;\n"
    echo `date`": Done dropping UserGrade table..." | tee --append $LOG_FILE
    
    echo `date`": About to create UserGrade table..." | tee --append $LOG_FILE
    # Create table 'UserGrade' in EdxPrivate, if it doesn't exist:
    mysql -u $LOCAL_USERNAME -p$LOCAL_MYSQL_PASSWD < $currScriptsDir/cronRefreshGradesCrTable.sql
    echo `date`": Done creating UserGrade table..." | tee --append $LOG_FILE

    echo `date`": About to load TSV into UserGrade table..." | tee --append $LOG_FILE
    # Do the load:
    mysql --local-infile -u $LOCAL_USERNAME -p$LOCAL_MYSQL_PASSWD -e "USE EdxPrivate; $MYSQL_LOAD_CMD"
    echo `date`": Done loading TSV into UserGrade table..." | tee --append $LOG_FILE

    # Build the indexes:
    echo `date`": About to build UserGrade indexes..." | tee --append $LOG_FILE
    mysql -u $LOCAL_USERNAME -p$LOCAL_MYSQL_PASSWD < $currScriptsDir/cronRefreshGradesMkIndexes.sql
else
    # Drop existing table:
    echo `date`": About to drop UserGrade table..." | tee --append $LOG_FILE
    mysql -u $LOCAL_USERNAME -e "USE EdxPrivate; DROP TABLE IF EXISTS UserGrade;"
    echo `date`": Done dropping UserGrade table..." | tee --append $LOG_FILE

    # Create table 'UserGrade' in EdxPrivate, if it doesn't exist:
    echo `date`": About to create UserGrade table..." | tee --append $LOG_FILE
    mysql -u $LOCAL_USERNAME < $currScriptsDir/cronRefreshGradesCrTable.sql
    echo `date`": Done creating UserGrade table..." | tee --append $LOG_FILE

    # Do the load:
    echo `date`": About to load TSV into UserGrade table..." | tee --append $LOG_FILE
    mysql --local-infile -u $LOCAL_USERNAME -e "USE EdxPrivate; $MYSQL_LOAD_CMD"
    echo `date`": Done loading TSV into UserGrade table..." | tee --append $LOG_FILE

    # Build the indexes:
    echo `date`": About to build UserGrade indexes..." | tee --append $LOG_FILE
    mysql -u $LOCAL_USERNAME < $currScriptsDir/cronRefreshGradesMkIndexes.sql
fi

# ------------------ Cleanup -------------------

rm $targetFile

# ------------------ Signout -------------------
echo `date`": Finished updating table UserGrade." | tee --append $LOG_FILE
echo "----------"   
