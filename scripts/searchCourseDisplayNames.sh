#!/bin/bash


USAGE="Usage: "`basename $0`" [-u uid][-p][-w mySqlPwd] courseNamePattern"

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

# Execute getopt
ARGS=`getopt -o "u:pw:" -l "user:,password,mysqlpwd:" \
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
# echo "COURSE_SUBSTR: $COURSE_SUBSTR"
# exit 0
#*************

# Auth part for the subsequent mysql call:
if [ -z $PASSWD ]
then
    # Password empty...
    MYSQL_AUTH="-u $USERNAME"
else
    MYSQL_AUTH="-u $USERNAME -p$PASSWD"
fi

COURSE_NAMES=`mysql --batch $MYSQL_AUTH -e "
              USE Edx;
              SELECT course_display_name 
	      FROM AllCourseDisplayNames 
	      WHERE course_display_name LIKE \"$COURSE_SUBSTR\" 
	      ORDER BY course_display_name\G"`

# In the following the first 'sed' call removes the
# line: "********** 1. row *********" and following rows.
# The second 'sed' call removes everything of the second
# line up to the ': '.

echo "$COURSE_NAMES" | sed '/[*]*\s*[0-9]*\. row\s*[*]*$/d' | sed 's/[^:]*: //'

exit 0
