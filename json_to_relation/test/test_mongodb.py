'''
Created on Sep 15, 2013

@author: paepcke
'''
from json_to_relation.mongodb import MongoDB
import unittest

TEST_ALL = True

class MongoTest(unittest.TestCase):
    '''
    Test the mongodb.py module. Uses a library that fakes
    a MongoDB server. See https://pypi.python.org/pypi/mongomock/1.0.1
    '''

    def setUp(self):
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
        self.mongodb.close()

    @unittest.skipIf(not TEST_ALL, "Skipping")
    def test_update_and_find_one(self):
        self.mongodb.insert(self.objs[0])
        # Get a generator for the results:
        resGen = self.mongodb.query({"fname" : "Franco"}, limit=1, collection="unittest")
        res = resGen.next()
        self.assertEqual('Corelli', res['lname'], "Failed retrieval of single obj; expected '%s' but got '%s'" % ('Corelli', res['lname']))

    @unittest.skipIf(not TEST_ALL, "Skipping")
    def test_set_coll_use_different_coll(self):
        # Insert into unittest:
        self.mongodb.insert(self.objs[0])
        # Switch to new_coll:
        self.mongodb.setCollection('new_coll')
        self.mongodb.insert({"recommendation" : "Hawaii"})
        
        # We're in new_coll; the following should be empty result:
        self.mongodb.query({"fname" : "Franco"}, limit=1)
        resCount = self.mongodb.resultCount({"fname" : "Franco"})
        self.assertIsNone(resCount, "Got non-null result that should be null: %s" % resCount)
        
        # But this search is within new_coll, and should succeed:
        resGen = self.mongodb.query({"recommendation" : {'$regex' : '.*'}}, limit=1)
        res = resGen.next()
        self.assertEqual('Hawaii', res['recommendation'], "Failed retrieval of single obj; expected '%s' but got '%s'" % ('Hawaii', res['recommendation']))
        
        # Try inline collection switch:
        resGen = self.mongodb.query({"fname" : "Franco"}, limit=1, collection="unittest")
        res = resGen.next()
        self.assertEqual('Corelli', res['lname'], "Failed retrieval of single obj; expected '%s' but got '%s'" % ('Corelli', res['lname']))

        # But the default collection should still be new_coll,
        # so a search with unspecified coll should be in new_coll:
        resGen = self.mongodb.query({"recommendation" : {'$regex' : '.*'}}, limit=1)
        res = resGen.next()
        self.assertEqual('Hawaii', res['recommendation'], "Failed retrieval of single obj; expected '%s' but got '%s'" % ('Hawaii', res['recommendation']))

    @unittest.skipIf(not TEST_ALL, "Skipping")
    def test_multi_result(self):
        # Insert two docs with fname == Franco:
        self.mongodb.insert(self.objs[0])
        self.mongodb.insert(self.objs[2])
        resGen = self.mongodb.query({"fname" : "Franco"})
        # To get result count, must retrieve at least one result first:
        resGen.next()
        resCount = self.mongodb.resultCount({"fname" : "Franco"})
        if resCount != 2:
            self.fail("Added two Franco objects, but only %s are found." % str(resCount))
            
    @unittest.skipIf(not TEST_ALL, "Skipping")
    def test_clear_collection(self):
        self.mongodb.insert({"foo" : 10})
        resGen = self.mongodb.query({"foo" : 10}, limit=1)
        res = resGen.next()
        self.assertIsNotNone(res, "Did not find document that was just inserted.")
        self.mongodb.clearCollection()
        resGen = self.mongodb.query({"foo" : 10}, limit=1)
        self.assertRaises(StopIteration, resGen.next)
        
    @unittest.skipIf(not TEST_ALL, "Skipping")
    def test_only_some_return_columns(self):
        # Also tests the suppression of _id col when desired:
        self.mongodb.insert(self.objs[0])
        self.mongodb.insert(self.objs[1])
        resGen = self.mongodb.query({}, ("lname"))
        names = []
        for lnameDict in resGen:
            resCount = self.mongodb.resultCount({})
            self.assertEqual(2, resCount)
            names.append(lnameDict['lname'])
        self.assertItemsEqual(['Corelli','DaVinci'], names, "Did not receive expected lnames: %s" % str(names))


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()