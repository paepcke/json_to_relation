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


# Copies the latest modulestore tar ball from Stanford's backup server.
# Does the following:
#   - imports the entire store into the local MongoDB
#   - queries the local MongoDB, retrieving the information needed
#     for table CourseInfo. Truncates that table, and re-loads
#     it with the query result.
#   - queries the local MongoDB store again to extract a
#     .json file with infomration needed by modulestoreImporter.py.
#     That information holds mappings from OpenEdX 32-bit hashes
#     to human-readable strings. The file is named with datetime, and
#     goes into <projRoot>/json_to_relation/data. It is linked to
#     modulestore_latest.json in that same directory.
#
# The JSON file looks like this:
#
# [
#  	{
#  		"_id" : {
#  			"tag" : "i4x",
#  			"org" : "edx",
#  			"course" : "templates",
#  			"category" : "annotatable",
#  			"name" : "Annotation",
#  			"revision" : null
#  		},
#  		"metadata" : {
#  			"display_name" : "Annotation"
#  		}
#  	},
#  	{
#  		"_id" : {
#  			"tag" : "i4x",
#  			"org" : "edx",
#  			"course" : "templates",
#  			"category" : "conditional",
#  			"name" : "Empty",
#  			"revision" : null
#  		},
#  		"metadata" : {
#  			"display_name" : "Empty"
#  		}
#  	},
#      ...
# ]
#
# If option -p is provided, script will request root password for
# local MySQL. Else script looks for file ~/.ssh/mysql_root to
# contain that pwd.

USAGE="Usage: "`basename $0`" [-p]"

# Get MySQL version on this machine
MYSQL_VERSION=$(mysql --version | sed -ne 's/.*Distrib \([0-9][.][0-9]\).*/\1/p')
if [[ $MYSQL_VERSION > 5.5 ]]
then
    MYSQL_VERSION='5.6+'
else
    MYSQL_VERSION='5.5'
fi

# Get directory in which this script is running,
# and where its support scripts therefore live:
currScriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TARGET_DIR=$currScriptsDir/../json_to_relation/data

# Machine where modulestore snapshots live. Directory
# /data/dump, with file modulestore-latest.tar.gz.
EDX_PLATFORM_DUMP_MACHINE=jenkins.prod.class.stanford.edu

mkdir -p ${HOME}/Data/EdX/NonTransformLogs/
LOG_FILE=${HOME}/Data/EdX/NonTransformLogs/refreshModuleStore.log
needPasswd=false

MYSQL_PASSWD=''
MYSQL_USERNAME=root

# Root dir of where downloaded snapshots of
# modulestore go:
EDXPROD_DUMP_DIR=${HOME}/Data/FullDumps/ModulestorePlatformDbs

if [ ! -e $EDXPROD_DUMP_DIR ]
then
    $(mkdir -p $EDXPROD_DUMP_DIR)
    if [[ $? -ne 0 ]]
    then
        echo "Cannot create directory ${EDXPROD_DUMP_DIR} (maybe permissions?)" 
        exit 1
    fi
fi


# --------------------- Process Input Args -------------

# Keep track of number of optional args the user provided:
NEXT_ARG=0

while getopts "p" opt
do
  case $opt in
    p)
      needPasswd=true
      NEXT_ARG=$((NEXT_ARG + 1))
      ;;
    \?)
      # Illegal option; the getopts provided the error message
      echo $USAGE
      exit 1
      ;;
  esac
done

# Shift past all the optional parms:
shift ${NEXT_ARG}

if $needPasswd
then
    # The -s option suppresses echo:
    read -s -p "Password for user '"$MYSQL_USERNAME"' on local MySQL server: " MYSQL_PASSWD
    echo
else
    if [ ! -f $HOME/.ssh/mysql_root ]
    then
    echo "No password found for local MySQL in $HOME/.ssh/mysql_root; trying without a password."
    else
    MYSQL_PASSWD=$(<$HOME/.ssh/mysql_root)
    needPasswd=true
    fi
fi

targetFile=$TARGET_DIR/modulestore_`date +"%m_%d_%Y_%H_%M_%S"`.json

echo `date`": Activating Anaconda json_to_relation environment..."
source /home/dataman/anaconda2/bin/activate json_to_relation
echo `date`": Done activating Anaconda json_to_relation environment..."

# ------------------ Signin -------------------

echo `date`": Starting to refresh modulestore: CourseInfo, EdxProblem, EdxVideo..."  | tee --append $LOG_FILE

# ------------------ Pull Modulestore from Backup Server -------------------

# Download new modulestore MongoDB files from backup server.
# SOURCE the script that does this so it sees all the 
# environment variables set up above:

echo `date`": Running cronRefreshModuleStore_Helper.sh..."  | tee --append $LOG_FILE
source /home/dataman/Code/json_to_relation/scripts/cronRefreshModuleStore_Helper.sh >> /home/dataman/cronlog/cronRefreshModuleStore.txt 2>&1
echo `date`": Done running cronRefreshModuleStore_Helper.sh..."  | tee --append $LOG_FILE

# ------------------ Update CourseInfo, EdxProblem, EdxVideo  -------------------

echo `date`": Running modulestoreToSQL.py..."  | tee --append $LOG_FILE
/home/dataman/Code/json_to_relation/json_to_relation/modulestoreToSQL.py >> /home/dataman/cronlog/modulestoreToSQL.txt
echo `date`": Done running modulestoreToSQL.py..."  | tee --append $LOG_FILE

# ------------------ Signout -------------------
echo `date`": Finished updating table modulestore extract."  | tee --append $LOG_FILE
echo "----------"
