#!/bin/bash

read -s -p "MySQL Password: " password
echo
cd ~dataman/Data/EdX/tracking/SQL
pushd ~/Code/json_to_relation/; 
time parallel --gnu --progress scripts/json2sql.py ~/Data/EdX/tracking/SQL ::: ~/Data/EdX/tracking/app*/*.gz; 
echo `date` >> /tmp/doneTransform.txt
popd; 
find . -name '*.sql' | awk '{ print "source",$0 }' | mysql -f --batch -p$password > loadLog.log 2>&1
echo `date` >> /tmp/doneLoad.txt
