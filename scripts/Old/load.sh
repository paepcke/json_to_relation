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


# NOTE: designed to be called from manageEdxDb.py, which acquires the 
#       MySQL pwd without printing it out.
#
# Loads SQL files into MySQL db. MySQL loads execute
# under the user uid that is running this script. The respective
# password must be passed in.
#
# When done with MySQL load, appends date/time to /tmp/doneLoad.txt
# Then indexes selected fields.
# Log of the MySQL load will be in /tmp/loadLog.log

# Usage: load.sh mySqlRootPWD {sqlDir | sqlFile sqlFile...}

PWD=$1
SQL_DIR=$2

if [ -d $SQL_DIR ]; then
    # $SQL_DIR is a directory from which all .sql files are to be loaded:
    echo "TransformAndLoad start load: `date`" >> /tmp/transformAndLoad.txt
    cd $SQL_DIR
    # Pipe each file name into awk to produce "source <fileName>", 
    # pipe that into the mysql command as a last arg:
    #*********time find . -name '*.sql' | awk '{ print "source",$0 }' | mysql -f --batch -u root -p$PWD > /tmp/loadLog.log 2>&1
    # To test, comment line above, and uncomment line below; also comment the mysql command down below (see comment there)
    find . -name '*.sql' | awk '{ print "source",$0 }' | cat
    echo "TransformAndLoad done load: `date`" >> /tmp/transformAndLoad.txt
elif [ -f $SQL_DIR ]; then
    # $SQL_DIR is actually a file, and so are all the remaining args:
    # Get rid of the pwd:
    shift
    # Cycle through the files and feed them to mysql:
    for sqlFile in $@
    do
	#***************echo "source $sqlFile" | mysql -f --batch -u root -p$PWD >> /tmp/loadLog.log 2>&1
	echo "source $sqlFile" | cat
        #***************
    done
else
    echo "$SQL_DIR is neither a file nor a directory; cannot load this entity into MySQL; no action taken"
    exit 1
fi

echo "TransformAndLoad start indexing: `date`" >> /tmp/transformAndLoad.txt
# To test, comment line below
mysql -u root -p$PWD < edxCreateIndexes.sql
echo "TransformAndLoad done indexing: `date`" >> /tmp/transformAndLoad.txt