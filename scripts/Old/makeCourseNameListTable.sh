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


# ------------------ Process Commandline Options -------------------

USAGE="Usage: "`basename $0`" [-u uid][-p][-h help]"

USERNAME=`whoami`
PASSWD=''
COURSE_SUBSTR=''
DB_NAME='Extracts'
needPasswd=false
TABLE_NAME=''
ALL_COLS=''

# Execute getopt
ARGS=`getopt -o "u:ph" -l "user:,password,help" \
      -n "getopt.sh" -- "$@"`
 
#Bad arguments
if [ $? -ne 0 ];
then
  exit 1
fi
 
# A little magic
eval set -- "$ARGS"
 
# Now go through all the options
while true;
do
  case "$1" in
    -u|--user)
      shift
      # Grab the option value:
      if [ -n "$1" ]
      then
        USERNAME=$1
        shift
      fi;;
 
    -p|--password)
      needPasswd=true
      shift;;
 
    -h|--help)
      echo $USAGE
      exit 0
      ;;
    --)
      shift
      break;;
  esac
done

if $needPasswd
then
    # The -s option suppresses echo:
    read -s -p "Password for user '$USERNAME' on `hostname`'s MySQL server: " PASSWD
    echo
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

if [ -z $PASSWD ]
then
    MYSQL_AUTH="-u $USERNAME"
else
    MYSQL_AUTH="-u $USERNAME -p$PASSWD"
fi

mysql $MYSQL_AUTH -e "USE Edx; DROP TABLE IF EXISTS AllCourseDisplayNames;"
mysql $MYSQL_AUTH -e "USE Edx; CREATE TABLE AllCourseDisplayNames \
                         (course_display_name varchar(255) NOT NULL PRIMARY KEY) \
                      (SELECT DISTINCT course_display_name \
                       FROM EventXtract) \
                      UNION \
                      (SELECT DISTINCT course_display_name \
                       FROM ActivityGrade) \
                      ;"
