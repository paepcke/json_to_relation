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


# Copies the latest modulestore tar ball from Stanford's backup server.
# Does the following:
#   - imports the entire store into the local MongoDB
#   - queries the local MongoDB, retrieving the information needed
#     for table CourseInfo. Truncates that table, and re-loads
#     it with the query result.
#   - queries the local MongoDB store again to extract a
#     .json file with infomration needed by modulestoreImporter.py.
#     That information holds mappings from OpenEdX 32-bit hashes
#     to human-readable strings. The file is named with datetime, and
#     goes into <projRoot>/json_to_relation/data. It is linked to
#     modulestore_latest.json in that same directory.
#
# The JSON file looks like this:
#
# [
#  	{
#  		"_id" : {
#  			"tag" : "i4x",
#  			"org" : "edx",
#  			"course" : "templates",
#  			"category" : "annotatable",
#  			"name" : "Annotation",
#  			"revision" : null
#  		},
#  		"metadata" : {
#  			"display_name" : "Annotation"
#  		}
#  	},
#  	{
#  		"_id" : {
#  			"tag" : "i4x",
#  			"org" : "edx",
#  			"course" : "templates",
#  			"category" : "conditional",
#  			"name" : "Empty",
#  			"revision" : null
#  		},
#  		"metadata" : {
#  			"display_name" : "Empty"
#  		}
#  	},
#      ...
# ]
#
# If option -p is provided, script will request root password for
# local MySQL. Else script looks for file ~/.ssh/mysql_root to
# contain that pwd.

USAGE="Usage: "`basename $0`" [-p]"

# Get MySQL version on this machine
MYSQL_VERSION=$(mysql --version | sed -ne 's/.*Distrib \([0-9][.][0-9]\).*/\1/p')
if [[ $MYSQL_VERSION > 5.5 ]]
then
    MYSQL_VERSION='5.6+'
else
    MYSQL_VERSION='5.5'
fi

# Get directory in which this script is running,
# and where its support scripts therefore live:
currScriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TARGET_DIR=$currScriptsDir/../json_to_relation/data

# Machine where modulestore snapshots live. Directory
# /data/dump, with file modulestore-latest.tar.gz.
EDX_PLATFORM_DUMP_MACHINE=jenkins.prod.class.stanford.edu

LOG_FILE=/home/dataman/Data/EdX/NonTransformLogs/refreshModuleStore.log
needPasswd=false

MYSQL_PASSWD=''
MYSQL_USERNAME=root

# Root dir of where downloaded snapshots of
# modulestore go:
EDXPROD_DUMP_DIR=/home/dataman/Data/FullDumps/ModulestorePlatformDbs

if [ ! -e $EDXPROD_DUMP_DIR ]
then
    mkdir -p $EDXPROD_DUMP_DIR
fi


# --------------------- Process Input Args -------------

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
    read -s -p "Password for user '"$MYSQL_USERNAME"' on local MySQL server: " MYSQL_PASSWD
    echo
else
    if [ ! -f $HOME/.ssh/mysql_root ]
    then
    echo "No password found for local MySQL in $HOME/.ssh/mysql_root; trying without a password."
    else
    MYSQL_PASSWD=$(<$HOME/.ssh/mysql_root)
    needPasswd=true
    fi
fi

targetFile=$TARGET_DIR/modulestore_`date +"%m_%d_%Y_%H_%M_%S"`.json

# ------------------ Signin -------------------
echo `date`": Start refreshing modulestore extract..."  | tee --append $LOG_FILE

# ------------------ Pull Excerpt of Modulestore from S3 -------------------

# For testing can limit number of returned records by replacing
# the --eval line below like this (adds the .limit(10) clause):
#   --eval "\"printjson(db.modulestore.find({}, {'_id' : 1, 'metadata.display_name' : 1}).limit(10).toArray())\"" \
#ssh goldengate.class.stanford.edu \
# ssh jenkins.prod.class.stanford.edu \
# 	        mongo \
#             	stanford-edx-prod.m0.mongolayer.com:27017/stanford-edx-prod \
# 	    	-u readonly \
# 	    	-p$PASSWD \
#                 --quiet \
# 	    	--eval "\"printjson(db.modulestore.find({}, {'_id' : 1, 'metadata.display_name' : 1}).toArray())\"" \
#                 > $targetFile


