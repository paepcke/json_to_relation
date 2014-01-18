#!/bin/bash

#******
# Takes a course name substring from the command line. Creates
# a subdirectory in ~dataman/Data/CustomExctracts, and places
# three tables into that subdirectory, each with course-relevant
# rows from EventXtract, VideoInteraction, and ActivityGrade.
#
# The given course triplet may be complete, or contain MySQL regex chars.
#
# Example: makeCourseTSVs.sh -p Medicine/HRP258/Statistics_in_Medicine
#
# The destination directory in which the tables directory will be placed
# may be controlled by the -d option.
# 
# The default user under which the necessary mysql calls are made is
# the current user as returned by 'whoami'. Else the user provided
# in the commandline -u option is the effective user.
#
# If the -p option is given, a password is requested on the commandline.
#
# If no password is provided, the script examines the effective user's
# $HOME/.ssh directory for a file named 'mysql'. If that file exists, 
# its content is used as a MySQL password, else no password is used 
# for running MySQL.
#
# The -i option, if provided, must be an absolute file path to which
# the script will write the full path of each table it has produced.
# This is useful when this script is called from the Web, and the 
# caller wishes to check the result tables, e.g. their length.
#
# The -x option controls what happens if the target csv files already
# exist. If the option is present, then existing files will be overwritten,
# else execution is aborted if any one of the files exists.

USAGE="Usage: "`basename $0`" [-u uid][-p][-d destDirPath][-x xpunge][-i infoDest] courseNamePattern"

# ----------------------------- Process CLI Parameters -------------

if [ $# -lt 1 ]
then
    echo $USAGE
    exit 1
fi

USERNAME=`whoami`
PASSWD=''
COURSE_SUBSTR=''
needPasswd=false
xpungeFiles=false
destDirGiven=false
DEST_DIR='/home/dataman/Data/CustomExcerpts'
INFO_DEST=''

# Execute getopt
ARGS=`getopt -o "u:pxd:i:" -l "user:,password,xpunge,destDir:infoDest:" \
      -n "getopt.sh" -- "$@"`
 
#Bad arguments
if [ $? -ne 0 ];
then
  exit 1
fi
 
# A little magic
eval set -- "$ARGS"
 
# Now go through all the options
while true;
do
  case "$1" in
    -u|--user)
      shift
      # Grab the option value
      # unless it's null:
      if [ -n "$1" ]
      then
        USERNAME=$1
        shift
      else
	echo $USAGE
	exit 1
      fi;;
 
    -p|--password)
      needPasswd=true
      shift;;
 
    -d|--destDir)
      shift
      # Grab the option value:
      if [ -n "$1" ]
      then
        DEST_DIR=$1
	destDirGiven=true
        shift
      else
	echo $USAGE
	exit 1
      fi;;
    -x|--xpunge)
      xpungeFiles=true
      shift;;
    -i|--infoDest)
      shift
      # Grab the option value:
      if [ -n "$1" ]
      then
        INFO_DEST=$1
        shift
      else
	echo $USAGE
	exit 1
      fi;;
 
    --)
      shift
      break;;
  esac
done

# Make sure one arg is left after
# all the shifting above: the search
# pattern for the course name:

if [ -z $1 ]
then
  echo $USAGE
  exit 1
fi
COURSE_SUBSTR=$1

# ----------------------------- Determine Directory Path for CSV Tables -------------

# Create a prefix for the table file name
# names. The same name will also be used as
# the directory subname under ~dataman/Data/CustomExcerpts.
# Strategy: if the COURSE_SUBSTR is a full, clean
#   course triplet part1/part2/part3, we use part2_part3,
#   b/c the course number (part 2) is supposed to be unique.
#   If we cannot create this part2_part3 name, b/c
#   $COURSE_SUBSTR is of a non-standard form, then 
#   we use all of $COURSE_SUBSTR.
#   Finally, in either case, All MySQL regex '%' chars
#   are replaced by '_ALL'.
# Ex:
#   Engineering/CS106A/Fall2013 => CS106A_Fall2013
#   Chemistry/CH%/Summer => CH_ALL_Summer

