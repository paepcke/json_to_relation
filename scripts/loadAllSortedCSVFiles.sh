#!/bin/bash

# Takes a directory name where a log file named mysqlCSVLoad.log
# will be created or appended to. The remaining arguments must
# be .csv files destined for Edx db. The file names are assumed
# to be of the form:
#     tracking.log-20131020.gz.2013-11-10T23_26_00.393001_16099_State_UnsortedSorted.csv
# In particular, the (zero based) 4th fragment of each .csv file must
# be the name of the table to which the file is directed. 

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
    else
	dbName='Edx'
    fi

    mysqlCmd="SET unique_checks=0; \
              SET foreign_key_checks = 0; \
	      SET sql_log_bin=0; \
	      USE $dbName; LOAD DATA LOCAL INFILE '$sortedCSVFile' \
	      INTO TABLE $tableName \
	      FIELDS OPTIONALLY ENCLOSED BY \"'\" TERMINATED BY ','; \
	      SET unique_checks=1; \
	      SET foreign_key_checks = 1; \
	      SET sql_log_bin=1;"

    mysql -f -u root -p$password --local_infile=1 -e "$mysqlCmd" >> $logDir/mysqlCSVLoad.log
done
exit
