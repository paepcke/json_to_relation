#!/bin/bash

# Takes a list of .sql 'main' files that were created by
# json2sql.py --targetFormat csv ... That command created
# a series of files: foo.sql, foo.sql_Table1.csv, foo.sql_Table2.csv,...
# This script prepares MySQL for a fast LOAD INFILE of the .csv files
# by using myisamchk to remove all indexes, and disabling
# on-insert index updates. Then the .csv files
# are loaded without indexing. Finally, myisamchk is used to
# create all the indexes in memory. 
# Finally indexes on other columns in various tables are built.
# Remember: each .sql file knows to load each table's .csv files.

usage="Usage: executeCSVLoad.sh logDir file1.sql file2.sql... # You'll be asked for MySQL root pwd."

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

if [ `whoami` != 'root' ]
then
    echo 'You must run this script as sudo.'
    exit
fi

read -s -p "Root's MySQL Password: " password
echo

logDir=$1
shift

# Get "datadir = <loc of MySQL data directory as declared in my.cnf>":
MYSQL_DATADIR_DECL=`grep datadir /etc/mysql/my.cnf`
# Extract just the directory:
MYSQL_DATADIR=`echo $s | cut -d'=' -f 2`

# Array of all tables we will deal with;
# the array is used in loops:
tables=(EdxTrackEvent \
        Answer \
        CorrectMap \
        InputState \
        LoadInfo \
        State \
       )
privateTables=(Account)

# Turn off MySQL indexing; Begin by flushing tables:

# Public tables:
for table in ${tables[@]}
do
    echo "`date`: Flushing table $table:"
    if [ -e ${MYSQL_DATADIR}/Edx/$table.MYI ]
    then
	mysql -u root -p$password -e 'FLUSH TABLES $table' Edx >> $logDir/mysqlCSVLoad.log
    fi
done

# Private tables:
for table in ${privateTables[@]}
do
    echo "`date`: Flushing table $table:"
    if [ -e ${MYSQL_DATADIR}/EdxPrivate/$table.MYI ]
    then
	mysql -u root -p$password -e 'FLUSH TABLES $table' EdxPrivate >> $logDir/mysqlCSVLoad.log
    fi
done


# Turn off indexing table by table:

# Public tables:
for table in ${tables[@]}
do
    if [ -e ${MYSQL_DATADIR}/Edx/$table.MYI ]
    then
	myisamchk --keys-used=0 -rq ${MYSQL_DATADIR}/Edx/$table.MYI; 
    fi
done

# Private tables:
for table in ${privateTables[@]}
do
    if [ -e ${MYSQL_DATADIR}/EdxPrivate/$table.MYI ]
    then 
	myisamchk --keys-used=0 -rq ${MYSQL_DATADIR}/EdxPrivate/$table.MYI; 
    fi
done

# Do the actual loading of CSV files into their respective tables:
for sqlFile in $@
do  
    echo "`date`: starting on $sqlFile" >> $logDir/mysqlCSVLoad.log
    mysql -f -u root -p$password --local_infile=1 < $sqlFile >> $logDir/mysqlCSVLoad.log
    echo "`date`: done loading $sqlFile" >> $logDir/mysqlCSVLoad.log
done

# Re-Index the primary and foreign key fields in each table. This
# happens in memory, and will leave prefectly balanced btrees.
# This does not yet index the non-key columns:

# Public tables:
for table in ${tables[@]}
do
    echo "`date`: Indexing primary and foreign keys for table $table..." >> $logDir/mysqlCSVLoad.log
    time sudo myisamchk -rq ${MYSQL_DATADIR}/Edx/$table.MYI >> $logDir/mysqlCSVLoad.log
done

# Private tables:
for table in ${privateTables[@]}
do
    echo "`date`: Indexing primary and foreign keys for table EdxPrivate.$table..." >> $logDir/mysqlCSVLoad.log
    time sudo  myisamchk -rq ${MYSQL_DATADIR}/EdxPrivate/$table.MYI >> $logDir/mysqlCSVLoad.log
done

echo "`date`: Done indexing primary and foreign keys." >> $logDir/mysqlCSVLoad.log

# Build the other indexes:

#mysql -u root -p$password < edxCreateIndexes.sql

echo "`date`: indexing Edx.EdxTrackEvent(event_type(255))"
mysql -u root -p$password -e 'CREATE INDEX EdxTrackEventIdxEvType ON Edx.EdxTrackEvent(event_type(255))'

