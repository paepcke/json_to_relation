#!/bin/bash

# Takes a list of .sql 'main' files that were created by
# json2sql.py --targetFormat csv ... That command created
# a series of files: foo.sql, foo.sql_Table1.csv, foo.sql_Table2.csv,...
# This script prepares MySQL for a fast LOAD INFILE of the .csv files
# by using myisamchk to remove all indexes. Then the .csv files
# are loaded without indexing. Finally, myisamchk is used to
# create all the indexes in memory. Remember: each .sql file
# knows to load each table's .csv files.

usage="Usage: executeCSVLoad.sh logDir file1.sql file2.sql..."

if [ $# -lt 1 ]
then
    echo $usage
    exit 1
fi

if [ ! -d "$1" ]
then
    echo "First arg must be a directory for the log file(s): $usage"
    exit 1
fi

read -s -p "Root's MySQL Password: " password
echo

logDir=$1
shift

# Get "datadir = <loc of MySQL data directory as declared in my.cnf>":
MYSQL_DATADIR_DECL=`grep datadir /etc/mysql/my.cnf`
# Extract just the directory:
MYSQL_DATADIR=`echo $s | cut -d'=' -f 2`

mysqladmin flush-tables
if [ -e ${MYSQL_DATADIR}/Edx/EdxTrackEvent.MYI ]; then myisamchk --keys-used=0 -rq ${MYSQL_DATADIR}/Edx/EdxTrackEvent.MYI; fi
if [ -e ${MYSQL_DATADIR}/Edx/Answer.MYI ]; then myisamchk --keys-used=0 -rq ${MYSQL_DATADIR}/Edx/Answer.MYI; fi
if [ -e ${MYSQL_DATADIR}/Edx/State.MYI ]; then myisamchk --keys-used=0 -rq ${MYSQL_DATADIR}/Edx/State.MYI; fi
if [ -e ${MYSQL_DATADIR}/Edx/CorrectMap.MYI ]; then myisamchk --keys-used=0 -rq ${MYSQL_DATADIR}/Edx/CorrectMap.MYI; fi
if [ -e ${MYSQL_DATADIR}/Edx/LoadInfor.MYI ]; then myisamchk --keys-used=0 -rq ${MYSQL_DATADIR}/Edx/LoadInfo.MYI; fi
if [ -e ${MYSQL_DATADIR}/Edx/Account.MYI ]; then myisamchk --keys-used=0 -rq ${MYSQL_DATADIR}/Edx/Account.MYI; fi
if [ -e ${MYSQL_DATADIR}/EdxPrivate/Account.MYI ]; then myisamchk --keys-used=0 -rq ${MYSQL_DATADIR}/EdxPrivate/Account.MYI; fi


for sqlFile in $@
do  
    echo "`date`: starting on $sqlFile" >> $logDir/mysqlCSVLoad.log
    mysql -f -u root -p$password --local_infile=1 < $sqlFile >> $logDir/mysqlCSVLoad.log
    echo "`date`: done loading $sqlFile" >> $logDir/mysqlCSVLoad.log
done
exit
