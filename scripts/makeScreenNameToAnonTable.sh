#!/bin/bash

USAGE="makeScreenNameToAnonTable.sh courseNameGrepPattern tracklogfile1.gz tracklogfile2.gz..."

if [ $# -lt 2 ]
then
    echo $USAGE
    exit 1
fi

# Given a Grep-compatible search string for finding 
# course names in zipped OpenEdx tracking logs, and a list of
# gzipped OpenEdx tracking log file names, produce a CSV table
# that maps each screen name to its equivalent anonymized version.
# Output to stdout.

tmpScreenNames=mktemp

# Put a list of screen names from all the .gz 
# files into a tmp file, one name per line,
# sorted alphabetically:
./listCourseScreenNames.sh $@ > $tmpScreenNames

# Pipe the screen names to the script that will 
# read each screen name from stdin, and output its
# anonymized version to stdout. Pass this stream
# of hashes to the bash 'paste' command, which pairs
# each hash with its corresponding screen name from
# the same tmp file we used to generate the hashes.
# Remove all-empty lines in the sed command. Finally,
# replace the tab used to separate the columns
# screenName and hashValue to a comma:
cat $tmpScreenNames | ./makeAnonScreenName.py - |  paste $tmpScreenNames - | sed '/^\s*$/d' | sed 's/\t/,/'

# Trap ensures that the tmp file is removed even
# on error:
trap 'rm $tmpScreenNames' EXIT


