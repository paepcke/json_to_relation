 #!/usr/bin/env bash                                                                                                     

# Run simple, full backup for all the relevant OpenEdX databases:
#   Edx
#   EdxPrivate
#   EdxForum
#   EdxPiazza

# If used outside of Stanford: change the target disk,
# which at Stanford is /lfs/datastage/1/MySQLBackup/
#
# NOTE: will ask for sudo pwd, which limits running by cron

usage="Usage: "`basename $0`" [-u username][-p[pwd]]"

USERNAME=`whoami`
PASSWD=''
askForPasswd=false

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
while getopts ":u:p" opt
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
    :)
      echo $USAGE
      exit 1
      ;;
  esac
done

# Shift past all the optional parms:
shift ${NEXT_ARG}


if $askForPasswd && [ -z $PASSWD ]
then
    # The -s option suppresses echo:
    read -s -p "Password for $USERNAME on MySQL server: " PASSWD
    echo
elif [ -z $PASSWD ]
then
    if [ $USERNAME == "root" ]
    then
        # Get home directory of whichever user will
        # log into MySQL:
	HOME_DIR=$(getent passwd `whoami` | cut -d: -f6)
        # If the home dir has a readable file called mysql_root in its .ssh
        # subdir, then pull the pwd from there:
	if test -f $HOME_DIR/.ssh/mysql_root && test -r $HOME_DIR/.ssh/mysql_root
	then
	    PASSWD=`cat $HOME_DIR/.ssh/mysql_root`
	fi
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
fi

# Create the mysql call password option:
if [ -z $PASSWD ]
then
    pwdOption=''
else
    pwdOption=$PASSWD
fi

# Create new directory with name including current date and time:
# The part `echo \`date\` | sed -e 's/[ ]/_/g'`:
# ...  \'date\': get date as string like "Fri Jun 20 08:54:42 PDT 2014"
# ... | sed -e 's/[ ]/_/g'` remove spaces within the date, and replace them with underscore
# Result example: "backupEdx_Fri_Jun_20_08:54:42_PDT_2014"

newDir=/lfs/datastage/1/MySQLBackup/backupEdx_`echo \`date\` | sed -e 's/[ ]/_/g'`
#echo $newDir

# The following will ask for sudo PWD, which limits 
# automatic run for now. Need to fix this:
sudo mkdir $newDir

# Use mysqlhotcopy to grab one MySQL db at a time:
echo "Backing up Edx db..."
sudo time mysqlhotcopy --user=$USERNAME --password=$pwdOption Edx $newDir       # ~3hrs
echo "Backing up EdxForum db..."
sudo time mysqlhotcopy  --user=$USERNAME --password=$pwdOption EdxForum $newDir       # instantaneous
echo "Backing up EdxPiazza db..."
sudo time mysqlhotcopy  --user=$USERNAME --password=$pwdOption EdxPiazza $newDir      # instantaneous
echo "Backing up EdxPrivate db..."
sudo time mysqlhotcopy  --user=$USERNAME --password=$pwdOption EdxPrivate $newDir     # ~3min
                                                                                                                         
                                                   