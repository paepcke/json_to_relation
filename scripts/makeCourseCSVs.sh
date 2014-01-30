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
# If the -w option is given, it provides the MySQL pwd to use.
#
# If neither -p nor -w is provided, the script examines the effective user's
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
#
# The -n option, if provided, must specify a password. That pwd will
# be used to encrypt the output table files into a single .zip file.


USAGE="Usage: "`basename $0`" [-u uid][-p][-w mySqlPwd][-d destDirPath][-x xpunge][-i infoDest][-n encryptionPwd] courseNamePattern"

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
pii=false
ENCRYPT_PWD=''

# Execute getopt
ARGS=`getopt -o "u:pw:xd:i:n:" -l "user:,password,mysqlpwd:,xpunge,destDir:infoDest:names:" \
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
 
    -w|--mysqlpwd)
      shift
      # Grab the option value:
      if [ -n "$1" ]
      then
        PASSWD=$1
	needPasswd=false
        shift
      else
	echo $USAGE
	exit 1
      fi;;

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
    -n|--names)
      pii=true
      shift
      # Grab the encryption pwd:
      if [ -n "$1" ]
      then
	  ENCRYPT_PWD=$1
	  shift
      else
	  echo $USAGE
	  echo "Need to provide an encryption pwd for the result zip file."
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
#   are replaced by '_any'.
# Ex:
#   Engineering/CS106A/Fall2013 => CS106A_Fall2013
#   Chemistry/CH%/Summer => CH_any_Summer

# The following SED expression has three repetitions
# of \([^/]*\)\/, which means all letters that are
# not forward slashes (the '[^/]*), followed by a 
# forward slash (the '\/'). The forward slash must
# be escaped b/c it's special in SED. 
# The escaped parentheses pairs form a group,
# which we then recall later, in the substitution
# part with \2 and \3 (the '/\2_\3/' part):

DIR_LEAF=`echo $COURSE_SUBSTR | sed -n "s/\([^/]*\)\/\([^/]*\)\/\(.*\)/\2_\3/p"`

#******************
#echo "DEST_LEAF after first xform: '$DIR_LEAF'<br>"
#echo "COURSE_SUBSTR after first xform: '$COURSE_SUBSTR'<br>"
#******************

if [ -z $DIR_LEAF ]
then
    DIR_LEAF=`echo $COURSE_SUBSTR | sed s/[%]/_any/g`
else
    # Len of DIR_LEAF > 0.
    # Replace any '%' MySQL wildcards with
    # '_All':
    DIR_LEAF=`echo $DIR_LEAF | sed s/[%]/_any/g`
fi

#******************
#echo "DEST_LEAF after second xform: '$DIR_LEAF'<br>"
#echo "DEST_LEAF after second xform: '$DIR_LEAF'" > /tmp/trash.log
#******************

# Last step: remove all remaining '/' chars,
# and any leading underscore(s), if present; the
# -E option enables extended regexp, which seems
# needed for the OR option: \|
DIR_LEAF=`echo $DIR_LEAF | sed -E s/^[_]*\|[/]//g`

#******************
#echo "DEST_LEAF after third xform: '$DIR_LEAF'<br>"
#******************

# If destination directory was not explicitly 
# provided, add a leaf directory to the
# standard directory to hold the three .csv
# files we'll put there as siblings to the
# ones we put there in the past:
if ! $destDirGiven
then
    DEST_DIR=$DEST_DIR/$DIR_LEAF
fi

#******************
#echo "DEST_DIR: $DEST_DIR\n\n"
#******************

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
    # MySQL pwd may have been provided via the -w option:
    if [ -z $PASSWD ]
    then
	# Password was not provided with -w option.
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
# if $pii
# then
#    echo "Want pii"
# else
#    echo "No pii"
# fi
# if [ -z $ENCRYPT_PWD ]
# then
#     echo "ENCYPT_PWD empty"
# else
#     echo "Encryption pwd: $ENCRYPT_PWD"
# fi
#  exit 0
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
# Create all tmp files:

EventXtract_HEADER_FILE=`mktemp -p /tmp`
VideoInteraction_HEADER_FILE=`mktemp -p /tmp`
ActivityGrade_HEADER_FILE=`mktemp -p /tmp`

# Ensure the files are cleaned up when script exits:
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

