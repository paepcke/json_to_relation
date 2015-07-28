#!/bin/bash

# Run as dataman or other non-root if using python virtual env

# Specific to Stanford installation.
# Refreshes the EdxPrivate.UserGrade table. Retrieves a subset of
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

# Get MySQL version on this machine
MYSQL_VERSION=$(mysql --version | sed -ne 's/.*Distrib \([0-9][.][0-9]\).*/\1/p')
if [[ $MYSQL_VERSION > 5.5 ]]
then
    MYSQL_VERSION='5.6+'
else
    MYSQL_VERSION='5.5'
fi

# If option -p is provided, script will request password for
# local MySQL db.

LOG_FILE=/home/dataman/Data/EdX/NonTransformLogs/refreshUserGradeTable.log
MYSQL_PASSWD=''

MYSQL_USERNAME=root
needLocalPasswd=false

# ------------------ Process Commandline Options -------------------

# Check whether given -pPassword, i.e. fused -p with a
# pwd string:

for arg in $@
do
   # The sed -r option enables extended regex, which
   # makes the '+' metachar wor. The -n option
   # says to print only if pattern matches:
   MYSQL_PASSWD=`echo $arg | sed -r -n 's/-p(.+)/\1/p'`
   if [ -z $MYSQL_PASSWD ]
   then
       continue
   else
       #echo "MYSQL_PASSWD is:"$MYSQL_PASSWD
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
      MYSQL_USERNAME=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    \?)
      # If $MYSQL_PASSWD is
      # set, we *assume* that
      # the unrecognized option was a
      # -pMyPassword or -rMyPassword, and don't signal
      # an error. Therefore, if either of those
      # are set, and *then* an illegal option
      # is on the command line, it is quietly
      # ignored:
      if [ ! -z $MYSQL_PASSWD ]
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
if $needLocalPasswd && [ -z $MYSQL_PASSWD ]
then
    # The -s option suppresses echo:
    read -s -p "Password for "$MYSQL_USERNAME" on local MySQL server: " MYSQL_PASSWD
    echo
elif [ -z $MYSQL_PASSWD ]
then
    # Get home directory of whichever user will
    # log into MySQL, except for root:

    if [[ $MYSQL_USERNAME == 'root' ]]
    then
        HOME_DIR=$(getent passwd `whoami` | cut -d: -f6)
        if test -f $HOME_DIR/.ssh/mysql_root && test -r $HOME_DIR/.ssh/mysql_root
        then
                MYSQL_PASSWD=`cat $HOME_DIR/.ssh/mysql_root`
        fi
    else
        HOME_DIR=$(getent passwd $MYSQL_USERNAME | cut -d: -f6)
        # If the home dir has a readable file called mysql in its .ssh
        # subdir, then pull the pwd from there:
        if test -f $HOME_DIR/.ssh/mysql && test -r $HOME_DIR/.ssh/mysql
        then
                MYSQL_PASSWD=`cat $HOME_DIR/.ssh/mysql`
        fi
    fi
fi

#**********
#echo 'Local MySQL uid: '$MYSQL_USERNAME
#echo 'Local MySQL pwd: '$MYSQL_PASSWD
#exit 0
#**********

# ------------------ Signin -------------------
echo `date`": Start updating table UserGrade..." | tee --append $LOG_FILE

# ------------------ Retrieve certificates_generatedcertificate Excerpt from S3 as TSV -------------------

# Need to find MySQL's tmpdir to be sure that MySQL
# can write the tmp file we'll ask it for. The mysql
# call runs a SHOW VARIABLES LIKE 'tmpdir' to get
# something like: "tmpdir /tmp". The 'cut' cmd then
# isolates the dir name in the second statement (or pipe element)

# Different auth for different MySQL versions:
if [[ $MYSQL_VERSION == '5.6+' ]]
then
    mysqlTmpDir=`mysql --login-path=root --silent --skip-column-names -e "SHOW VARIABLES LIKE 'tmpdir';" | cut --fields=2`
