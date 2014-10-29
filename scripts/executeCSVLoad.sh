#!/bin/bash

# Takes a list of .sql 'main' files that were created by
# json2sql.py --targetFormat csv ... That command created
# a series of files: foo.sql, foo.sql_Table1.csv, foo.sql_Table2.csv,...
# This script prepares MySQL for a fast LOAD INFILE of the .csv files
# by removing all indexes, and disabling
# on-insert index updates. Then the .csv files
# are loaded without indexing. Finally, the indexes are
# created in memory, if sufficient RAM is available.
# Remember: each .sql file knows to load each table's .csv files.
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
# 
# This script is complex enough that Python would have
# been more appropriate. But it grew from a small kernel.

usage="Usage: "`basename $0`" [-u username][-p][-w rootpass] logDir file1.sql file2.sql... # You may be asked for MySQL root pwd."

if [ $# -lt 1 ]
then
    echo $usage
    exit 1
fi

askForPasswd=false
USERNAME=`whoami`
password=''
LOGFILE_NAME='loadLog'`date +%Y-%m-%dT%H_%M_%S`.log

#  -------------------  Define Bash Functions -----------------

inArray() {
# Given a value to find, followed by
# other values to check against, 
# echo 1 if value matches any of the
# trailing values, else 
# echo 0.
# Use: result=$(inArray foo bar fum foo) ---> echoes '1'
# or:  result=$(inArray foo ${myArray[@]}) ---> echoes '1' if 'foo' is in myArray

    elemToFind=$1
    shift
    for element in $@
    do
	if [ $elemToFind == $element ]
	then
	    echo 1
	    return
	fi
    done
    echo 0
}

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
    HOME_DIR=$(getent passwd $USERNAME | cut -d: -f6)
    # If the home dir has a readable file called mysql_root in its .ssh
    # subdir, then pull the pwd from there:
    if test -f $HOME_DIR/.ssh/mysql_root && test -r $HOME_DIR/.ssh/mysql_root
    then
	password=`cat $HOME_DIR/.ssh/mysql_root`
    fi
fi

logDir=$1
shift

# Make sure all the files remaining in the 
# argument list are readable files:
for file in $@
do
    okSoFar=1
    # Get file extension:
    filename=$(basename "$file")
    extension="${filename##*.}"

    if [ ! -r $file ]
    then
	echo "File "$file" is not readable."
	okSoFar=0
    elif [ -d $file ]
    then
	echo "File "$file" is a directory."
	okSoFar=0
    elif [ $extension != 'sql' ]
    then
	echo "File "$file" does not end with .sql (I know...picky, but better than crashing later)"
	okSoFar=0
    fi
done
if [ $okSoFar -ne 1 ]
then
    echo "Aborting due to above errors; no files were loaded into the database."
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

# Get "datadir = <loc of MySQL data directory as declared in my.cnf>":
MYSQL_DATADIR_DECL=`grep datadir /etc/mysql/my.cnf`
# Extract just the directory:
MYSQL_DATADIR=`echo $s | cut -d'=' -f 2`

# -------------------  Declare Table Vars and FLUSH MySQL Tables -----------------

# Dict of tables and their primary key columns
# Use a bash associative array (like a Python dict):
declare -A tables
tables=( ["EdxTrackEvent"]="_id" \
         ["Answer"]="answer_id" \
         ["CorrectMap"]="correct_map_id" \
         ["InputState"]="input_state_id" \
         ["LoadInfo"]="load_info_id" \
         ["State"]="state_id" \
         ["ABExperiment"]="event_table_id" \
         ["OpenAssessment"]="event_table_id" \
    )

declare -A privateTables
privateTables=( ["Account"]="account_id" \
                ["EventIp"]="event_table_id" \
    )

# Flush Public tables; the ${!tables[@]} loops through the table names (i.e. dict keys)
for table in ${!tables[@]}
do
    echo "`date`: Flushing table $table:" >> $LOG_FILE 2>&1
    { mysql -u root -p$password -e 'FLUSH TABLES $table' Edx; } >> $LOG_FILE 2>&1
done

# Flush Private tables; the ${!privateTables[@]} loops through the table names (i.e. dict keys)
for table in ${!privateTables[@]}
do
    echo "`date`: Flushing table $table:"  >> $LOG_FILE 2>&1
    { mysql -u root -p$password -e 'FLUSH TABLES $table' EdxPrivate; } >> $LOG_FILE 2>&1
done

# -------------------  Remove Primary Keys for Loading Speed -----------------

# # Remove primary keys from public tables to speed loading; the ${!tables[@]} loops through the table names (i.e. dict keys)
# for table in ${!tables[@]}
# do
#     echo "`date`: dropping primary key from Edx.$table" >> $LOG_FILE 2>&1
#     { mysql -u root -p$password -e "USE Edx; CALL dropPrimaryIfExists('"$table"');"; } >> $LOG_FILE 2>&1	
# done

# # Private tables; the ${!privateTables[@]} loops through the table names (i.e. dict keys)
# for table in ${!privateTables[@]}
# do
#     echo "`date`: dropping primary key from EdxPrivate.$table" >> $LOG_FILE 2>&1
#     { mysql -u root -p$password -e "USE EdxPrivate; CALL dropPrimaryIfExists('"$table"');"; } >> $LOG_FILE 2>&1	
# done

# -------------------  Loading SQL Files, Which Load CSVs -----------------

# Do the actual loading of CSV files into their respective tables;
# $@ are the .sql files from the CLI:
for sqlFile in $@
do  
    echo "`date`: starting on $sqlFile"  >> $LOG_FILE 2>&1
    { mysql -f -u root -p$password --local_infile=1 < $sqlFile; } >> $LOG_FILE 2>&1
    mysql -f -u root -p$password -e "USE Edx; COMMIT; USE EdxPrivate; COMMIT;"
    echo "`date`: done loading $sqlFile"  >> $LOG_FILE 2>&1
done

# -------------------  Restore Primary Keys -----------------

# Add primary keys back in:
# Public tables; the ${!tables[@]} loops through the table names (i.e. dict keys)
# for table in ${!tables[@]}
# do
#     echo "`date`: adding primary key to table Edx."$table"..." >> $LOG_FILE 2>&1
#     # The ${tables["$table"]} accesses the primary key column name (i.e. the value of the dict):
#     { mysql -u root -p$password -e "USE Edx; CALL addPrimaryIfNotExists('"$table"','"${tables[$table]}"');"; } >> $LOG_FILE 2>&1
# done

# # Private tables; the ${!tables[@]} loops through the table names (i.e. dict keys)
# for table in ${!privateTables[@]}
# do
#     echo "`date`: adding primary key to table EdxPrivate."$table"..." >> $LOG_FILE 2>&1
#     # The ${tables["$table"]} accesses the primary key column (i.e. the value of the dict):
#     { mysql -u root -p$password -e "USE EdxPrivate; CALL addPrimaryIfNotExists('"$table"','"${privateTables[$table]}"');"; } >> $LOG_FILE 2>&1
# done

# -------------------  Update Non-Primary Indexes -----------------

# Fix up the indexes, since we didn't update
# them during the load. 

currScriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Re-Enable foreign key constraints that were disabled in the 
# loaded .sql files:
for table in ${!tables[@]}
do
    echo "`date`: re-enabling non-primary key indexes for Edx."$table"..." >> $LOG_FILE 2>&1
    # The ${tables["$table"]} accesses the primary key column name (i.e. the value of the dict):
    { mysql -u root -p$password -e "USE Edx; ALTER TABLE "$table" ENABLE KEYS;"; } >> $LOG_FILE 2>&1
done

# Same for private tables
for table in ${!privateTables[@]}
do
    echo "`date`: re-enabling non-primary key indexes for EdxPrivate."$table"..." >> $LOG_FILE 2>&1
    # The ${tables["$table"]} accesses the primary key column name (i.e. the value of the dict):
    { mysql -u root -p$password -e "USE EdxPrivate; ALTER TABLE "$table" ENABLE KEYS;"; } >> $LOG_FILE 2>&1
done

# Create any missing non-primary indexes:
{ $currScriptsDir/createIndexForTable.sh -u root -p$password; } >> $LOG_FILE 2>&1

# Any un-updated indexes are now rebuilt in memory by the following:
# We don't normally need to do this, since above indexes were either
# newly created (in createIndexForTable.sh), or refreshed in
# the ALTER TABLE ENABLE KEYS calls:
#echo "`date`: checking indexes using mysqlcheck..." >> $LOG_FILE 2>&1
#{ time mysqlcheck -u root -p$password --repair --databases Edx EdxPrivate; } >> $LOG_FILE 2>&1

echo "`date`: Done updating indexes." >> $LOG_FILE 2>&1
echo "-------------------------------------------------------------"  >> $LOG_FILE 2>&1
exit