# The following SED expression has three repetitions
# of \([^/]*\)\/, which means all letters that are
# not forward slashes (the '[^/]*), followed by a 
# forward slash (the '\/'). The forward slash must
# be escaped b/c it's special in SED. 
# The escaped parentheses pairs form a group,
# which we then recall later, in the substitution
# part with \2 and \3 (the '/\2_\3/' part):

DIR_LEAF=`echo $COURSE_SUBSTR | sed -n "s/\([^/]*\)\/\([^/]*\)\/\(.*\)/\2_\3/p"`

if [ -z $DIR_LEAF ]
then
    DIR_LEAF=`echo $COURSE_SUBSTR | sed s/[%]/_ALL/g`
else
    # Len of DIR_LEAF > 0.
    # Replace any '%' MySQL wildcards with
    # '_All':
    DIR_LEAF=`echo $DIR_LEAF | sed s/[%]/_ALL/g`
fi

# Last step: remove all remaining '/' chars:
DIR_LEAF=`echo $DIR_LEAF | sed s/[/]//g`

# If destination directory was not explicitly 
# provided, add a leaf directory to the
# standard directory to hold the three .csv
# files we'll put there as siblings to the
# ones we put there in the past:
if ! $destDirGiven
then
    DEST_DIR=$DEST_DIR/$DIR_LEAF
fi

# Make sure the directory path exists all the way:
mkdir -p $DEST_DIR

# Unfortunately, we cannot chmod when called
# from the Web, so this is commented out:
#chmod a+w $DEST_DIR

# ----------------------------- Process or Lookup the Password -------------

if $needPasswd
then
    # The -s option suppresses echo:
    read -s -p "Password for user '$USERNAME' on `hostname`'s MySQL server: " PASSWD
    echo
else
    # Get home directory of whichever user will
    # log into MySQL:
    HOME_DIR=$(getent passwd $USERNAME | cut -d: -f6)
    # If the home dir has a readable file called mysql in its .ssh
    # subdir, then pull the pwd from there:
    if test -f $HOME_DIR/.ssh/mysql && test -r $HOME_DIR/.ssh/mysql
    then
	PASSWD=`cat $HOME_DIR/.ssh/mysql`
    fi
fi

#*************
# echo "Course substr: '$COURSE_SUBSTR'"
# echo "HOME_DIR: $HOME_DIR"
# echo "User: $USERNAME"
# echo "PWD: '$PASSWD'"
# if [ -z $PASSWD ]
# then
#     echo "PWD empty"
# else
#     echo "PWD full"
# fi
# echo "DEST_DIR: '$DEST_DIR'"
# echo "COURSE_SUBSTR: $COURSE_SUBSTR"
# echo "DIR_LEAF: $DIR_LEAF"
# exit 0
#*************

# ----------------------------- Get column headers for each table -------------

# MySQL does not output column name headers for CSV files, only
# for tsv. So need to get those; it's messy. First, we get the
# column names into a bash variable. The var's content will look this
# this:
#
#*************************** 1. row ***************************
#GROUP_CONCAT(CONCAT("'",information_schema.COLUMNS.COLUMN_NAME,"'")): 'event_type','resource_display_name','video_current_time'...
#
# Where the second row contains the table's columns
# after the colon. We use the sed command to get rid of the
# '**** 1. row ****' entirely. Then we use sed again to 
# get rid of the 'GROUP_CONCAT...: 'part. We write the 
# remaining info, the actual col names, to a tmp file. We
# do this for each of the three tables. 
#
# Get all tmp files:

EventXtract_HEADER_FILE=`mktemp -p /tmp`
VideoInteraction_HEADER_FILE=`mktemp -p /tmp`
ActivityGrade_HEADER_FILE=`mktemp -p /tmp`

# Ensure the files are cleaned up:
trap "rm -f $EventXtract_HEADER_FILE VideoInteraction_HEADER_FILE ActivityGrade_HEADER_FILE" EXIT

# A tmp file for one table's csv data:
# Must be unlinked (the -u option), b/c
# otherwise MySQL complains that the file
# exists; The unlinking prevents us from
# deleting this file except as superuser.
# Need to fix that:

