#!/bin/bash

# Companion script to transformGivenLogFilesOnCluster.sh.
# That script appends '.DONE' to all files that have been
# processed. This script removes that extension from
# all files in subdirectories under a given root, whose
# directory name begins with 'app<int>'. Leaves untouched
# any files that do not live under a app<int> subdirectory,
# or do not have a '.DONE' extension.

USAGE="Usage: "`basename $0`" trackLogRootDir"

if [ $# -lt 1 ]
then
    echo $USAGE
    exit 1
fi
srcRootDir=$1
if [ ! -d $srcRootDir ]
then
    echo "First argument must be the root directory of the tracking logs under subdirs appN; $USAGE"
    exit 1
fi

filesToDo=($(find ${srcRootDir}/app* -name *.gz.DONE -type f))
for fileName in "${filesToDo[@]}"
do
    # Chop off the '.DONE':
    newFileName=`echo $fileName | sed s/.DONE$//`
    #echo $newFileName
    mv $fileName $newFileName
done


