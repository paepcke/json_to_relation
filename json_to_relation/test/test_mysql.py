'''
Created on Sep 24, 2013

@author: paepcke
'''
# TODO: Test calling query() multiple times with several queries and get results alternately from the iterators
# TODO: In: cmd = 'INSERT INTO %s (%s) VALUES (%s)' % (str(tblName), ','.join(colNames), ','.join(map(str, colValues)))
#                 the map removes quotes from strins: ','join(map(str,('My poem', 10)) --> (My Poem, 10) 

from collections import OrderedDict
import unittest

from mysqldb import MySQLDB


#from mysqldb import MySQLDB
class TestMySQL(unittest.TestCase):
    '''
    To make these unittests work, prepare the local MySQL db as follows:
        o CREATE USER unittest;
        o CREATE DATABASE unittest;
		o GRANT SELECT ON unittest.* TO 'unittest'@'localhost';
		o GRANT INSERT ON unittest.* TO 'unittest'@'localhost';
	    o GRANT DROP ON unittest.* TO 'unittest'@'localhost';
	    o GRANT CREATE ON unittest.* TO 'unittest'@'localhost';

    '''
    


    def setUp(self):
        #self.mysqldb = MySQLDB(host='127.0.0.1', port=3306, user='unittest', passwd='', db='unittest')
        try:
            self.mysqldb = MySQLDB(host='localhost', port=3306, user='unittest', db='unittest')
        except ValueError as e:
            self.fail(str(e) + " (For unit testing, localhost MySQL server must have user 'unittest' without password, and a database called 'unittest')")


    def tearDown(self):
        self.mysqldb.dropTable('unittest')
        self.mysqldb.close()


    def testInsert(self):
        schema = OrderedDict({'col1' : 'INT', 'col2' : 'TEXT'})
        self.mysqldb.createTable('unittest', schema)
        colnameValueDict = {'col1' : 10}
        self.mysqldb.insert('unittest', colnameValueDict)
        self.assertEqual((None, 10), self.mysqldb.query("SELECT * FROM unittest").next())
        #for value in self.mysqldb.query("SELECT * FROM unittest"):
        #    print value

    def testInsertSeveralColums(self):
        schema = OrderedDict({'col1' : 'INT', 'col2' : 'TEXT'})
        self.mysqldb.createTable('unittest', schema)
        colnameValueDict = {'col1' : 10, 'col2' : 'My poem'}
        self.mysqldb.insert('unittest', colnameValueDict)
        self.assertEqual(('My poem', 10), self.mysqldb.query("SELECT * FROM unittest").next())
        


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testQuery']
    unittest.main()