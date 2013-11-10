#!/bin/bash

# Takes a destination dir and a list of track log
# files. Transforms the log files, and places the
# resulting .sql files in the destination dir.
# Assumes that json2sql.py is in same directory
# as this script. But this script can be called
# from anywhere.

USAGE="Usage: transform.sh sqlDestDir logFiles"

if [ $# -lt 2 ]
then
    echo $USAGE
    exit 1
fi

destDir=$1
echo $destDir
shift
#echo ${@}
thisScriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Transform-only start transform: `date`" >> /tmp/transformOnly.txt
time parallel --gnu --progress $thisScriptDir/json2sql.py $destDir ::: ${@};
echo "Transform-only transform done: `date`" >> /tmp/transformOnly.txt

