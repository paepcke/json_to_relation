'''
Created on Sep 15, 2013

@author: paepcke
'''
import unittest
import mongomock

class MongoTest(unittest.TestCase):
    '''
    Test the mongodb.py module. Uses a library that fakes
    a MongoDB server. See https://pypi.python.org/pypi/mongomock/1.0.1
    '''

    def setUp(self):
        # Clear out the mock MongoDB:
        self.collection = mongomock.Connection().db.collection
        

    def testFind(self):
        pass


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()