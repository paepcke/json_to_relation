#!/bin/bash

# Takes a standard mysqldump file and a table name.
# Writes to stdout a new mysqldump file that contains
# only restoration information for the given table.
# Handles .sql and .sql.gz input files.
# 
# This is a service script for cronRefreshEdxprod.sh.
# Though it may be called by itself.


USAGE='Usage: '`basename $0`' <MySQL dump file> <table name>'

if [[ $1 = 'h' || $1 == 'help' ]]
then
    echo $USAGE
    exit -1
fi


if [ $# != 2 ]
then
    echo $USAGE
    exit -1
fi

SOURCE_MYSQL_DUMP=$1
TABLE=$2

echo "-- Prolog"

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


# If source mysqldump gzipped, deal with
# it without unzipping:
if [[ $SOURCE_MYSQL_DUMP == *.sql.gz ]]
then
    zcat $SOURCE_MYSQL_DUMP | sed -n '/-- Table structure for table `'$TABLE'`/,/UNLOCK TABLES;/p'
else
    sed -n '/-- Table structure for table `'$TABLE'`/,/UNLOCK TABLES;/p' $SOURCE_MYSQL_DUMP
fi