else
    if [ -z $MYSQL_PASSWD ]
    then
        mysqlTmpDir=`mysql -u $MYSQL_USERNAME --silent --skip-column-names -e "SHOW VARIABLES LIKE 'tmpdir';" | cut --fields=2`
    else
        mysqlTmpDir=`mysql -u $MYSQL_USERNAME -p$MYSQL_PASSWD --silent --skip-column-names -e "SHOW VARIABLES LIKE 'tmpdir';"`
        mysqlTmpDir=`echo $mysqlTmpDir | cut --fields=2`
    fi
fi


#**********
#echo 'mysqlTmpDir: '$mysqlTmpDir
#exit 0
#**********

# Ensure all directories to the target
# file exist:
mkdir -p $mysqlTmpDir
targetFile=$mysqlTmpDir/userTable.tsv

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

# The SELECT...UNION ALL SELECT... in the following MySQL
# statement gets a column name header as the 0th row in the
# TSV file that the statement produces:
tmpTableCmd="USE edxprod; \
             SELECT 'name', 'screen_name', 'grade', \
                    'course_id', 'distinction', 'status', \
                    'user_int_id' \
             UNION ALL \
             SELECT name, auth_user.username as screen_name, grade, \
                    course_id, distinction, status, \
                    auth_user.id as user_int_id \
             INTO OUTFILE '"$targetFile"' \
             FROM certificates_generatedcertificate RIGHT OUTER JOIN auth_user \
             ON certificates_generatedcertificate.user_id = auth_user.id;"

# Different auth for different MySQL versions:
if [[ $MYSQL_VERSION == '5.6+' ]]
then
    mysql --login-path=root edxprod -e "$tmpTableCmd"
else
    if [ -z $MYSQL_PASSWD ]
    then
        mysql -u $MYSQL_USERNAME edxprod -e "$tmpTableCmd"
    else
        mysql -u $MYSQL_USERNAME -p$MYSQL_PASSWD edxprod -e "$tmpTableCmd"
    fi
fi

echo `date`": Done constructing amalgam from certificates_generatedcertificate and auth_user." | tee --append $LOG_FILE

# Copy intermediate file to tmp for checking
cp $targetFile /tmp/intermediate.tsv

# ----------------- Fill in the Screen Name Hash Column anon_screen_name ----------

# Get directory in which this script is running,
# and where its support scripts therefore live:
currScriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# The TSV file does not yet have values for the
# anon_screen_name column. The following adds
# those values to the end of each TSV row:

echo `date`": About to add anon_screen_name to UserGrade TSV..." | tee --append $LOG_FILE

if [ ! -z $MYSQL_PASSWD ]
then
    $currScriptsDir/addAnonToUserGradeTable.py -l $LOG_FILE -u $MYSQL_USERNAME -w $MYSQL_PASSWD $targetFile $SCREEN_NAME_POS
else
    $currScriptsDir/addAnonToUserGradeTable.py -l $LOG_FILE -u $MYSQL_USERNAME $targetFile $SCREEN_NAME_POS
fi

echo `date`": Done adding anon_screen_name to UserGrade TSV..." | tee --append $LOG_FILE

# Copy intermediate file after adding ASNs
cp $targetFile /tmp/intermediate2.tsv

# ------------------ Load TSV Into Local MySQL -------------------

# Construct the TSV load command for
# use below:
MYSQL_LOAD_CMD="LOAD DATA LOCAL INFILE '$targetFile' IGNORE INTO TABLE UserGrade FIELDS TERMINATED BY '\t' IGNORE 1 LINES;"

# Distinguish between MySQL pwd known, vs. unspecified.
# If $MYSQL_PASSWD is empty, then don't provide
# the -p option to MySQL, otherwise the two branches
# below are identical:

