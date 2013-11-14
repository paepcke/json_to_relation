#!/bin/bash

# Transforms all Edx SQL INSERTs style .sql files in a (hard-coded)
# directory  into equivalent .csv files in a (hard-coded) ouput
# directory. For each table a separate .csv file is created.
#
# When starting and when all done, appends to (hard-coded) directory
# file sqlInsertsToCSV.log
#
# Can be called from anywhere, as long as cd /home/dataman/Data/EdX/tracking/SQL
# exists.

cd /home/dataman/Data/EdX/tracking/SQL
# Ensure that log and CSV directories exist:
mkdir -p ../TransformLogs
mkdir -p ../CSV
thisScriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "SQLInsertsToCSV start conversion: `date`" >> ../TransformLogs/sqlInsertsToCSV.log
time parallel --gnu --progress $thisScriptDir/sqlInsert2CSV.py /home/dataman/Data/EdX/tracking/CSV ::: /home/dataman/Data/EdX/tracking/SQL/*.sql
echo "SQLInsertsToCSV finished conversion: `date`" >> ../TransformLogs/sqlInsertsToCSV.log

