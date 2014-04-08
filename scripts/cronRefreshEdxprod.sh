#!/bin/bash

# Copies latest edxprod database with all its tables from
# deploy.prod.class.stanford.edu:/data/dump, and imports
# a selection of tables into local MySQL's db 'edxprod'. Password-less
# login must have been arranged to the remote machine.
#
# To add tables that are to be included in the load, modify
# below as follows:
#
#   1. In array variable TABLE, add name of new table
#   2. In file createEdxprodTables.sql add the table's CREATE statement.
#   3. In section 'Build Indexes of Tables We Just Loaded' below: add index creation of new table.
#
# This script uses service script extractTableFromDump.sh
# Stats:
#    courseware_studentmodule loading: ~1hr45min (w/o index building)


USAGE='Usage: '`basename $0`' [-u localUbuntuUser][-p][-pLocalMySQLRootPwd]'

# If -u is omitted, then unix 'whoami' is used.
# If option -p is provided, script will request password for
# local MySQL db's root user. As per MySQL the -p can be
# fused with the pwd on the CL. The MySQL activities all run as
# MySQL user root. The -u localUbuntuUser is only relevant
# if no MySQL root pwd is provided with -p. In that case 
# the given Ubuntu user's home dir is expected to contain
# file .ssh/mysql_root with the password.

# Array of tables to get from edxprod (NOTE: no commas between tables!):
TABLES=(courseware_studentmodule courseware_studentmodulehistory auth_user certificates_generatedcertificate)

MYSQL_PASSWD=''
MYSQL_USERNAME=root
UBUNTU_USERNAME=`whoami`
EDXPROD_DUMP_DIR=/home/dataman/Data/FullDumps/EdxAppPlatformDbs
LOG_FILE=/home/dataman/Data/EdX/NonTransformLogs/refreshEdxprod.log
needLocalPasswd=false

# Get directory in which this script is running,
# and where its support scripts therefore live:
currScriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"



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
      UBUNTU_USERNAME=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    \?)
      # If $MYSQL_PASSWD is set, we *assume* that 
      # the unrecognized option was a
      # -pMyPassword, and don't signal
      # an error. Therefore, if $MYSQL_PASSWD
      # is set, and *then* an illegal option
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
    read -s -p "Password for "$UBUNTU_USERNAME" on local MySQL server: " MYSQL_PASSWD
    echo
elif [ -z $MYSQL_PASSWD ]
then
    # Get home directory of whichever user will
    # log into MySQL:
    HOME_DIR=$(getent passwd $UBUNTU_USERNAME | cut -d: -f6)
    # If the home dir has a readable file called mysql_root in its .ssh
    # subdir, then pull the pwd from there:
    if [[ -f $HOME_DIR/.ssh/mysql_root && -r $HOME_DIR/.ssh/mysql_root ]]
    then
	MYSQL_PASSWD=`cat $HOME_DIR/.ssh/mysql_root`
    fi
fi

#**********
# echo 'MySQL uid: '$MYSQL_USERNAME
# echo 'MySQL pwd: '$MYSQL_PASSWD
# echo 'Ubuntu uid: '$UBUNTU_USERNAME
# exit 0
# *********

# ------------------ Signin-------------------
echo `date`": Begin refreshing edxprod."  | tee --append $LOG_FILE
echo "----------"
# ------------------ Copy full edxprod dump from prod machine to datastage -------------------

scp deploy.prod.class.stanford.edu:/data/dump/edxapp-latest.sql.gz \
    $EDXPROD_DUMP_DIR/

# ------------------ Ensure Existence of Local Database -------------------

mysql -u root -p$MYSQL_PASSWD -e "CREATE DATABASE IF NOT EXISTS edxprod;"


# ------------------ Extract and Load Tables from Dump File -------------------

# Path to the just copied large edxprod mysqldump file:
DUMP_FILE=$EDXPROD_DUMP_DIR/edxapp-latest.sql.gz

# For each table we want, use script extractTableFromDump.sh
# to pull out the table restoration commands into a separate
# .sql file, load the file into database edxprod on the
# datastage MySQL server, and build the indexes:

