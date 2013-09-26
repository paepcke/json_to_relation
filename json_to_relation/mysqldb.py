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
        try:
            self.connection = pymysql.connect(host=host, port=port, user=user, passwd=passwd, db=db)
        except pymysql.OperationalError:
            pwd = '...............' if len(passwd) > 0 else '<no password>'
            raise ValueError('Cannot reach MySQL server with host:%s, port:%s, user:%s, pwd:%s, db:%s' %
                             (host, port, user, pwd, db))
        
    def close(self):
        for cursor in self.cursors:
            try:
                cursor.close()
            except:
                pass

    def createTable(self, tableName, schema):
        colSpec = ''
        for colName, colVal in schema.items():
            colSpec += str(colName) + ' ' + str(colVal) + ','
        cmd = 'CREATE TABLE IF NOT EXISTS %s (%s) ' % (tableName, colSpec[:-1])
        cursor = self.connection.cursor()
        try:
            cursor.execute(cmd)
            self.connection.commit()
        finally:
            cursor.close()

    def dropTable(self, tableName):
        cursor = self.connection.cursor()
        try:
            cursor.execute('DROP TABLE IF EXISTS %s' % tableName)
            self.connection.commit()
        finally:
            cursor.close()

    def insert(self, tblName, colnameValueDict):
        colNames, colValues = zip(*colnameValueDict.items())
        cursor = self.connection.cursor()
        try:
            cmd = 'INSERT INTO %s (%s) VALUES (%s)' % (str(tblName), ','.join(colNames), ','.join(map(str, colValues)))
            cursor.execute(cmd)
            self.connection.commit()
        finally:
            cursor.close()
        

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
        
