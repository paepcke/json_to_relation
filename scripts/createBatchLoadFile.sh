#!/bin/bash

usage="Usage: "`basename $0`" {<path/to/.sql-files>|<.sql-files-list}"

if [[ $# < 1  || $1 == "-h" || $1 == "--help" ]]
then
    echo "Provide path to directory with .sql (and .csv) files that were created by transform, or provide .sql file list. Batch load SQL file is written to stdout."
    exit
fi

csvDirOrFirstFile=$1
# batchLoadFile=batchLoad_`$(date --utc +%FT%TZ)`.sql

echo "/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;"
echo "/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;"
echo "/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;"
echo "/*!40101 SET NAMES utf8 */;"
echo "/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;"
echo "/*!40103 SET TIME_ZONE='+00:00' */;"
echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;"
echo "/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;"
echo "/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;"
echo "/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;"
echo "/*!40101 SET @saved_cs_client     = @@character_set_client */;"
echo "/*!40101 SET character_set_client = utf8 */;"

echo "LOCK TABLES \`EdxTrackEvent\` WRITE, \`State\` WRITE, \`InputState\` WRITE, \`Answer\` WRITE, \`CorrectMap\` WRITE, \`LoadInfo\` WRITE, \`Account\` WRITE, \`EventIp\` WRITE, \`ABExperiment\` WRITE, \`OpenAssessment\` WRITE;"
echo "/*!40000 ALTER TABLE \`EdxTrackEvent\` DISABLE KEYS */;"
echo "/*!40000 ALTER TABLE \`State\` DISABLE KEYS */;"
echo "/*!40000 ALTER TABLE \`InputState\` DISABLE KEYS */;"
echo "/*!40000 ALTER TABLE \`Answer\` DISABLE KEYS */;"
echo "/*!40000 ALTER TABLE \`CorrectMap\` DISABLE KEYS */;"
echo "/*!40000 ALTER TABLE \`LoadInfo\` DISABLE KEYS */;"
echo "/*!40000 ALTER TABLE \`Account\` DISABLE KEYS */;"
echo "/*!40000 ALTER TABLE \`EventIp\` DISABLE KEYS */;"
echo "/*!40000 ALTER TABLE \`ABExperiment\` DISABLE KEYS */;"
echo "/*!40000 ALTER TABLE \`OpenAssessment\` DISABLE KEYS */;"
echo "SET sql_log_bin=0;"
echo "SET autocommit=0;"

if [ -d $1 ]
then
    for fileName in ${csvDirOrFirstFile}/*.sql
    do
	echo "-- Loading data from "$(echo ${fileName} | sed -n -e 's/.*\(tracking.*\.gz\).*/\1/p')
	echo `sed -n '/LOAD DATA LOCAL INFILE/p' ${csvDir}/*.sql`
    done
else
    for fileName in $@
    do
	echo "-- Loading data from "$(echo ${fileName} | sed -n -e 's/.*\(tracking.*\.gz\).*/\1/p')
	echo "$(sed -n '/LOAD DATA LOCAL INFILE/p' ${fileName})"
    done
fi    

echo "SET autocommit=1;"
echo "SET sql_log_bin=1;"
echo "-- /*!40000 ALTER TABLE \`EdxTrackEvent\` ENABLE KEYS */;"
echo "-- /*!40000 ALTER TABLE \`State\` ENABLE KEYS */;"
echo "-- /*!40000 ALTER TABLE \`InputState\` ENABLE KEYS */;"
echo "-- /*!40000 ALTER TABLE \`Answer\` ENABLE KEYS */;"
echo "-- /*!40000 ALTER TABLE \`CorrectMap\` ENABLE KEYS */;"
echo "-- /*!40000 ALTER TABLE \`LoadInfo\` ENABLE KEYS */;"
echo "-- /*!40000 ALTER TABLE \`Account\` ENABLE KEYS */;"
echo "-- /*!40000 ALTER TABLE \`EventIp\` ENABLE KEYS */;"
echo "-- /*!40000 ALTER TABLE \`ABExperiment\` ENABLE KEYS */;"
echo "-- /*!40000 ALTER TABLE \`OpenAssessment\` ENABLE KEYS */;"
echo "UNLOCK TABLES;"
echo "REPLACE INTO EdxPrivate.Account (account_id,screen_name,name,anon_screen_name,mailing_address,zipcode,country,gender,year_of_birth,level_of_education,goals,honor_code,terms_of_service,course_id,enrollment_action,email,receive_emails) SELECT account_id,screen_name,name,anon_screen_name,mailing_address,zipcode,country,gender,year_of_birth,level_of_education,goals,honor_code,terms_of_service,course_id,enrollment_action,email,receive_emails FROM Edx.Account;"
echo "DROP TABLE Edx.Account;"
echo "REPLACE INTO EdxPrivate.EventIp (event_table_id,event_ip) SELECT event_table_id,event_ip FROM Edx.EventIp;"
echo "DROP TABLE Edx.EventIp;"
echo "/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;"
echo "/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;"
echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;"
echo "/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;"
echo "/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;"
echo "/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;"
echo "/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;"
echo "/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;"
