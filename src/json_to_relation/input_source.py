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

    def __init__(self, inputSource):
        self.inputSource = inputSource

    def __enter__(self):
        return self.inputSource.fileHandle
        
    def __exit__(self, excType, excValue, excTraceback):
        # Even if the conversion threw an error, 
        # try to close the input source:
        try:
            self.inputSource.close()
        except:
            # If the conversion itself when fine, then
            # raise this exception from the closing attempt.
            # But if the conversion failed, then have the 
            # system re-raise that earlier exception:
            if excValue is None:
                (errType, errValue, errTraceback) = sys.exc_info()  # @UnusedVariable
                raise IOError("Could not close the input to the conversion: %s" % errValue)
        # Return False to indicate that if the conversion
        # threw an error, the exception should now be re-raised.
        # If the conversion worked fine, then this return value
        # is ignored.
        return False
            
    

class InURI(InputSource):
    def __init__(self, inFilePathOrURL):
        self.inFilePathOrURL = inFilePathOrURL
        self.fileHandle = urlopen(inFilePathOrURL)
    
    def close(self):
        # closing is different in case of file vs. URL:
        try:
            (scheme,netloc,path,query,fragment) = self.fileHandle.urlsplit()  # @UnusedVariable
        except AttributeError:
            self.fileHandle.close()
        else:
            urlcleanup(self.fileHandle)
      
    
class InString(InputSource):
    def __init__(self, inputStr):
        self.fileHandle = StringIO.StringIO(inputStr)
                
    def close(self):
        pass
    
class InMongoDB(InputSource):
    def __init__(self, server, pwd, dbName, collName):
        self.server = server
        self.pwd = pwd
        self.dbName = dbName
        self.collName = collName
        self.fileHandle = self.connect()

    def connect(self):
        raise NotImplementedError("MangoDB connector not yet implemented")
    
    def close(self):
        raise NotImplementedError("MangoDB connector not yet implemented")

class InPipe(object):
    def __init__(self):
        self.fileHandle = sys.stdin
        
    def close(self):
        pass # don't close stdin
        