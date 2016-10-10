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

# Create two email lists: of learners who ever enrolled from given country,
# and those who enrolled within the past 20 months. Used to clean email lists
# of learners who have not enrolled in a Lagunita course for 20 months or more.
#
# Country is the full official country name as used in the UserCountry table.
# Example: 'Canada'.


USAGE="Usage: "`basename $0`" [-h][-u username][-p] country"
help="Create two email lists: of learners who ever enrolled from given country, and those who enrolled within the past 20 months."

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
    h) # help
      echo $help
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

# Now must have one arg left: the country:

if [ $# -lt 1 ]
then
   echo $USAGE
   exit 1
fi

COUNTRY=$1
TODAY=`date +%Y_%m_%d`

# Find un-taken output files for the
# all-emails and the newbie-emails files:

NUM=0
while true
do
    # echo "Checking /tmp/all${COUNTRY}Emails_$TODAY.txt"
    if [[ ! -e /tmp/all${COUNTRY}Emails_$TODAY_$NUM.txt ]]
    then
        # echo "/tmp/all${COUNTRY}Emails_$TODAY.txt"
        ALL_COUNTRY_EMAIL_FILE=/tmp/all${COUNTRY}Emails_$TODAY_$NUM.txt
        break
    fi
    ((NUM++))
done

NUM=0
while true
do
    if [[ ! -e /tmp/${COUNTRY}Newbies_$TODAY_$NUM.txt ]]
    then
        # echo "Picking /tmp/${COUNTRY}Newbies_$TODAY.txt"
        COUNTRY_NEWBIE_EMAIL_FILE=/tmp/${COUNTRY}Newbies_$TODAY_$NUM.txt
        break
    fi
    ((NUM++))
done

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
    pwdOption='-p'$PASSWD
fi

# Build a variable MYSQL_AUTH that depends on
# the MySQL server version. Versions <5.6 use
#   -u $USERNAME $pwdOption
# For newer servers we use --login-path=root

if [[ $MYSQL_VERSION == '5.6+' ]]
then
    MYSQL_AUTH="--login-path=root"
else
    MYSQL_AUTH="-u $USERNAME $pwdOption"
fi

QUERY="use Edx;
DROP TEMPORARY TABLE IF EXISTS CanadianAnons;
CREATE TEMPORARY TABLE CanadianAnons (anon_screen_name_ca varchar(40))
AS (SELECT anon_screen_name AS anon_screen_name_ca
      FROM UserCountry
     WHERE country = '$COUNTRY'
   );

DROP TEMPORARY TABLE IF EXISTS CanadianAnonInts;
CREATE TEMPORARY TABLE CanadianAnonInts (anon_screen_name_ca varchar(40), user_int_id int)
AS (
     SELECT anon_screen_name_ca, user_int_id
       FROM CanadianAnons
         LEFT JOIN 
            EdxPrivate.UserGrade
         ON CanadianAnons.anon_screen_name_ca = EdxPrivate.UserGrade.anon_screen_name
   );

DROP TEMPORARY TABLE IF EXISTS CanadianEmails;
CREATE TEMPORARY TABLE CanadianEmails (anon_screen_name_ca varchar(40), 
                                       user_int_id int,
                                       email varchar(100))
AS (
     SELECT DISTINCT anon_screen_name_ca, user_int_id, email
       FROM CanadianAnonInts
         LEFT JOIN
            edxprod.auth_user
         ON edxprod.auth_user.id = CanadianAnonInts.user_int_id
      WHERE email IS NOT NULL
   );


SELECT email FROM CanadianEmails
  INTO OUTFILE '${ALL_COUNTRY_EMAIL_FILE}';

SELECT DISTINCT email
  INTO OUTFILE '${COUNTRY_NEWBIE_EMAIL_FILE}'
  FROM
     Edx.CanadianEmails
   RIGHT JOIN
     (SELECT user_id
        FROM edxprod.courseenrollment_all_info
       WHERE created >= DATE_SUB(CURDATE(), INTERVAL 20 MONTH)
     ) Learners
   ON Edx.CanadianEmails.user_int_id = Learners.user_id
 WHERE email IS NOT NULL;
"

# echo $QUERY

echo "Running query..."

mysql $MYSQL_AUTH --silent --skip-column-names -e "$QUERY"

echo "All email addresses of ${COUNTRY}'s enrollees are in ${ALL_COUNTRY_EMAIL_FILE}."
echo "Emails from ${COUNTRY} learners enrolled within past 20 months are in ${COUNTRY_NEWBIE_EMAIL_FILE}."
