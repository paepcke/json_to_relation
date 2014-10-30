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
#    qsub -V -v logsSrc=<pathToJSONParentDir> sqlDest=<pathToResultSQL/CSV>  scripts/qsubClusterSubmission.sh
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
    manageEdxDbLoc=${currScriptsDir}
fi

#PBS -N $jobName
#PBS -o /dfs/scratch1/paepcke/ClusterLogs/${jobName}.out
#PBS -e /dfs/scratch1/paepcke/ClusterLogs/${jobName}.err
#PBS -l nodes=25:ppn=25

# Have cluster send mail when job starts and finishes
#PBS -m be -M paepcke@cs.stanford.edu


${manageEdxDbLoc} --logsSrc ${logsSrc} --sqlDest ${sqlDest} --onCluster transform
