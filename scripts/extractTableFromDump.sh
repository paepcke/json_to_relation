#!/bin/bash
# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


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

