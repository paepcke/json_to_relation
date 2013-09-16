from unittest import TestSuite
from test_json_to_relation import TestJSONToRelation
from test_mongodb import MongoTest

class AllTests(TestSuite):
    
    def __init__(self):
        self.addTest(TestJSONToRelation())
        self.addTest(MongoTest())
AllTests()     