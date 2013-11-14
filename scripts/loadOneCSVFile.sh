#!/bin/bash

mysqlCmd="SET unique_checks=0; \
SET foreign_key_checks = 0; \
SET sql_log_bin=0; \
USE Edx; LOAD DATA LOCAL INFILE '/tmp/tracking.log-20131001.gz.2013-11-10T22_38_33.272564_15192_EdxTrackEvent.csv' \
INTO TABLE EdxTrackEvent;"
mysql --local_infile=1 -e "$mysqlCmd"