echo `date`": Begin copying modulestore dump tarballs from backup server."
scp $EDX_PLATFORM_DUMP_MACHINE:/data/dump/modulestore-latest.tar.gz \
    $EDXPROD_DUMP_DIR/
scp $EDX_PLATFORM_DUMP_MACHINE:/data/dump/modulestore_active_versions-latest.tar.gz \
  $EDXPROD_DUMP_DIR/
scp $EDX_PLATFORM_DUMP_MACHINE:/data/dump/modulestore_definitions-latest.tar.gz \
    $EDXPROD_DUMP_DIR/
scp $EDX_PLATFORM_DUMP_MACHINE:/data/dump/modulestore_structures-latest.tar.gz \
    $EDXPROD_DUMP_DIR/
scp $EDX_PLATFORM_DUMP_MACHINE:/data/dump/modulestore_location_map-latest.tar.gz \
    $EDXPROD_DUMP_DIR/
echo `date`": Unpack modulestore dump tarballs."
cd $EDXPROD_DUMP_DIR
tar zxvf modulestore-latest.tar.gz
tar zxvf modulestore_active_versions-latest.tar.gz
tar zxvf modulestore_definitions-latest.tar.gz
tar zxvf modulestore_structures-latest.tar.gz
tar zxvf modulestore_location_map-latest.tar.gz

# Cd to the newly untarred directory:
# 'ls -dt': list directories, sorted by time, newest first.
# The '| head -2 | tail -1' grabs the second of the list. The first will
# always be the modulestore-latest.tar.gz that we just
# downloaded. The second will be the directory created by
# untarring that file. The time stamp of that directory
# is the time it was created earlier on the *backup server*,
# not the time it was created by the untarring:
# CHANGED:
# cd $EDXPROD_DUMP_DIR
# cd `ls -dt * | head -2 | tail -1`
# cd stanford-edx-prod

