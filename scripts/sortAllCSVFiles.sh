#!/bin/bash

# Sorts all Edx .csv files by their primary keys to accelerate
# subsequent loading into MySQL via load infile command.
# Source directory is hard-coded: /home/dataman/Data/EdX/tracking/CSV
# Destination directory is hard-coded as well: /home/dataman/Data/EdX/tracking/CSVSorted
# The latter directory is created if necessary.
#
# When starting and when all done, appends to sortCSV.log in
# hard-coded directory /home/dataman/Data/EdX/tracking/TransformLogs
#
# Can be called from anywhere, as long as cd /home/dataman/Data/EdX/tracking/CSV
# exists.

thisScriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Ensure that log and CSVSorted directories exist:
cd 
mkdir -p /home/dataman/Data/EdX/tracking/TransformLogs
mkdir -p /home/dataman/Data/EdX/tracking/CSVSorted

echo "Sort CSV files start: `date`" >> /home/dataman/Data/EdX/tracking/TransformLogs/sortCSV.log
time parallel --gnu --progress $thisScriptDir/sortOneCSVFile.sh ::: /home/dataman/Data/EdX/tracking/CSV/*.csv
echo "Sort CSV files done: `date`" >> /home/dataman/Data/EdX/tracking/TransformLogs/sortCSV.log