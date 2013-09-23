'''
Created on Sep 14, 2013

@author: paepcke
'''
import csv
import sys


class OutputDisposition(object):
    '''
    Specifications for where completed relation rows
    should be deposited, and in which format. Source
    options are files, stdout, and a MySQL table.
    
    Also defined here are available output formats, of
    which there are two: CSV, and SQL insert statements. 
    '''
    def __init__(self, outputDest):
        '''
        @param outputDest: os file descriptor for output
        @type outputDest: File
        '''
        self.outputDest = outputDest
    
    def __enter__(self):
        return self.outputDest
        
    def __exit__(self,excType, excValue, excTraceback):
        try:
            self.outputDest.close()
        except:
            # If the conversion itself when fine, then
            # raise this exception from the closing attempt.
            # But if the conversion failed, then have the 
            # system re-raise that earlier exception:
            if excValue is None:
                raise IOError("Could not close the output of the conversion: %s" % sys.exc_info()[0])

        # Return False to indicate that if the conversion
        # threw an error, the exception should now be re-raised.
        # If the conversion worked fine, then this return value
        # is ignored.
        return False

    #--------------------- Available Output Formats
      
    class OutputFormat():
        CSV = 0
        SQL_INSERT_STATEMENTS = 1
            
#--------------------- Available Output Destination Options:  
        
class OutputPipe(OutputDisposition):
    def __init__(self):
        self.fileHandle = sys.stdout
        # Make file name accessible as property just like 
        # Python file objects do:
        self.name = "<stdout>"  # @UnusedVariable
        self.csvWriter = csv.writer(sys.stdout, dialect='excel', delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        
    def close(self):
        pass # don't close stdout
    
    def __str__(self):
        return "<OutputPipe:<stdout>"

    def writerow(self, colElementArray):
        self.csvWriter.writerow(colElementArray)

class OutputFile(OutputDisposition):
    def __init__(self, fileName, options='ab'):
        # Make file name accessible as property just like 
        # Python file objects do:
        self.name = fileName  # @UnusedVariable
        # Open the output file as 'append' and 'binary'
        # The latter is needed for Windows.
        self.fileHandle = open(fileName, options)
        self.csvWriter = csv.writer(self.fileHandle, dialect='excel', delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        
    def close(self):
        self.fileHandle.close()

    def __str__(self):
        return "<OutputFile:%s>" % self.name

    def writerow(self, colElementArray):
        self.csvWriter.writerow(colElementArray)

class OutputMySQLTable(OutputDisposition):
    def __init__(self, server, pwd, dbName, tbleName):
        raise NotImplementedError("MySQL connector not yet implemented")
        self.name = "<MySQL:%s:%s:%s>" % (server,dbName,tbleName)
        self.server = server
        self.pwd = pwd
        self.dbName = dbName
        self.tbleName = tbleName
        self.fileHandle = self.connect()
        
    def connect(self):
        raise NotImplementedError("MySQL connector not yet implemented")
    
    def close(self):
        raise NotImplementedError("MySQL connector not yet implemented")

    def __str__(self):
        return "<OutputMySQLTable--%s>" % self.name

    def writerow(self, fd, colElementArray):
        raise NotImplementedError("MySQL connector not yet implemented")
                    