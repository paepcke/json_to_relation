#!/bin/bash
# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


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
    # log into MySQL, except for root:

    if [[ $USERNAME == 'root' ]]
    then
        HOME_DIR=$(getent passwd `whoami` | cut -d: -f6)
        if test -f $HOME_DIR/.ssh/mysql_root && test -r $HOME_DIR/.ssh/mysql_root
        then
                MYSQL_PWD=`cat $HOME_DIR/.ssh/mysql_root`
        fi
    else
        HOME_DIR=$(getent passwd $USERNAME | cut -d: -f6)
        # If the home dir has a readable file called mysql in its .ssh
        # subdir, then pull the pwd from there:
        if test -f $HOME_DIR/.ssh/mysql && test -r $HOME_DIR/.ssh/mysql
        then
                MYSQL_PWD=`cat $HOME_DIR/.ssh/mysql`
        fi
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

if [[ $MYSQL_VERSION == '5.6+' ]]
then
        mysql --login-path=root < $currScriptsDir/cronRefreshActivityGradeCrTable.sql
        LATEST_DATE=`mysql --login-path=root --silent --skip-column-names Edx -e \
    	  "SELECT MAX(last_submit) FROM ActivityGrade;"`
else
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
fi

if [[ $? != 0 ]]
then
    echo `date`": Error reading latest last_submit field from ActivityGrade."  | tee --append $LOG_FILE
    exit 1
fi


if [ "${LATEST_DATE}" == "NULL" ]
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
      
# Output just created date and course name from
# courseware_studentmodule to CSV:

TMP_FILE=$(mktemp /tmp/removeTestCourses_XXXXXXXXXXX.csv)

# But at this point, remove file so that MySQL won't complain about
# its existence. This is a race condition if we run this script in
# multiple simultaneous copies, which we won't:

rm ${TMP_FILE}

# Ensure that at least the temporary clean-up .csv file is removed
# on exit (cleanly or otherwise):

function cleanup {

    # The $TMP_FILE is writen by MySQL, so
    # this user cannot remove it from /tmp,
    # which generally has the sticky bit set
    # (ls -l shows .......t). So only owner
    # can write even though rw for all:
    
    #if [[ -e ${TMP_FILE} ]]
    #then
    #    rm ${TMP_FILE}
    #fi
    
    if [[ -e ${CLEANED_FILE} ]]
    then
        rm ${CLEANED_FILE}
    fi
}

trap cleanup EXIT

# Export from courseware_studentmodule:
# test courses:

read -rd '' TBL_EXPORT_CMD <<EOF
SELECT created,course_id FROM edxprod.courseware_studentmodule
  where modified > '${LATEST_DATE}'
  INTO OUTFILE '${TMP_FILE}'
  FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n';
EOF

#***********
echo "TBL_EXPORT_CMD: ${TBL_EXPORT_CMD}"
#***********

echo `date`": Export new modified/course_id pairs from courseware_studentmodule..."  | tee --append $LOG_FILE
if [[ $MYSQL_VERSION == '5.6+' ]]
then
    mysql --login-path=root -e "$TBL_EXPORT_CMD"
else
    if [ -z $MYSQL_PWD ]
    then
        mysql -u $USERNAME -e "$TBL_EXPORT_CMD"
    else
        mysql -u $USERNAME -p$MYSQL_PWD -e "$TBL_EXPORT_CMD"
    fi
fi

if [[ $? != 0 ]]
then
    echo `date`": Error during modified/course-name export from courseware_studentmodule."  | tee --append $LOG_FILE
    exit 1
fi

echo `date`": Done exporting new modified/course_id pairs from courseware_studentmodule."  | tee --append $LOG_FILE

# Use AWK to filter out the created-date/course-name pairs
# in which the course name is a test file.
# Create a temporary .csv file name for AWK to write the
# redacted result to:

CLEANED_FILE=/tmp/$(basename ${TMP_FILE} .csv)_Cleaned.csv

#*********
echo "CLEANED_FILE: '${CLEANED_FILE}'"
#*********

# Pump the dirty .csv file through AWK into the new .csv file:
echo `date`": Using AWK to remove entries for test courses..."  | tee --append $LOG_FILE
cat ${TMP_FILE} | awk -v COURSE_NAME_INDEX=${CRSE_NAME_INDEX} -f ${currScriptsDir}/removeTestCourses.awk > ${CLEANED_FILE}
echo `date`": Done using AWK to remove entries for test courses."  | tee --append $LOG_FILE

# Load the new file into a newly created
# table:

read -rd '' TBL_IMPORT_CMD <<EOF
USE edxprod;
DROP TABLE if exists TMP_FILTER_TABLE;
CREATE TABLE TMP_FILTER_TABLE (modified datetime, course_display_name varchar(255));
LOAD DATA LOCAL INFILE '${CLEANED_FILE}'
  INTO TABLE TMP_FILTER_TABLE
   FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n';
