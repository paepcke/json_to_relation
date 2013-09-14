'''
Created on Sep 14, 2013

@author: paepcke
'''
import sys


class OutputDisposition(object):
    
    def __enter__(self, outputDest):
        
        # I am *so* sorry to use instanceof here.
        # These constructions would be much cleaner
        # with parameter type based polymorphism!
        
        if isinstance(outputDest, OutputPipe):
            self.fileHandle = sys.stdout
            
        elif isinstance(outputDest, OutputFile):
            self.fileHandle = open(outputDest.fileName, outputDest.options)
            
        elif isinstance(outputDest, OutputMySQLTable):
            self.mySQLHandle = outputDest.connect
        
    def __exit__(self):
        if self.fileHandle is not None:
            self.fileHandle.close()
        if self.mysqlHandle is not None:
            # TODO: make this real
            self.mySQLHandle.close()

#--------------------- Available Output Formats
  
class OutputFormat():
    CSV = 0
    SQL_INSERT_STATEMENTS = 1
        
#--------------------- Available Output Destination Options:  
        
class OutputPipe(object):
    pass

class OutputFile(object):
    def __init__(self, fileName, options='ab'):
        self.fileName = fileName
        self.options = options

class OutputMySQLTable(object):
    def __init__(self, server, pwd, dbName, tbleName):
        self.server = server
        self.pwd = pwd
        self.dbName = dbName
        self.tbleName = tbleName
        
    def connect(self):
        raise NotImplementedError("MySQL connector not yet implemented")            