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


# Companion script to transformGivenLogFilesOnCluster.sh.
# That script appends '.DONE.gz' to all files that have been
# processed. This script removes that extension from
# all files in subdirectories under a given root, whose
# directory name begins with 'app<int>'. Leaves untouched
# any files that do not live under a app<int> subdirectory,
# or do not have a '.gz.DONE' extension.

USAGE="Usage: "`basename $0`" trackLogRootDir"

if [ $# -lt 1 ]
then
    echo $USAGE
    exit 1
fi
srcRootDir=$1
if [ ! -d $srcRootDir ]
then
    echo "First argument must be the root directory of the tracking logs under subdirs appN; $USAGE"
    exit 1
fi

filesToDo=($(find ${srcRootDir}/app* -name *.gz.DONE.gz -type f))
for fileName in "${filesToDo[@]}"
do
    # Chop off the '.DONE.gz':
    newFileName=`echo $fileName | sed s/.DONE.gz$//`
    #echo $newFileName
    mv $fileName $newFileName
done


