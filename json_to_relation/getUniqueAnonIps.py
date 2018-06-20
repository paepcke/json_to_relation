#!/usr/bin/env python
'''
Created on Jun 10, 2018

@author: paepcke
'''

import os

from pymysql_utils.pymysql_utils import MySQLDB


class RowGetter(object):
    '''
    classdocs
    '''
    seenAnons = {}

    def __init__(self, db, table):
        '''
        Constructor
        '''
        home = os.environ['HOME']
        with open(os.path.join(home, '.ssh/mysql')) as pwdFd:
            pwd = pwdFd.read().strip()
                        
        db = MySQLDB(db=db, user='paepcke', passwd=pwd)
        rowCount = 0
        with open('/tmp/anonIp.csv', 'w') as fd:
            fd.write('anon_screen_name,ip\n')
            for (anon_screen_name, ip)  in db.query('SELECT anon_screen_name, event_ip from EventIp'):
                rowCount += 1
                if (rowCount % 50000) == 0:
                    print("Did % rows." % rowCount) 
                if RowGetter.seenAnons.get(anon_screen_name, None) is None:
                    fd.write(anon_screen_name + ',' + ip + '\n')
                    RowGetter.seenAnons[anon_screen_name] = 1
                
if __name__ == '__main__':
    RowGetter('EdxPrivate', 'EventIp')
    
    