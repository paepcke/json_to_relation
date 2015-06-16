#!/bin/bash

# Used by sortCSVFiles.sh, don't call directly
# from command line:
# Given a single .csv file path, sort it 
# on the first column.
# Outputs to /home/dataman/Data/EdX/tracking/CSVSorted
# using the input filename with 'Sorted' appended to
# the basename.

if [ $# -ne 1 ]
then
    echo "Usage sortOndCSVFile.sh pathToCSV.csv"
    exit 1
fi

cd /home/dataman/Data/EdX/tracking/CSVSorted
outFile=`basename $1 .csv`Sorted.csv
echo "Processing $outFile" >> ../TransformLogs/sortCSV.log
sort --field-separator=',' --key=1 --buffer-size=1G $1 > $outFile
