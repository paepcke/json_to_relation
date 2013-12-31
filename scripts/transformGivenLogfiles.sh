#!/bin/bash

# Takes a destination dir and a list of track log
# files. Transforms the log files, and places the
# resulting .sql and .csv files in the destination dir.
# Invokes json2sql.py with '-t csv', causing one
# .sql file for each log file to be created, plus
# as many .csv files for each log file as there are
# tables. The .sql file contains statements that loads 
# the .csv files. The loading is done after transform
# via executeCSVLoad.sh
#
# Assumes that json2sql.py is in same directory
# as this script. But this script can be called
# from anywhere.

USAGE="Usage: `basename $0` sqlDestDir trackingLogFile1 trackingLogFile2..."

if [ $# -lt 2 ]
then
    echo $USAGE
    exit 1
fi

destDir=$1
#echo $destDir
if [ ! -d $destDir ]
then
    echo "First argument must be a directory; $USAGE"
    exit 1
fi
shift
#echo ${@}
thisScriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Transform-only start transform: `date`" >> /tmp/transformOnly.txt
time parallel --gnu --progress $thisScriptDir/json2sql.py  -t csv $destDir ::: ${@};
echo "Transform-only transform done: `date`" >> /tmp/transformOnly.txt

