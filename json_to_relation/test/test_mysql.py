'''
Created on Sep 24, 2013

@author: paepcke
'''
import unittest
import pymysql
 


class TestMySQL(unittest.TestCase):


    def setUp(self):
        try:
            self.connection = pymysql.connect(host='127.0.0.1', port=3306, user='unittest', passwd='', db='unittest')
        except pymysql.OperationalError:
            self.fail("To unittest module test_mysql you need to run a mysql demon; none is running.")


    def tearDown(self):
        pass


    def testQuery(self):
        pass


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testQuery']
    unittest.main()