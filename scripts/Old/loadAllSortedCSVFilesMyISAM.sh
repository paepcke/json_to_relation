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


# Takes a directory name where a log file named mysqlCSVLoad.log
# will be created or appended to. The remaining arguments must
# be .csv files destined for Edx db. The file names are assumed
# to be of the form:
#     tracking.log-20131020.gz.2013-11-10T23_26_00.393001_16099_State_UnsortedSorted.csv
# In particular, the (zero based) 4th fragment of each .csv file must
# be the name of the table to which the file is directed. 
#
# If incoming rows duplicate keys of already existing rows, then the
# incoming rows are ignored. It is therefore safe to re-load files
# with fixed primary keys.

usage="Usage: loadAllSortedCSVFiles.sh logDir file1.csv file2.csv..."

if [ $# -lt 1 ]
then
    echo $usage
    exit 1
fi

if [ ! -d "$1" ]
then
    echo "First arg must be a directory: $usage"
    exit 1
fi

read -s -p "Root's MySQL Password: " password
echo

logDir=$1
shift

for sortedCSVFile in $@
do  
    # File names are like this:
    #   tracking.log-20131020.gz.2013-11-10T23_26_00.393001_16099_State_UnsortedSorted.csv
    # We need the table name, in this case 'State'. Use bash array: Chop the file
    # name into an array by splitting it on '_'; the 4th element will be the table name:
    IFS='_' read  -a array <<< "$sortedCSVFile"
    tableName=${array[4]}

    if [ $tableName = 'Account' ]
    then
	dbName='EdxPrivate'
	lockTablesCmd="LOCK TABLES Account WRITE;"
    else
	dbName='Edx'
	lockTablesCmd="LOCK TABLES EdxTrackEvent WRITE,Answer WRITE,State WRITE,CorrectMap WRITE,InputState WRITE,Account WRITE,LoadInfo WRITE;"
    fi

    echo "`date`: starting on $sortedCSVFile" >> $logDir/mysqlCSVLoad.log

    mysqlCmd=\
"SET unique_checks=0; \
SET foreign_key_checks=0; \
SET sql_log_bin=0; \
USE $dbName; \
$lockTablesCmd; \
LOAD DATA LOCAL INFILE '$sortedCSVFile' \
IGNORE \
INTO TABLE $tableName \
FIELDS OPTIONALLY ENCLOSED BY \"'\" TERMINATED BY ','; \
UNLOCK TABLES; \
SET unique_checks=1; \
SET foreign_key_checks=1; \
SET sql_log_bin=1;"

  mysql -f -u root -p$password --local_infile=1 -e "$mysqlCmd" >> $logDir/mysqlCSVLoad.log
#    echo $mysqlCmd; exit

#     mysql -f -u root -p$password -e "$mysqlCmd" >> $logDir/mysqlCSVLoad.log
done
exit
