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


# This script is only useful if you ran a transform
# through a compute cluster using qsubClusterSubmission.sh
# B/c of shortcomings in my scripts, The .sql files produced 
# will contain LOAD INFILE commands with paths to .csv files
# as they are on the cluster head machine. If you then 
# copy those files to ~dataman/Data/EdX/tracking/CSV, those
# load paths are wrong. This script corrects the paths.
# A hack; I should fix the scripts that generate the LOAD
# commands in the first place!
#
# Example: scripts/correctSqlLoadPaths.sh /home/dataman/Data/EdX/tracking/CSV  /dfs/scratch1/paepcke /home/dataman/Data/EdX

USAGE='Usage: '`basename $0`' rootForSQLFiles filePathToReplace newFilePath'

if [[ $@ < 3 ]]
then
    echo $USAGE
    exit
fi

rootDir=$1
srcStr=$2
dstStr=$3

#******
# echo "rootDir: $rootDir"
# echo "srcStr: $srcStr"
# echo "dstStr: $dstStr"
#******

if [[ $srcStr == '*|*' || $dstStr == '*|*' ]]
then
    echo "File paths must not contain the character '|'."
    exit
fi

for fileName in `find ${rootDir} -name "*.sql"`
do
    echo "Fixing file ${fileName}"
    sed -e "s|${srcStr}|${dstStr}|g" ${fileName} > ${fileName}.tmp && mv ${fileName}.tmp ${fileName}
done
