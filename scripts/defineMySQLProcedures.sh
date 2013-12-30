#!/bin/bash

# Sources mysqlProcAndFuncBodies.sql into the local
# MySQL server twice: once into the Edx database,
# and once into the EdxPrivate database. 
# Without args: runs as root with no pwd.
# Obviously, then MySQL will complain if root
# has a pwd.

USAGE="Usage: `basename $0` [-u username][-p]"

USERNAME=`whoami`
PASSWD=''
needPasswd=false
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Keep track of number of optional args the user provided:
NEXT_ARG=0
while getopts "u:ph" opt
do
  case $opt in
    u)
      USERNAME=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    p)
      needPasswd=true
      NEXT_ARG=$((NEXT_ARG + 1))
      ;;
    h)
      echo $USAGE
      exit 0
     ;;
    \?)
      # Illegal option; the getopts provided the error message
      echo $USAGE
      exit 1
      ;;
  esac
done

# Shift past all the optional parms:
shift ${NEXT_ARG}

if $needPasswd
then
    # The -s option suppresses echo:
    read -s -p "Password for user '$USERNAME' on MySQL server: " PASSWD
    echo
fi

# Load the .sql file that contains the procedure
# function bodies twice: once into each of Edx
# and EdxPrivate:
if [ -z $PASSWD ]
then
    mysql -u $USERNAME -e "USE Edx; source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    mysql -u $USERNAME -e "USE EdxPrivate; source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
else
    mysql -u $USERNAME -p$PASSWD -e "USE Edx; source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    mysql -u $USERNAME -p$PASSWD -e "USE EdxPrivate; source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
fi
