#!/bin/bash

# Takes a destination dir and a list of track log
# files. Transforms the log files, and places the
# resulting .sql files in the destination dir.
# Assumes that json@sql.py is either in CWD, or
# in the $PATH.

USAGE="Usage: transform.sh sqlDestDir logFiles"

if [ $# -lt 2 ]
then
    echo $USAGE
    exit 1
fi

destDir=$1
echo $destDir
shift
echo ${@}

time parallel --gnu --progress ./json2sql.py $destDir ::: ${@}
echo `date` >> /tmp/doneTransform.txt
