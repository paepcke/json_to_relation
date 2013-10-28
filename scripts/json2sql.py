#!/usr/bin/env python

import sys
import os
import argparse
from cgi import logfile
import datetime
import time
import cProfile

source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir

from json_to_relation import JSONToRelation
from output_disposition import OutputDisposition, OutputFile
from input_source import InURI
from edxTrackLogJSONParser import EdXTrackLogJSONParser

if __name__ == "__main__":

    parser = argparse.ArgumentParser(prog='json_to_relation')
    parser.add_argument('-x', '--expungeTables',
                        help='DROP all tables in database before beginning transform',
                        dest='dropTables',
                        action='store_true',
                        default=False)
    parser.add_argument('-l', '--logFile', 
                        help='fully qualified log file name. Default: no logging.',
                        dest='logFile',
                        default='/tmp/j2s.sql');
    parser.add_argument('-v', '--verbose', 
                        help='print operational info to console.', 
                        dest='verbose',
                        action='store_true');
    parser.add_argument('destDir',
                        help='file path for the destination .sql file')                        
    parser.add_argument('inFilePath',
                        help='json file path to be converted to sql.') 
    
    
    args = parser.parse_args();

    # Output file is name of input file with the
    # .json extension replaced by .sql, and a unique
    # timestamp/pid added to avoid name collisions during
    # parallel processing:
    dt = datetime.datetime.fromtimestamp(time.time())
    fileStamp = dt.isoformat().replace(':','_') + '_' + str(os.getpid())

    outFullPath = os.path.join(args.destDir, os.path.basename(args.inFilePath)) + '.' + fileStamp + '.sql'

    # Log file is in /tmp, named j2s_<inputFileName>.log:
    logFile = '/tmp/j2s_%s_%s.log' % (os.path.basename(args.inFilePath), fileStamp)
    

#    print('xpunge: %s' % args.dropTables)
#    print('verbose: %s' % args.verbose)
#     print('destDir: %s' % args.destDir)
#     print('in=FilePath: %s' % args.inFilePath)
#     print('outFullPath: %s' % outFullPath)
#     print('logFile: %s' % logFile)

    # Create an instance of JSONToRelation, taking input from stdin,
    # and pumping output to stdout. Format output as SQL dump statements.
    jsonConverter = JSONToRelation(InURI(args.inFilePath),
                                   OutputFile(outFullPath,
                                              OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS,
                                              options='wb'),  # overwrite any sql file that's there
				                   mainTableName='EdxTrackEvent',
				                   logFile=logFile
                                   )
    jsonConverter.setParser(EdXTrackLogJSONParser(jsonConverter, 'EdxTrackEvent', replaceTables=args.dropTables, dbName='Edx'
))
    jsonConverter.convert()

