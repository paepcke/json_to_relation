'''
Created on Sep 15, 2013

@author: paepcke
'''
from json_to_relation.mongodb import MongoDB
import mongomock
import unittest

TEST_ALL = False

class MongoTest(unittest.TestCase):
    '''
    Test the mongodb.py module. Uses a library that fakes
    a MongoDB server. See https://pypi.python.org/pypi/mongomock/1.0.1
    '''

    def setUp(self):
        # Clear out the mock MongoDB:
        self.collection = mongomock.Connection().db.testCollection
        self.objs = [{"fname" : "Franco", "lname" : "Corelli"}, 
                     {"fname" : "Leonardo", "lname" : "DaVinci", "age" : 300},
                     {"fname" : "Franco", "lname" : "Gandolpho"}]
        
        self.mongodb = MongoDB()

    @unittest.skipIf(not TEST_ALL, "Skipping")
    def test_update_and_find_one(self):
        self.mongodb.insert(self.objs[0], "unit_testing")
        res = self.mongodb.find({"fname" : "Franco"}, 1, collection="test_collection")
        self.assertEqual('Corelli', res['lname'], "Failed retrieval of single obj; expected '%s' but got '%s'" % ('Corelli', res['lname']))

    @unittest.skipIf(not TEST_ALL, "Skipping")
    def test_set_coll_use_different_coll(self):
        self.mongodb.set_collection('new_coll')
        self.mongodb.insert({"recommendation" : "Hawaii"}, "unit_testing")
        
        # We're in new_coll; the following should be empty result:
        res = self.mongodb.find({"fname" : "Franco"}, limit=1)
        self.assertIsNone(res, "Got non-null result that should be null: %s" % res)
        
        # But this search is within new_coll, and should succeed:
        res = self.mongodb.find({"recommendation" : {'$regex' : '.*'}}, limit=1)
        self.assertEqual('Hawaii', res['recommendation'], "Failed retrieval of single obj; expected '%s' but got '%s'" % ('Hawaii', res['recommendation']))
        
        # Try inline collection switch:
        res = self.mongodb.find({"fname" : "Franco"}, 1, collection="test_collection")
        self.assertEqual('Corelli', res['lname'], "Failed retrieval of single obj; expected '%s' but got '%s'" % ('Corelli', res['lname']))

        # But the default collection should still be new_coll,
        # so a search with unspecified coll should be in new_coll:
        res = self.mongodb.find({"recommendation" : {'$regex' : '.*'}}, limit=1)
        self.assertEqual('Hawaii', res['recommendation'], "Failed retrieval of single obj; expected '%s' but got '%s'" % ('Hawaii', res['recommendation']))

    @unittest.skipIf(not TEST_ALL, "Skipping")
    def test_multi_result(self):
        resCursor = self.mongodb.find({"fname" : "Franco"})
        for res in resCursor:
            print res
    
    def test_clear_collection(self):
        self.mongodb.clear_collection()
        
        
                                

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()