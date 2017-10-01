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


### Master shell script to be executed by cron on a weekly basis.

# Ensure in correct directory and activate virtualenv

echo `date`": Activating Anaconda json_to_relation environment..."
source /home/dataman/anaconda2/bin/activate json_to_relation
echo `date`": Done activating Anaconda json_to_relation environment..."
cd /home/dataman/Code/json_to_relation/scripts/

# Initialize a new row in the FullLoadDates:
# Fill the load_start column. We will fill the
# load_end column at the end of the script:

read -r -d '' START_TIME_CMD <<EOF
CREATE TABLE IF NOT EXISTS FullLoadDates (load_start DATETIME, load_end DATETIME);
INSERT INTO FullLoadDates (load_start) values(NOW());
EOF

mysql --login-path=dataman Edx -e "$START_TIME_CMD"

# Execute refresh scripts.
# Call shell scripts using `source` to ensure virtualenv works.
# Python scripts use #!/usr/bin/env python to let virtualenv work correctly.
/home/dataman/Code/json_to_relation/scripts/manageEdxDb.py pullTransformLoad >> /home/dataman/cronlog/manageEdxDb.txt 2>&1
source /home/dataman/Code/json_to_relation/scripts/cronRefreshEdxprod.sh >> /home/dataman/cronlog/cronRefreshEdxprod.txt 2>&1

# 3hrs:
source /home/dataman/Code/json_to_relation/scripts/cronRefreshModuleStore.sh >> /home/dataman/cronlog/cronRefreshModuleStore.txt 2>&1

source /home/dataman/Code/json_to_relation/scripts/cronRefreshActivityGrade.sh >> /home/dataman/cronlog/cronRefreshActivityGrade.txt 2>&1

source /home/dataman/Code/json_to_relation/scripts/cronRefreshGrades.sh >> /home/dataman/cronlog/cronRefreshGrades.txt 2>&1

/home/dataman/Code/json_to_relation/scripts/cronRefreshUserCountryTable.py >> /home/dataman/cronlog/cronRefreshUserCountryTable.txt 2>&1

source /home/dataman/Code/json_to_relation/scripts/cronRefreshEdxForum.sh >> /home/dataman/cronlog/cronRefreshEdxForum.txt 2>&1

# 2hrs:15min:
/home/dataman/Code/mooc_data_request_processing/src/data_req_etl/surveyextractor.py -amsri >> /home/dataman/cronlog/cronRefreshEdxQualtrics.txt 2>&1


# Add end timestamp to this load's entry
# in FullLoadDates:

read -r -d '' END_TIME_CMD <<EOF
UPDATE FullLoadDates
  JOIN (SELECT MAX(load_start) AS start_time
          FROM FullLoadDates
       )  AS RowInfo
  SET load_end = NOW()
  WHERE load_start = RowInfo.start_time;
EOF

mysql --login-path=dataman Edx -e "$END_TIME_CMD"

