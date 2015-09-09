#!/bin/bash

### Master shell script to be executed by cron on a weekly basis.

# Ensure in correct directory and activate virtualenv
source /home/dataman/.virtualenvs/json_to_relation/bin/activate
cd /home/dataman/Code/json_to_relation/scripts/

# Execute refresh scripts.
# Call shell scripts using `source` to ensure virtualenv works.
# Python scripts use #!/usr/bin/env python to let virtualenv work correctly.
./manageEdxDb.py pullTransformLoad > /home/dataman/cronlog/manageEdxDb.txt 2>&1
source ./cronRefreshEdxprod.sh > /home/dataman/cronlog/cronRefreshEdxprod.txt 2>&1
source ./cronRefreshModuleStore.sh > /home/dataman/cronlog/cronRefreshModuleStore.txt 2>&1
source ./cronRefreshActivityGrade.sh > /home/dataman/cronlog/cronRefreshActivityGrade.txt 2>&1
source ./cronRefreshGrades.sh > /home/dataman/cronlog/cronRefreshGrades.txt 2>&1
./cronRefreshUserCountryTable.py > /home/dataman/cronlog/cronRefreshUserCountryTable.txt 2>&1
source ./cronRefreshEdxForum.sh > /home/dataman/cronlog/cronRefreshEdxForum.txt 2>&1
./cronRefreshEdxQualtrics.py -amsr > /home/dataman/cronlog/cronRefreshEdxQualtrics.txt 2>&1