EventXtract_VALUES=`mktemp -u -p /tmp`
VideoInteraction_VALUES=`mktemp -u -p /tmp`
ActivityGrade_VALUES=`mktemp -u -p /tmp`


ACTIVITY_GRADE_HEADER=`mysql --batch -e "
              SELECT GROUP_CONCAT(CONCAT(\"'\",information_schema.COLUMNS.COLUMN_NAME,\"'\")) 
	      FROM information_schema.COLUMNS 
	      WHERE TABLE_SCHEMA = 'Edx' 
	         AND TABLE_NAME = 'ActivityGrade' 
	      ORDER BY ORDINAL_POSITION\G"`
# In the following the first 'sed' call removes the
# line: "********** 1. row *********" (see above).
# The second 'sed' call removes everything of the second
# line up to the ': '. The result finally is placed
# in a tempfile:
echo "$ACTIVITY_GRADE_HEADER" | sed '/[*]*\s*1\. row\s*[*]*$/d' | sed 's/[^:]*: //'  | cat > $ActivityGrade_HEADER_FILE

VIDEO_INTERACTION_HEADER=`mysql --batch -e "
              SELECT GROUP_CONCAT(CONCAT(\"'\",information_schema.COLUMNS.COLUMN_NAME,\"'\")) 
	      FROM information_schema.COLUMNS 
	      WHERE TABLE_SCHEMA = 'Edx' 
	         AND TABLE_NAME = 'VideoInteraction' 
	      ORDER BY ORDINAL_POSITION\G"`
# In the following the first 'sed' call removes the
# line: "********** 1. row *********" (see above).
# The second 'sed' call removes everything of the second
# line up to the ': '. The result finally is placed
# in a tempfile:
echo "$VIDEO_INTERACTION_HEADER" | sed '/[*]*\s*1\. row\s*[*]*$/d' | sed 's/[^:]*: //'  | cat > $VideoInteraction_HEADER_FILE

EVENT_XTRACT_HEADER=`mysql --batch -e "
              SELECT GROUP_CONCAT(CONCAT(\"'\",information_schema.COLUMNS.COLUMN_NAME,\"'\")) 
	      FROM information_schema.COLUMNS 
	      WHERE TABLE_SCHEMA = 'Edx' 
	         AND TABLE_NAME = 'EventXtract' 
	      ORDER BY ORDINAL_POSITION\G"`
# In the following the first 'sed' call removes the
# line: "********** 1. row *********" (see above).
# The second 'sed' call removes everything of the second
# line up to the ': '. The result finally is placed
# in a tempfile:
echo "$EVENT_XTRACT_HEADER" | sed '/[*]*\s*1\. row\s*[*]*$/d' | sed 's/[^:]*: //'  | cat > $EventXtract_HEADER_FILE


# ----------------------------- Create a full path for each of the tables -------------

EVENT_EXTRACT_FNAME=$DEST_DIR/${DIR_LEAF}_EventXtract.csv
ACTIVITY_GRADE_FNAME=$DEST_DIR/${DIR_LEAF}_ActivityGrade.csv
VIDEO_FNAME=$DEST_DIR/${DIR_LEAF}_VideoInteraction.csv

# ----------------------------- If requested on CL: Punt if tables exist -------------

# Refuse to overwrite existing files, unless the -x option
# was present in the CL:
if [ -e $EVENT_EXTRACT_FNAME ]
then
    if $xpungeFiles
    then
	echo "Removing existing csv file $EVENT_EXTRACT_FNAME<br>"
	rm $EVENT_EXTRACT_FNAME
    else
	echo "File $EVENT_EXTRACT_FNAME already exists; aborting.<br>"
	exit 1
    fi
fi

if [ -e $ACTIVITY_GRADE_FNAME ]
then
    if $xpungeFiles
    then
	echo "Removing existing csv file $ACTIVITY_GRADE_FNAME<br>"
	rm $ACTIVITY_GRADE_FNAME
    else
	echo "File $ACTIVITY_GRADE_FNAME already exists; aborting.<br>"
	exit 1
    fi
fi

