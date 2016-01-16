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


# Transforms all JSON track .gz log files in ~dataman/Data/Edx/tracking/app*,
# and loads the resulting .sql files into MySQL. MySQL loads execute
# under the user uid that is running this script. The respective
# password is requested right at the start. It is only used after
# the transform is done, so get it right. Monitor in /tmp/transformAndLoad.txt
#
# Make sure ~dataman/Code/json_to_relation has the latest code from git.
#
# Places resulting .sql files into ~dataman/Data/Edx/tracking/SQL.
# Places the transform log files into /tmp/j2s_tracking.log-xxx
# When done with transform, appends date/time to /tmp/doneTransform.txt
# When done with MySQL load, appends date/time to /tmp/doneLoad.txt
# Then indexes selected fields.
# Log of the MySQL load will be in ~dataman/Data/Edx/tracking/SQL: loadLog.log

read -s -p "Root's MySQL Password: " password
echo
cd /home/dataman/Data/EdX/tracking/SQL
pushd /home/dataman/Code/json_to_relation/; 
echo "TransformAndLoad start transform: `date`" >> /tmp/transformAndLoad.txt
time parallel --gnu --progress scripts/json2sql.py /home/dataman/Data/EdX/tracking/SQL ::: /home/dataman/Data/EdX/tracking/app*/*.gz; 
echo "TransformAndLoad transform done: `date`" >> /tmp/transformAndLoad.txt
popd; 
echo "TransformAndLoad start load: `date`" >> /tmp/transformAndLoad.txt
time find . -name '*.sql' | awk '{ print "source",$0 }' | mysql -f --batch -u root -p$password > loadLog.log 2>&1
echo "TransformAndLoad done load: `date`" >> /tmp/transformAndLoad.txt

echo "TransformAndLoad start indexing: `date`" >> /tmp/transformAndLoad.txt
mysql -u root -p$password < edxCreateIndexes.sql
echo "TransformAndLoad done indexing: `date`" >> /tmp/transformAndLoad.txt