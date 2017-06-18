#!/usr/bin/env bash
# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


# This script runs a MySQL bulk load script that was
# created by createBatchLoadFile.sh. Those scripts
# turn off lots of MySQL maintenance functions before
# running many LOAD DATA INFILE statements. The functions
# are then reinstated, and tables are re-indexed.
#
# This script needs to use MySQL as root. There are multiple
# methods for accomplishing this from the cmd line:
#   If -p is specified, the script asks for the pwd.
#   If -u myuid is specified, the script looks in myuid's
#      home directory for .ssh/mysql_root
#      If that file is found, its content is used as
#      the MySQL root pwd.
#   If neither -p nor -u are specified, the script looks in
#      the current user's home directory for .ssh/mysql_root
#      If that file is found, its content is used as
#      the MySQL root pwd. The current user is determined
#      by whoami
#   If -w rootpwd is specified, then that given pwd is used.
#   If none of -p, -u, -w are specified and/or no mysql_root
#      file is found, then the script attempts to access
#      MySQL as root without a pwd.

usage="Usage: "`basename $0`" [-u username][-p][-w rootpass] logDir bulkLoadSqlFile # You may be asked for MySQL root pwd."

# Determine if this is a Mac. Some bash
# commands are not available there:
if [[ $(echo $OSTYPE | cut -c 1-6) == 'darwin' ]]
then
    PLATFORM='macos'
    BASH_VERSION=$(echo $(bash --version) | sed -n 's/[^0-9]*version \([0-9]\).*/\1/p')
    if [[ $BASH_VERSION < 4 ]]
    then
        echo "On MacOS Bash version must be 4.0 or higher."
        exit 1
    fi
else
    PLATFORM='other'
fi    

# Get MySQL version on this machine.
# Cannot get PATH to be inherited by
# subshell on MacOS, so must hardcode
# the mysql executable...

if [[ $PLATFORM == 'macos' ]]
then
    MYSQL_BIN=/usr/local/bin/mysql
    MYSQL_VERSION=$($MYSQL_BIN --version | sed -ne 's/.*Distrib \([0-9][.][0-9]\).*/\1/p')
else
    MYSQL_BIN=$(which mysql)
    MYSQL_VERSION=$(${MYSQL_BIN} --version | sed -ne 's/.*Distrib \([0-9][.][0-9]\).*/\1/p')
fi

if [[ $MYSQL_VERSION > 5.5 ]]
then
    MYSQL_VERSION='5.6+'
else
    MYSQL_VERSION='5.5'
fi

if [ $# -lt 2 ]
then
    echo $usage
    exit 1
fi

askForPasswd=false
USERNAME=root
password=''
LOGFILE_NAME='loadLog'`date +%Y-%m-%dT%H_%M_%S`.log


# -------------------  Process Commandline Option -----------------

# Keep track of number of optional args the user provided:
NEXT_ARG=0
while getopts "u:pw:" opt
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
    w) # mysql pwd given on commandline:
      password=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    \?)
      # Illegal option; the getopts provided the error message
      echo $USAGE
      exit 1
      ;;
    :)
      echo $USAGE
      exit 1
      ;;
  esac
done

# Shift past all the optional parms:
shift ${NEXT_ARG}

if [ ! -d "$1" ]
then
    echo "First arg must be an existing directory for the load log file: $usage"
    exit 1
fi

if $askForPasswd
then
    # The -s option suppresses echo:
    read -s -p "Password for root on MySQL server: " password
    echo
elif [ -z $password ]
then
    # Get home directory of whichever user will
    # log into MySQL:
    if [[ $PLATFORM == 'macos' ]]
    then
        HOME_DIR=$(dscacheutil -q user -a name $USERNAME | sed -n 's/dir: \(.*$\).*/\1/p')
    else
        HOME_DIR=$(getent passwd $USERNAME | cut -d: -f6)
    fi
    # If the home dir has a readable file called mysql_root in its .ssh
    # subdir, then pull the pwd from there:
    if test -f $HOME_DIR/.ssh/mysql_root && test -r $HOME_DIR/.ssh/mysql_root
    then
	password=`cat $HOME_DIR/.ssh/mysql_root`
    fi
fi

logDir=$1
bulkLoadFile=$2

#************
#echo "logDir: "${logDir}
#echo "bulkLoadFile: "${bulkLoadFile}
#************

