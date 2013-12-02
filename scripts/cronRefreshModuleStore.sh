#!/bin/bash

USAGE='Usage: cronRefreshModuleStore.sh [-p] targetDir'

PASSWD=''
needPasswd=false

# Require at least the target directory:
if [ $# -lt 1 ]
then
   echo $USAGE
   exit 1
fi

# Keep track of number of optional args the user provided:
NEXT_ARG=0

while getopts "p" opt
do
  case $opt in
    p)
      needPasswd=true
      NEXT_ARG=$((NEXT_ARG + 1))
      ;;
    \?)
      # Illegal option; the getopts provided the error message
      echo $USAGE
      exit 1
      ;;
  esac
done

# Shift past all the optional parms:
shift ${NEXT_ARG}


if $needPasswd
then
    # The -s option suppresses echo:
    read -s -p "Password for user 'readonly' on modulestore repo: " PASSWD
    echo
else
    PASSWD=$(</home/dataman/.cron/modstore.txt)
fi

targetFile=$1/modulestore_`date +"%m_%d_%Y_%H_%M_%S"`.json

# For testing can limit number of returned records by replacing
# the --eval line below like this (adds the .limit(10) clause):
#   --eval "\"printjson(db.modulestore.find({}, {'_id' : 1, 'metadata.display_name' : 1}).limit(10).toArray())\"" \
ssh goldengate.class.stanford.edu \
	        mongo \
            	stanford-edx-prod.m0.mongolayer.com:27017/stanford-edx-prod \
	    	-u readonly \
	    	-p$PASSWD \
                --quiet \
	    	--eval "\"printjson(db.modulestore.find({}, {'_id' : 1, 'metadata.display_name' : 1}).toArray())\"" \
                > $targetFile

ln -s $targetFile $1/modulestore_latest.json
