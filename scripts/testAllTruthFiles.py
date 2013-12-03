#!/usr/bin/env python
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
            
