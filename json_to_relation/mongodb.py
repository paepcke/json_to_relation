

from pymongo import MongoClient


class MongoDB(object):
    '''
    Very simple Python interface to MongoDB. Based on pymongo,
    this class provides methods to get and set default databases
    and collections, to insert documents, query collections, and
    clear all documents in a collection. 
    
    The query() method encapsulates MangoDB native methods find() 
    and find_one(). The query() method makes it very convenient to
    to request only particular sets of fields (columns in relational 
    terms). Example::
        myMongoDb.query({'lname' : 'Doe'}, ('fname', 'lname', 'age'))
    '''
    
    # Map of query strings to MongoDB cursors. Administered
    # by query() method. Used in resultCount():
    queryCursors = {}
    
    # ----------------------------  Public Methods -------------------
    
    def __init__(self, host="localhost", ssl_keyfile=None, dbName="test", collection="test_collection", port=27017, user=None, pwd=""):
        '''
        Create a connection to the MongoDB demon on the given host/port.
        @param host: host name where MongoDB demon is running. Can be IP address as string.
        @type host: String
        @param port: MongoDB demon's port
        @type port: int
        '''
        self.host       = host
        self.port       = port
        self.dbName     = dbName
        self.collection = collection
        if user is not None:
            # Use Mongodb URI, mongodb://[username:password@]host1[:port1][,host2[:port2],...[,hostN[:portN]]][/[database][?options]] 
            # e.g.: mongodb://readonly:xxxxx@stanford-edx-prod.m0.mongolayer.com/stanford-edx-prod)
            if ssl_keyfile is None:
                self.client=MongoClient("mongodb://%s:%s@%s/%s" % (user,pwd,host,dbName), port)
            else:
                self.client=MongoClient("mongodb://%s:%s@%s/%s" % (user,pwd,host,dbName), port, ssl_keyfile=ssl_keyfile)
        else:
            if ssl_keyfile is None:
                self.client=MongoClient("mongodb://%s/%s" % (host,dbName), port)
            else:
                self.client=MongoClient("mongodb://%s/%s" % (host,dbName), port, ssl_keyfile=ssl_keyfile)
        self.setDB(dbName)
        self.setCollection(collection)
         
    def setDB(self, dbName):
        '''
        Establish a default database within MongoDB for subsequent calls 
        to other methods of this class.
        @param dbName: MongoDB database name
        @type dbName: String
        '''
        self.dbName = dbName
        self.db = self.client[dbName]
        
    def getDBName(self):
        '''
        Obtain the name of the MongoDB database that is
        currently the default for calls to methods of this class.
        @rtype: String
        '''
        return self.dbName

    def setCollection(self, collName):
        '''
        Establish a default MongoDB collection for subsequent calls to 
        other methods of this class.
        @param collName: MongoDB collection name
        @type collName: String
        '''
        self.coll = self.db[collName]
        
    def getCollectionName(self):
        '''
        Obtain the name of the MongoDB collection that is
        currently the default for calls to methods of this class.
        @rtype: String
        '''
        return self.coll.name
        
    def query(self, mongoQuery, colNameTuple=(), limit=0, db=None, collection=None):
        '''
        Method for querying the database. The mongoQuery parameter is a 
        dictionary conforming to the MongoDB query conventions. This query
        is passed through to the underlying MongoDB.
        
        The colNameTuple contains a list of field (a.k.a. relational column) names.
        Result documents will contain only those fields. In contrast to MangoDB
        convention, the _id field is not automatically returned in the result dictionaries.
        This field is only included if the caller lists it in colNameTuple. If colNameTuple
        is an empty tuple, the entirety of each document is returned for each query result.
        
        The limit parameter determines how many documents will be returned. A value of zero
        returns the entire result set. A value of 1 makes the method's behavior analogous to
        MangoDB's native find_one() method.
        
        The db and collection keyword arguments allow callers to address a MongoDB database
        and/or collection that are not the default. After the method returns, the default
        database and collection values will still be untouched. 
        
        @param mongoQuery: MangoDB query
        @type mongoQuery: Dict<String,<any>>
        @param colNameTuple: a possibly empty tuple of field/column names to retrieve for each result document
        @type colNameTuple: (String)
        @param limit: maximum number of documents to return
        @type limit: int
        @param db: name of MongoDB database other than the current default
        @type db: String
        @param collection: name of MongoDB collection other than the current default
        @type collection: String
        @rtype: {generator<ResultDict>} 
        '''
        with newMongoDB(self, db) as db, newMongoColl(self, collection) as coll:
            # Turn the list of column names to return into
            # Mongo-speak. First, take care of the Python weirdness
            # that turn single-element tuples into the element
            # themselve: ("foo", "bar") ---> ("foo", "bar"). BUT
            #            ("foo") ---> "foo". Whereas
            #            ("foo,") ---> ("foo",). Whereas
            if not isinstance(colNameTuple, tuple):
                colNameTuple = (str(colNameTuple),)
                  
            # Create dict {"colName1" : 1, "colName2" : 1,...} 
            colsToReturn = {}
            for colName in colNameTuple:
                colsToReturn[colName] = 1
            # MongoDB insists on returning the '_id' field, even
            # if you don't ask for it. Suppress that behavior
            # iff (i) caller did specify at least one col name (i.e.
            #     didn't just pass in an empty tuple to get all
            #     columns, but also (ii) did *not* ask for '_id'
            try:
                if len(colsToReturn) > 0 and colsToReturn['_id']:
                    pass
            except KeyError:
                # Caller did not explicitly ask for the _id field,
                # yet did ask for at least *one* col name. So 
                # suppress _id:
                colsToReturn['_id'] = 0
                
            if len(colsToReturn) > 0:
                cursor = coll.find(mongoQuery, colsToReturn, limit=limit)
            else:
                cursor = coll.find(mongoQuery, limit=limit)
            # Make the cursor findable, so that callers can ask for number of results
            MongoDB.queryCursors[str(mongoQuery)] = cursor
            while True:
                # Termination happens when cursor is exhausted:
                try:
                    yield cursor.next()
                except:
                    # Cursor is exhausted, remove it from our
                    # records:
                    del(MongoDB.queryCursors[str(mongoQuery)])
                    return
    
    def resultCount(self, queryDict):
        '''
        Return number of results in the given query. Only works
        when query has previously been issued via the query()
        method AND at least one result has been extracted. That's
        because the first call to query() only returns a generator.
        This isn't good. 
        @param queryDict: Same query that was provided to the query() method
        @type queryDict: Dict<String,<any>>
        @return: number of results, taking into account limit provided to query(). None if no result has been pulled from query()
        @rtype: {int | None}
        '''
        try:
            cursor = MongoDB.queryCursors[str(queryDict)]
            return cursor.count(with_limit_and_skip=True)
        except KeyError:
            #raise ValueError("Called resultCount() with a query string that was not used in a prior call to query(), or the query results have all been retrieved.")
            return None
    
    def clearCollection(self, db=None, collection=None):
        '''
        Remove all documents from a collection. The affected database/collection
        are the current defaults, if database/collection are None, else the specified
        database/collection is affected.
        @param db: Name of MongoDB database, or None
        @type db: String
        @param collection: Name of MongoDB collection, or None
        @type collection: String
        '''
        with newMongoDB(self, db) as db, newMongoColl(self, collection) as coll:
            coll.remove()
            
    def dropCollection(self, db=None, collection=None):
        '''
        Remove a collection from the database. The affected database/collection
        are the current defaults, if database/collection are None, else the specified
        database/collection is affected.
        @param db: Name of MongoDB database, or None
        @type db: String
        @param collection: Name of MongoDB collection, or None
        @type collection: String
        '''
        with newMongoDB(self, db) as db, newMongoColl(self, collection) as coll:
            coll.drop()
            

    def insert(self, doc_or_docs, db=None, collection=None):
        '''
        Insert the given dictionary into a MongoDB collection.
        @param doc_or_docs: Dictionary whose entries are the documents
        @type doc_or_docs: Dict<String,<any>>
        @param db: Name of MongoDB database, or None
        @type db: String
        @param collection: Name of MongoDB collection, or None
        @type collection: String
        '''
        with newMongoDB(self, db) as db, newMongoColl(self, collection) as coll:
            coll.insert(doc_or_docs)


    def close(self):
        '''
        Release all resources.
        '''
        for cursor in MongoDB.queryCursors.values():
            try:
                cursor.close()
            except:
                pass
        self.client.close()

    # ----------------------------  Private Methods -------------------
    
    def get_db(self):
        '''
        Obtain current default MongoDB database object
        '''
        return self.db
    
    def get_collection(self):
        '''
        Obtain current default MongoDB database object
        '''
        return self.coll
    
    # ----------------------------  Private Classes -------------------    
    
