'''
Created on Sep 14, 2013

@author: paepcke
'''
import StringIO
import bz2
import gzip
import os
import sys
from urllib import FancyURLopener
import urllib2
from urlparse import urlparse


class COMPRESSION_TYPE:
    NO_COMPRESSION = 0;
    GZIP = 1;
    BZIP2 = 2

class InputSource(object):
    '''
    Possible sources for JSON objects. These are
    files on the local file system, URLs linking to
    JSON strings, and MongoDB collections.
    '''

    def __init__(self, inputSource):
        self.inputSource = inputSource

    def __enter__(self):
        return self.fileHandle
        
    def __exit__(self, excType, excValue, excTraceback):
        # Even if the conversion threw an error, 
        # try to close the input source:
        try:
            self.close()
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
        if len(urlparse(inFilePathOrURL)[0]) == 0:
            inFilePathOrURL = 'file://' + inFilePathOrURL 
        self.inFilePathOrURL = inFilePathOrURL
        self.compression = self.determineCompression(self.inFilePathOrURL)

        # If file is compressed and remote, pull it into a temp file
        # so we can decompress locally. Sets self.localPathFile
        # so that urlopen() or gzip.open(), or bz2.BZ2File() will work.
        # Sets self.deleteTempFile if a tmp file was created:
        self.ensureFileLocal(inFilePathOrURL)
        
        if self.compression == COMPRESSION_TYPE.NO_COMPRESSION:
            self.fileHandle = urllib2.urlopen(self.localFilePath)
        elif self.compression == COMPRESSION_TYPE.GZIP:
            self.fileHandle = gzip.open(self.localFilePath, 'rb')
        elif self.compression == COMPRESSION_TYPE.BZIP2:
            self.fileHandle = bz2.BZ2File(self.localFilePath, 'rb')
    
    def getSourceName(self):
        '''
        Identify this source such that logging can identify sources
        of errors.

        :return: a string that can be prepended to a line number in error/warn msgs
        @rtype: String
        '''
        return self.inFilePathOrURL
    
    def decompress(self, line):
        if self.compression == COMPRESSION_TYPE.NO_COMPRESSION:
            return line
        # For gzip and bz2, the read() of the fileHandle took
        # care of decompression. This method is here for expansion
        # to other compression schemes:
        return line
        
    def close(self):
        # closing is different in case of file vs. URL:
        try:
            (scheme,netloc,path,query,fragment) = self.fileHandle.urlsplit()  # @UnusedVariable
        except AttributeError:
            self.fileHandle.close()
        if self.deleteTempFile:
            try:
                os.remove(self.localFilePath)
            except:
                pass
    
    def determineCompression(self, fileURI):
        '''
        Given a file path, determine by file extension whether
        the file is gzip or bzip2 compressed, or whether it is
        not compressed.

        :param fileURI: item that str() turns into a file path or URL
        :type fileURI: STRING
        '''
        if str(fileURI).endswith('bz2'):
            return COMPRESSION_TYPE.BZIP2
        elif str(fileURI).endswith('gz'):
            return COMPRESSION_TYPE.GZIP
        else:
            return COMPRESSION_TYPE.NO_COMPRESSION
    
    def ensureFileLocal(self, inFilePathOrURL):
        '''
        Takes a file path or URL. Sets self.localFilePath
        to the same path if file is local, or
        if the file is remote but uncompressed. 
        If a file is remote and compressed, retrieves
        the file into a local tmp file and returns that
        file name. In this case the flag self.deleteTempFile
        is set to True. 

        :param inFilePathOrURL: file path or URL to file
        :type inFilePathOrURL: String
        '''
        self.localFilePath = inFilePathOrURL
        self.deleteTempFile = False
        if self.compression == COMPRESSION_TYPE.NO_COMPRESSION:
            return
        # Got compressed file; is it local?
        parseResult = urlparse(inFilePathOrURL)
        if parseResult.scheme == 'file':
            self.localFilePath = parseResult.path
            return
        opener = FancyURLopener()
        # Throws IOError if URL does not exist:
        self.localFilePath = opener.retrieve(inFilePathOrURL)[0]
        self.deleteTempFile = True
    
class InString(InputSource):
    def __init__(self, inputStr):
        self.fileHandle = StringIO.StringIO(inputStr)

    def getSourceName(self):
        '''
        Identify this source such that logging can identify sources
        of errors.

        :return: a string that can be prepended to a line number in error/warn msgs
        @rtype: String
        '''
        return "In-string"
        
    def decompress(self, line):
        '''
        No decompression for strings

        :param line:
        :type line:
        '''
        return line
                
    def close(self):
        pass
    
class InMongoDB(InputSource):
    def __init__(self, server, pwd, dbName, collName):
        self.server = server
        self.pwd = pwd
        self.dbName = dbName
        self.collName = collName
        self.fileHandle = self.connect()

    def getSourceName(self):
        '''
        Identify this source such that logging can identify sources
        of errors.

        :return: a string that can be prepended to a line number in error/warn msgs
        @rtype: String
        '''
        return "%s:%s" % (self.dbName, self.collName)


    def connect(self):
        raise NotImplementedError("MangoDB connector not yet implemented")
    
    def decompress(self, line):
        raise NotImplementedError("MangoDB connector not yet implemented")
    
    def close(self):
        raise NotImplementedError("MangoDB connector not yet implemented")

class InPipe(InputSource):
    def __init__(self):
        self.fileHandle = sys.stdin

    def getSourceName(self):
        '''
        Identify this source such that logging can identify sources
        of errors.

        :return: a string that can be prepended to a line number in error/warn msgs
        @rtype: String
        '''
        return "Pipe"


    def decompress(self, line):
        '''
        No decompression for pipes. Pipe through gunzip or similar first.

        :param line:
        :type line:
        '''
        return line
        
    def close(self):
        pass # don't close stdin
        