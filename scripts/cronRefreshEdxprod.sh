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


# Copies latest edxprod database with all its tables from
# Stanford's platform instance table dump machine, and imports
# a selection of tables into local MySQL's db 'edxprod'. Password-less
# login must have been arranged to the remote machine so
# that scp works.
#
# The -n CL option causes the already existing local copy
# of edxapp-latest.sql.gz to be used to find the tables, 
# rather than copying a new one from the backup server.
#
# To add tables that are to be included in the load, modify
# below as follows:
#
#   1. In array variable TABLE, add name of new table
#
# This script uses service script extractTableFromDump.sh
# and incremental_update_CWSMH.sh.
#
# Stats:
#    courseware_studentmodule loading: ~1hr45min (w/o index building)

EDX_PLATFORM_DUMP_MACHINE=jenkins.prod.class.stanford.edu

# Called in some ways (maybe via cron?)
# $0 is not a script name, but "-bash".
# The leading "-" fools basename into
# thinking a switch "-b" is being passed
# to it. Take care of that to avoid an
# error mst:

if [[ $0 =~ ^- ]]
then
    USAGE='Called via source: non-interactive'
else    
    USAGE='Usage: '`basename $0`' [-u localUbuntuUser][-p][-pLocalMySQLRootPwd][-n]'
fi    

# Get MySQL version on this machine
MYSQL_VERSION=$(mysql --version | sed -ne 's/.*Distrib \([0-9][.][0-9]\).*/\1/p')
if [[ $MYSQL_VERSION > 5.5 ]]
then 
    MYSQL_VERSION='5.6+'
else 
    MYSQL_VERSION='5.5'
fi

# If -u is omitted, then unix 'whoami' is used.
# If option -p is provided, script will request password for
# local MySQL db's root user. As per MySQL the -p can be
# fused with the pwd on the CL. The MySQL activities all run as
# MySQL user root. The -u localUbuntuUser is only relevant
# if no MySQL root pwd is provided with -p. In that case 
# the given Ubuntu user's home dir is expected to contain
# file .ssh/mysql_root with the password.

# Array of tables to get from edxprod (NOTE: no commas between tables!):
# Tbl courseware_studentmodulehistory is commented out b/c it takes
# so long to refresh:
TABLES=(courseware_studentmodule \
        #courseware_studentmodulehistory \
        auth_user \
        certificates_generatedcertificate \
        auth_userprofile \
        external_auth_externalauthmap \
        student_anonymoususerid \
        student_courseenrollment\
        submissions_score\
        submissions_scoresummary\
        submissions_studentitem\
        submissions_submission 
       )

MYSQL_PASSWD=''
MYSQL_USERNAME=root
UBUNTU_USERNAME=`whoami`
EDXPROD_DUMP_DIR=/home/dataman/Data/FullDumps/EdxAppPlatformDbs
LOG_FILE=/home/dataman/Data/EdX/NonTransformLogs/refreshEdxprod.log
needLocalPasswd=false
# Want to pull a fresh copy of edxapp-latest.sql.gz from backup server,
# unless find the -n option further down:
COPY_FROM_PLATFORM_BACKUP=1

# Get directory in which this script is running,
# and where its support scripts therefore live:
currScriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ------------------ Process Commandline Options -------------------

# Check whether given -pPassword, i.e. fused -p with a 
# pwd string:

for arg in $@
do
   # The sed -r option enables extended regex, which
   # makes the '+' metachar work. The -n option
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

while getopts ":pnu:" opt
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
    n)
      COPY_FROM_PLATFORM_BACKUP=0
      NEXT_ARG=$((NEXT_ARG + 1))
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
        HOME_DIR=$(getent passwd $UBUNTU_USERNAME | cut -d: -f6)
        # If the home dir has a readable file called mysql in its .ssh
        # subdir, then pull the pwd from there:

        if test -f $HOME_DIR/.ssh/mysql && test -r $HOME_DIR/.ssh/mysql
        then
                MYSQL_PASSWD=`cat $HOME_DIR/.ssh/mysql`
        fi
    fi
fi

#**********
#echo 'MySQL uid: '$MYSQL_USERNAME
#echo 'MySQL pwd: "'$MYSQL_PASSWD'"'
#echo 'Ubuntu uid: '$UBUNTU_USERNAME
#exit 0
# *********

# ------------------ Signin-------------------
echo `date`": Begin refreshing edxprod."  | tee --append $LOG_FILE
echo "----------"
# ------------------ Copy full edxprod dump from prod machine to datastage -------------------

if [[ COPY_FROM_PLATFORM_BACKUP -eq 1 ]]
then
    echo `date`": Begin copying edxapp-latest.sql.gz from backup server."
    scp $EDX_PLATFORM_DUMP_MACHINE:/data/dump/edxapp-latest.sql.gz \
      	$EDXPROD_DUMP_DIR/
    echo `date`": Done copying edxapp-latest.sql.gz from backup server."
