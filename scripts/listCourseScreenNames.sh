#!/bin/bash

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

USAGE="listCourseScreenNames.sh courseNameGrepPattern tracklogfile1.gz tracklogfile2.gz..."

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
