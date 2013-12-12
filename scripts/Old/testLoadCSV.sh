#!/bin/bash

lockTablesCmd="LOCK TABLES Account WRITE;"
tableName="Account"
dbName="EdxPrivate"
csvTestFile="/tmp/testCSV.csv"

mysqlCmd=\
"SET unique_checks=0; \
SET foreign_key_checks=0; \
SET sql_log_bin=0; \
USE $dbName; \
$lockTablesCmd; \
LOAD DATA LOCAL INFILE '$csvTestFile' \
IGNORE \
INTO TABLE $tableName \
FIELDS OPTIONALLY ENCLOSED BY \"'\" TERMINATED BY ','; \
UNLOCK TABLES; \
SET unique_checks=1; \
SET foreign_key_checks=1; \
SET sql_log_bin=1;"

mysql -f -u paepcke --local_infile=1 -e "$mysqlCmd"
