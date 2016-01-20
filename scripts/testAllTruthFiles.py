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

'''
Created on Oct 23, 2013

@author: paepcke

Finds all files in subdir 'data' that end with 'Truth.sql'.
Attempts to load them into MySql to check for errors.
Used to ensure that unittest truth files are legal MySQL
Assumed to be running in <json_to_relation-ProjectRoot>/scripts

'''
import os
import pymysql
import sys

from json_to_relation.mysqldb import MySQLDB


class TruthFileTester(object):
    
    def __init__(self, testing=False):
        if testing:
            return
        self.mysqlDb = MySQLDB(user='paepcke')
        
	scriptDir = os.path.dirname(os.path.abspath(__file__))
	print scriptDir #****
	truthFilesDir = os.path.join(scriptDir, '../json_to_relation/test/data')
	print truthFilesDir #****
        for filename in os.listdir(truthFilesDir):
            if filename.endswith('Truth.sql'):
                print('Testing truth file %s' % filename)
                for sqlStatement in self.getSQLStatement(os.path.join(truthFilesDir, filename)):
                    try:
                        for res in self.mysqlDb.query(sqlStatement):
                            print res
                    except (pymysql.err.InternalError, pymysql.err.IntegrityError, pymysql.err.Error) as e:
                        print >>sys.stderr, 'Failed in filename %s: %s' % (filename, `e`)
        print 'Done.'

    def getSQLStatement(self, fileName):
        fullLine = ''
        for line in open(fileName, 'r'):
            line = line.strip()
            fullLine += line
            if fullLine.endswith(';'):
                yield fullLine
                fullLine = ''
             
if __name__ == '__main__':
    
    TruthFileTester(False) # turn off test mode
#     tester = TruthFileTester(True) # turn on test mode
#     for line in tester.getSQLStatement('data/problemCheckInPathTruth.sql'):
#         if line is None:
#             print('done')
#             sys.exit()
#         else:
#             print(line)
            
