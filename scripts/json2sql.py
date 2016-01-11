#!/usr/bin/env python

import argparse
import datetime
import os
import re
import socket
import sys
import time

# Add json_to_relation source dir to $PATH
# for duration of this execution:
source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir

from edxTrackLogJSONParser import EdXTrackLogJSONParser
from input_source import InURI
from json_to_relation import JSONToRelation
from output_disposition import OutputDisposition, OutputFile


# Transforms a single .json OpenEdX tracking log file to
# relational tables. See argparse below for options.

# For non-Stanford installations, customize the following
# setting of LOCAL_LOG_STORE_ROOT. This is the file system
# directory from which S3 key paths descend. Example: Stanford's
# S3 file keys where .json tracking logs are stored are of the form
#    tracking/app10/tracking.log-<date>.gz
# For transform to relational tables we copy these files
# to /foo/bar/, so that they end up like this:
# /foo/bar/tracking/app10/tracking.log-<date>.gz
# LOCAL_LOG_STORE_ROOT in this example is /foo/bar/

LOCAL_LOG_STORE_ROOT = None

hostname = socket.gethostname()
if hostname == 'duo':
    LOCAL_LOG_STORE_ROOT = "/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsTests/"
elif hostname == 'mono':
    LOCAL_LOG_STORE_ROOT = "/home/dataman/Data/EdX/tracking"
elif hostname == 'datastage':
    LOCAL_LOG_STORE_ROOT = "/home/dataman/Data/EdX/tracking"
elif hostname == 'datastage2':
    LOCAL_LOG_STORE_ROOT = "/home/dataman/Data/EdX/tracking"
elif hostname == 'datastage2go':
    LOCAL_LOG_STORE_ROOT = "/home/dataman/Data/EdX/tracking"

def buildOutputFileName(inFilePath, destDir, fileStamp):
    '''
    Given the full path to a .json tracking log file, a destination
    directory where results of a transform to relational tables will
    go, and a timestamp to ensure uniqueness, generate a new .sql
    filename that will be used by the transform. Example: given::
      /EdX/EdXTrackingLogsTests/tracking/app10/tracking.log-20130610.gz
    and given destDir of /tmp, and LOCAL_LOG_STORE_ROOT being /EdX/EdXTrackingLogsTests/
    /returns something like::
      /tmp/racking.app10.tracking.log-20130610.gz.2013-12-05T00_33_10.462711_5050.sql

    That is the LOCAL_STORE_ROOT is removed from the infile, leaving just
    tracking/app10/tracking.log-20130610.gz. Then the destDir is prepended,
    the fileStamp is appended, together with a trailing .sql

    If the inFilePath does not end with '.gz', but '.gz' is part of the
    inner part of the file name then enough of the file
    name tail is removed to have the name end in .gz. If no '.gz' is
    anywhwere in the filename, the filename is left alone. This odd behavior
    takes care of a particularity of the compute cluster implementation for
    transforms. Script transformGivenLogFilesOnCluster.sh appends '.DONE' to
    file names as part of the file selection protocol that all the cluster
    machines follow. We don't want that '.DONE' to be part of the name
    we return here.

    @param inFilePath: full path to .json file
    @type inFilePath: String
    @param destDir: full path to destination directory
    @type destDir: String
    @param fileStamp: timestamp
    @type fileStamp: String
    @return: a full filename with a .sql extension, derived from the input file name
    @rtype: String
    '''
    # For cluster operations, 'DONE.gz' is appended to
    # file names to indicate that they are done.
    # Chop that flag off for the purpose of creating
    # an output file name:
    if inFilePath.endswith('.DONE.gz'):
        inFilePath = inFilePath[:-8]

    # If file name has no .gz at all, simply proceed,
    # not worrying about any unwanted extensions:
    if  re.search('.gz', inFilePath) is not None:
        while not inFilePath.endswith('.gz'):
            inFilePath,oldExtension = os.path.splitext(inFilePath) #@UnusedVariable

    if LOCAL_LOG_STORE_ROOT is None:
        return os.path.join(destDir, os.path.basename(inFilePath)) + '.' + fileStamp + '.sql'
    rootEnd = inFilePath.find(LOCAL_LOG_STORE_ROOT)
    if rootEnd < 0:
        return os.path.join(destDir, os.path.basename(inFilePath)) + '.' + fileStamp + '.sql'
    subTreePath = inFilePath[rootEnd+len(LOCAL_LOG_STORE_ROOT):]
    subTreePath = re.sub('/', '.', subTreePath)
    if subTreePath[0] == '.':
        subTreePath = subTreePath[1:]
    res = os.path.join(destDir, subTreePath + '.' + fileStamp + '.sql')
    return res