if [ -e $VIDEO_FNAME ]
then
    if $xpungeFiles
    then
	echo "Removing existing csv file $VIDEO_FNAME<br>"
	rm $VIDEO_FNAME
    else
	echo "File $VIDEO_FNAME already exists; aborting.<br>"
	exit 1
    fi
fi


# ----------------------------- Create MySQL Commands -------------

# Create the three MySQL export commands that 
# will write the table values:
EXPORT_EventXtract_CMD=" \
  SELECT * \
  INTO OUTFILE '"$EventXtract_VALUES"' \
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' \
    LINES TERMINATED BY '\r\n' \
  FROM Edx.EventXtract \
  WHERE course_display_name LIKE '"$COURSE_SUBSTR"';"

EXPORT_ActivityGrade_CMD=" \
  SELECT * \
  INTO OUTFILE '"$ActivityGrade_VALUES"' \
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' \
    LINES TERMINATED BY '\r\n' \
  FROM Edx.ActivityGrade \
  WHERE course_display_name LIKE '"$COURSE_SUBSTR"';"

EXPORT_VideoInteraction_CMD=" \
  SELECT * \
  INTO OUTFILE '"$VideoInteraction_VALUES"' \
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' \
    LINES TERMINATED BY '\r\n' \
  FROM Edx.VideoInteraction \
  WHERE course_display_name LIKE '"$COURSE_SUBSTR"';"

#********************
# echo "EXPORT_EventXtract_CMD: $EXPORT_EventXtract_CMD"
# echo "EXPORT_ActivityGrade_CMD: $EXPORT_ActivityGrade_CMD"
# echo "EXPORT_VideoInteraction_CMD: $EXPORT_VideoInteraction_CMD"
# exit 0
#********************

# ----------------------------- Execute the MySQL Commands -------------

# If the pwd is empty, don't issue -p to mysql:
if [ -z $PASSWD ]
then
    # Password empty...
    echo "Creating extract EventXtract ...<br>"
    echo "$EXPORT_EventXtract_CMD" | mysql -u $USERNAME
    # Concatenate the col name header and the table:
    cat $EventXtract_HEADER_FILE $EventXtract_VALUES > $EVENT_EXTRACT_FNAME

    echo "Creating extract ActivityGrade ...<br>"
    echo "$EXPORT_ActivityGrade_CMD" | mysql -u $USERNAME
    cat $ActivityGrade_HEADER_FILE $ActivityGrade_VALUES > $ACTIVITY_GRADE_FNAME

    echo "Creating extract VideoInteraction ...<br>"
    echo "$EXPORT_VideoInteraction_CMD" | mysql -u $USERNAME
    cat $VideoInteraction_HEADER_FILE $VideoInteraction_VALUES > $VIDEO_FNAME

else
    # Password not empty ...
    echo "Creating extract EventXtract ...<br>"
    echo "$EXPORT_EventXtract_CMD" | mysql -u $USERNAME -p$PASSWD
    # Concatenate the col name header and the table:
    cat $EventXtract_HEADER_FILE $EventXtract_VALUES > $EVENT_EXTRACT_FNAME

    echo "Creating extract ActivityGrade ...<br>"
    echo "$EXPORT_ActivityGrade_CMD" | mysql -u $USERNAME -p$PASSWD
    cat $ActivityGrade_HEADER_FILE $ActivityGrade_VALUES > $ACTIVITY_GRADE_FNAME

    echo "Creating extract VideoInteraction ...<br>"
    echo "$EXPORT_VideoInteraction_CMD" | mysql -u $USERNAME -p$PASSWD
    cat $VideoInteraction_HEADER_FILE $VideoInteraction_VALUES > $VIDEO_FNAME

fi

echo "Done exporting class $COURSE_SUBSTR to CSV<br>"

# ----------------------- Write table paths to a file -------------

if [ -n $INFO_DEST ]
then
    echo ${EVENT_EXTRACT_FNAME}    >  $INFO_DEST
    echo ${ACTIVITY_GRADE_FNAME}   >> $INFO_DEST
    echo ${VIDEO_FNAME}            >> $INFO_DEST
fi
exit 0