EOF

echo `date`": Loading valid modified/course-name pairs..."  | tee --append $LOG_FILE
if [[ $MYSQL_VERSION == '5.6+' ]]
then
    mysql --login-path=root -e "$TBL_IMPORT_CMD"
else
    if [ -z $MYSQL_PWD ]
    then
        mysql -u $USERNAME -e "$TBL_IMPORT_CMD"
    else
        mysql -u $USERNAME -p$MYSQL_PWD -e "$TBL_IMPORT_CMD"
    fi
fi

if [[ $? != 0 ]]
then
    echo `date`": Error during modified/course-name pairs"  | tee --append $LOG_FILE
    exit 1
fi


echo `date`": Done loading valid modified/course-name pairs."  | tee --append $LOG_FILE

echo `date`": About to pull from courseware_studentmodule"  | tee --append $LOG_FILE

# Create a temporary table to hold the result;
# the table's name 'StudentmoduleExcerpt' is significant;
# script addAnonToActivityGradeTable.py assumes
# this name. The @foo names below sneak in columns
# that are not in courseware_studentmodule where we
# pull the courses. 

read -rd '' tmpTableCmd <<EOF
SET @emptyStr:='';
SET @floatPlaceholder:=-1.0;
SET @intPlaceholder:=-1;
USE edxprod;
DROP TABLE IF EXISTS StudentmoduleExcerpt;
CREATE TABLE StudentmoduleExcerpt (activity_grade_id INT) ENGINE=MyISAM
SELECT id AS activity_grade_id,
       student_id,
       course_id AS course_display_name,
       grade,
       max_grade,
       @floatPlaceholder AS percent_grade,
       state AS parts_correctness,
       @emptyStr AS answers,
       @intPlaceholder AS num_attempts,
       created AS first_submit,
       courseware_studentmodule.modified AS last_submit,
       module_type,
       @emptyStr AS anon_screen_name,
       @emptyStr AS resource_display_name,
       module_id
FROM TMP_FILTER_TABLE LEFT JOIN courseware_studentmodule
     ON TMP_FILTER_TABLE.modified = courseware_studentmodule.modified
    AND TMP_FILTER_TABLE.course_display_name = courseware_studentmodule.course_id;
DROP TABLE if exists TMP_FILTER_TABLE;
EOF

echo `date`": About to create auxiliary table StudentmoduleExcerpt in prep of addAnonToActivityGradeTable.py..."  | tee --append $LOG_FILE
if [[ $MYSQL_VERSION == '5.6+' ]]
then
    mysql --login-path=root -e "$tmpTableCmd"
else
    if [ -z $MYSQL_PWD ]
    then
        mysql -u $USERNAME  -e "$tmpTableCmd"
    else
        mysql -u $USERNAME  -p$MYSQL_PWD -e "$tmpTableCmd"
    fi
fi

if [[ $? != 0 ]]
then
    echo `date`": Error during creation/loading of aux tbl edxprod.StudentmoduleExcerpt"  | tee --append $LOG_FILE
    exit 1
fi


echo `date`": Done creating auxiliary table."  | tee --append $LOG_FILE

# ----------------- Fill in the Module IDs' Human Readable Names and  anon_screen_name  Columns ----------

echo `date`": About to add percent_grade, resolve resource id, add anon_screen_name, and module_id..."  | tee --append $LOG_FILE

if [[ $MYSQL_VERSION == '5.6+' ]]
then
    echo "    "`date`": Begin disable ActivityGrade indexing."  | tee --append $LOG_FILE
    mysql --login-path=root -e "ALTER TABLE Edx.ActivityGrade DISABLE KEYS;"
    if [[ $? != 0 ]]
    then
        echo `date`": Error disabling indexing on ActivityGrade."  | tee --append $LOG_FILE
        exit 1
    fi

    echo "    "`date`": Done done disable ActivityGrade indexing."  | tee --append $LOG_FILE
    KEYS_DISABLED=1
else
    KEYS_DISABLED=0
fi

if [ ! -z $MYSQL_PWD ]
then
    # Turn off indexing while bulk-adding:
    if [[ $KEYS_DISABLED == 0 ]]
    then
	echo "    "`date`": Begin disable ActivityGrade indexing."  | tee --append $LOG_FILE
	mysql -u $USERNAME -w $MYSQL_PWD -e "ALTER TABLE Edx.ActivityGrade DISABLE KEYS;"
        if [[ $? != 0 ]]
        then
            echo `date`": Error "  | tee --append $LOG_FILE
            exit 1
        fi
            echo "    "`date`": Done done disable ActivityGrade indexing."  | tee --append $LOG_FILE
        fi
        $currScriptsDir/addAnonToActivityGradeTable.py -u $USERNAME -w $MYSQL_PWD
