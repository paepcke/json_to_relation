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


# Given a Grep-compatible search string for finding 
# course names in zipped OpenEdx tracking logs, and a list of
# gzipped OpenEdx tracking log file names, produce a CSV table
# that maps each screen name to its equivalent anonymized version.
# Output to stdout.

USAGE="Usage: "`basename $0`" courseNameGrepPattern tracklogfile1.gz tracklogfile2.gz..."

if [ $# -lt 2 ]
then
    echo $USAGE
    exit 1
fi

# Get directory in which this script runs:
thisScriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tmpScreenNames=mktemp

# Put a list of screen names from all the .gz 
# files into a tmp file, one name per line,
# sorted alphabetically:
$thisScriptDir/listCourseScreenNames.sh $@ > $tmpScreenNames

# Pipe the screen names to the script that will 
# read each screen name from stdin, and output its
# anonymized version to stdout. Pass this stream
# of hashes to the bash 'paste' command, which pairs
# each hash with its corresponding screen name from
# the same tmp file we used to generate the hashes.
# Remove all-empty lines in the sed command. Finally,
# replace the tab used to separate the columns
# screenName and hashValue to a comma:
cat $tmpScreenNames | $thisScriptDir/makeAnonScreenName.py - |  paste $tmpScreenNames - | sed '/^\s*$/d' | sed 's/\t/,/'

# Trap ensures that the tmp file is removed even
# on error:
trap 'rm $tmpScreenNames' EXIT