class newMongoDB:
    '''
    Class that enables the construct "with newMongoDB('myDB') as db:"
    See http://effbot.org/zone/python-with-statement.htm for explanation 
    '''
    
    def __init__(self, mongoObj, newDbName):
        self.mongoObj = mongoObj
        self.newDbName = newDbName
        
    def __enter__(self):
        self.savedDBName = self.mongoObj.getDBName()
        if self.newDbName is not None:
            self.mongoObj.setDB(self.newDbName)
        return self.mongoObj.get_db()
        
    def __exit__(self, errType, errValue, errTraceback):
        self.mongoObj.setDB(self.savedDBName)
        # Have any exception re-raised:
        return False
    
    
class newMongoColl:
    '''
    Class that enables the construct "with newMongoColl('myColl') as coll:"
    See http://effbot.org/zone/python-with-statement.htm for explanation 
    '''
    
    def __init__(self, mongoObj, newCollName):
        self.mongoObj = mongoObj
        self.newCollName = newCollName
    
    def __enter__(self):
        self.savedCollName = self.mongoObj.getCollectionName()
        if self.newCollName is not None:
            self.mongoObj.setCollection(self.newCollName)
        return self.mongoObj.get_collection()
        
    def __exit__(self, errType, errValue, errTraceback):
        self.mongoObj.setCollection(self.savedCollName)
        # Have any exception re-raised:
        return False
    
    
    
    