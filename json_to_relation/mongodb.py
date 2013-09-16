

from pymongo import MongoClient


class MongoDB(object):
    
    def __init__(self, host="localhost", port=27017):
        self.host = host
        self.port = port
        self.client = MongoClient(host, port)
        self.set_db("test")
        self.set_collection('test_collection')
         
    def set_db(self, dbName):
        self.dbName = dbName
        self.db = self.client[dbName]
        
    def get_db(self):
        return self.db
    
    def get_db_name(self):
        return self.dbName

    def set_collection(self, collName):
        self.coll = self.db[collName]
        
    def get_collection(self):
        return self.coll
    
    def get_collection_name(self):
        return self.coll.name
        
    def find(self, mongoQuery, colNameTuple=(), limit=0, db=None, collection=None):
        with newMongoDB(self, db) as db, newMongoColl(self, collection) as coll:
            # Turn the list of column names to return into
            # Mongo-speak:
            colsToReturn = {}
            for colName in colNameTuple:
                colsToReturn[colName] = 1
            if limit == 1:            
                return coll.find_one(mongoQuery, colsToReturn)
            else:
                return coll.find(mongoQuery, colsToReturn, limit=limit)
    
    def clear_collection(self, db=None, collection=None):
        with newMongoDB(self, db) as db, newMongoColl(self, collection) as coll:
            cursor = self.find({}, colNameTuple=("_id"))
            for res in cursor:
                print res
    
    def insert(self, doc_or_docs, pwd=None):
        if pwd != "unit_testing":
            raise NotImplementedError("This MongoDB interface is read-only.")
        self.coll.insert(doc_or_docs)
        
class newMongoDB:
    
    def __init__(self, mongoObj, newDbName):
        self.mongoObj = mongoObj
        self.newDbName = newDbName
        
    def __enter__(self):
        self.savedDBName = self.mongoObj.get_db_name()
        if self.newDbName is not None:
            self.mongoObj.set_db(self.newDbName)
        return self.mongoObj.get_db()
        
    def __exit__(self, errType, errValue, errTraceback):
        self.mongoObj.set_db(self.savedDBName)
        # Have any exception re-raised:
        return False
    
    
class newMongoColl:
    
    def __init__(self, mongoObj, newCollName):
        self.mongoObj = mongoObj
        self.newCollName = newCollName
    
    def __enter__(self):
        self.savedCollName = self.mongoObj.get_collection_name()
        if self.newCollName is not None:
            self.mongoObj.set_collection(self.newCollName)
        return self.mongoObj.get_collection()
        
    def __exit__(self, errType, errValue, errTraceback):
        self.mongoObj.set_collection(self.savedCollName)
        # Have any exception re-raised:
        return False
    
    
    
    