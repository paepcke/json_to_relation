#!/bin/bash

# Intended for use from CLI (in contrast to
# sortOneCSVFile.sh).
# Given any number of .csv file paths, sort them
# on the first column, sending to a file with
# infile's basename having the word 'Sorted' 
# appended to the same directory where the respective
# input file resides.

if [ $# -lt 1 ]
then
    echo "Usage sortOndCSVFile.sh pathToCSV1.csv pathToCSV2.csv ..."
    exit 1
fi

for file in $@
do
    outFile=`dirname $file`/`basename $file .csv`Sorted.csv
    sort --field-separator=',' --key=1 --buffer-size=1G $file > $outFile
done
