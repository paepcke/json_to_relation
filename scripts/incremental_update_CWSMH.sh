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


# Copies latest incremental courseware_studentmodulehistory tables
# from jenkins, loads them, appends them to the courseware_studentmodulehistory
# table, and registers that these incrementals are now done:

EDX_PLATFORM_DUMP_MACHINE=jenkins.prod.class.stanford.edu
REMOTE_BACKUP_DIR=/data/dump/csmhe

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
echo `date`": Begin incremental appending to courseware_studentmodulehistory."  | tee --append $LOG_FILE
echo "----------"
# ------------------ Copy full edxprod dump from prod machine to datastage -------------------

if [[ COPY_FROM_PLATFORM_BACKUP -eq 1 ]]
then
    # Get array of dates of incremental updates. They are
    # in the form: edxappcsmh-20171220.sql.gz
    # So, get a bash array like [20171220 20171223 ...]:

    INCREMENTALS_DATES=( $(ssh ${EDX_PLATFORM_DUMP_MACHINE} "ls ${REMOTE_BACKUP_DIR} \
                            | sed -rn 's/edxappcsmh-([0-9]{8,8}).sql.gz$/\1/p'") )
    if [[ $? != 0 ]]
    then
        echo "********* Could not pull dates of incremental updates; quitting"
        exit 1
    fi

    # Get latest already loaded incremental's date as yyyymmdd, i.e.
    # remove the dashes in 2017-12-04:
    MOST_RECENT=$( mysql --login-path=${MYSQL_USERNAME} edxprod -e "select max(load_date) from CrseWareStdntModHistLoadDates;" \
                       | sed -rn 's/([0-9]{4,4})-([0-9]{2,2})-([0-9]{2,2})/\1\2\3/p' )

    echo "Most recently loaded courseware_studentmodulehistory increment: ${MOST_RECENT}."

    for (( i=0; i<${#INCREMENTALS_DATES[@]}; i++ ))
    do
        FILE_DATE=${INCREMENTALS_DATES[i]}
        #**********
        echo "FILE_DATE: '${FILE_DATE}'"
        #**********
        # Is incremental file older than the most recently loaded file?
        if [[ ${MOST_RECENT} -ge ${FILE_DATE} ]]
        then
            # Already loaded this file:
            continue
        fi

        # Construct the incremental's file name to copy over:
        FILENAME=edxappcsmh-${FILE_DATE}.sql.gz

        echo "Pulling incremental file ${FILENAME}..."

        scp ${EDX_PLATFORM_DUMP_MACHINE}:${REMOTE_BACKUP_DIR}/${FILENAME} ${EDXPROD_DUMP_DIR}

        # Load this file:
        echo `date`": Loading file ${FILENAME}..."
        zcat ${EDXPROD_DUMP_DIR}/${FILENAME} | mysql --login-path=${MYSQL_USERNAME} edxprod
        if [[ $? != 0 ]]
        then
            echo `date`": ********* Could not load ${FILENAME}."
            exit 1
        else
            echo `date`": Done loading ${FILENAME}."
        fi

        #**********
        echo `date`": Would insert new entries..."
        
        read -rd '' HISTORY_INSERT_CMD <<EOF
        INSERT IGNORE INTO courseware_studentmodulehistory
        select id,student_module_id, version, created, state, grade, max_grade,course_id
          from coursewarehistoryextended_studentmodulehistoryextended;
EOF

        echo "TMP: HISTORY_INSERT_CMD: '${HISTORY_INSERT_CMD}'"
        #****mysql --login-path=${MYSQL_USERNAME} edxprod -e "${HISTORY_INSERT_CMD}"


        DATE_WITH_DASHES=$( echo ${FILE_DATE} | sed -rn 's/([0-9]{4,4})([0-9]{2,2})([0-9]{2,2})/\1-\2-\3/p' )
        read -rd '' DATE_INSERT_CMD <<EOF
        INSERT INTO CrseWareStdntModHistLoadDates VALUES ('${DATE_WITH_DASHES}');
EOF
        echo "TMP: DATE_INSERT_CMD: ${DATE_INSERT_CMD}"

        echo `date`": Would insert update of latest increment-date record..."

        #****mysql --login-path=${MYSQL_USERNAME} edxprod -e "${DATE_INSERT_CMD}"

        echo `date`": Dropping incremental table..."
        mysql --login-path=${MYSQL_USERNAME} edxprod -e "DROP TABLE coursewarehistoryextended_studentmodulehistoryextended;"
        echo `date`": Done dropping incremental table..."
        
        #**********
    done
fi
