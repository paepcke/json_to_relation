#!/bin/bash

# Creates empty Edx and EdxPrivate databases
# on local MySQL server. Uses createEmptyEdxDbs.sql
# for the definitions. Then invokes defineMySQLProcedures.sh
# to install the stored prodcedures and functions required
# for operation.

usage="Usage: "`basename $0`" [-u username][-p][-n noindexex]"


askForPasswd=false
buildIndexes=1
USERNAME=`whoami`
PASSWD=''

# Issue dire warning and ask for confirmation:
read -p "This command will delete databases Edx and EdxPrivate! Confirm with capital-Y " confirmation

if [ $confirmation != 'Y' ] || [ -z $confirmation ]
then
   echo "Aborting...good for you!"
   exit 0
else
    echo "OK, going ahead."
fi

# -------------------  Process Commandline Option -----------------

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
while getopts ":u:pn" opt
do
  case $opt in
    u) # look in given user's HOME/.ssh/ for mysql_root
      USERNAME=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    p) # ask for mysql root pwd
      askForPasswd=0
      NEXT_ARG=$((NEXT_ARG + 1))
      ;;
    n) # don't build indexes on the empty tables:
      buildIndexes=false
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

if $askForPasswd && [ -z $PASSWD ]
then
    # The -s option suppresses echo:
    read -s -p "Password for "$USERNAME" on MySQL server: " PASSWD
    echo
elif [ -z $PASSWD ]
then
    # Get home directory of whichever user will
    # log into MySQL:
    HOME_DIR=$(getent passwd $USERNAME | cut -d: -f6)
    # If the home dir has a readable file called mysql_root in its .ssh
    # subdir, then pull the pwd from there:
    if test -f $HOME_DIR/.ssh/mysql_root && test -r $HOME_DIR/.ssh/mysql_root
    then
	PASSWD=`cat $HOME_DIR/.ssh/mysql_root`
    fi
fi

#**************
# echo 'UID of script caller: '$USERNAME
# echo 'UID used for MySQL operations: root'
# echo 'MySQL root password: '$PASSWD
# exit 0
#**************

#**************
echo "About to create tables"
#**************

currScriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -z $PASSWD ]
then
    mysql -u root < ${currScriptsDir}/createEmptyEdxDbs.sql
else
    mysql -u root -p$PASSWD < ${currScriptsDir}/createEmptyEdxDbs.sql
fi
#**************
echo "Done creating tables"
echo "About to create procedures and functions."
#**************

if [ -z $PASSWD ]
then
    $currScriptsDir/defineMySQLProcedures.sh -u root
else
    $currScriptsDir/defineMySQLProcedures.sh -u root -p${PASSWD}
fi

#**************
echo "Done creating procedures and functions."
#**************

if [ $buildIndexes = 1 ]
then
    echo "Starting index creation."
    $currScriptsDir/createIndexForTable.sh -u root -p${PASSWD}
    echo "Done creating indexes."
else
    echo "No index creation requested; no indexes defined."
fi