# cp new modulestore dumps to staging directory
mkdir modulestore_latest_stage
cd `ls -dt *store-20* | head -1`
cp ./stanford-edx-prod/modulestore*.*son ../modulestore_latest_stage/
cd ..
cp *active_versions*/stanford-edx-prod/*active_versions*.*son ./modulestore_latest_stage/
cp *definitions*/stanford-edx-prod/*definitions*.*son ./modulestore_latest_stage/
cp *structures*/stanford-edx-prod/*structures*.*son ./modulestore_latest_stage/
cp *location_map*/stanford-edx-prod/*location_map*.*son ./modulestore_latest_stage/
cd modulestore_latest_stage

echo `date`": Deleting old modulestore from local MongoDB."
# CHANGED: mongo modulestore --eval "db.modulestore.remove({})"
mongo modulestore --quiet --eval "db.dropDatabase()"

echo `date`": Loading new modulestore copy into local MongoDB."
mongorestore --db modulestore modulestore.bson
mongorestore --db modulestore modulestore.active_versions.bson
mongorestore --db modulestore modulestore.structures.bson
mongorestore --db modulestore modulestore.definitions.bson
mongorestore --db modulestore modulestore.location_map.bson

cd ..
rm -rf modulestore_latest/
mv modulestore_latest_stage/ modulestore_latest/

TMP_FILE=`mktemp`
chmod a+r $TMP_FILE

# Detect modulestore version and refresh accordingly
cd $currScriptsDir/../json_to_relation/
ms_collections=`mongo modulestore --quiet --eval "db.getCollectionNames()"`
if [[ $ms_collections =~ "active_versions" ]]
# TODO: Make sure this actually works
then
    python modulestoreToSQL.py
else
    echo `date`": modulestore not reloaded correctly..."
fi

# # Create command that loads modulestoreJavaScriptUtils.js into
# # MongoDB, creates a CourseInfoExtractor instance, and invokes
# # method createCourseCSV() on it. We give the method 0 for the
# # academic year, b/c we want a list of all years, and the string
# # 'all' to get all quarters of each year. The result, when the
# # mongo application is run with this command to --eval is a
# # stream of course information in CSV format:
# mongoCmd="load('"${currScriptsDir}/modulestoreJavaScriptUtils.js"'); \
#           courseExtractor = new CourseInfoExtractor();"
# if $SPLIT
# then
#     mongoCmd="${mongoCmd} courseExtractor.createCourseCSV(0, 'all', true);"
# else
#     mongoCmd="${mongoCmd} courseExtractor.createCourseCSV(0, 'all', false);"
# fi
# mongo modulestore --eval "$mongoCmd" > $TMP_FILE
#
# #************
# #echo "TMP_FILE: $TMP_FILE"
# #exit 0
# #************
# MYSQL_CMD="LOAD DATA LOCAL INFILE '"$TMP_FILE"' INTO TABLE Edx.CourseInfo \
#            FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' \
#            LINES TERMINATED BY '\n' \
#            IGNORE 3 LINES;"
#
# #************
# # echo "TMP_FILE: $TMP_FILE"
# # ls -l $TMP_FILE
# # echo $MYSQL_CMD
# # exit 0
# #************
#
# echo `date`": Truncating current CourseInfo table, and importing new modulestore."
# if [[ $MYSQL_VERSION == '5.6+' ]]
# then
#     # Use 5.6 auth to MySQL:
#     mysql --login-path=root Edx -e "TRUNCATE TABLE CourseInfo; ""$MYSQL_CMD"
# else
#     # Use 5.5 auth to MySQL:
#     if $needPasswd
#     then
#         mysql -u $MYSQL_USERNAME -p$MYSQL_PASSWD Edx -e "TRUNCATE TABLE CourseInfo; ""$MYSQL_CMD"
#     else
#         mysql -u $MYSQL_USERNAME Edx -e "TRUNCATE TABLE CourseInfo; ""$MYSQL_CMD"
#     fi
# fi
# echo `date`": Deleting temp file."
# rm $TMP_FILE

# ------------------ Extract Display Name Information For OpenEdX 32-bit Hashes -------------------

# We excerpt modulestore into a json string that will
# be read by modulestoreImporter.py. The class defined
# there will load the JSON, and construct an in-memory dict.
# The dict will enable the mapping of 32-bit OpenEdX hashes
# of learning module names and other resources to human-readable
# names:

echo `date`": Writing OpenEdX-hash-->display_name modulestore json excerpt to "$targetFile"."
#mongo --quiet --eval "printjson(db.modulestore.find({}, {'_id' : 1, 'metadata.display_name' : 1}).toArray())" > $targetFile
# Note: the following little JS script loads
#       all of modulestore into RAM. To avoid this, you
#       need to change that script to create a JSON array
#       [<firstResult>,<secondResult>,...]. Use of toArray()
#       in the scripts does that automatically:
mongo  --quiet ${currScriptsDir}/mongoPrintCourseMetadata.js >> $targetFile


# ------------------ Make Available in Well Known Location -------------------

# Remove the linked-to 'modulestore_latest.json'
# if it exists; we'll make a new link below:
if [ -e $TARGET_DIR/modulestore_latest.json ]
then
    rm $TARGET_DIR/modulestore_latest.json
fi

# If $targetFile is empty, the above query failed.
# Remove the empty file (-s: 'not zero size'; so
# negation of that is 'if is zero size'). If
# the Mongo query worked, symlink the result

if [ -s $targetFile ]
then
    ln -s $targetFile $TARGET_DIR/modulestore_latest.json
else
    rm $targetFile
    exit 1
fi

# Remove old hash lookup pickle file to force ModulestoreImporter
# to re-build that hash:
echo `date`": Removing old ModulestoreImporter cash pickle file if exists; OK if it does not."
rm $TARGET_DIR/hashLookup.pkl

# ------------------ Signout -------------------
echo `date`": Finished updating table modulestore extract."  | tee --append $LOG_FILE
echo "----------"