else
    # Turn off indexing while bulk-adding:
    if [[ $KEYS_DISABLED == 0 ]]
    then
        echo "    "`date`": Begin disable ActivityGrade indexing."  | tee --append $LOG_FILE
	mysql -u $USERNAME -e "ALTER TABLE Edx.ActivityGrade DISABLE KEYS;"
        if [[ $? != 0 ]]
        then
            echo `date`": Error "  | tee --append $LOG_FILE
            exit 1
        fi
        echo "    "`date`": Done done disable ActivityGrade indexing."  | tee --append $LOG_FILE
    fi
    $currScriptsDir/addAnonToActivityGradeTable.py -u $USERNAME
fi

echo "    "`date`": Done loading new entries into ActivityGrade."  | tee --append $LOG_FILE
echo "    "`date`": Start re-enabling indexing in ActivityGrade..."  | tee --append $LOG_FILE

if [[ $MYSQL_VERSION == '5.6+' ]]
then
    mysql --login-path=root -e "ALTER TABLE Edx.ActivityGrade ENABLE KEYS;"
else
    if [ ! -z $MYSQL_PWD ]
    then
        mysql -u $USERNAME -w $MYSQL_PWD -e "ALTER TABLE Edx.ActivityGrade ENABLE KEYS;"
    else
        mysql -u $USERNAME -e "ALTER TABLE Edx.ActivityGrade ENABLE KEYS;"
    fi
fi
if [[ $? != 0 ]]
then
    echo `date`": Error re-enabling indexing on ActivityGrade."  | tee --append $LOG_FILE
    exit 1
fi

echo `date`": Done adding percent_grade, ..."  | tee --append $LOG_FILE

# The following is commented out, b/c we now ensure that all
# indexes on ActivityGrade have been built before this script is called.
# We DISABLE/ENABLE those indexes above.

# echo `date`": Creating indexes ..."  | tee --append $LOG_FILE
#
# if [[ $MYSQL_VERSION == '5.6+' ]]
# then
#         mysql --login-path=root Edx -e "CREATE INDEX ActGrdAnonSNIdx ON ActivityGrade (anon_screen_name);"
#         mysql --login-path=root Edx -e "CREATE INDEX ActGrdCourseDisNmIdx ON ActivityGrade (course_display_name);"
#         mysql --login-path=root Edx -e "CREATE INDEX ActGrdNumAttemptsIdx ON ActivityGrade (num_attempts);"
#         mysql --login-path=root Edx -e "CREATE INDEX ActGrdModIdIdx ON ActivityGrade (module_id);"
#         mysql --login-path=root Edx -e "CREATE INDEX ActGrdResDispNmIdx ON ActivityGrade (resource_display_name);"
#         mysql --login-path=root Edx -e "CREATE INDEX ActGrdLastSubmitIdx ON ActivityGrade (last_submit);"           
# else
#     if [ -z $MYSQL_PWD ]
#     then
#         mysql -u $USERNAME Edx -e "CREATE INDEX ActGrdAnonSNIdx ON ActivityGrade (anon_screen_name);"
#         mysql -u $USERNAME Edx -e "CREATE INDEX ActGrdCourseDisNmIdx ON ActivityGrade (course_display_name);"
#         mysql -u $USERNAME Edx -e "CREATE INDEX ActGrdNumAttemptsIdx ON ActivityGrade (num_attempts);"
#         mysql -u $USERNAME Edx -e "CREATE INDEX ActGrdModIdIdx ON ActivityGrade (module_id);"
#         mysql -u $USERNAME Edx -e "CREATE INDEX ActGrdResDispNmIdx ON ActivityGrade (resource_display_name);"
#         mysql -u $USERNAME Edx -e "CREATE INDEX ActGrdLastSubmitIdx ON ActivityGrade (last_submit);"           
#     else
#         mysql -u $USERNAME -p$MYSQL_PWD Edx -e "CREATE INDEX ActGrdAnonSNIdx ON ActivityGrade (anon_screen_name);"          
#         mysql -u $USERNAME -p$MYSQL_PWD Edx -e "CREATE INDEX ActGrdCourseDisNmIdx ON ActivityGrade (course_display_name);"  
#         mysql -u $USERNAME -p$MYSQL_PWD Edx -e "CREATE INDEX ActGrdNumAttemptsIdx ON ActivityGrade (num_attempts);"
#         mysql -u $USERNAME -p$MYSQL_PWD Edx -e "CREATE INDEX ActGrdModIdIdx ON ActivityGrade (module_id);"                  
#         mysql -u $USERNAME -p$MYSQL_PWD Edx -e "CREATE INDEX ActGrdResDispNmIdx ON ActivityGrade (resource_display_name);"  
#         mysql -u $USERNAME -p$MYSQL_PWD Edx -e "CREATE INDEX ActGrdLastSubmitIdx ON ActivityGrade (last_submit);"           
#     fi
# fi

# echo `date`": Done creating indexes ..."  | tee --append $LOG_FILE

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

