#!/bin/bash

# Sibling script to transformGivenLogFiles.sh. That
# script transforms tracking log files using Gnu parallel
# on a single machine with multiple cores. This script
# instead works on a cluster.
#
# Takes a root directory under which OpenEdX
# tracking log files are stored in subdirectories
# with names of the form app<integer>. Second arg
# is a destination dir into which result SQL/CSV files
# will be placed. Transforms the log files, and places the
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
#
# Strategy: this script runs on all cluster machines.
# it uses 'mkdir directory' to lock tracking log
# files while picking a new file to work on. Uses
# find to identify log tracking files that end with
# .gz and reside under the app<int> directories.
# Once the script has picked a file, it renames
# the file it picks to <file>.DONE, and releases the
# lock by removing the directory. 

USAGE="Usage: "`basename $0`" trackLogRootDir sqlDestDir"

LOCKDIR=/tmp/transformLock.lock
LOGFILE=/tmp/transformActivityLog.log
rm $LOGFILE

if [ $# -lt 2 ]
then
    echo $USAGE
    exit 1
fi

srcRootDir=$1
destDir=$2
#echo $srcRootDir
#echo $destDir

if [ ! -d $srcRootDir ]
then
    echo "First argument must be the root directory of the tracking logs under subdirs appN; $USAGE"
    exit 1
fi

if [ ! -d $destDir ]
then
    echo "Second argument must be the destination directory for the SQL and CSV files; $USAGE"
    exit 1
fi

thisScriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Make sure that all exits (other than -9)
# will release the lock:
function finish {
    echo "Cleaning up..."
    rmdir ${LOCKDIR}
}
trap finish EXIT

while [ true ]
do
    # Is someone else looking for a file to process?
    if ! mkdir ${LOCKDIR} 2>/dev/null
    then
	#echo "Someone else looking for a file to work on." >&2
	sleep 1
	continue
    fi
    
    # Find files in root directory under subdirs
    # app<n,m>. The inner $() executes the find,
    # the outer parens turn the result into an array.
    # The find only retrieves files that end in .gz.
    # The limit on type 'f' suppresses return of 
    # intermediate directory names:
    filesToDo=($(find ${srcRootDir}/app* -name *.gz -type f))

    #*********
    #echo ${filesToDo[@]}
    #*********

    # Are all the files done?
    if [[ ${#filesToDo[@]} == 0 ]]
    then
	exit
    fi

    # Grab the first file, and change its name 
    # on the file system to <fileName>.DONE. 
    chosenFile=${filesToDo[0]}
    mv $chosenFile ${chosenFile}.DONE
    
    # Release the lock:
    rmdir ${LOCKDIR}

    # ...and process:
    echo "Transform-only start transform: `date`: ${chosenFile}" >> $LOGFILE
#****    $thisScriptDir/json2sql.py  -t csv $destDir ${chosenFile}.DONE
    echo "`date`: ${chosenFile} is done." >> $LOGFILE
done
