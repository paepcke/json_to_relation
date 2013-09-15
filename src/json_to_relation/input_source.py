'''
Created on Sep 14, 2013

@author: paepcke
'''
import StringIO
import sys
from urllib import urlopen, urlcleanup


class InputSource(object):
    '''
    Possible sources for JSON objects. These are
    files on the local file system, URLs linking to
    JSON strings, and MongoDB collections.
    '''

    def __enter__(self, inputSource):
        
        self.fileHandle = None
        self.mongoDBHandle = None
        self.inputDest = inputSource
        
        # I am *so* sorry to use instanceof here.
        # These constructions would be much cleaner
        # with parameter type based polymorphism!

        
        if isinstance(inputSource, InputSource.InPipe):
            self.fileHandle = sys.stdin

        elif isinstance(inputSource, InputSource.InString):
            self.fileHandle = StringIO(inputSource.inputStr)
            
        elif isinstance(inputSource, InputSource.InURI):
            self.fileHandle = inputSource.fileHandle
            
        elif isinstance(inputSource, InputSource.InMongoDB):
            #self.mySQLHandle = outputDest.connect()
            raise NotImplementedError("Input from MongoDB collection not yet implemented")
        
    def __exit__(self):
        if self.fileHandle is not None:
            self.fileHandle.close()
        if self.mongoDBHandle is not None:
            self.mongoDBHandle.close()
    
    
    class InURI(object):
        def __init__(self, inFilePathOrURL):
            self.inFilePathOrURL = inFilePathOrURL
            self.fileHandle = urlopen(inFilePathOrURL)
        
        def close(self):
            # closing is different in case of file vs. URL:
            (scheme,netloc,path,query,fragment) = self.inFilePathOrURL.urlsplit()  # @UnusedVariable
            if len(scheme) == 0:
                self.inFilePathOrURL.close()
            else:
                urlcleanup(self.inFilePathOrURL)
          
        
    class InString(object):
        def __init__(self, inputStr):
            self.inputStr = inputStr
            
        def close(self):
            pass
        
    class InMongoDB(object):
        def __init__(self, server, pwd, dbName, collName):
            self.server = server
            self.pwd = pwd
            self.dbName = dbName
            self.collName = collName
    
        def connect(self):
            raise NotImplementedError("MangoDB connector not yet implemented")
        
        def close(self):
            raise NotImplementedError("MangoDB connector not yet implemented")
    
    class InPipe(object):
        def __init__(self):
            raise NotImplementedError("Input pipe not implemented.")
            
        def close(self):
            pass # don't close stdin
        