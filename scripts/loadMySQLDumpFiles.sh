#!/bin/bash

# Loads one or more SQL dump files into the locally accessible MySQL (at usual port 3306)
# Files may be .sql, .sql.gz, or .sql.bz2. The correct decompression will
# happen in a pipe (i.e. files are not decompressed on the disk.)
#
# Commandline required argument: at least one file to import. 
# Optional arguments are -p (use password) -u <username>, and -d <dbName>.
# If -p is provided, the script will ask for the MySQL password without
# echoing the answer. Default is no password. If no username
# is provided, default is 'root'. If no database name is provided,
# the SQL dump should create or use a database. If a database
# name is provided, that database must exist in the MySQL server.
#
# NOTE: Script not robust against missing username after -u. So:
#           loadSQLFiles -u myDb file1.sql
#       will do nothing, b/c myDb is taken as username, and file1.sql
#       will be taken as the db name
#           loadSQLFiles -u -p myDb file1.sql
#       will take '-p' as user name.         

USAGE='Usage: loadSQLFiles.sh [-u userName] [-p] [-d dbname] file1 file2 ... '

USERNAME=root
PASSWD=''
DATABASE=''
needPasswd=false

# Require at least database name and one file:
if [ $# -lt 1 ]
then
   echo $USAGE
   exit 1
fi

# Keep track of number of optional args the user provided:
NEXT_ARG=0
while getopts "u:pd:" opt
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
    d)
      DATABASE=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    \?)
      # Illegal option; the getopts provided the error message
      echo $USAGE
      exit 1
      ;;
    :)
      # Not reliable: a -u w/o a username would swallow the db name.
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Shift past all the optional parms:
shift ${NEXT_ARG}

#*************
# echo "DB: '$DATABASE'"
# echo "User: $USERNAME"
# echo "Files: ${@}"
# exit
#*************

if $needPasswd
then
    # The -s option suppresses echo:
    read -s -p "Password for user '$USERNAME' on MySQL server: " PASSWD
    echo
fi

# For each file, check its extension, and decompress
# if needed:
for fileName in "${@}"
do
   echo "Ingesting $fileName into $USERNAME's $DATABASE..."

   if [ "${fileName##*.}" == 'bz2' ]
   then
      #echo "is bz2"
      bunzip2 < $fileName | mysql --user=$USERNAME --password=$PASSWD $DATABASE
   elif [ "${fileName##*.}" == 'gz' ]
   then
      #echo "is gz"
      gunzip < $fileName | mysql --user=$USERNAME --password=$PASSWD $DATABASE
   else
      #echo "is regular"
      cat $fileName | mysql --user=$USERNAME --password=$PASSWD $DATABASE
   fi
   
   echo "Done ingesting $fileName..."
done