for TABLE in ${TABLES[@]} 
do
    echo `date`": Extracting table $TABLE."  | tee --append $LOG_FILE
    $currScriptsDir/extractTableFromDump.sh $DUMP_FILE $TABLE > $EDXPROD_DUMP_DIR/$TABLE.sql
    echo `date`": Loading table $TABLE."  | tee --append $LOG_FILE
    mysql -u root -p$MYSQL_PASSWD edxprod < $EDXPROD_DUMP_DIR/$TABLE.sql
done

# -------------- Build Indexes of Tables We Just Loaded -------------------

# Indexes of courseware_studentmodule:
echo `date`": Creating indexes for table courseware_studentmodule."  | tee --append $LOG_FILE
mysql -u root -p$MYSQL_PASSWD edxprod -e "CREATE INDEX courseware_studentmodule_module_type_IDX ON courseware_studentmodule (module_type (32));"
mysql -u root -p$MYSQL_PASSWD edxprod -e "CREATE INDEX courseware_studentmodule_module_id_IDX ON courseware_studentmodule (module_id (255));"
mysql -u root -p$MYSQL_PASSWD edxprod -e "CREATE INDEX courseware_studentmodule_student_id_IDX ON courseware_studentmodule (student_id);"
mysql -u root -p$MYSQL_PASSWD edxprod -e "CREATE INDEX courseware_studentmodule_grade_IDX ON courseware_studentmodule (grade);"
mysql -u root -p$MYSQL_PASSWD edxprod -e "CREATE INDEX courseware_studentmodule_created_IDX ON courseware_studentmodule (created);"
mysql -u root -p$MYSQL_PASSWD edxprod -e "CREATE INDEX courseware_studentmodule_modified_IDX ON courseware_studentmodule (modified);"
mysql -u root -p$MYSQL_PASSWD edxprod -e "CREATE INDEX courseware_studentmodule_max_grade_IDX ON courseware_studentmodule (max_grade);"
mysql -u root -p$MYSQL_PASSWD edxprod -e "CREATE INDEX courseware_studentmodule_done_IDX ON courseware_studentmodule (done (8));"
mysql -u root -p$MYSQL_PASSWD edxprod -e "CREATE INDEX courseware_studentmodule_course_id_IDX ON courseware_studentmodule (course_id (255));"

# Indexes of student_auth:
echo `date`": Creating indexes for table auth_user."  | tee --append $LOG_FILE
mysql -u root -p$MYSQL_PASSWD edxprod -e "CREATE INDEX auth_user_username_IDX ON auth_user (username(30));"
mysql -u root -p$MYSQL_PASSWD edxprod -e "CREATE INDEX auth_user_email_IDX ON auth_user  (email (255));"

# Indexes of courseware_studentmodulehistory
echo `date`": Creating indexes for table courseware_studentmodulehistory."  | tee --append $LOG_FILE
mysql -u root -p$MYSQL_PASSWD edxprod -e "CREATE INDEX courseware_studenthistory_student_module_id_IDX ON courseware_studentmodulehistory(student_module_id);"
mysql -u root -p$MYSQL_PASSWD edxprod -e "CREATE INDEX courseware_studenthistory_version_IDX ON courseware_studentmodulehistory(version (255));"
mysql -u root -p$MYSQL_PASSWD edxprod -e "CREATE INDEX courseware_studenthistory_created_IDX ON courseware_studentmodulehistory(created);"

# Indexes of certificates_generatedcertificate
echo `date`": Creating indexes for table certificates_generatedcertificate."  | tee --append $LOG_FILE
mysql -u root -p$MYSQL_PASSWD edxprod -e "CREATE INDEX certificates_generatedcertificate_course_id_IDX ON certificates_generatedcertificate(course_id (255));"
mysql -u root -p$MYSQL_PASSWD edxprod -e "CREATE INDEX certificates_generatedcertificate_user_id_IDX ON certificates_generatedcertificate(user_id);"


# ------------------ Signout -------------------
echo `date`": Finished refreshing edxprod tables."  | tee --append $LOG_FILE
echo "----------"