echo "`date`: indexing Edx..EdxTrackEvent(anon_screen_name(255))"
mysql -u root -p$password -e 'CREATE INDEX EdxTrackEventIdxUname ON Edx.EdxTrackEvent(anon_screen_name(255))'

echo "`date`: indexing Edx..EdxTrackEvent(course_id(255))"
mysql -u root -p$password -e 'CREATE INDEX EdxTrackEventIdxCourseID ON Edx.EdxTrackEvent(course_id(255))'

echo "`date`: indexing Edx..EdxTrackEvent(course_display_name(255))"
mysql -u root -p$password -e 'CREATE INDEX EdxTrackEventIdxCourseDisplayName ON Edx.EdxTrackEvent(course_display_name(255))'

echo "`date`: indexing Edx..EdxTrackEvent(resource_display_name(255))"
mysql -u root -p$password -e 'CREATE INDEX EdxTrackEventIdxResourceDisplayName ON Edx.EdxTrackEvent(resource_display_name(255))'

echo "`date`: indexing Edx..EdxTrackEvent(sequence_id(255))"
mysql -u root -p$password -e 'CREATE INDEX EdxTrackEventIdxSeqID ON Edx.EdxTrackEvent(sequence_id(255))'

echo "`date`: indexing Edx..EdxTrackEvent(problem_id(255))"
mysql -u root -p$password -e 'CREATE INDEX EdxTrackEventIdxProbID ON Edx.EdxTrackEvent(problem_id(255))'

echo "`date`: indexing Edx..EdxTrackEvent(video_id(255))"
mysql -u root -p$password -e 'CREATE INDEX EdxTrackEventIdxVidID ON Edx.EdxTrackEvent(video_id(255))'

echo "`date`: indexing Edx..EdxTrackEvent(answer_id(255))"
mysql -u root -p$password -e 'CREATE INDEX EdxTrackEventIdxAnsID ON Edx.EdxTrackEvent(answer_id(255))'

echo "`date`: indexing Edx..EdxTrackEvent(success(15))"
mysql -u root -p$password -e 'CREATE INDEX EdxTrackEventIdxSuccess ON Edx.EdxTrackEvent(success(15))'

echo "`date`: indexing Edx..EdxTrackEvent(time)"
mysql -u root -p$password -e 'CREATE INDEX EdxTrackEventIdxTime ON Edx.EdxTrackEvent(time)'

echo "`date`: indexing Edx..Answer(answer(255))"
mysql -u root -p$password -e 'CREATE INDEX AnswerIdxAns ON Edx.Answer(answer(255))'

echo "`date`: indexing Edx..Answer(problem_id(255))"
mysql -u root -p$password -e 'CREATE INDEX AnswerIdxProbID ON Edx.Answer(problem_id(255))'

echo "`date`: indexing Edx..Answer(course_id(255))"
mysql -u root -p$password -e 'CREATE INDEX AnswerIdxCourseID ON Edx.Answer(course_id(255))'

echo "`date`: indexing Private.Account(screen_name(255))"
mysql -u root -p$password -e 'CREATE INDEX AccountIdxUname ON EdxPrivate.Account(screen_name(255))'

echo "`date`: indexing Private.Account(anon_screen_name(255))"
mysql -u root -p$password -e 'CREATE INDEX AccountIdxAnonUname ON EdxPrivate.Account(anon_screen_name(255))'

echo "`date`: indexing Private.Account(zipcode(10))"
mysql -u root -p$password -e 'CREATE INDEX AccountIdxZip ON EdxPrivate.Account(zipcode(10))'

echo "`date`: indexing Private.Account(country(255))"
mysql -u root -p$password -e 'CREATE INDEX AccountIdxCoun ON EdxPrivate.Account(country(255))'

echo "`date`: indexing Private.Account(gender(6))"
mysql -u root -p$password -e 'CREATE INDEX AccountIdxGen ON EdxPrivate.Account(gender(6))'

echo "`date`: indexing Private.Account(year_of_birth)"
mysql -u root -p$password -e 'CREATE INDEX AccountIdxDOB ON EdxPrivate.Account(year_of_birth)'

echo "`date`: indexing Private.Account(level_of_education(10))"
mysql -u root -p$password -e 'CREATE INDEX AccountIdxEdu ON EdxPrivate.Account(level_of_education(10))'

echo "`date`: indexing Private.Account(course_id(255))"
mysql -u root -p$password -e 'CREATE INDEX AccountIdxCouID ON EdxPrivate.Account(course_id(255))'

echo "`date`: Done loading" >> $logDir/mysqlCSVLoad.log

exit
