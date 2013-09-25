'''
Created on Sep 24, 2013

@author: paepcke
'''

import pymysql

class MySQLDB(object):
    '''
    Shallow interface to MySQL databases
    '''

    def __init__(self, host='127.0.0.1', port=3306, user='root', passwd='', db='mysql'):
        '''
        Constructor
        '''
        self.cursors = []
        self.connection = pymysql.connect(host, port, user, passwd, db)
        
    def close(self):
        for cursor in self.cursors:
            try:
                cursor.close()
            except:
                pass

    def __iter__(self, queryStr):
        cursor = self.connection.cursor()
        cursor.execute(queryStr)
        # Save the cursor so we can close it if need be:
        self.cursors.append(cursor)
        return QueryIterator(cursor) 

class QueryIterator(object):
    
    def __init__(self, cursor):
        self.cursor = cursor

    def next(self): #@ReservedAssignment
        try:
            return self.cursor.fetchone()
        except StopIteration:
            self.cursor.close()
            raise StopIteration()
        except:
            print ("Attempt to operate on closed cursor")
            raise StopIteration()
        
