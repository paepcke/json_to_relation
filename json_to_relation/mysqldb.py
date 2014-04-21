'''
Created on Sep 24, 2013

@author: paepcke


Modifications:
  - Dec 30, 2013: Added closing of connection to close() method

'''

import re
import subprocess
import tempfile

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
        '''
        
        :param host: MySQL host
        :type host: string
        :param port: MySQL host's port
        :type port: int
        :param user: user to log in as
        :type user: string
        :param passwd: password to use for given user
        :type passwd: string
        :param db: database to connect to within server
        :type db: string
        '''
        
        # If all arguments are set to None, we are unittesting:
        if all(arg is None for arg in (host,port,user,passwd,db)):
            return
        
        self.user = user
        self.pwd  = passwd
        self.db   = db
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
        try:
            self.connection.close()
        except:
            pass

    def createTable(self, tableName, schema):
        '''
        Create new table, given its name, and schema.
        The schema is a dict mappingt column names to 
        column types. Example: {'col1' : 'INT', 'col2' : 'TEXT'}

        :param tableName: name of new table
        :type tableName: String
        :param schema: dictionary mapping column names to column types
        :type schema: Dict<String,String>
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

        :param tableName: name of table
        :type tableName: String
        '''
        cursor = self.connection.cursor()
        try:
            cursor.execute('DROP TABLE IF EXISTS %s' % tableName)
            self.connection.commit()
        finally:
            cursor.close()

    def truncateTable(self, tableName):
        '''
        Delete all table rows. No errors

        :param tableName: name of table
        :type tableName: String
        '''
        cursor = self.connection.cursor()
        try:
            cursor.execute('TRUNCATE TABLE %s' % tableName)
            self.connection.commit()
        finally:
            cursor.close()

    def insert(self, tblName, colnameValueDict):
        '''
        Given a dictionary mapping column names to column values,
        insert the data into a specified table

        :param tblName: name of table to insert into
        :type tblName: String
        :param colnameValueDict: mapping of column name to column value
        :type colnameValueDict: Dict<String,Any>
        '''
        colNames, colValues = zip(*colnameValueDict.items())
        cursor = self.connection.cursor()
        try:
            cmd = 'INSERT INTO %s (%s) VALUES (%s)' % (str(tblName), ','.join(colNames), self.ensureSQLTyping(colValues))
            cursor.execute(cmd)
            self.connection.commit()
        finally:
            cursor.close()
    
    def bulkInsert(self, tblName, colNameTuple, valueTupleArray):
        '''
        Inserts large number of rows into given table. Strategy: write
        the values to a temp file, then generate a LOAD INFILE LOCAL
        MySQL command. Execute that command via subprocess.call(). 
        Using a cursor.execute() fails with error 'LOAD DATA LOCAL
        is not supported in this MySQL version...' even though MySQL
        is set up to allow the op (load-infile=1 for both mysql and
        mysqld in my.cnf).

        :param tblName: table into which to insert
        :type tblName: string
        :param colNameTuple: tuple containing column names in proper order, i.e. \
	   corresponding to valueTupleArray orders.
        :type colNameTuple: (str[,str[...]])
        :param valueTupleArray: array of n-tuples, which hold the values. Order of\
           values must corresond to order of column names in colNameTuple.
        :type valueTupleArray: [(<anyMySQLCompatibleTypes>[<anyMySQLCompatibleTypes,...]])
        '''
        tmpCSVFile = tempfile.NamedTemporaryFile(dir='/tmp',prefix='userCountryTmp',suffix='.csv')
        for valueTuple in valueTupleArray:
            tmpCSVFile.write(','.join(valueTuple) + '\n')
        try:
            # Remove quotes from the values inside the colNameTuple's:
            mySQLColNameList = re.sub("'","",str(colNameTuple))
            mySQLCmd = "USE %s; LOAD DATA LOCAL INFILE '%s' INTO TABLE %s FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\\n' %s" %\
                      (self.db, tmpCSVFile.name, tblName, mySQLColNameList)
            subprocess.call(['mysql', '-u', self.user, '-p%s'%self.pwd, '-e', mySQLCmd])
        finally:
            tmpCSVFile.close()
    
    def update(self, tblName, colName, newVal, fromCondition=None):
        '''
        Update one column with a new value.

        :param tblName: name of table in which update is to occur
        :type tblName: String
        :param colName: column whose value is to be changed
        :type colName: String
        :param newVal: value acceptable to MySQL for the given column 
        :type newVal: type acceptable to MySQL for the given column 
        :param fromCondition: optionally condition that selects which rows to update.\
                      if None, the named column in all rows are updated to\
                      the given value. Syntax must conform to what may be in\
                      a MySQL FROM clause (don't include the 'FROM' keyword)
        :type fromCondition: String
        '''
        cursor = self.connection.cursor()
        try:
            if fromCondition is None:
                cmd = "UPDATE %s SET %s = '%s';" % (tblName,colName,newVal)
            else:
                cmd = "UPDATE %s SET %s = '%s' WHERE %s;" % (tblName,colName,newVal,fromCondition)
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

        :param colVals: list of column values destined for a MySQL table
        :type colVals: <any>
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

        :param queryStr: query
        :type queryStr: String
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
