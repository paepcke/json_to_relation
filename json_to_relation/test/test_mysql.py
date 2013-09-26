'''
Created on Sep 24, 2013

@author: paepcke
'''
# TODO: 
#    o Test inserting values for several columns
#    o Test calling query() multiple times with several queries and get results alternately from the iterators 

from collections import OrderedDict
import unittest

from mysqldb import MySQLDB


class TestMySQL(unittest.TestCase):
    '''
    To make these unittests work, prepare the local MySQL db as follows:
        o CREATE USER unittest;
        o CREATE DATABASE unittest;
		o GRANT SELECT ON unittest.* TO 'unittest'@'localhost';
		o GRANT INSERT ON unittest.* TO 'unittest'@'localhost';
	    o GRANT DROP ON unittest.* TO 'unittest'@'localhost';

    '''
    


    def setUp(self):
        #self.mysqldb = MySQLDB(host='127.0.0.1', port=3306, user='unittest', passwd='', db='unittest')
        try:
            self.mysqldb = MySQLDB(host='localhost', port=3306, user='unittest', db='unittest')
        except ValueError as e:
            self.fail(str(e) + " (For unit testing, localhost MySQL server must have user 'unittest' without password, and a database called 'unittest')")


    def tearDown(self):
        self.mysqldb.dropTable('testTable')
        self.mysqldb.close()


    def testInsert(self):
        schema = OrderedDict({'col1' : 'INT', 'col2' : 'TEXT'})
        self.mysqldb.createTable('testTable', schema)
        colnameValueDict = {'col1' : 10}
        self.mysqldb.insert('testTable', colnameValueDict)
        self.assertEqual((None, 10), self.mysqldb.query("SELECT * FROM testTable").next())
        #for value in self.mysqldb.query("SELECT * FROM testTable"):
        #    print value
        


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testQuery']
    unittest.main()