fi

# ------------------ Ensure Existence of Local Database -------------------

if [[ $MYSQL_VERSION == '5.6+' ]]
then
    mysql --login-path=root -e "CREATE DATABASE IF NOT EXISTS edxprod;"
else
    mysql -u root -p$MYSQL_PASSWD -e "CREATE DATABASE IF NOT EXISTS edxprod;"
fi

# ------------------ Extract and Load Tables from Dump File -------------------

# Path to the just copied large edxprod mysqldump file:
DUMP_FILE=$EDXPROD_DUMP_DIR/edxapp-latest.sql.gz

# For each table we want, use script extractTableFromDump.sh
# to pull out the table restoration commands into a separate
# .sql file, load the file into database edxprod on the
# datastage MySQL server, and build the indexes that came
# with the tables:

for TABLE in ${TABLES[@]} 
do
    if [[ $TABLE == 'courseware_studentmodulehistory' ]]
    then
        # courseware_studentmodulehistory is updated incrementally.
        # Handle that in a different script.
        $currScriptsDir/incremental_update_CWSMH.sh
        # Next table:
        continue
    fi

    echo `date`": Extracting table $TABLE."  | tee --append $LOG_FILE
    $currScriptsDir/extractTableFromDump.sh $DUMP_FILE $TABLE > $EDXPROD_DUMP_DIR/$TABLE.sql

    # Because MySQL is soooo slow loading tables
    # with a primary index, modify the table
    # courseware_studentmodule.sql to not define
    # a primary index. Since we don't need them,
    # we also remove UNIQUE and CONSTRAINT declarations
    # from the CREATE TABLE statement. We do this 
    # by copying the courseware_studentmodule.sql file
    # through an awk script into a tmp file, and then
    # load that tmp file, rather than the original:
    if [[ $TABLE == 'courseware_studentmodule' ]]
    then
	      echo "Removing PRIMARY/UNIQUE/CONSTRAINTS decls from courseware_studentmodule.sql file..." | tee --append $LOG_FILE
	      cat $EDXPROD_DUMP_DIR/courseware_studentmodule.sql | awk -f $currScriptsDir/stripUniquePrimaryConstraintsFromCreateTable.awk \
                  > $EDXPROD_DUMP_DIR/courseware_studentmoduleNoPrimaryIndex.sql
        TABLE=courseware_studentmoduleNoPrimaryIndex
	      echo `date`": Done adding the PRIMARY/UNIQUE/CONSTRAINTS removal." | tee --append $LOG_FILE
    fi

    # Same with courseware_studentmodulehistory:
    if [[ $TABLE == 'courseware_studentmodulehistory' ]]
    then
	      echo "Removing PRIMARY/UNIQUE/CONSTRAINTS decls from courseware_studentmodule.sql file..." | tee --append $LOG_FILE
	      cat $EDXPROD_DUMP_DIR/courseware_studentmodulehistory.sql | awk -f $currScriptsDir/stripUniquePrimaryConstraintsFromCreateTable.awk \
                  > $EDXPROD_DUMP_DIR/courseware_studentmodulehistoryNoPrimaryIndex.sql
        TABLE=courseware_studentmodulehistoryNoPrimaryIndex
	      echo `date`": Done adding the PRIMARY/UNIQUE/CONSTRAINTS removal." | tee --append $LOG_FILE
    fi

    echo `date`": Loading table $TABLE."  | tee --append $LOG_FILE
    if [[ $MYSQL_VERSION == '5.6+' ]]
    then
	      mysql --login-path=root edxprod < $EDXPROD_DUMP_DIR/$TABLE.sql
    else
	      mysql -u root -p$MYSQL_PASSWD edxprod < $EDXPROD_DUMP_DIR/$TABLE.sql
    fi  

done

# ------------------ Create Table of Enrollments Excluding Casual Browsers -------------------

# Now create the true_enrollment table, which only
# contains rows for learners that fully enrolled, i.e.
# answered the confirmation email, and who do not
# receive one or more entries in student_courseenrollment just
# because they accessed course material in an internal course
# that was marked as internal, but allowed public access.

