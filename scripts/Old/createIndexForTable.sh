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


# NOTE: this script is only used for repairs when entire
#       tables had to be deleted, and were then loaded
#       (and thereby created) from scratch. In that case
#       all the indexes would be missing. No need to
#       use this script after using manageEdxDb.sh
# Optionally given one or more table names in the Edx 
# or EdxPrivate databases, create the indexes that are 
# needed for those tables. If no tables are given,
# will create the indexes for all tables.

usage="Usage: `basename $0` [-u username][-p] [tableName [tableName ...]]"

USERNAME=`whoami`
askForPasswd=false

# Keep track of number of optional args the user provided:
NEXT_ARG=0
while getopts "u:p:" opt
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


if $askForPasswd
then
    # The -s option suppresses echo:
    read -s -p "Password for $USERNAME on MySQL server: " password
    echo
elif [ -z $password ]
then
    if [ $USERNAME == "root" ]
    then
        # Get home directory of whichever user will
        # log into MySQL:
	HOME_DIR=$(getent passwd `whoami` | cut -d: -f6)
        # If the home dir has a readable file called mysql_root in its .ssh
        # subdir, then pull the pwd from there:
	if test -f $HOME_DIR/.ssh/mysql_root && test -r $HOME_DIR/.ssh/mysql_root
	then
	    password=`cat $HOME_DIR/.ssh/mysql_root`
	fi
    else
        # Get home directory of whichever user will
        # log into MySQL:
	HOME_DIR=$(getent passwd $USERNAME | cut -d: -f6)

        # If the home dir has a readable file called mysql in its .ssh
        # subdir, then pull the pwd from there:
	if test -f $HOME_DIR/.ssh/mysql && test -r $HOME_DIR/.ssh/mysql
	then
	    password=`cat $HOME_DIR/.ssh/mysql`
	fi
    fi
fi

# Dict of tables and the db names in which they reside.
# Use a bash associative array (like a Python dict):
declare -A allTables
allTables=( ["EdxTrackEvent"]="Edx" \
            ["Answer"]="Edx" \
            ["CorrectMap"]="Edx" \
            ["InputState"]="Edx" \
            ["LoadInfo"]="Edx" \
            ["State"]="Edx" \
            ["Account"]="EdxPrivate" \
    )

# If no table name was given, create the appropriate indexes
# for all the tables:

if [ $# -lt 1 ]
then
    # No tables provided on CL; use the keys of
    # the tables dict (the ! chooses 'all keys';
    # without the ! would choose all values):
    tables=${!allTables[@]}
else
    tables=$@
fi

#*****************
# echo 'UID: '$USERNAME
# echo 'Password: '$password
# echo 'Tables to index: '$tables
# exit 0
#*****************

for table in ${tables[@]}
do
    if [ $table == 'EdxTrackEvent' ]
    then
	# The '${allTables["$table"]}' parts below resolve to the database in which the respective table resides:
	echo "Creating index on EdxTrackEvent(event_type)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX EdxTrackEventIdxEvType ON '${allTables["$table"]}'.EdxTrackEvent(event_type(255));'
	echo "Creating index on EdxTrackEvent(anon_screen_name)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX EdxTrackEventIdxIdxUname ON '${allTables["$table"]}'.EdxTrackEvent(anon_screen_name(255));'
	echo "Creating index on EdxTrackEvent(course_id)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX EdxTrackEventIdxCourseID ON '${allTables["$table"]}'.EdxTrackEvent(course_id(255));'
	echo "Creating index on EdxTrackEvent(course_display_name)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX EdxTrackEventIdxCourseDisplayName ON '${allTables["$table"]}'.EdxTrackEvent(course_display_name(255));'
	echo "Creating index on EdxTrackEvent(resource_display_name)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX EdxTrackEventIdxResourceDisplayName ON '${allTables["$table"]}'.EdxTrackEvent(resource_display_name(255));'
	echo "Creating index on EdxTrackEvent(success)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX EdxTrackEventIdxSuccess ON '${allTables["$table"]}'.EdxTrackEvent(success(15));'
	echo "Creating index on EdxTrackEvent(time)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX EdxTrackEventIdxTime ON '${allTables["$table"]}'.EdxTrackEvent(time);'
	echo "Creating index on EdxTrackEvent(ip)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX EdxTrackEventIdxIP ON '${allTables["$table"]}'.EdxTrackEvent(ip(16));'
    elif [ $table == 'Answer' ]
    then
	echo "Creating index on Answer(answer)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX AnswerIdxAns ON '${allTables["$table"]}'.Answer(answer(255));'
	echo "Creating index on Answer(course_id)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX AnswerIdxCourseID ON '${allTables["$table"]}'.Answer(course_id(255));'
    elif [ $table == 'Account' ]
    then
	echo "Creating index on Account(screen_name)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX AccountIdxUname ON '${allTables["$table"]}'.Account(screen_name(255));'
	echo "Creating index on Account(anon_screen_name)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX AccountIdxAnonUname ON '${allTables["$table"]}'.Account(anon_screen_name(255));'
	echo "Creating index on Account(zipcode)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX AccountIdxZip ON '${allTables["$table"]}'.Account(zipcode(10));'
	echo "Creating index on Account(country)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX AccountIdxCoun ON '${allTables["$table"]}'.Account(country(255));'
	echo "Creating index on Account(gender)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX AccountIdxGen ON '${allTables["$table"]}'.Account(gender(6));'
	echo "Creating index on Account(year_of_birth)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX AccountIdxDOB ON '${allTables["$table"]}'.Account(year_of_birth);'
	echo "Creating index on Account(level_of_education)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX AccountIdxEdu ON '${allTables["$table"]}'.Account(level_of_education(10));'
	echo "Creating index on Account(course_id)..."
	mysql -u $USERNAME -p$password -e 'CREATE INDEX AccountIdxCouID ON '${allTables["$table"]}'.Account(course_id(255));'
    fi
done
