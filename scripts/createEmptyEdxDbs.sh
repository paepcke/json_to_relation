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


# Creates empty Edx and EdxPrivate databases
# on local MySQL server. Uses createEmptyEdxDbs.sql
# for the definitions. Then invokes defineMySQLProcedures.sh
# to install the stored prodcedures and functions required
# for operation.

usage="Usage: "`basename $0`" [-u username][-p][-n noindexex]"


# Determine if this is a Mac. Some bash
# commands are not available there:
if [[ $(echo $OSTYPE | cut -c 1-6) == 'darwin' ]]
then
    PLATFORM='macos'
    BASH_VERSION=$(echo $(bash --version) | sed -n 's/[^0-9]*version \([0-9]\).*/\1/p')
    if [[ $BASH_VERSION < 4 ]]
    then
        echo "On MacOS Bash version must be 4.0 or higher."
        exit 1
    fi
else
    PLATFORM='other'
fi    

# Get MySQL version on this machine
MYSQL_VERSION=$(mysql --version | sed -ne 's/.*Distrib \([0-9][.][0-9]\).*/\1/p')
if [[ $MYSQL_VERSION > 5.5 ]]
then
    MYSQL_VERSION='5.6+'
else
    MYSQL_VERSION='5.5'
fi

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
	# The sed -n option
	# says to print only if pattern matches:
	PASSWD=$(echo $arg | sed -n 's/-p\([^ ]*\)/\1/p')
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
	if [[ $PLATFORM == 'macos' ]]
	 then
		# MacOS dcacheutil outputs multiple /etc/passwd related 
		# lines for given user: name, uid, gid. Etc. The one we
		# want is: "dir: /Users/theUser". Use awk to find
		# the line, and extract the 2nd field (i.e. the home dir:
		HOME_DIR=$(dscacheutil -q user -a name $USERNAME | awk '/dir:/ {print $2}')
	 else	
		HOME_DIR=$(getent passwd $USERNAME | cut -d: -f6)
	 fi
    # log into MySQL:
    # If the home dir has a readable file called mysql_root in its .ssh
    # subdir, then pull the pwd from there:
    if test -f $HOME_DIR/.ssh/mysql_root && test -r $HOME_DIR/.ssh/mysql_root
    then
	PASSWD=`cat $HOME_DIR/.ssh/mysql_root`
    fi
fi

#**************
 #echo 'UID of script caller: '$USERNAME
 #echo 'UID used for MySQL operations: root'
 #echo 'MySQL root password: '$PASSWD
# exit 0
#**************

#**************
echo "About to create tables"
#**************

currScriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [[ $MYSQL_VERSION == '5.6+' ]]
then
    mysql --login-path=root < ${currScriptsDir}/createEmptyEdxDbs.sql
else
    if [ -z $PASSWD ]
    then
        mysql -u root < ${currScriptsDir}/createEmptyEdxDbs.sql
    else
        mysql -u root -p$PASSWD < ${currScriptsDir}/createEmptyEdxDbs.sql
    fi
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