# Make sure that the bulk load script is readable:

if [ ! -r $bulkLoadFile ]
then
    echo "Bulk SQL load file "$bulkLoadFile" is not readable."
    exit 1
fi

LOG_FILE=$logDir/$LOGFILE_NAME
echo "Load process is logging to "$LOG_FILE

#**************
 # echo 'Password: '$password
 # echo 'Log dir: '$logDir
 # echo 'Files to load: '$@
 # echo 'Log file: ' $LOG_FILE
 # exit 0
#**************

# -------------------  Run the Bulk Load Script in MySQL -----------------

# Dict of tables and the db names in which they reside.
# Use a bash associative array (like a Python dict):
declare -A allTables
allTables=( ["EdxTrackEvent"]="Edx" \
            ["Answer"]="Edx" \
            ["CorrectMap"]="Edx" \
            ["InputState"]="Edx" \
            ["LoadInfo"]="Edx" \
            ["State"]="Edx" \
            ["ABExperiment"]="Edx" \
            ["OpenAssessment"]="Edx" \
            ["Account"]="EdxPrivate" \
            ["UserCountry"]="Edx" \
            ["EventIp"]="EdxPrivate" \
    )


# Do the actual loading of CSV files into their respective tables;
# We simply source the passed-in bulk load file to MySQL:
echo "`date`: starting load from $bulkLoadFile"  >> $LOG_FILE 2>&1

if [[ $MYSQL_VERSION == '5.6+' ]]
then
   MYSQL_AUTH="--login-path=root"
else
   MYSQL_AUTH="-u root -p$password"
fi

# For each table: disable keys:

echo "`date`: Disable indexing on all tables..."  >> $LOG_FILE 2>&1
for table in ${!allTables[*]}
do
  echo "    `date`: Disable indexing on ${allTables[$table]}.${table}..."  >> $LOG_FILE 2>&1
  ${MYSQL_BIN} $MYSQL_AUTH -e "ALTER TABLE ${allTables[$table]}.${table} DISABLE KEYS;" >> $LOG_FILE 2>&1
done
echo "`date`: Done disabling indexing on all tables..."  >> $LOG_FILE 2>&1

# Now load the big file:
echo "`date`: Start loading from $bulkLoadFile..."  >> $LOG_FILE 2>&1
${MYSQL_BIN} $MYSQL_AUTH -f --local_infile=1 < "${bulkLoadFile}" >> "${LOG_FILE}" 2>&1
echo "`date`: done loading from $bulkLoadFile"  >> $LOG_FILE 2>&1

# Re-build the indexes:
echo "`date`: Rebuilding indexes on tables..."  >> $LOG_FILE 2>&1
for table in ${!allTables[*]}
do
  MYSQL_CMD="USE ${allTables[$table]}; SET SESSION read_buffer_size = 64*1024*1024; \
             SET GLOBAL repair_cache.key_buffer_size = 50*1024*1024*1024; \
             CACHE INDEX ${allTables[$table]}.${table} IN repair_cache; \
             LOAD INDEX INTO CACHE ${allTables[$table]}.${table}; \
             REPAIR NO_WRITE_TO_BINLOG TABLE ${allTables[$table]}.${table}; \
             SET GLOBAL repair_cache.key_buffer_size = 0; \
            "
  #********************
  #echo "Re-index cmd: '$MYSQL_CMD'"
  #********************
  echo "    `date`: Rebuilding index on ${allTables[$table]}.${table}..."  >> $LOG_FILE 2>&1
  ${MYSQL_BIN} $MYSQL_AUTH -e "$MYSQL_CMD" >> $LOG_FILE 2>&1
  echo "    `date`: Done rebuilding index on ${allTables[$table]}.${table}..."  >> $LOG_FILE 2>&1
done

echo "`date`: Enable indexing on all tables..."  >> $LOG_FILE 2>&1
for table in ${!allTables[*]}
do
  echo "    `date`: Enable indexing on ${allTables[$table]}.${table}..."  >> $LOG_FILE 2>&1
  ${MYSQL_BIN} $MYSQL_AUTH -e "ALTER TABLE ${allTables[$table]}.${table} ENABLE KEYS;" >> $LOG_FILE 2>&1
done
echo "`date`: Done enabling indexing on all tables..."  >> $LOG_FILE 2>&1

exit 0
