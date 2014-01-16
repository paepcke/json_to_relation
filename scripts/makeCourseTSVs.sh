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

# If the -p option is given, a password is requested on the commandline.
#
# If no password is provided, the script examines the effective user's
# $HOME/.ssh directory for a file named 'mysql'. If that file exists, 
# its content is used as a MySQL password, else no password is used 
# for running MySQL.
#
# ***** What happens if target files exist?

USAGE="Usage: "`basename $0`" [-u uid][-p][-d destDirPath] courseNamePattern"

if [ $# -lt 1 ]
then
    echo $USAGE
    exit 1
fi

USERNAME=`whoami`
PASSWD=''
COURSE_SUBSTR=''
needPasswd=false
destDirGiven=false
DEST_DIR='/home/dataman/Data/CustomExcerpts'

# Execute getopt
ARGS=`getopt -o "u:pd:" -l "user:,password,destDir:" \
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
# standard directory to hold the three .tsv
# files we'll put there as siblings to the
# ones we put there in the past:
if ! $destDirGiven
then
    DEST_DIR=$DEST_DIR/$DIR_LEAF
fi

# Make sure the directory path exists all the way:
mkdir -p $DEST_DIR
chmod a+w $DEST_DIR

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

# Create a full path for each of the tables'
# .tsv:

EVENT_EXTRACT_FNAME=$DEST_DIR/${DIR_LEAF}_EventXtract.tsv
ACTIVITY_GRADE_FNAME=$DEST_DIR/${DIR_LEAF}_ActivityGrade.tsv
VIDEO_FNAME=$DEST_DIR/${DIR_LEAF}_VideoInteraction.tsv

# Refuse to overwrite existing files:
if [ -e $EVENT_EXTRACT_FNAME ]
then
    echo "File $EVENT_EXTRACT_FNAME already exists; aborting."
    exit 1
fi

if [ -e $ACTIVITY_GRADE_FNAME ]
then
    echo "File $ACTIVITY_GRADE_FNAME already exists; aborting."
    exit 1
fi

if [ -e $VIDEO_FNAME ]
then
    echo "File $VIDEO_FNAME already exists; aborting."
    exit 1
fi

# Create the three MySQL export commands:
EXPORT_EventXtract_CMD=" \
  SELECT * \
  INTO OUTFILE '"$EVENT_EXTRACT_FNAME"' \
    FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\"' \
    LINES TERMINATED BY '\r\n' \
  FROM Edx.EventXtract \
  WHERE course_display_name LIKE '"$COURSE_SUBSTR"';"

EXPORT_ActivityGrade_CMD=" \
  SELECT * \
  INTO OUTFILE '"$ACTIVITY_GRADE_FNAME"' \
    FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\"' \
    LINES TERMINATED BY '\r\n' \
  FROM Edx.ActivityGrade \
  WHERE course_display_name LIKE '"$COURSE_SUBSTR"';"

EXPORT_VideoInteraction_CMD=" \
  SELECT * \
  INTO OUTFILE '"$VIDEO_FNAME"' \
    FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\"' \
    LINES TERMINATED BY '\r\n' \
  FROM Edx.VideoInteraction \
  WHERE course_display_name LIKE '"$COURSE_SUBSTR"';"

#********************
# echo "EXPORT_EventXtract_CMD: $EXPORT_EventXtract_CMD"
# echo "EXPORT_ActivityGrade_CMD: $EXPORT_ActivityGrade_CMD"
# echo "EXPORT_VideoInteraction_CMD: $EXPORT_VideoInteraction_CMD"
# exit 0
#********************

# If the pwd is empty, don't issue -p to mysql:
if [ -z $PASSWD ]
then
    # Password empty...
    echo "Creating extract EventXtract ..."
#**************
    echo "$EXPORT_EventXtract_CMD" | mysql --debug=d:t:O,/tmp/client.trace -u $USERNAME
    #echo "$EXPORT_EventXtract_CMD" | mysql -u $USERNAME
#**************
    echo "Creating extract ActivityGrade ..."
    echo "$EXPORT_ActivityGrade_CMD" | mysql -u $USERNAME
    echo "Creating extract VideoInteraction ..."
    echo "$EXPORT_VideoInteraction_CMD" | mysql -u $USERNAME

else
    # Password not empty ...
    echo "Creating extract EventXtract ..."
    echo "$EXPORT_EventXtract_CMD" | mysql -u $USERNAME -p$PASSWD
    echo "Creating extract ActivityGrade ..."
    echo "$EXPORT_ActivityGrade_CMD" | mysql -u $USERNAME -p$PASSWD
    echo "Creating extract VideoInteraction ..."
    echo "$EXPORT_VideoInteraction_CMD" | mysql -u $USERNAME -p$PASSWD
fi

echo "Done exporting class to tsv"
