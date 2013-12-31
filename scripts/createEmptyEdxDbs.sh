#!/bin/bash

# Creates empty Edx and EdxPrivate databases
# on local MySQL server. Uses createEmptyEdxDbs.sql
# for the definitions. Then invokes defineMySQLProcedures.sh
# to install the stored prodcedures and functions required
# for operation.

usage="Usage: `basename $0` [-u username][-p]"


askForPasswd=false
USERNAME=`whoami`
password=''

# Issue dire warning and ask for confirmation:
read -p "This command will delete databases Edx and EdxPrivate! Confirm with capital-Y " confirmation

if [ $confirmation != 'Y' ]
then
   echo "Aborting...good for you!"
   exit 0
else
    echo "OK, going ahead."
fi

# -------------------  Process Commandline Option -----------------

# Keep track of number of optional args the user provided:
NEXT_ARG=0
while getopts "u:p" opt
do
  case $opt in
    u) # look in given user's HOME/.ssh/ for mysql_root
      USERNAME=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    p) # ask for mysql root pwd
      askForPasswd=true
      NEXT_ARG=$((NEXT_ARG + 1))
      ;;
    \?)
      # Illegal option; the getopts provided the error message
      echo $USAGE
      exit 1
      ;;
    :)
      echo $USAGE
      exit 1
      ;;
  esac
done

# Shift past all the optional parms:
shift ${NEXT_ARG}

if $askForPasswd
then
    # The -s option suppresses echo:
    read -s -p "Password for "$USERNAME" on MySQL server: " password
    echo
elif [ -z $password ]
then
    # Get home directory of whichever user will
    # log into MySQL:
    HOME_DIR=$(getent passwd $USERNAME | cut -d: -f6)
    # If the home dir has a readable file called mysql_root in its .ssh
    # subdir, then pull the pwd from there:
    if test -f $HOME_DIR/.ssh/mysql && test -r $HOME_DIR/.ssh/mysql
    then
	password=`cat $HOME_DIR/.ssh/mysql`
    fi
fi

#**************
#echo 'UID: '$USERNAME
#echo 'Password: '$password
#exit 0
#**************

currScriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
mysql -u $USERNAME -p$password < ${currScriptsDir}/createEmptyEdxDbs.sql
$currScriptsDir/defineMySQLProcedures.sh -u $USERNAME $password