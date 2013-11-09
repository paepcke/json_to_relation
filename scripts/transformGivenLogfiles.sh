#!/bin/bash

# Takes a destination dir and a list of track log
# files. Transforms the log files, and places the
# resulting .sql files in the destination dir.
# Assumes that json@sql.py is in subdir scripts.
# I.e.: run in json_to_relation proj root. 

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

echo "Transform-only start transform: `date`" >> /tmp/transformOnly.txt
time parallel --gnu --progress scripts/json2sql.py $destDir ::: ${@};
echo "Transform-only transform done: `date`" >> /tmp/transformOnly.txt

