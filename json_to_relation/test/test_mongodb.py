'''
Created on Sep 15, 2013

@author: paepcke
'''
from json_to_relation.mongodb import MongoDB
import mongomock
import unittest

TEST_ALL = True

class MongoTest(unittest.TestCase):
    '''
    Test the mongodb.py module. Uses a library that fakes
    a MongoDB server. See https://pypi.python.org/pypi/mongomock/1.0.1
    '''

    def setUp(self):
        # Clear out the mock MongoDB:
        #self.collection = mongomock.Connection().db.unittest
        self.objs = [{"fname" : "Franco", "lname" : "Corelli"}, 
                     {"fname" : "Leonardo", "lname" : "DaVinci", "age" : 300},
                     {"fname" : "Franco", "lname" : "Gandolpho"}]
        
        self.mongodb = MongoDB(dbName='unittest', collection='unittest')
        self.mongodb.clearCollection(collection="unittest")
        self.mongodb.clearCollection(collection="new_coll")
        self.mongodb.setCollection("unittest")

    def tearDown(self):
        self.mongodb.dropCollection(collection='unittest')
        self.mongodb.dropCollection(collection='new_coll')

    @unittest.skipIf(not TEST_ALL, "Skipping")
    def test_update_and_find_one(self):
        self.mongodb.insert(self.objs[0])
        res = self.mongodb.query({"fname" : "Franco"}, limit=1, collection="unittest")
        self.assertEqual('Corelli', res['lname'], "Failed retrieval of single obj; expected '%s' but got '%s'" % ('Corelli', res['lname']))

    @unittest.skipIf(not TEST_ALL, "Skipping")
    def test_set_coll_use_different_coll(self):
        # Insert into unittest:
        self.mongodb.insert(self.objs[0])
        # Switch to new_coll:
        self.mongodb.setCollection('new_coll')
        self.mongodb.insert({"recommendation" : "Hawaii"})
        
        # We're in new_coll; the following should be empty result:
        res = self.mongodb.query({"fname" : "Franco"}, limit=1)
        self.assertIsNone(res, "Got non-null result that should be null: %s" % res)
        
        # But this search is within new_coll, and should succeed:
        res = self.mongodb.query({"recommendation" : {'$regex' : '.*'}}, limit=1)
        self.assertEqual('Hawaii', res['recommendation'], "Failed retrieval of single obj; expected '%s' but got '%s'" % ('Hawaii', res['recommendation']))
        
        # Try inline collection switch:
        res = self.mongodb.query({"fname" : "Franco"}, limit=1, collection="unittest")
        self.assertEqual('Corelli', res['lname'], "Failed retrieval of single obj; expected '%s' but got '%s'" % ('Corelli', res['lname']))

        # But the default collection should still be new_coll,
        # so a search with unspecified coll should be in new_coll:
        res = self.mongodb.query({"recommendation" : {'$regex' : '.*'}}, limit=1)
        self.assertEqual('Hawaii', res['recommendation'], "Failed retrieval of single obj; expected '%s' but got '%s'" % ('Hawaii', res['recommendation']))

    @unittest.skipIf(not TEST_ALL, "Skipping")
    def test_multi_result(self):
        # Insert two docs with fname == Franco:
        self.mongodb.insert(self.objs[0])
        self.mongodb.insert(self.objs[2])
        resCursor = self.mongodb.query({"fname" : "Franco"})
        if resCursor.count(with_limit_and_skip=True) != 2:
            self.fail("Added two Franco objects, but only %d are found." % resCursor.count(with_limit_and_skip=True))
            
    @unittest.skipIf(not TEST_ALL, "Skipping")
    def test_clear_collection(self):
        self.mongodb.insert({"foo" : 10})
        res = self.mongodb.query({"foo" : 10}, limit=1)
        self.assertIsNotNone(res, "Did not find document that was just inserted.")
        self.mongodb.clearCollection()
        res = self.mongodb.query({"foo" : 10}, limit=1)
        self.assertIsNone(res, "Found document after clearing collection: " + str(res))
        
    @unittest.skipIf(not TEST_ALL, "Skipping")
    def test_only_some_return_columns(self):
        # Also tests the suppression of _id col when desired:
        self.mongodb.insert(self.objs[0])
        self.mongodb.insert(self.objs[1])
        resCur = self.mongodb.query({}, ("lname"))
        names = []
        for lnameDict in resCur:
            names.append(lnameDict['lname'])
        self.assertItemsEqual(['Corelli','DaVinci'], names, "Did not receive expected lnames: %s" % str(names))

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()