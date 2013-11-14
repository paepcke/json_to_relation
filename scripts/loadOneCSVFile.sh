#!/bin/bash

mysqlCmd="SET unique_checks=0; \
SET foreign_key_checks = 0; \
SET sql_log_bin=0; \
USE Edx; LOAD DATA LOCAL INFILE '/tmp/EdxTrackEventSorted.csv' \
INTO TABLE EdxTrackEvent \
FIELDS OPTIONALLY ENCLOSED BY \"'\" TERMINATED BY ','; \
SET unique_checks=1; \
SET foreign_key_checks = 1; \
SET sql_log_bin=1;"
mysql --local_infile=1 -e "$mysqlCmd"
