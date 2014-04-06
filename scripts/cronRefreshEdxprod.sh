#!/bin/bash

# Copies latest edxprod database with all its tables from
# deploy.prod.class.stanford.edu:/data/dump, and imports
# the tables into local MySQL's db 'edxprod'. Password-less
# login must have been arranged to the remote machine.

USAGE='Usage: '`basename $0`' [-u localUbuntuUser][-p][-pLocalMySQLRootPwd]'

# If option -p is provided, script will request password for
# local MySQL db's root user. As per MySQL the -p can be
# fused with the pwd on the CL. The MySQL activities all run as
# MySQL user root. The -u localUbuntuUser is only relevant
# if no MySQL root pwd is provided with -p. In that case 
# the given Ubuntu user's home dir is expected to contain
# file .ssh/mysql_root with the password.

MYSQL_PASSWD=''
MYSQL_USERNAME=root
UBUNTU_USERNAME=`whoami`
EDXPROD_DUMP_DIR=/home/dataman/Data/FullDumps/EdxAppPlatformDbs
LOG_FILE=/home/dataman/Data/EdX/NonTransformLogs/refreshEdxprod.log
needLocalPasswd=false

# ------------------ Process Commandline Options -------------------

# Check whether given -pPassword, i.e. fused -p with a 
# pwd string:

for arg in $@
do
   # The sed -r option enables extended regex, which
   # makes the '+' metachar wor. The -n option
   # says to print only if pattern matches:
   MYSQL_PASSWD=`echo $arg | sed -r -n 's/-p(.+)/\1/p'`
   if [ -z $MYSQL_PASSWD ]
   then
       continue
   else
       #echo "MYSQL_PASSWD is:"$MYSQL_PASSWD
       break
   fi
done


# Now check for '-p' without explicit pwd;
# the leading colon in options causes wrong options
# to drop into \? branch:
NEXT_ARG=0

while getopts ":pu:" opt
do
  case $opt in
    p)
      needLocalPasswd=true
      NEXT_ARG=$((NEXT_ARG + 1))
      ;;
    u)
      UBUNTU_USERNAME=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    \?)
      # If $MYSQL_PASSWD is set, we *assume* that 
      # the unrecognized option was a
      # -pMyPassword, and don't signal
      # an error. Therefore, if $MYSQL_PASSWD
      # is set, and *then* an illegal option
      # is on the command line, it is quietly
      # ignored:
      if [ ! -z $MYSQL_PASSWD ] 
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

# ------------------ Ask for Passwords if Requested on CL -------------------

# Ask for local pwd, unless was given
# a fused -pLocalPWD:
if $needLocalPasswd && [ -z $MYSQL_PASSWD ]
then
    # The -s option suppresses echo:
    read -s -p "Password for "$UBUNTU_USERNAME" on local MySQL server: " MYSQL_PASSWD
    echo
elif [ -z $MYSQL_PASSWD ]
then
    # Get home directory of whichever user will
    # log into MySQL:
    HOME_DIR=$(getent passwd $UBUNTU_USERNAME | cut -d: -f6)
    # If the home dir has a readable file called mysql_root in its .ssh
    # subdir, then pull the pwd from there:
    if [[ -f $HOME_DIR/.ssh/mysql_root && -r $HOME_DIR/.ssh/mysql_root ]]
    then
	MYSQL_PASSWD=`cat $HOME_DIR/.ssh/mysql_root`
    fi
fi

#**********
# echo 'MySQL uid: '$MYSQL_USERNAME
# echo 'MySQL pwd: '$MYSQL_PASSWD
# echo 'Ubuntu uid: '$UBUNTU_USERNAME
# exit 0
# *********

# ------------------ Signin-------------------
echo `date`": Begin refreshing edxprod."  | tee --append $LOG_FILE
echo "----------"
scp deploy.prod.class.stanford.edu:/data/dump/edxapp-latest.sql.gz \
    $EDXPROD_DUMP_DIR/
gunzip $EDXPROD_DUMP_DIR/edxapp-latest.sql.gz
mysql -u root -p$MYSQL_PASSWD < $EDXPROD_DUMP_DIR/edxapp-latest.sql.gz

# ------------------ Signout -------------------
echo `date`": Finished refreshing edxprod tables."  | tee --append $LOG_FILE
echo "----------"
