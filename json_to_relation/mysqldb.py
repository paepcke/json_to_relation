'''
Created on Sep 24, 2013

@author: paepcke
'''

import pymysql
#import MySQLdb


class MySQLDB(object):
    '''
    Shallow interface to MySQL databases. Some niceties nonetheless.
    The query() method is an iterator. So::
        for result in mySqlObj.query('SELECT * FROM foo'):
            print result
    '''

    def __init__(self, host='127.0.0.1', port=3306, user='root', passwd='', db='mysql'):
        
        # If all arguments are set to None, we are unittesting:
        if all(arg is None for arg in (host,port,user,passwd,db)):
            return
        
        self.cursors = []
        try:
            self.connection = pymysql.connect(host=host, port=port, user=user, passwd=passwd, db=db)
            #self.connection = MySQLdb.connect(host=host, port=port, user=user, passwd=passwd, db=db, local_infile=1)
        
        #except MySQLdb.OperationalError:
        except pymysql.OperationalError:
            pwd = '...............' if len(passwd) > 0 else '<no password>'
            raise ValueError('Cannot reach MySQL server with host:%s, port:%s, user:%s, pwd:%s, db:%s' %
                             (host, port, user, pwd, db))
        
    def close(self):
        '''
        Close all cursors that are currently still open.
        '''
        for cursor in self.cursors:
            try:
                cursor.close()
            except:
                pass

    def createTable(self, tableName, schema):
        '''
        Create new table, given its name, and schema.
        The schema is a dict mappingt column names to 
        column types. Example: {'col1' : 'INT', 'col2' : 'TEXT'}
        @param tableName: name of new table
        @type tableName: String
        @param schema: dictionary mapping column names to column types
        @type schema: Dict<String,String>
        '''
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
        '''
        Delete table safely. No errors
        @param tableName: name of table
        @type tableName: String
        '''
        cursor = self.connection.cursor()
        try:
            cursor.execute('DROP TABLE IF EXISTS %s' % tableName)
            self.connection.commit()
        finally:
            cursor.close()

    def insert(self, tblName, colnameValueDict):
        '''
        Given a dictionary mapping column names to column values,
        insert the data into a specified table
        @param tblName: name of table to insert into
        @type tblName: String
        @param colnameValueDict: mapping of column name to column value
        @type colnameValueDict: Dict<String,Any>
        '''
        colNames, colValues = zip(*colnameValueDict.items())
        cursor = self.connection.cursor()
        try:
            cmd = 'INSERT INTO %s (%s) VALUES (%s)' % (str(tblName), ','.join(colNames), self.ensureSQLTyping(colValues))
            cursor.execute(cmd)
            self.connection.commit()
        finally:
            cursor.close()
        
    def ensureSQLTyping(self, colVals):
        '''
        Given a list of items, return a string that preserves
        MySQL typing. Example: (10, 'My Poem') ---> '10, "My Poem"'
        Note that ','.join(map(str,myList)) won't work:
        (10, 'My Poem') ---> '10, My Poem'
        @param colVals: list of column values destined for a MySQL table
        @type colVals: <any>
        '''
        resList = []
        for el in colVals:
            if isinstance(el, basestring):
                resList.append('"%s"' % el)
            else:
                resList.append(el)
        return ','.join(map(str,resList))        
        
    def query(self, queryStr):
        '''
        Query iterator. Given a query, return one result for each
        subsequent call.
        @param queryStr: query
        @type queryStr: String
        '''
        cursor = self.connection.cursor()
        # For if caller never exhausts the results by repeated calls:
        self.cursors.append(cursor)
        cursor.execute(queryStr)
        while True:
            nextRes = cursor.fetchone()
            if nextRes is None:
                cursor.close()
                return
            yield nextRes
