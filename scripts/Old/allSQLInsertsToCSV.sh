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


# Transforms all Edx SQL INSERTs style .sql files in a (hard-coded)
# directory  into equivalent .csv files in a (hard-coded) ouput
# directory. For each table a separate .csv file is created.
#
# When starting and when all done, appends to (hard-coded) directory
# file sqlInsertsToCSV.log
#
# Can be called from anywhere, as long as cd /home/dataman/Data/EdX/tracking/SQL
# exists.

# Ensure that log and CSV directories exist:
mkdir -p ../TransformLogs
mkdir -p ../CSV
thisScriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd /home/dataman/Data/EdX/tracking/SQL

echo "SQLInsertsToCSV start conversion: `date`" >> ../TransformLogs/sqlInsertsToCSV.log
time parallel --gnu --progress $thisScriptDir/sqlInsert2CSV.py /home/dataman/Data/EdX/tracking/CSV ::: /home/dataman/Data/EdX/tracking/SQL/*.sql
echo "SQLInsertsToCSV finished conversion: `date`" >> ../TransformLogs/sqlInsertsToCSV.log

