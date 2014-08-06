#!/bin/bash

# Sources mysqlProcAndFuncBodies.sql into the local
# MySQL server three times: once into the Edx database,
# once into the EdxPrivate database, and again in EdxForum.
# Without args: runs as root with no pwd.
# Obviously, then MySQL will complain if root
# has a pwd.
#
# The function idForum2Anon() is dropped from all but
# EdxPrivate to prevent Forum int IDs to be turned
# into anon_screen_name. To let people to that,
# give them GRANT EXECUTE ON EdxPrivate.idForum2Anon TO <userDef>
#
# Args: MySQL authentication. If -p is not given, and MySQL user
#       is 'root', then looks in ~/.ssh/mysql_root for pwd. If -p
#       is not given, and MySQL user is not 'root', then 
#       looks in ~/.ssh/mysql_root for pwd.
#       If no pwd is found, calls MySQL w/o pwd.

USAGE="Usage: `basename $0` [-u username][-p][-pYourPwd]"

MYSQL_USERNAME=`whoami`
SHELL_USERNAME=`whoami`
PASSWD=''
needPasswd=false
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Read the Forum UID generation key passphrase from the file that
# is customized for this installation:
if [[ ! -f $THIS_SCRIPT_DIR/forumKeyPassphrase.txt ]]
then
    echo "Forum keyphrase file forumKeyPassphrase.txt not found; see file forumKeyPassphrase.txt.CHANGE_ME."
    exit 1
fi
FORUM_KEY_PASSPHRASE=`cat $THIS_SCRIPT_DIR/forumKeyPassphrase.txt`

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
      MYSQL_USERNAME=$OPTARG
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


if $needPasswd
then
    # The -s option suppresses echo:
    read -s -p "Password for user '$MYSQL_USERNAME' on `hostname`'s MySQL server: " PASSWD
    echo
else
    # Get home directory of whichever user will
    # log into MySQL:
    HOME_DIR=$(getent passwd $SHELL_USERNAME | cut -d: -f6)
    # If the home dir has a readable file called mysql in its .ssh
    # subdir, then pull the pwd from there:
    if [[ $MYSQL_USERNAME == 'root' ]]
    then
	if [[ -f $HOME_DIR/.ssh/mysql_root && -r $HOME_DIR/.ssh/mysql_root ]]
	then
            PASSWD=`cat $HOME_DIR/.ssh/mysql_root`
	fi
    else
	if [[ -f $HOME_DIR/.ssh/mysql && -r $HOME_DIR/.ssh/mysql ]]
	then
            PASSWD=`cat $HOME_DIR/.ssh/mysql`
	fi
    fi
fi

#*****************
# echo "UID: $MYSQL_USERNAME"
# echo "PWD: $PASSWD"
# echo "FORUM_KEY_PASSPHRASE: $FORUM_KEY_PASSPHRASE"
# exit 0
#*****************

# Create table EdxPrivate.Keys, whose forumKey column 
# will hold the key used for the Forum UID creation.
KEY_INSTALL_CMD="DROP TABLE IF EXISTS EdxPrivate.Keys; \
                 CREATE TABLE EdxPrivate.Keys (forumKey varchar(255) DEFAULT ''); \
                 INSERT INTO EdxPrivate.Keys SET forumKey = (SELECT SHA2('"$FORUM_KEY_PASSPHRASE"',224) AS forumKey);"

#*****************
#echo "KEY_INSTALL_CMD: $KEY_INSTALL_CMD"
# exit 0
#*****************

if [ -z $PASSWD ]
then
    mysql -u $MYSQL_USERNAME EdxPrivate -e "$KEY_INSTALL_CMD"
else
    mysql -u $MYSQL_USERNAME -p$PASSWD EdxPrivate -e "$KEY_INSTALL_CMD"
fi

# Load the .sql file that contains the procedure
# function bodies several times: into each of Edx
# and EdxPrivate, and into EdxForum, so that they
# are available there:
if [ -z $PASSWD ]
then
    mysql -u $MYSQL_USERNAME Edx        -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    mysql -u $MYSQL_USERNAME EdxPrivate -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    mysql -u $MYSQL_USERNAME EdxForum   -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    mysql -u $MYSQL_USERNAME EdxPiazza  -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    mysql -u $MYSQL_USERNAME edxprod    -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    mysql -u $MYSQL_USERNAME unittest   -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
else
    mysql -u $MYSQL_USERNAME -p$PASSWD Edx        -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    mysql -u $MYSQL_USERNAME -p$PASSWD EdxPrivate -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    mysql -u $MYSQL_USERNAME -p$PASSWD EdxForum   -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    mysql -u $MYSQL_USERNAME -p$PASSWD EdxPiazza  -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    mysql -u $MYSQL_USERNAME -p$PASSWD edxprod    -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    mysql -u $MYSQL_USERNAME -p$PASSWD unittest   -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
fi
