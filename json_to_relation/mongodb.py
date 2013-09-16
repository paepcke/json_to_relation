

import pymongo
from pymongo import MongoClient


class MongoDB(object):
    
    def __init__(self, host="localhost", port=27017):
        self.host = host
        self.port = port
        self.set_db("test")
        self.set_collection('test_collection')
        self.client = MongoClient(host, port)
         
    def set_db(self, dbName):
        self.db = self.client[dbName]

    def set_collection(self, collName):
        self.coll = self.db[collName]
        
    def find(self, mongoQuery, limit=0, db=None, collection=None):
        if db is None:
            db = self.db
        if collection is None:
            collection = self.coll

        if limit == 1:            
            return self.client.find_one(mongoQuery)
        return self.client.find(mongoQuery, limit=limit)
    
    def insert(self, doc_or_docs, pwd=None):
        if pwd != "unit_testing":
            raise NotImplementedError("This MongoDB interface is read-only.")
        self.coll.insert(doc_or_docs)