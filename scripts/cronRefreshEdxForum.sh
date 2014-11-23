#!/bin/bash

# Pull latest Forum dump from backup machine. Anonymize
# the contents, and store in db EdxForum.contents. Assumes
# this script is running in a place from which ../../forum_etl/...
# is the path towards forum_etl/src/forum_etl/extractor.py

EDX_PLATFORM_DUMP_MACHINE=jenkins.prod.class.stanford.edu

USAGE='Usage: '`basename $0`' [-u localMySQLUser][-p][-pLocalMySQLPwd]'
# If option -p is provided, script will request password for
# local MySQL db.

# Get directory in which this script is running,
# and where its support scripts therefore live:
CURR_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


MYSQL_PWD=''
LOG_FILE=/home/dataman/Data/EdX/NonTransformLogs/refreshEdXForumTable.log
USERNAME=`whoami`
needLocalPasswd=false
# Get directory in which this script is running,
# and where its support scripts therefore live:
currScriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -f $LOG_FILE ]
then
    # Create directories to log file as needed:
    DIR_PART_LOG_FILE=`dirname $LOG_FILE`
    mkdir --parents $DIR_PART_LOG_FILE
    touch $LOG_FILE
fi

# ------------------ Process Commandline Options -------------------

# Check whether given -pPassword, i.e. fused -p with a 
# pwd string:

for arg in $@
do
   # The sed -r option enables extended regex, which
   # makes the '+' metachar wor. The -n option
   # says to print only if pattern matches:
   MYSQL_PWD=`echo $arg | sed -r -n 's/-p(.+)/\1/p'`
   if [ -z $MYSQL_PWD ]
   then
       continue
   else
       #echo "MYSQL_PWD is:"$MYSQL_PWD
       break
   fi
done

# Now check for '-p' and '-r' without explicit pwd;
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
      USERNAME=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    \?)
      # If $MYSQL_PWD is set, we *assume* that 
      # the unrecognized option was a
      # -pMyPassword and don't signal
      # an error. Therefore, if $MYSQL_PWD is set
      # and *then* an illegal option
      # is on the command line, it is quietly
      # ignored:
      if [ ! -z $MYSQL_PWD ]
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
if $needLocalPasswd && [ -z $MYSQL_PWD ]
then
    # The -s option suppresses echo:
    read -s -p "Password for "$USERNAME" on local MySQL server: " MYSQL_PWD
    echo
elif [ -z $MYSQL_PWD ]
then
    # Get home directory of whichever user will
    # log into MySQL, except for root:

    if [[ $USERNAME == 'root' ]]
    then
        HOME_DIR=$(getent passwd `whoami` | cut -d: -f6)
        if test -f $HOME_DIR/.ssh/mysql_root && test -r $HOME_DIR/.ssh/mysql_root
        then
                MYSQL_PWD=`cat $HOME_DIR/.ssh/mysql_root`
        fi
    else
        HOME_DIR=$(getent passwd $USERNAME | cut -d: -f6)
        # If the home dir has a readable file called mysql in its .ssh
        # subdir, then pull the pwd from there:
        if test -f $HOME_DIR/.ssh/mysql && test -r $HOME_DIR/.ssh/mysql
        then
                MYSQL_PWD=`cat $HOME_DIR/.ssh/mysql`
        fi
    fi
fi

#**********
# echo 'Local MySQL uid: '$USERNAME
# echo 'Local MySQL pwd: '$MYSQL_PWD
# exit 0
#**********

# ------------------ Signin -------------------
 echo  `date`": Start updating table EdxForum.contents ..."  | tee --append $LOG_FILE

# Pull the latest EdX Forum dump from jenkins.prod.class.stanford.edu to datastage. 
# Untar, and load into datastage EdxForum.contents. Two options:

echo `date`": Copying latest Forum copy from "$EDX_PLATFORM_DUMP_MACHINE" ..."  | tee --append $LOG_FILE

scp $EDX_PLATFORM_DUMP_MACHINE:/data/dump/forum-latest.tar.gz \
    ~dataman/Data/FullDumps/EdxForum
cd ~dataman/Data/FullDumps/EdxForum/
tar -zxvf forum-latest.tar.gz

# Now we have at least one subdirectory of the form
# forum-20140405. There may also be older ones. We
# want to symlink the latest of them to forum-latest
#
# The pipe below this comment does that linking. The pieces:
#
#      ls -t -r -d forum-[0-9]*
#
# list, sorted by modification time (-t) in
# reverse order, i.e. latest first (-r) all
# directories (-d) whose names start with 
# 'forum-' and are are followed by nothing but 
# digits (forum-[0-9]*)
#
# Grab the first line (tail -1). Now we have
# just the directory name that resulted from the
# tar -x above.
#
# Symbolically link the result to forum-latest:
# ln -s using backticks.

echo `date`": Symlinking Forum copy to forum_latest..."  | tee --append $LOG_FILE

 rm --force forum-latest
 ln -s `ls -t -r -d forum-[0-9]* | tail -1` forum-latest

echo `date`": Anonymizing and loading into MySQL..."  | tee --append $LOG_FILE

# Anonymize and load:
python $CURR_SCRIPT_DIR/../../forum_etl/src/forum_etl/extractor.py --anonymize $PWD/forum-latest/stanford*/contents.bson

# Delete the first 559 rows, which are all in Latin (test posts):
if [ ! -z $MYSQL_PWD ]
then
    mysql -u $USERNAME -p$MYSQL_PWD EdxForum -e "DELETE FROM contents ORDER BY forum_post_id LIMIT 559;"
else
    mysql -u $USERNAME  EdxForum  -e "DELETE FROM contents ORDER BY forum_post_id LIMIT 559;"
fi
