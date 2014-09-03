#!/bin/bash

# ------------------ Process Commandline Options -------------------

USAGE="Usage: "`basename $0`" [-u uid][-p][-h help]"

USERNAME=`whoami`
PASSWD=''
COURSE_SUBSTR=''
DB_NAME='Extracts'
needPasswd=false
TABLE_NAME=''
ALL_COLS=''

# Execute getopt
ARGS=`getopt -o "u:ph" -l "user:,password,help" \
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
      # Grab the option value:
      if [ -n "$1" ]
      then
        USERNAME=$1
        shift
      fi;;
 
    -p|--password)
      needPasswd=true
      shift;;
 
    -h|--help)
      echo $USAGE
      exit 0
      ;;
    --)
      shift
      break;;
  esac
done

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

if [ -z $PASSWD ]
then
    MYSQL_AUTH="-u $USERNAME"
else
    MYSQL_AUTH="-u $USERNAME -p$PASSWD"
fi

mysql $MYSQL_AUTH -e "USE Edx; DROP TABLE IF EXISTS AllCourseDisplayNames;"
mysql $MYSQL_AUTH -e "USE Edx; CREATE TABLE AllCourseDisplayNames \
                         (course_display_name varchar(255) NOT NULL PRIMARY KEY) \
                      (SELECT DISTINCT course_display_name \
                       FROM EventXtract) \
                      UNION \
                      (SELECT DISTINCT course_display_name \
                       FROM ActivityGrade) \
                      ;"
