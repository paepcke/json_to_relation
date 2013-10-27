#!/usr/bin/env python

import sys
import os
import argparse
from cgi import logfile

#source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
#source_dir.extend(sys.path)
#sys.path = source_dir

#from json_to_relation import JSONToRelation
#from output_disposition import OutputPipe, OutputDisposition
#from input_source import InPipe
#from edxTrackLogJSONParser import EdXTrackLogJSONParser

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
    parser.add_argument('filePath',
                        nargs='+',
                        help='json file paths to be converted to sql.') 
    
    
    args = parser.parse_args();

    print('xpunge: %s' % args.dropTables)
    print('logFile: %s' % args.logFile)
    print('verbose: %s' % args.verbose)
    print('files: %s' % args.filePath)

    # Create an instance of JSONToRelation, taking input from stdin,
    # and pumping output to stdout. Format output as SQL dump statements.
#    jsonConverter = JSONToRelation(InPipe(),
#                                   OutputPipe(OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS),
#				   mainTableName='EdxTrackEvent',
#				   logFile='/tmp/j2s.log'
#                                   )
#    jsonConverter.setParser(EdXTrackLogJSONParser(jsonConverter, 'EdxTrackEvent', replaceTables=True, dbName='test'
#))
#    jsonConverter.convert()
