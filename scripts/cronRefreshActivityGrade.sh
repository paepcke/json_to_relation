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

REMOTE_MYSQL_PASSWD=''
LOCAL_MYSQL_PASSWD=''
targetFile=$HOME/MySQLTmp/studModTable.tsv
LOCAL_USERNAME=`whoami`
REMOTE_USERNAME='readonly'
needLocalPasswd=false
needRemotePasswd=false

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

# Same for remote MySQL edxprod pwd:
for arg in $@
do
   # The sed -r option enables extended regex, which
   # makes the '+' metachar wor. The -n option
   # says to print only if pattern matches:
   REMOTE_MYSQL_PASSWD=`echo $arg | sed -r -n 's/-r(.+)/\1/p'`
   if [ -z $REMOTE_MYSQL_PASSWD ]
   then
       continue
   else
       #echo "REMOTE_MYSQL_PASSWD is:"$REMOTE_MYSQL_PASSWD
       break
   fi
done

# Now check for '-p' and '-r' without explicit pwd;
# the leading colon in options causes wrong options
# to drop into \? branch:
NEXT_ARG=0

while getopts ":pru:s:" opt
do
  case $opt in
    p)
      needLocalPasswd=true
      NEXT_ARG=$((NEXT_ARG + 1))
      ;;
    r)
      needRemotePasswd=true
      NEXT_ARG=$((NEXT_ARG + 1))
      ;;
    u)
      LOCAL_USERNAME=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    s)
      REMOTE_USERNAME=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    \?)
      # If $LOCAL_MYSQL_PASSWD or $REMOTE_MYSQL_PASSWD
      # are set, we *assume* that 
      # the unrecognized option was a
      # -pMyPassword or -rMyPassword, and don't signal
      # an error. Therefore, if either of those
      # are set, and *then* an illegal option
      # is on the command line, it is quietly
      # ignored:
      if [ ! -z $LOCAL_MYSQL_PASSWD ] || [ ! -z $REMOTE_MYSQL_PASSWD ]
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

# Ask for remote pwd, unless was given
# a fused -rRemotePWD:
if $needRemotePasswd && [ -z $REMOTE_MYSQL_PASSWD ]
then
    # The -s option suppresses echo:
    read -s -p "Password for user "$REMOTE_USERNAME" on remote edxprod repo: " REMOTE_MYSQL_PASSWD
    echo
elif [ -z $REMOTE_MYSQL_PASSWD ]
then
    # Get home directory of whichever user will
    # log into MySQL:
    HOME_DIR=$(getent passwd $LOCAL_USERNAME | cut -d: -f6)
    # If the home dir has a readable file called mysql in its .ssh
    # subdir, then pull the pwd from there:
    if test -f $HOME_DIR/.ssh/edxprod && test -r $HOME_DIR/.ssh/edxprod
    then
	REMOTE_MYSQL_PASSWD=`cat $HOME_DIR/.ssh/edxprod`
    fi
fi

# Ask for remote pwd, unless was given
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
# echo 'Remote MySQL uid: '$REMOTE_USERNAME
# echo 'Remote MySQL pwd: '$REMOTE_MYSQL_PASSWD
# exit 0
#**********

# ------------------ Signin -------------------
echo `date`": Start updating table ActivityGrade..."


# ------------------ Retrieve courseware_studentmodule Excerpt from S3 as CSV -------------------

# Ensure all directories to the target
# file exist:
mkdir -p $(dirname ${targetFile})

# SSH to remote machine, log into MySQL from
# there, do the query, and redirect the result
# into a *local* file.

# NOTE: two places rely on the sequence of column names
#       in the following SELECT to be constant:
#     o cronRefreshActivityGradeCrTable.sql and
#     o addAnonToActivityGradeTable.py
      
echo `date`": About to pull courseware_studentmodule excerpt from S3"

ssh goldengate.class.stanford.edu "mysql --host=edx-prod-ro.cn2cujs3bplc.us-west-1.rds.amazonaws.com \
                                         -u "$REMOTE_USERNAME" \
                                          -p"$REMOTE_MYSQL_PASSWD" \
                                          -e \"USE edxprod; \
                                             SELECT id as activity_grade_id, \
                                                    student_id, \
                                                    course_id, \
                                                    grade, \
                                                    max_grade, \
                                                    state as parts_correctness, \
                                                    created as first_submit, \
                                                    modified as last_submit, \
                                                    module_type, \
                                                    module_id as resource_display_name \
                                             FROM courseware_studentmodule; \"
                                  " > $targetFile

