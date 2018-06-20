#!/usr/bin/env python
'''
Created on Jun 10, 2018

@author: paepcke
'''

import os
import sys

from pymysql_utils.pymysql_utils import MySQLDB


class UniqueAnonIpExtractor(object):
    '''
    classdocs
    '''
    seenAnons = {}
    BATCH_SIZE = 50000
    # *******BATCH_SIZE = 2

    def __init__(self, db, table, totalRows=None):
        '''
        Constructor
        '''
        home = os.environ['HOME']
        with open(os.path.join(home, '.ssh/mysql')) as pwdFd:
            pwd = pwdFd.read().strip()
                        
        db = MySQLDB(db=db, user='paepcke', passwd=pwd)
        # Number of rows pulled from EventIp:
        rowCount = 0
        
        # First row to get in the select statement:
        nextBatchStartRow = -UniqueAnonIpExtractor.BATCH_SIZE
        
        with open('/tmp/anonIps.csv', 'w') as fd:
        #*****with sys.stdout as fd:
            fd.write('anon_screen_name,ip\n')
            numRecords = db.query('SELECT count(*) from EventIp').next()
            if numRecords == 0:
                sys.exit()
            if totalRows is None:
                totalRows = numRecords
            while rowCount < numRecords and rowCount < totalRows:
                nextBatchStartRow += UniqueAnonIpExtractor.BATCH_SIZE
                for (anon_screen_name, ip)  in db.query('SELECT anon_screen_name, event_ip from EventIp LIMIT %s,%s' % \
                                                        (nextBatchStartRow, UniqueAnonIpExtractor.BATCH_SIZE)):
                    if UniqueAnonIpExtractor.seenAnons.get(anon_screen_name, None) is None:
                        fd.write(anon_screen_name + ',' + ip + '\n')
                        UniqueAnonIpExtractor.seenAnons[anon_screen_name] = 1
                    rowCount += 1
                    if (rowCount % UniqueAnonIpExtractor.BATCH_SIZE) == 0:
                        print("Did %s rows." % rowCount)
                    if rowCount >= totalRows:
                        break 
            print('Finished %s rows; %s unique anon_screen_names' % (rowCount, len(UniqueAnonIpExtractor.seenAnons.keys())))  
if __name__ == '__main__':
    USAGE = 'Usage: getUniqueAnonIps [totalRows]'
    if len(sys.argv) > 1 and (sys.argv[1] == '-h' or sys.argv[1] == '--help'):
        print(USAGE)
        sys.exit()
    if len(sys.argv) > 1:
        try:
            totalRows = int(sys.argv[1])
        except Exception:
            print(USAGE)
            sys.exit()
    else:
        totalRows = None
    UniqueAnonIpExtractor('EdxPrivate', 'EventIp', totalRows=totalRows)
    
    