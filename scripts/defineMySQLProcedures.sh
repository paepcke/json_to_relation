#!/bin/bash
# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


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

# Get MySQL version on this machine
MYSQL_VERSION=$(mysql --version | sed -ne 's/.*Distrib \([0-9][.][0-9]\).*/\1/p')
if [[ $MYSQL_VERSION > 5.5 ]]
then 
    MYSQL_VERSION='5.6+'
else 
    MYSQL_VERSION='5.5'
fi

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
	# The sed -n option
	# says to print only if pattern matches:
	PASSWD=$(echo $arg | sed -n 's/-p\([^ ]*\)/\1/p')
	if [ -z $PASSWD ]
	then
       continue
   else
       #************
       #echo "Pwd is:"$PASSWD
       #************
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

#*****************
# echo "UID: $MYSQL_USERNAME"
# echo "PWD: $PASSWD"
# echo "needPasswd: $needPasswd"
# exit
#*****************

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
# echo "KEY_INSTALL_CMD: $KEY_INSTALL_CMD"
# exit 0
#*****************

if [[ $MYSQL_VERSION == '5.6+' ]]
then
    mysql --login-path=root EdxPrivate -e "$KEY_INSTALL_CMD"
else
    if [ -z $PASSWD ]
    then
        mysql -u $MYSQL_USERNAME EdxPrivate -e "$KEY_INSTALL_CMD"
    else
        mysql -u $MYSQL_USERNAME -p$PASSWD EdxPrivate -e "$KEY_INSTALL_CMD"
    fi
fi


# Load the .sql file that contains the procedure
# function bodies several times: into each of Edx
# and EdxPrivate, into EdxForum, and into EdxQualtrics, 
# so that they # are available there:
if [[ $MYSQL_VERSION == '5.6+' ]]
then
        mysql --login-path=root Edx          -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql --login-path=root EdxPrivate   -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql --login-path=root EdxForum     -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql --login-path=root EdxPiazza    -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql --login-path=root edxprod      -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql --login-path=root EdxQualtrics -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql --login-path=root unittest     -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
else
    if [ -z $PASSWD ]
    then
        mysql -u $MYSQL_USERNAME Edx          -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql -u $MYSQL_USERNAME EdxPrivate   -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql -u $MYSQL_USERNAME EdxForum     -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql -u $MYSQL_USERNAME EdxPiazza    -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql -u $MYSQL_USERNAME edxprod      -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql -u $MYSQL_USERNAME EdxQualtrics -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql -u $MYSQL_USERNAME unittest     -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    else
        mysql -u $MYSQL_USERNAME -p$PASSWD Edx          -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql -u $MYSQL_USERNAME -p$PASSWD EdxPrivate   -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql -u $MYSQL_USERNAME -p$PASSWD EdxForum     -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql -u $MYSQL_USERNAME -p$PASSWD EdxPiazza    -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql -u $MYSQL_USERNAME -p$PASSWD edxprod      -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql -u $MYSQL_USERNAME -p$PASSWD EdxQualtrics -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
        mysql -u $MYSQL_USERNAME -p$PASSWD unittest     -e "source "$THIS_SCRIPT_DIR"/mysqlProcAndFuncBodies.sql;"
    fi
fi

