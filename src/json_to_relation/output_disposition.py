'''
Created on Sep 14, 2013

@author: paepcke
'''
import sys


class OutputDisposition(object):
    '''
    Specifications for where completed relation rows
    should be deposited, and in which format. Source
    options are files, stdout, and a MySQL table.
    
    Also defined here are available output formats, of
    which there are two: CSV, and SQL insert statements. 
    '''
    
    def __enter__(self, outputDest):
        
        self.fileHandle = None
        self.mySQLHandle = None
        
        # I am *so* sorry to use instanceof here.
        # These constructions would be much cleaner
        # with parameter type based polymorphism!
        
        if isinstance(outputDest, OutputDisposition.OutputPipe):
            self.fileHandle = sys.stdout
            
        elif isinstance(outputDest, OutputDisposition.OutputFile):
            self.fileHandle = outputDest.fileHandle
            
        elif isinstance(outputDest, OutputDisposition.OutputMySQLTable):
            #self.mySQLHandle = outputDest.connect()
            raise NotImplementedError("Output to MySQL Table not yet implemented")
        
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
        def close(self):
            pass # don't close stdout
    
    class OutputFile(object):
        def __init__(self, fileName, options='ab'):
            self.fileHandle = open(fileName, options)
            
        def close(self):
            self.fileHandle.close()
    
    class OutputMySQLTable(object):
        def __init__(self, server, pwd, dbName, tbleName):
            self.server = server
            self.pwd = pwd
            self.dbName = dbName
            self.tbleName = tbleName
            raise NotImplementedError("MySQL connector not yet implemented")
            
        def connect(self):
            raise NotImplementedError("MySQL connector not yet implemented")
        
        def close(self):
            raise NotImplementedError("MySQL connector not yet implemented")
                    