#!/usr/bin/env python
# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


import sys
import os
import argparse
# from cgi import logfile
import datetime
import time

source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir

from json_to_relation import JSONToRelation
from output_disposition import OutputDisposition, OutputFile
from input_source import InURI
from edxTrackLogJSONParser import EdXTrackLogJSONParser

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

    # Log file will go to <destDir>/../TransformLogs, the file being named j2s_<inputFileName>.log:
    logDir = os.path.join(args.destDir, '..') + '/TransformLogs'
    if not os.access(logDir, os.W_OK):
        os.makedirs(logDir)

    logFile = os.path.join(logDir, 'j2s_%s_%s.log' % (os.path.basename(args.inFilePath), fileStamp))
    

#    print('xpunge: %s' % args.dropTables)
#    print('verbose: %s' % args.verbose)
#    print('destDir: %s' % args.destDir)
#    print('in=FilePath: %s' % args.inFilePath)
#    print('outFullPath: %s' % outFullPath)
#    print('logFile: %s' % logFile)

    # Create an instance of JSONToRelation, taking input from the given file:
    # and pumping output to the given output path:

    jsonConverter = JSONToRelation(InURI(args.inFilePath),
                                   OutputFile(outFullPath,
                                              OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS,
                                              options='wb'),  # overwrite any sql file that's there
    				                   mainTableName='EdxTrackEvent',
    				                   logFile=logFile
                                   )
    jsonConverter.setParser(EdXTrackLogJSONParser(jsonConverter, 
    						  'EdxTrackEvent', 
    						  replaceTables=args.dropTables, 
    						  dbName='Edx'
    						  ))
    jsonConverter.convert()