newTblCmd="DROP TABLE IF EXISTS true_courseenrollment;
	   CREATE TABLE true_courseenrollment (
	     user_id int(11) NOT NULL,
	     course_display_name varchar(255) NOT NULL,
	     created datetime DEFAULT NULL,
	     mode varchar(100) NOT NULL,
	     KEY true_courseenrollment_uid (user_id),
	     KEY true_courseenrollment_course_id (course_display_name),
	     KEY true_courseenrollment_created (created)
	   ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
	   ALTER TABLE true_courseenrollment DISABLE KEYS;
	   INSERT INTO true_courseenrollment
	   SELECT student_courseenrollment.user_id,
	          course_id AS course_display_name,
	          created,
	          mode
	   FROM student_courseenrollment LEFT JOIN 
	        (SELECT user_id
	         FROM auth_userprofile
	        WHERE nonregistered = 0
	        ) AS TrueRegistrations
	     ON student_courseenrollment.user_id = TrueRegistrations.user_id
	     WHERE student_courseenrollment.is_active = 1;
	   ALTER TABLE true_courseenrollment ENABLE KEYS;
         "

echo `date`": Creating true_courseenrollment."
if [[ $MYSQL_VERSION == '5.6+' ]]
then
    echo $newTblCmd | mysql --login-path=root edxprod
else
    echo $newTblCmd | mysql -u root -p$MYSQL_PASSWD edxprod
fi
echo `date`": Done creating true_courseenrollment."

# ------------------ Table mapping any LTI to anon_screen_name -------------------

echo `date`": Creating Lti2Anon."
newTblCmd="DROP TABLE IF EXISTS Lti2Anon;
           CREATE TABLE Lti2Anon (lti_id varchar(32), anon_screen_name varchar(40))
           SELECT anonymous_user_id AS lti_id, anon_screen_name
             FROM edxprod.student_anonymoususerid LEFT JOIN EdxPrivate.UserGrade 
               ON edxprod.student_anonymoususerid.user_id = EdxPrivate.UserGrade.user_int_id;
          "

if [[ $MYSQL_VERSION == '5.6+' ]]
then
    echo $newTblCmd | mysql --login-path=root edxprod
    echo `date`": Building index Lti2Anon.lti_id."
    echo 'CREATE INDEX ltianon_lti_idx ON edxprod.Lti2Anon (lti_id);' | mysql --login-path=root edxprod
    echo `date`": Building index Lti2Anon.anon_screen_name."
    echo 'CREATE INDEX ltianon_anon_idx ON edxprod.Lti2Anon (anon_screen_name);' | mysql --login-path=root edxprod
else
    echo $newTblCmd | mysql -u root -p$MYSQL_PASSWD edxprod
    echo `date`": Building index on Lti2Anon.lti_id."
    echo 'CREATE INDEX ltianon_lti_idx ON edxprod.Lti2Anon (lti_id);' | mysql -u root -p$MYSQL_PASSWD edxprod
    echo `date`": Building index Lti2Anon.anon_screen_name."
    echo 'CREATE INDEX ltianon_anon_idx ON edxprod.Lti2Anon (anon_screen_name);' | mysql -u root -p$MYSQL_PASSWD edxprod
fi

echo `date`": Done creating Lti2Anon."


# ------------------ Table mapping any LTI to corresponding GlobalLti -------------------

echo `date`": Creating Lti2GlobalLti."
newTblCmd="DROP TABLE IF EXISTS Lti2GlobalLti;
	   CREATE TABLE Lti2GlobalLti (course_dependent_lti_id varchar(32),
	           	     	       global_lti_id varchar(32)) 
	   SELECT anonymous_user_id AS course_dependent_lti_id, 
	          IntIdGlobalLti.global_lti_id
	     FROM edxprod.student_anonymoususerid,
	          (SELECT user_id, anonymous_user_id AS global_lti_id
	           FROM edxprod.student_anonymoususerid
	          WHERE course_id = '') AS IntIdGlobalLti
	   WHERE  IntIdGlobalLti.user_id = edxprod.student_anonymoususerid.user_id;
          "

if [[ $MYSQL_VERSION == '5.6+' ]]
then
    echo $newTblCmd | mysql --login-path=root edxprod
    echo `date`": Building index Lti2GlobalLti.course_dependent_lti_id."
    echo 'CREATE INDEX lti2global_local_lti_idx ON edxprod.Lti2GlobalLti (course_dependent_lti_id);' | mysql --login-path=root edxprod
    echo `date`": Building index Lti2GlobalLti.global_lti_id."
    echo 'CREATE INDEX lti2global_global_id_idx ON edxprod.Lti2GlobalLti (global_lti_id);' | mysql --login-path=root edxprod
else
    echo $newTblCmd | mysql -u root -p$MYSQL_PASSWD edxprod
    echo `date`": Building index Lti2GlobalLti.course_dependent_lti_id."
    echo 'CREATE INDEX lti2global_local_lti_idx ON edxprod.Lti2GlobalLti (course_dependent_lti_id);' | mysql -u root -p$MYSQL_PASSWD edxprod
    echo `date`": Building index Lti2GlobalLti.global_lti_id."
    echo 'CREATE INDEX lti2global_global_id_idx ON edxprod.Lti2GlobalLti (global_lti_id);' | mysql -u root -p$MYSQL_PASSWD edxprod
fi

echo `date`": Done creating Lti2GlobalLti."

# ------------------ Signout -------------------
echo `date`": Finished refreshing edxprod tables."  | tee --append $LOG_FILE
echo "----------"
