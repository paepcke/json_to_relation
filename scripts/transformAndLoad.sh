#!/bin/bash

# Transforms all JSON track .gz log files in ~dataman/Data/Edx/tracking/app*,
# and loads the resulting .sql files into MySQL. MySQL loads execute
# under the user uid that is running this script. The respective
# password is requested right at the start. It is only used after
# the transform is done, so get it right. Monitor in /tmp/transformAndLoad.txt
#
# Make sure ~dataman/Code/json_to_relation has the latest code from git.
#
# Places resulting .sql files into ~dataman/Data/Edx/tracking/SQL.
# Places the transform log files into /tmp/j2s_tracking.log-xxx
# When done with transform, appends date/time to /tmp/doneTransform.txt
# When done with MySQL load, appends date/time to /tmp/doneLoad.txt
# Then indexes selected fields.
# Log of the MySQL load will be in ~dataman/Data/Edx/tracking/SQL: loadLog.log

read -s -p "Dataman's MySQL Password: " password
echo
cd /home/dataman/Data/EdX/tracking/SQL
pushd /home/dataman/Code/json_to_relation/; 
echo "TransformAndLoad start transform: `date`" >> /tmp/transformAndLoad.txt
time parallel --gnu --progress scripts/json2sql.py /home/dataman/Data/EdX/tracking/SQL ::: /home/dataman/Data/EdX/tracking/app*/*.gz; 
echo "TransformAndLoad transform done: `date`" >> /tmp/transformAndLoad.txt
popd; 
echo "TransformAndLoad start load: `date`" >> /tmp/transformAndLoad.txt
time find . -name '*.sql' | awk '{ print "source",$0 }' | mysql -f --batch -p$password > loadLog.log 2>&1
echo "TransformAndLoad done load: `date`" >> /tmp/transformAndLoad.txt

echo "TransformAndLoad start indexing: `date`" >> /tmp/transformAndLoad.txt
mysql < edxCreateIndexes.sql
echo "TransformAndLoad done indexing: `date`" >> /tmp/transformAndLoad.txt