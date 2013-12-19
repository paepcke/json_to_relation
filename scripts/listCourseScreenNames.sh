#!/bin/bash

# Given a Grep-compatible search string for finding 
# course names in zipped OpenEdx tracking logs, and a list of
# gzipped OpenEdx tracking logs, produce all the screen 
# names of individuals who generated events in the 
# referenced class. 
# Ex: makeScreenNameToAnonMapping.sh "ENGR14" *.gz
# would look through all gzipped files in cwd, find
# events that contain "ENGR14", extract the "username" field,
# and print its value.
#
# The result will generally have duplicates. To eliminate those:
#   listCourseScreenNames.sh pattern files | sort | uniq


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
#      away with .*. 
zcat $@ | zgrep --no-filename $GREP_PATTERN | sed 's/{.username.: .\([^"]*\).*/\1/p' 
