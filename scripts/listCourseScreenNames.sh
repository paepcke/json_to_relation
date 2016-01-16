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
# gzipped OpenEdx tracking log file names, produce all the screen 
# names of individuals who generated events in the 
# referenced class. The list have duplicates removed.
# Ex: makeScreenNameToAnonMapping.sh "ENGR14" *.gz
# would look through all gzipped files in cwd, find
# events that contain "ENGR14", extract the "username" field,
# and print its value.
#
# Used by makeScreenNameToAnonTable.sh, but can be used
# independently.

USAGE="Usage: "`basename $0`" courseNameGrepPattern tracklogfile1.gz tracklogfile2.gz..."

if [ $# -lt 2 ]
then
    echo $USAGE
    exit 1
fi

GREP_PATTERN=$1
shift

# The following sed command:
#   1. its structure: substitue/regexWithGroupCapture/capturedGroup/print
#   2. the username field is always the first in tracking log files,
#      so we look for the opening brace, followed by one char (the double quote
#      for the username field name, followed by 'username', its closing quote
#      (the dot after 'username'), followed by a colon, space, and opening
#      double quote of the username field value (the dot after ': '). Then
#      we capture anything up to the next double quote, namely the field value.
#      The \( and \) delimit the group. We then throw the rest of the event
#      away with .*. Output will be a list of screen names, one per line.
#   3. the sed '/^\s*$/d' part removes lines that only have whitespace between
#      the line's beginning and its end (^ and $)
#   4. The sort and uniq remove duplicates:

zcat $@ | zgrep --no-filename $GREP_PATTERN | sed 's/{.username.: .\([^"]*\).*/\1/p' | sed '/^\s*$/d' | sort | uniq
