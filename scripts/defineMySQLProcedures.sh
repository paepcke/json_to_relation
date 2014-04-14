#!/bin/bash

# Sources mysqlProcAndFuncBodies.sql into the local
# MySQL server three times: once into the Edx database,
# once into the EdxPrivate database, and again in EdxForum.
# Without args: runs as root with no pwd.
# Obviously, then MySQL will complain if root
# has a pwd.

USAGE="Usage: `basename $0` [-u username][-p][-pYourPwd]"

USERNAME=`whoami`
PASSWD=''
needPasswd=false
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check whether given -pPassword, i.e. fused -p with a 
# pwd string:

for arg in $@
do
   # The sed -r option enables extended regex, which
   # makes the '+' metachar wor. The -n option
   # says to print only if pattern matches:
   PASSWD=`echo $arg | sed -r -n 's/-p(.+)/\1/p'`
   if [ -z $PASSWD ]
   then
       continue
   else
       #echo "Pwd is:"$PASSWD
       break
   fi
done

# Keep track of number of optional args the user provided:
NEXT_ARG=0

# Use leading ':' in options list to have
# erroneous optons end up in the \? clause
# below:
while getopts ":u:ph" opt
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
    \?)
      # If the $PASSWD is set, we *assume* that 
      # the unrecognized option was a
      # -pMyPassword, and don't signal
      # an error. Therefore, if $PASSWD is 
      # set then illegal options are quietly 
      # ignored:
      if [ ! -z $PASSWD ]
      then 
	  continue
      else
	  echo $USAGE
	  exit 1
      fi
      ;;
  esac
done

# Shift past all the optional parms:
shift ${NEXT_ARG}

if $needPasswd && [ -z $PASSWD ]
then
    # The -s option suppresses echo:
    read -s -p "Password for user '$USERNAME' on MySQL server: " PASSWD
    echo
fi

#*****************
#echo "UID: $USERNAME"
#echo "PWD: $PASSWD"
#exit 0
#*****************

# Load the .sql file that contains the procedure
# function bodies twice: once into each of Edx
# and EdxPrivate:
if [ -z $PASSWD ]
then
    mysql -u $USERNAME -e "USE Edx; source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    mysql -u $USERNAME -e "USE EdxPrivate; source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    mysql -u $USERNAME -e "USE EdxForum; source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
else
    mysql -u $USERNAME -p$PASSWD -e "USE Edx; source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    mysql -u $USERNAME -p$PASSWD -e "USE EdxPrivate; source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    mysql -u $USERNAME -p$PASSWD -e "USE EdxForum; source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
fi
