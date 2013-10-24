'''
Created on Oct 23, 2013

@author: paepcke

Finds all files in subdir 'data' that end with 'Truth.sql'.
Attempts to load them into MySql to check for errors.
Used to ensure that unittest truth files are legal MySQL

'''
import os
import pymysql
import sys

from mysqldb import MySQLDB


class TruthFileTester(object):
    
    def __init__(self, testing=False):
        if testing:
            return
        self.mysqlDb = MySQLDB(user='paepcke')
        
        for filename in os.listdir('data'):
            if filename.endswith('Truth.sql'):
                print('Testing truth file %s' % filename)
                for sqlStatement in self.getSQLStatement(os.path.join(os.path.dirname('__file__'), 'data/'+filename)):
                    try:
                        for res in self.mysqlDb.query(sqlStatement):
                            print res
                    except (pymysql.err.InternalError, pymysql.err.IntegrityError) as e:
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
            