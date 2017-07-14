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
Created on Sep 24, 2013

@author: paepcke


Modifications:
  - Dec 30, 2013: Added closing of connection to close() method

'''
#import pymysql
#import MySQLdb

import csv
import subprocess
import tempfile

import MySQLdb


class MySQLDB(object):
    '''
    Shallow interface to MySQL databases. Some niceties nonetheless.
    The query() method is an iterator. So::
        for result in mySqlObj.query('SELECT * FROM foo'):
            print result
    '''

    #*****
    # Set to True if this code is running on 
    # a machine other than datastage, for instance
    # inside of Eclipse. Normally this code is
    # run as part of a CRON job on datastage:
    RUN_REMOTELY = False

    def __init__(self, host='127.0.0.1', port=3306, user='root', passwd='', db='mysql'):
        '''

        @param host: MySQL host
        @type host: string
        @param port: MySQL host's port
        @type port: int
        @param user: user to log in as
        @type user: string
        @param passwd: password to use for given user
        @type passwd: string
        @param db: database to connect to within server
        @type db: string
        '''

        # If all arguments are set to None, we are unittesting:
        if all(arg is None for arg in (host,port,user,passwd,db)):
            return

        self.user = user
        self.pwd  = passwd
        self.db   = db
        self.name = db
        self.cursors = []
        try:
            #self.connection = pymysql.connect(host=host, port=port, user=user, passwd=passwd, db=db)
            #self.connection = pymysql.connect(host=host, port=port, user=user, passwd=passwd, db=db,charset='utf8')
            self.connection = MySQLdb.connect(host=host, port=port, user=user, passwd=passwd, db=db, local_infile=1)

        except MySQLdb.OperationalError:
        #except pymysql.OperationalError:
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

    def createTable(self, tableName, schema, temporary=False):
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

    def truncateTable(self, tableName):
        '''
        Delete all table rows. No errors
        @param tableName: name of table
        @type tableName: String
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

    def bulkInsert(self, tblName, colNameTuple, valueTupleArray):
        '''
        Inserts large number of rows into given table. Strategy: write
        the values to a temp file, then generate a LOAD INFILE LOCAL
        MySQL command. Execute that command via subprocess.call().
        Using a cursor.execute() fails with error 'LOAD DATA LOCAL
        is not supported in this MySQL version...' even though MySQL
        is set up to allow the op (load-infile=1 for both mysql and
        mysqld in my.cnf).
        @param tblName: table into which to insert
        @type tblName: string
        @param colNameTuple: tuple containing column names in proper order, i.e.
                corresponding to valueTupleArray orders.
        @type colNameTuple: (str[,str[...]])
        @param valueTupleArray: array of n-tuples, which hold the values. Order of
                values must correspond to order of column names in colNameTuple.
        @type valueTupleArray: [(<anyMySQLCompatibleTypes>[<anyMySQLCompatibleTypes,...]])
        '''
        tmpCSVFile = tempfile.NamedTemporaryFile(dir='/tmp',prefix='userCountryTmp',suffix='.csv')
        self.csvWriter = csv.writer(tmpCSVFile, dialect='excel-tab', lineterminator='\n', delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        # Can't use csvWriter.writerows() b/c some rows have
        # weird chars: self.csvWriter.writerows(valueTupleArray)
        for row in valueTupleArray:
            # Convert each element in row to a string,
            # including mixed-in Unicode Strings:
            self.csvWriter.writerow([rowElement for rowElement in self.stringifyList(row)])
        tmpCSVFile.flush()

        if MySQLDB.RUN_REMOTELY:
            # For running surveyextractor.py (e.g. in Eclipse) on non-datastage machine,
            # need to copy the temp file over to datastage:
            subprocess.call(["scp", tmpCSVFile.name, '%s@datastage:/tmp' % self.user])
            subprocess.call(["ssh", "%s@datastage" % self.user, "chmod a+r %s" % tmpCSVFile.name]) 

        try:
            mySQLCmd = '''
              USE %s;
              LOAD DATA LOCAL INFILE '%s'
                INTO TABLE %s
                FIELDS TERMINATED BY ','
                LINES TERMINATED BY '\n';
              commit; 
            ''' % (self.db, tmpCSVFile.name, tblName)
            subprocess.call(['ssh', '%s@datastage' % self.user, 'mysql --login-path=%s -e "%s"' % (self.user, mySQLCmd)])
        finally:
            tmpCSVFile.close()

    def update(self, tblName, colName, newVal, fromCondition=None):
        '''
        Update one column with a new value.
        @param tblName: name of table in which update is to occur
        @type tblName: String
        @param colName: column whose value is to be changed
        @type colName: String
        @param newVal: value acceptable to MySQL for the given column
        @type newVal: type acceptable to MySQL for the given column
        @param fromCondition: optionally condition that selects which rows to update.
                      if None, the named column in all rows are updated to
                      the given value. Syntax must conform to what may be in
                      a MySQL FROM clause (don't include the 'FROM' keyword)
        @type fromCondition: String
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

    def execute(self,query):
        '''
        Execute an arbitrary query, including
        MySQL directives.
        @param query: query or directive
        @type query: String
        '''

        cursor=self.connection.cursor()
        try:
            cursor.execute(query)
            self.connection.commit()
        finally:
            cursor.close()

    def executeParameterized(self,query,params):
        '''
        Executes arbitrary query that is parameterized
        as in the Python string format statement. Ex:
        executeParameterized('SELECT %s FROM myTable', ('col1', 'col3'))
        @param query: query with parameter placeholder
        @type query: string
        @param params: actuals for the parameters
        @type params: (<any>)
        '''
        cursor=self.connection.cursor()


        try:
            cursor.execute(query,params)
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
                resList.append('"%s"' % el.encode('UTF-8', 'ignore'))
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
        queryStr = queryStr.encode('UTF-8')
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

    def stringifyList(self, iterable):
        '''
        Goes through the iterable. For each element, tries
        to turn into a string, part of which attempts encoding
        with the 'ascii' codec. Then encountering a unicode
        char, that char is UTF-8 encoded.

        Acts as an iterator! Use like:
        for element in stringifyList(someList):
            print(element)
        @param iterable: mixture of items of any type, including Unicode strings.
        @type iterable: [<any>]
        '''
        for element in iterable:
            try:
                yield(str(element))
            except UnicodeEncodeError:
                yield element.encode('UTF-8','ignore')
