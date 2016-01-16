# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Submit this script to the Torque cluster queue manager
# when using a compute cluster to transform many OpenEdX
# tracking log files to relational tables.
#
# Two options for passing the required parameters to qsub.
# Recommended: Option 2:
#
# Option 1: set two or three environment vars before running.
#   [ manageEdxDbLoc: full path to the script manageEdxDb.py. 
#                   Only required if manageEdxDb.py is in a
#                   directory other than this script.
#   ]
#   logsSrc: full path of directory under which the JSON files to
#            be transformed reside. The subdirectories are assumed
#            to be called app<int> where <int> is some integer.
#   sqlDest: full path to the directory where the resulting sql and
#            csv files reside.
#
# Option 2: keep this script in same directory as manageEdxDb.py
#           (it's there by default). Then pass the info described
#           Option 1 on the command line.
#
#    [cd <json_to_relation dir>] # Optional; if skipped need full 
#                                # path to script in statement below.
#    qsub -V -t 0-500 -v logsSrc=<pathToJSONParentDir>,sqlDest=<pathToResultSQL/CSV>,scripts/qsubClusterSubmission.sh
#
# The -V passes the environment to all the nodes. The -v accepts the
# key/value pairs.
#
# You want to change the email directive to send email
# to you, not the person set now (#PBS -m be directive)
#

jobName=paepckeTransforms$(date --utc +%FT%TZ)
currScriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# If manageEdxDbLoc is set, use it, else
# set manageEdxDbLoc to the dir of this script:
if [ ${manageEdxDbLoc}foo == 'foo' ]
then
    manageEdxDbLoc=${currScriptsDir}/manageEdxDb.py
fi

#PBS -N $jobName
#PBS -o /dfs/scratch1/paepcke/ClusterLogs/${jobName}.out
#PBS -e /dfs/scratch1/paepcke/ClusterLogs/${jobName}.err
#PBS -l nodes=1:ppn=1



# Have cluster send mail when job starts and finishes
#PBS -m be -M paepcke@cs.stanford.edu


${manageEdxDbLoc} --logsSrc ${logsSrc} --sqlDest ${sqlDest} --onCluster transform
