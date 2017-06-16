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


# Takes a destination dir and a list of track log
# files. Transforms the log files, and places the
# resulting .sql and .csv files in the destination dir.
# Invokes json2sql.py with '-t csv', causing one
# .sql file for each log file to be created, plus
# as many .csv files for each log file as there are
# tables. The .sql file contains statements that loads 
# the .csv files. The loading is done after transform
# via executeCSVLoad.sh
#
# Assumes that json2sql.py is in same directory
# as this script. But this script can be called
# from anywhere.

USAGE="Usage: "`basename $0`" sqlDestDir trackingLogFile1 trackingLogFile2..."

if [ $# -lt 2 ]
then
    echo $USAGE
    exit 1
fi

# Determine if this is a Mac. Some bash
# commands are not available there:
if [[ $(echo $OSTYPE | cut -c 1-6) == 'darwin' ]]
then
    PLATFORM='macos'
    BASH_VERSION=$(echo $(bash --version) | sed -n 's/[^0-9]*version \([0-9]\).*/\1/p')
    if [[ $BASH_VERSION < 4 ]]
    then
        echo "On MacOS Bash version must be 4.0 or higher."
        exit 1
    fi
else
    PLATFORM='other'
fi    

destDir=$1
#echo $destDir
if [ ! -d $destDir ]
then
    echo "First argument must be a directory; $USAGE"
    exit 1
fi
shift
#echo ${@}

thisScriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# BSD bash seems not to pass PATH down into
# subshells; so hard-code parallel's location
# for the MacOS case:

echo "Transform-only start transform: `date`" >> /tmp/transformOnly.txt
if [[ $PLATFORM == 'macos' ]]
then   
    time /usr/local/bin/parallel --gnu --progress $thisScriptDir/json2sql.py  -t csv $destDir ::: ${@};
else
    time parallel --gnu --progress $thisScriptDir/json2sql.py  -t csv $destDir ::: ${@};
fi    
echo "Transform-only transform done: `date`" >> /tmp/transformOnly.txt