if [ ! -z $MYSQL_PASSWD ]
then
    echo `date`": About to drop UserGrade table..." | tee --append $LOG_FILE
    # Drop UserGrade table if it exists:
    if [[ $MYSQL_VERSION == '5.6+' ]]
    then
	mysql --login-path=root -e "USE EdxPrivate; DROP TABLE IF EXISTS UserGrade;\n"
    else
	mysql -u $MYSQL_USERNAME -p$MYSQL_PASSWD -e "USE EdxPrivate; DROP TABLE IF EXISTS UserGrade;\n"
    fi
    echo `date`": Done dropping UserGrade table..." | tee --append $LOG_FILE

    echo `date`": About to create UserGrade table..." | tee --append $LOG_FILE
    # Create table 'UserGrade' in EdxPrivate, if it doesn't exist:
    if [[ $MYSQL_VERSION == '5.6+' ]]
    then
        mysql --login-path=root < $currScriptsDir/cronRefreshGradesCrTable.sql
    else
	mysql -u $MYSQL_USERNAME -p$MYSQL_PASSWD < $currScriptsDir/cronRefreshGradesCrTable.sql
    fi
    echo `date`": Done creating UserGrade table..." | tee --append $LOG_FILE

    echo `date`": About to load TSV into UserGrade table..." | tee --append $LOG_FILE
    # Do the load:
    if [[ $MYSQL_VERSION == '5.6+' ]]
    then
	mysql --login-path=root --local-infile -e "USE EdxPrivate; $MYSQL_LOAD_CMD"
    else
	mysql --local-infile -u $MYSQL_USERNAME -p$MYSQL_PASSWD -e "USE EdxPrivate; $MYSQL_LOAD_CMD"
    fi
    echo `date`": Done loading TSV into UserGrade table..." | tee --append $LOG_FILE

    # Build the indexes:
    echo `date`": About to build UserGrade indexes..." | tee --append $LOG_FILE
    if [[ $MYSQL_VERSION == '5.6+' ]]
    then
	mysql --login-path=root < $currScriptsDir/cronRefreshGradesMkIndexes.sql
    else
	mysql -u $MYSQL_USERNAME -p$MYSQL_PASSWD < $currScriptsDir/cronRefreshGradesMkIndexes.sql
    fi
else
    # Drop existing table:
    echo `date`": About to drop UserGrade table..." | tee --append $LOG_FILE
    if [[ $MYSQL_VERSION == '5.6+' ]]
    then
	mysql --login-path=root -e "USE EdxPrivate; DROP TABLE IF EXISTS UserGrade;"
    else
	mysql -u $MYSQL_USERNAME -e "USE EdxPrivate; DROP TABLE IF EXISTS UserGrade;"
    fi
    echo `date`": Done dropping UserGrade table..." | tee --append $LOG_FILE

    # Create table 'UserGrade' in EdxPrivate, if it doesn't exist:
    echo `date`": About to create UserGrade table..." | tee --append $LOG_FILE
    if [[ $MYSQL_VERSION == '5.6+' ]]
    then
	mysql --login-path=root < $currScriptsDir/cronRefreshGradesCrTable.sql
    else
	mysql -u $MYSQL_USERNAME < $currScriptsDir/cronRefreshGradesCrTable.sql
    fi
    echo `date`": Done creating UserGrade table..." | tee --append $LOG_FILE

    # Do the load:
    echo `date`": About to load TSV into UserGrade table..." | tee --append $LOG_FILE
    if [[ $MYSQL_VERSION == '5.6+' ]]
    then
	mysql --login-path=root --local-infile -e "USE EdxPrivate; $MYSQL_LOAD_CMD"
    else
	mysql --local-infile -u $MYSQL_USERNAME -e "USE EdxPrivate; $MYSQL_LOAD_CMD"
    fi
    echo `date`": Done loading TSV into UserGrade table..." | tee --append $LOG_FILE

    # Build the indexes:
    echo `date`": About to build UserGrade indexes..." | tee --append $LOG_FILE
    if [[ $MYSQL_VERSION == '5.6+' ]]
    then
	mysql --login-path=root < $currScriptsDir/cronRefreshGradesMkIndexes.sql
    else
	mysql -u $MYSQL_USERNAME < $currScriptsDir/cronRefreshGradesMkIndexes.sql
    fi
fi

# ------------------ Cleanup -------------------

# rm $targetFile

# ------------------ Signout -------------------
echo `date`": Finished updating table UserGrade." | tee --append $LOG_FILE
echo "----------"
