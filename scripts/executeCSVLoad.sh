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
# This script must also be run as superuser, b/c it needs
# to examine MySQL table directories.

usage="Usage: `basename $0` [-u username][-p][-w rootpass] logDir file1.sql file2.sql... # You may be asked for MySQL root pwd."

if [ $# -lt 1 ]
then
    echo $usage
    exit 1
fi

askForPasswd=false
USERNAME=`whoami`
password=''
LOGFILE_NAME='loadLog.log'

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
    echo "Aborting due to above errors; nothing was done."
    exit 1
fi


LOG_FILE=$logDir/$LOGFILE_NAME

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
    )

declare -A privateTables
privateTables=( ["Account"]="account_id" )

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

# Remove primary keys from public tables to speed loading; the ${!tables[@]} loops through the table names (i.e. dict keys)
for table in ${!tables[@]}
do
    echo "`date`: dropping primary key from Edx.$table" >> $LOG_FILE 2>&1
    { mysql -u root -p$password -e "USE Edx; CALL Edx.dropPrimaryIfExists('"$table"');"; } >> $LOG_FILE 2>&1	
done

# # Private tables; the ${!privateTables[@]} loops through the table names (i.e. dict keys)
for table in ${!privateTables[@]}
do
    echo "`date`: dropping primary key from EdxPrivate.$table" >> $LOG_FILE 2>&1
    { mysql -u root -p$password -e "USE EdxPrivate; CALL Edx.dropPrimaryIfExists('"$table"');"; } >> $LOG_FILE 2>&1	
done

# -------------------  Loading SQL Files, Which Load CSVs -----------------

# Do the actual loading of CSV files into their respective tables;
# $@ are the .sql files from the CLI:
for sqlFile in $@
do  
    echo "`date`: starting on $sqlFile"  >> $LOG_FILE 2>&1
    { mysql -f -u root -p$password --local_infile=1 < $sqlFile; } >> $LOG_FILE 2>&1
    echo "`date`: done loading $sqlFile"  >> $LOG_FILE 2>&1
done

# -------------------  Restore Primary Keys -----------------

# Add primary keys back in:
# Public tables; the ${!tables[@]} loops through the table names (i.e. dict keys)
for table in ${!tables[@]}
do
    echo "`date`: adding primary key to table "$table"..." >> $LOG_FILE 2>&1
    # The ${tables["$table"]} accesses the primary key column name (i.e. the value of the dict):
    { mysql -u root -p$password -e "USE Edx; CALL Edx.addPrimaryIfNotExists('"$table"','"${tables[$table]}"');"; } >> $LOG_FILE 2>&1
done

# Private tables; the ${!tables[@]} loops through the table names (i.e. dict keys)
for table in ${!privateTables[@]}
do
    echo "`date`: adding primary key to table "$table"..." >> $LOG_FILE 2>&1
    # The ${tables["$table"]} accesses the primary key column (i.e. the value of the dict):
    { mysql -u root -p$password -e "USE EdxPrivate; CALL Edx.addPrimaryIfNotExists('"$table"','"${privateTables[$table]}"');"; } >> $LOG_FILE 2>&1
done

# -------------------  Update or First-Time-Build Non-Primary Indexes -----------------

# Fix up the indexes, since we didn't update
# them during the load. 

currScriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# The '!' causes the tables dict's keys to be returned
# as the list to traverse (i.e. the table names):
for table in ${!tables[@]} ${!privateTables[@]}
do  
    # Check whether any non-primary index exists on this table.
    # If not, create all indexes for this table. If at least
    # one non-primary index does exist, we assume that for this
    # table all the required indexes exist. In that case use
    # mysqlcheck to update the existing indexes:
    indexesExist=$(mysql Edx -se "SELECT anyIndexExists('"$table"');")
    if [ "$indexesExist" -eq 0 ]
    then
	# Check whether the table is in EdxPrivate, and no indexes
	# were found for that reason:
	indexesExist=$(mysql EdxPrivate -se "SELECT anyIndexExists('"$table"');")
    fi

    if [ "$indexesExist" -eq 0 ]
    then
	# Really no indexes found for this table:
	echo "`date`: creating all indexes for table "$table" (if needed)..." >> $LOG_FILE 2>&1
	{ $currScriptsDir/createIndexForTable.sh $table; } >> $LOG_FILE 2>&1
    fi
done

# Any un-updated indexes are now rebuilt in memory:
echo "`date`: checking indexes using mysqlcheck..." >> $LOG_FILE 2>&1
{ time mysqlcheck --repair --databases Edx EdxPrivate; } >> $LOG_FILE 2>&1

echo "`date`: Done updating indexes." >> $LOG_FILE 2>&1

exit