echo `date`": Done pulling courseware_studentmodule excerpt from S3"

# ----------------- Fill in the Module IDs' Human Readable Names and  anon_screen_name  Columns ----------

# Get directory in which this script is running,
# and where its support scripts therefore live:
currScriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# The CSV file does not yet have values for the
# resource_display_name anon_screen_name column. 
# The following adds those values to the end of 
# each TSV row:

echo `date`": About to add percent_grade, resolve resource id, and add anon_screen_name..."

if [ ! -z $LOCAL_MYSQL_PASSWD ]
then
    $currScriptsDir/addAnonToActivityGradeTable.py -u $LOCAL_USERNAME -w $LOCAL_MYSQL_PASSWD $targetFile
else
    $currScriptsDir/addAnonToActivityGradeTable.py -u $LOCAL_USERNAME $targetFile
fi

echo `date`": Done adding percent_grade, ..."

# ------------------ Load CSV Into Local MySQL -------------------

# Construct the CSV load command for
# use below:
MYSQL_LOAD_CMD="LOAD DATA LOCAL INFILE '$targetFile' IGNORE INTO TABLE ActivityGrade FIELDS TERMINATED BY '\t' IGNORE 1 LINES;"

# Distinguish between MySQL pwd known, vs. unspecified.
# If $LOCAL_MYSQL_PASSWD is empty, then don't provide
# the -p option to MySQL, otherwise the two branches
# below are identical:

if [ ! -z $LOCAL_MYSQL_PASSWD ]
then
    # Drop table ActivityGrade if it exists:
    echo `date`": About to drop ActivityGrade table..."
    mysql -u $LOCAL_USERNAME -p$LOCAL_MYSQL_PASSWD -e "USE Edx; DROP TABLE IF EXISTS ActivityGrade;\n"
    echo `date`": Done dropping ActivityGrade table..."

    # Create table 'ActivityGrade' in Edx, if it doesn't exist:
    echo `date`": About to create ActivityGrade table..."
    mysql -u $LOCAL_USERNAME -p$LOCAL_MYSQL_PASSWD < $currScriptsDir/cronRefreshActivityGradeCrTable.sql
    echo `date`": Done creating ActivityGrade table..."

    # Do the load:
    echo `date`": About to load TSV into ActivityGrade table..."
    mysql --local-infile -u $LOCAL_USERNAME -p$LOCAL_MYSQL_PASSWD -e "USE Edx; $MYSQL_LOAD_CMD"
    echo `date`": Done loading TSV into ActivityGrade table..."

    # Build the indexes:
    echo `date`": About to build ActivityGrade indexes..."
    mysql -u $LOCAL_USERNAME -p$LOCAL_MYSQL_PASSWD < $currScriptsDir/cronRefreshActivityGradeMkIndexes.sql

    echo `date`": Done building ActivityGrade indexes..."
else
    # Drop existing table:
    echo `date`": About to drop ActivityGrade table..."
    mysql -u $LOCAL_USERNAME -e "USE Edx; DROP TABLE IF EXISTS ActivityGrade;"
    echo `date`": Done dropping ActivityGrade table..."

    # Create table 'ActivityGrade' in Edx, if it doesn't exist:
    echo `date`": About to create ActivityGrade table..."
    mysql -u $LOCAL_USERNAME < $currScriptsDir/cronRefreshActivityGradeCrTable.sql
    echo `date`": Done creating ActivityGrade table..."

    # Do the load:
    echo `date`": About to load TSV into ActivityGrade table..."
    mysql --local-infile -u $LOCAL_USERNAME -e "USE Edx; $MYSQL_LOAD_CMD"
    echo `date`": Done loading TSV into ActivityGrade table..."

    # Build the indexes:
    echo `date`": About to build ActivityGrade indexes..."
    mysql -u $LOCAL_USERNAME < $currScriptsDir/cronRefreshActivityGradeMkIndexes.sql
fi

# ------------------ Cleanup -------------------

#*********rm $targetFile

# ------------------ Signout -------------------
echo `date`": Finished updating table ActivityGrade."
echo "----------"