# Auth part for the subsequent three mysql calls:
if [ -z $PASSWD ]
then
    # Password empty...
    MYSQL_AUTH="-u $USERNAME"
else
    MYSQL_AUTH="-u $USERNAME -p$PASSWD"
fi

ACTIVITY_GRADE_HEADER=`mysql --batch $MYSQL_AUTH -e "
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

VIDEO_INTERACTION_HEADER=`mysql --batch $MYSQL_AUTH -e "
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

EVENT_XTRACT_HEADER=`mysql --batch $MYSQL_AUTH -e "
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


#*******************
# echo "EventXtract header line should be in $EventXtract_HEADER_FILE"
# echo "VideoInteraction  header line should be in $VideoInteraction_HEADER_FILE"
# echo "ActivityGrade  header line should be in $ActivityGrade_HEADER_FILE"
# echo "Contents EventXtract header file:"
# cat $EventXtract_HEADER_FILE
# echo "Contents VideoInteraction header file:"
# cat $VideoInteraction_HEADER_FILE
# echo "Contents ActivityGrade header file:"
# cat $ActivityGrade_HEADER_FILE
# exit 0
#*******************

# ----------------------------- Create a full path for each of the tables -------------

EVENT_EXTRACT_FNAME=$DEST_DIR/${DIR_LEAF}_EventXtract.csv
ACTIVITY_GRADE_FNAME=$DEST_DIR/${DIR_LEAF}_ActivityGrade.csv
VIDEO_FNAME=$DEST_DIR/${DIR_LEAF}_VideoInteraction.csv
ZIP_FNAME=$DEST_DIR/${DIR_LEAF}_report.zip

# ----------------------------- If requested on CL: Punt if tables exist -------------

# Refuse to overwrite existing files, unless the -x option
# was present in the CL:

# If caller wanted pii then only a zipped file
# would interfere:
if $pii
then
    if [ -e $ZIP_FNAME ]
    then
	if $xpungeFiles
	then
	    echo "Removing existing zipped csv file $ZIP_FNAME<br>"
	    rm $ZIP_FNAME
	else
	    echo "File $ZIP_FNAME already exists; aborting.<br>"
	    # Zero out the file in which we are to list
	    # the names of the result files:
	    if [ ! -z $INFO_DEST ]
	    then
		truncate -s 0 $INFO_DEST
	    fi
	    exit 1
	fi
    fi
else
    # No PII: check for each .csv file being present:
    if [ -e $EVENT_EXTRACT_FNAME ]
    then
	if $xpungeFiles
	then
	    echo "Removing existing csv file $EVENT_EXTRACT_FNAME<br>"
	    rm $EVENT_EXTRACT_FNAME
	else
	    echo "File $EVENT_EXTRACT_FNAME already exists; aborting.<br>"
	    # Zero out the file in which we are to list
	    # the names of the result files:
	    if [ ! -z $INFO_DEST ]
	    then
		truncate -s 0 $INFO_DEST
	    fi
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
	    # Zero out the file in which we are to list
	    # the names of the result files:
	    if [ ! -z $INFO_DEST ]
	    then
		truncate -s 0 $INFO_DEST
	    fi
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
	    # Zero out the file in which we are to list
	    # the names of the result files:
	    if [ ! -z $INFO_DEST ]
	    then
		truncate -s 0 $INFO_DEST
	    fi
	    exit 1
	fi
    fi
fi

# ----------------------------- Create MySQL Commands -------------

# Create the three MySQL export commands that 
# will write the table values. Two variants for each table:
# with or without personally identifiable information:
if $pii
then
  EXPORT_EventXtract_CMD=" \
  SELECT EventXtract.*, Account.name, Account.screen_name \
  INTO OUTFILE '"$EventXtract_VALUES"' \
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' \
    LINES TERMINATED BY '\r\n' \
  FROM Edx.EventXtract, EdxPrivate.Account \
  WHERE course_display_name LIKE '"$COURSE_SUBSTR"' \
    AND EventXtract.anon_screen_name = Account.anon_screen_name;"
else
  EXPORT_EventXtract_CMD=" \
  SELECT * \
  INTO OUTFILE '"$EventXtract_VALUES"' \
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' \
    LINES TERMINATED BY '\r\n' \
  FROM Edx.EventXtract \
  WHERE course_display_name LIKE '"$COURSE_SUBSTR"';"
fi

if $pii
then
  EXPORT_ActivityGrade_CMD=" \
  SELECT ActivityGrade.*, Account.name, Account.screen_name \
  INTO OUTFILE '"$ActivityGrade_VALUES"' \
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' \
    LINES TERMINATED BY '\r\n' \
  FROM Edx.ActivityGrade, EdxPrivate.Account \
  WHERE course_display_name LIKE '"$COURSE_SUBSTR"' \
    AND ActivityGrade.anon_screen_name = Account.anon_screen_name;"
else
  EXPORT_ActivityGrade_CMD=" \
  SELECT * \
  INTO OUTFILE '"$ActivityGrade_VALUES"' \
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' \
    LINES TERMINATED BY '\r\n' \
  FROM Edx.ActivityGrade \
  WHERE course_display_name LIKE '"$COURSE_SUBSTR"';"
fi

if $pii
then
  EXPORT_VideoInteraction_CMD=" \
  SELECT VideoInteraction.*, Account.name, Account.screen_name \
  INTO OUTFILE '"$VideoInteraction_VALUES"' \
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' \
    LINES TERMINATED BY '\r\n' \
  FROM Edx.VideoInteraction, EdxPrivate.Account \
  WHERE course_display_name LIKE '"$COURSE_SUBSTR"' \
    AND VideoInteraction.anon_screen_name = Account.anon_screen_name;"
else
EXPORT_VideoInteraction_CMD=" \
  SELECT * \
  INTO OUTFILE '"$VideoInteraction_VALUES"' \
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' \
    LINES TERMINATED BY '\r\n' \
  FROM Edx.VideoInteraction \
  WHERE course_display_name LIKE '"$COURSE_SUBSTR"';"
fi

#********************
 # echo "EXPORT_EventXtract_CMD: $EXPORT_EventXtract_CMD"
 # echo "EXPORT_ActivityGrade_CMD: $EXPORT_ActivityGrade_CMD"
 # echo "EXPORT_VideoInteraction_CMD: $EXPORT_VideoInteraction_CMD"
 # exit 0
#********************

# ----------------------------- Execute the Main MySQL Commands -------------

echo "Creating extract EventXtract ...<br>"
echo "$EXPORT_EventXtract_CMD" | mysql $MYSQL_AUTH
# Concatenate the col name header and the table:
cat $EventXtract_HEADER_FILE $EventXtract_VALUES > $EVENT_EXTRACT_FNAME

echo "Creating extract ActivityGrade ...<br>"
echo "$EXPORT_ActivityGrade_CMD" | mysql $MYSQL_AUTH
cat $ActivityGrade_HEADER_FILE $ActivityGrade_VALUES > $ACTIVITY_GRADE_FNAME

echo "Creating extract VideoInteraction ...<br>"
echo "$EXPORT_VideoInteraction_CMD" | mysql $MYSQL_AUTH
cat $VideoInteraction_HEADER_FILE $VideoInteraction_VALUES > $VIDEO_FNAME

echo "Done exporting class $COURSE_SUBSTR to CSV<br>"

# ----------------------- If PII then Zip and Encrypt -------------

if $pii
then
    echo "Encrypting report...<br>"
    # The --junk-paths puts just the files into
    # the zip, not all the directories on their
    # path from root to leaf:
    zip --junk-paths --password $ENCRYPT_PWD $ZIP_FNAME $EVENT_EXTRACT_FNAME $ACTIVITY_GRADE_FNAME $VIDEO_FNAME
    rm $EVENT_EXTRACT_FNAME $ACTIVITY_GRADE_FNAME $VIDEO_FNAME
    # Write path to the encrypted zip file to 
    # path the caller provided:
    if [ ! -z $INFO_DEST ]
    then
	echo $ZIP_FNAME > $INFO_DEST
    fi
    exit 0
fi

# ----------------------- Write table paths to a file -------------

# For unencrypted files:

if [ ! -z $INFO_DEST ]
then
    echo ${EVENT_EXTRACT_FNAME}    >  $INFO_DEST
    echo ${ACTIVITY_GRADE_FNAME}   >> $INFO_DEST
    echo ${VIDEO_FNAME}            >> $INFO_DEST
fi

exit 0
