#!/bin/bash

# This script is only useful if you ran a transform
# through a compute cluster using qsubClusterSubmission.sh
# B/c of shortcomings in my scripts, The .sql files produced 
# will contain LOAD INFILE commands with paths to .csv files
# as they are on the cluster head machine. If you then 
# copy those files to ~dataman/Data/EdX/tracking/CSV, those
# load paths are wrong. This script corrects the paths.
# A hack; I should fix the scripts that generate the LOAD
# commands in the first place!
#
# Example: scripts/correctSqlLoadPaths.sh /home/dataman/Data/EdX/tracking/CSV  /dfs/scratch1/paepcke /home/dataman/Data/EdX

USAGE='Usage: '`basename $0`' rootForSQLFiles filePathToReplace newFilePath'

if [[ $@ < 3 ]]
then
    echo $USAGE
    exit
fi

rootDir=$1
srcStr=$2
dstStr=$3

#******
# echo "rootDir: $rootDir"
# echo "srcStr: $srcStr"
# echo "dstStr: $dstStr"
#******

if [[ $srcStr == '*|*' || $dstStr == '*|*' ]]
then
    echo "File paths must not contain the character '|'."
    exit
fi

for fileName in `find ${rootDir} -name "*.sql"`
do
    echo "Fixing file ${fileName}"
    sed -e "s|${srcStr}|${dstStr}|g" ${fileName} > ${fileName}.tmp && mv ${fileName}.tmp ${fileName}
done
