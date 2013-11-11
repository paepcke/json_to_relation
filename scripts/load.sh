#!/bin/bash

# NOTE: designed to be called from manageEdxDb.py, which acquires the 
#       MySQL pwd without printing it out.
#
# Loads SQL files into MySQL db. MySQL loads execute
# under the user uid that is running this script. The respective
# password must be passed in.
#
# When done with MySQL load, appends date/time to /tmp/doneLoad.txt
# Then indexes selected fields.
# Log of the MySQL load will be in /tmp/loadLog.log

# Usage: load.sh mySqlRootPWD {sqlDir | sqlFile sqlFile...}

PWD=$1
SQL_DIR=$2

if [ -d $SQL_DIR ]; then
    # $SQL_DIR is a directory from which all .sql files are to be loaded:
    echo "TransformAndLoad start load: `date`" >> /tmp/transformAndLoad.txt
    cd $SQL_DIR
    # Pipe each file name into awk to produce "source <fileName>", 
    # pipe that into the mysql command as a last arg:
    #*********time find . -name '*.sql' | awk '{ print "source",$0 }' | mysql -f --batch -u root -p$PWD > /tmp/loadLog.log 2>&1
    # To test, comment line above, and uncomment line below; also comment the mysql command down below (see comment there)
    find . -name '*.sql' | awk '{ print "source",$0 }' | cat
    echo "TransformAndLoad done load: `date`" >> /tmp/transformAndLoad.txt
elif [ -f $SQL_DIR ]; then
    # $SQL_DIR is actually a file, and so are all the remaining args:
    # Get rid of the pwd:
    shift
    # Cycle through the files and feed them to mysql:
    for sqlFile in $@
    do
	#***************echo "source $sqlFile" | mysql -f --batch -u root -p$PWD >> /tmp/loadLog.log 2>&1
	echo "source $sqlFile" | cat
        #***************
    done
else
    echo "$SQL_DIR is neither a file nor a directory; cannot load this entity into MySQL; no action taken"
    exit 1
fi

echo "TransformAndLoad start indexing: `date`" >> /tmp/transformAndLoad.txt
# To test, comment line below
mysql -u root -p$PWD < edxCreateIndexes.sql
echo "TransformAndLoad done indexing: `date`" >> /tmp/transformAndLoad.txt