#!/bin/bash

### Master shell script to be executed by cron on a weekly basis.

# Ensure in correct directory and virtualenv
cd /home/dataman/Code/json_to_relation/scripts/
use_env json_to_relation

# Execute refresh scripts
./manageEdxDb.py pullTransformLoad > /home/dataman/cronlog/manageEdxDb.txt 2>&1
./cronRefreshEdxprod.sh > /home/dataman/cronlog/cronRefreshEdxprod.txt 2>&1
./cronRefreshModuleStore.sh > /home/dataman/cronlog/cronRefreshModuleStore.txt 2>&1
./cronRefreshActivityGrade.sh > /home/dataman/cronlog/cronRefreshActivityGrade.txt 2>&1
./cronRefreshGrades.sh > /home/dataman/cronlog/cronRefreshGrades.txt 2>&1
./cronRefreshUserCountryTable.py > /home/dataman/cronlog/cronRefreshUserCountryTable.txt 2>&1
./cronRefreshEdxForum.sh > /home/dataman/cronlog/cronRefreshEdxForum.txt 2>&1
./cronRefreshEdxQualtrics.py -msr > crontest.txt 2>&1