if __name__ == "__main__":

    parser = argparse.ArgumentParser(prog='json2sql.py')
    parser.add_argument('-x', '--expungeTables',
                        help='DROP all tables in database before beginning transform',
                        dest='dropTables',
                        action='store_true',
                        default=False)
    # parser.add_argument('-l', '--logFile',
    #                     help='fully qualified log file name. Default: no logging.',
    #                     dest='logFile',
    #                     default='/tmp/j2s.sql');
    parser.add_argument('-v', '--verbose',
                        help='print operational info to console.',
                        dest='verbose',
                        action='store_true');
    parser.add_argument('-t', '--targetFormat',
                        help='Output one CSV file per table, a dump file as would be created my mysqldump, or both. Default: sql_dump',
                        dest='targetFormat',
                        default='sql_dump',
                        choices = ['csv', 'sql_dump', 'sql_dump_and_csv']);
    parser.add_argument('destDir',
                        help='file path for the destination .sql/csv file(s)')
    parser.add_argument('inFilePath',
                        help='json file path to be converted to sql/csv.')


    args = parser.parse_args();

    # Output file is name of input file with the
    # .json extension replaced by .sql, and a unique
    # timestamp/pid added to avoid name collisions during
    # parallel processing:
    dt = datetime.datetime.fromtimestamp(time.time())
    fileStamp = dt.isoformat().replace(':','_') + '_' + str(os.getpid())

    outFullPath = buildOutputFileName(args.inFilePath, args.destDir, fileStamp)

    #********************
    #print('In: %s' % args.inFilePath)
    #print('Out: %s' % outFullPath)
    #sys.exit()
    #********************

    # Log file will go to <destDir>/../TransformLogs, the file being named j2s_<inputFileName>.log:
    logDir = os.path.join(args.destDir, '..') + '/TransformLogs'
    if not os.access(logDir, os.W_OK):
        try:
            os.makedirs(logDir)
        except OSError:
            # Log dir already existed:
            pass

    logFile = os.path.join(logDir, 'j2s_%s_%s.log' % (os.path.basename(args.inFilePath), fileStamp))


#    print('xpunge: %s' % args.dropTables)
#    print('verbose: %s' % args.verbose)
#    print('destDir: %s' % args.destDir)
#    print('in=FilePath: %s' % args.inFilePath)
#    print('outFullPath: %s' % outFullPath)
#    print('logFile: %s' % logFile)

    # Create an instance of JSONToRelation, taking input from the given file:
    # and pumping output to the given output path:

    if args.targetFormat == 'csv':
        outputFormat = OutputDisposition.OutputFormat.CSV
    elif args.targetFormat == 'sql_dump':
        outputFormat = OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS
    else:
        outputFormat = OutputDisposition.OutputFormat.SQL_INSERTS_AND_CSV

    outSQLFile = OutputFile(outFullPath, outputFormat, options='wb')  # overwrite any sql file that's there
    jsonConverter = JSONToRelation(InURI(args.inFilePath),
                                   outSQLFile,
                                   mainTableName='EdxTrackEvent',
    				               logFile=logFile
                                   )
    try:
        jsonConverter.setParser(EdXTrackLogJSONParser(jsonConverter,
        						  'EdxTrackEvent',
        						  replaceTables=args.dropTables,
        						  dbName='Edx'
        						  ))
    except Exception as e:
        with open(logFile, 'w') as fd:
            fd.write("In json2sql: could not create EdXTrackLogJSONParser; infile: %s; outfile: %s; logfile: %s (%s)" % (InURI(args.inFilePath), outSQLFile, logFile, `e`))
        # Try to delete the .sql file that was created when
        # the OutputFile instance was made in the JSONToRelation
        # instantiation statement above:
        try:
            outSQLFile.remove();
        except Exception as e:
            pass
        sys.exit(1)

    jsonConverter.convert()
