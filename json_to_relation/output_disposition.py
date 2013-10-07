'''
Created on Sep 14, 2013

@author: paepcke
'''
import csv
import sys
import tempfile


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
        self.tmpTableFiles = {}
        self.schemas = TableSchema.createInstance()
    
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

    def addSchemaHints(self, tableName, schemaHints):
        '''
        Provide a schema hint dict for the table of the given name.
        @param tableName: name of table to which schema applies. The name may be None, in which case it refers to the main (default) table.
        @type tableName: String
        @param schemaHints: dict mapping column names to SQL types via ColumnSpec instances
        @type schemaHints: [ordered]Dict<String,ColumnSpec>
        '''
        self.schemas[tableName].extendColSpecs(schemaHints)

    def ensureColExistence(self, colName, colDataType, tableName=None):
        '''
        Given a column name and MySQL datatype name, check whether this
        column has previously been encountered. If not, a column information
        object is created, which will eventually be used to create the column
        header, or SQL alter statements.
        @param colName: name of the column to consider
        @type colName: String
        @param colDataType: datatype of the column.
        @type colDataType: ColDataType
        @param tableName: name of table to which the column is to belong; None if for main table
        @type tableName: {String | None}
        '''
        
        
        if tableName is None:
            try:
                self.cols[colName]
            except KeyError:
                # New column must be added to table:
                self.cols[colName] = ColumnSpec(colName, colDataType, self)
        else:
            self.outputFormat.ensureColExistence(self, colName, colDataType, tableName=None)


    def createTmpTableFile(self, tableName, fileSuffix):
        '''
        Used for cases in which parsers must create more than one
        table. Those tables need to be written to disk, even when
        output of the main table is piped.
        @param tableName: name by which the table file obj can be retrieved 
        @type tableName: String
        @param fileSuffix: suffix for temp file name. Ex. 'csv' for CSV outputs, or 'sql' for SQL dumps
        @type fileSuffix: String
        '''
        self.tmpTableFiles[tableName] = tempfile.NamedTemporaryFile(prefix='tmpTable', 
                                                                    suffix=fileSuffix)
        return self.tmpTableFiles[tableName]
        
        
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
        self.tableCSVWriters = {}
        
    def close(self):
        pass # don't close stdout
    
    def __str__(self):
        return "<OutputPipe:<stdout>"

    def writerow(self, colElementArray, tableName=None):
        if tableName is None:
            self.csvWriter.writerow(colElementArray)
        else:
            self.tableCSVWriters[tableName].writerow(colElementArray)

    def startNewTable(self, tableName, schemaHintsNewTable):
        '''
        Called when parser needs to create a table beyond
        the main table. 
        @param schemaHintsNewTable:
        @type schemaHintsNewTable:
        '''
        self.schemaHints[tableName] = schemaHintsNewTable
        tmpTableFile = self.createTmpTableFile(tableName, 'csv')
        self.tableCSVWriters[tableName] = csv.writer(tmpTableFile, 
                                                     dialect='excel', 
                                                     delimiter=',', 
                                                     quotechar='"', 
                                                     quoting=csv.QUOTE_MINIMAL)

class OutputFile(OutputDisposition):
    def __init__(self, fileName, options='ab'):
        # Make file name accessible as property just like 
        # Python file objects do:
        self.name = fileName  # @UnusedVariable
        # Open the output file as 'append' and 'binary'
        # The latter is needed for Windows.
        self.fileHandle = open(fileName, options)
        self.csvWriter = csv.writer(self.fileHandle, dialect='excel', delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        self.tableCSVWriters = {}
        
    def close(self):
        self.fileHandle.close()

    def __str__(self):
        return "<OutputFile:%s>" % self.name

    def writerow(self, colElementArray, tableName=None):
        if tableName is None:
            self.csvWriter.writerow(colElementArray)
        else:
            self.tableCSVWriters[tableName].writerow(colElementArray)

    def startNewTable(self, tableName, schemaHintsNewTable):
        '''
        Called when parser needs to create a table beyond
        the main table. 
        @param schemaHintsNewTable:
        @type schemaHintsNewTable:
        '''
        self.schemaHints[tableName] = schemaHintsNewTable
        tmpTableFile = self.createTmpTableFile(tableName, 'csv')
        self.tableCSVWriters[tableName] = csv.writer(tmpTableFile, 
                                                     dialect='excel', 
                                                     delimiter=',', 
                                                     quotechar='"', 
                                                     quoting=csv.QUOTE_MINIMAL)


class OutputMySQLDump(OutputDisposition):
    def __init__(self, dbName, tbleName):
        raise NotImplementedError("MySQL dump not yet implemented")
        self.tableFiles = {}
        
    def close(self):
        raise NotImplementedError("MySQL connector not yet implemented")

    def __str__(self):
        return "<OutputMySQLTable--%s>" % self.name

    def writerow(self, fd, colElementArray, tableName=None):
        raise NotImplementedError("MySQL connector not yet implemented")

    def startNewTable(self, tableName, schemaHintsNewTable):
        '''
        Called when parser needs to create a table beyond
        the main table. 
        @param schemaHintsNewTable:
        @type schemaHintsNewTable:
        '''
        self.schemaHints[tableName] = schemaHintsNewTable
        tmpTableFile = self.createTmpTableFile(tableName, 'sql')
        self.tableFiles[tableName] = tmpTableFile

class TableSchema(object):
    '''
    Repository for the schemas of all tables. A schema is an 
    array ColumnSpec instances. Each such list is associated with
    one relational table. A class var dict holds the schemas for
    all tables. The class 
    '''

    singleObj = None    
    # Class var:
    allSchemas = {}
    
    def __init__(self):
        if TableSchema.singleObj is not None:
            raise ValueError("TableSchema is a singleton: use TableSchema.createInstance()")
        
    @classmethod
    def createInstance(cls):
        if TableSchema.singleObj is not None:
            return TableSchema.singleObj
        TableSchema.singleObj = TableSchema()
        return TableSchema.singleObj
    
    def __getitem__(self, tableName):
        return TableSchema.allSchemas[tableName]
    
    def __setitem__(self, tableName, colSpecsList):
        TableSchema.allSchemas[tableName] = colSpecsList

    def addColSpec(self, tableName, colSpec):
        try:
            TableSchema.allSchemas[tableName].append(colSpec)
        except KeyError:
            TableSchema.allSchemas[tableName] = [colSpec]
        
    def extendColSpecs(self, tableName, colSpecsList):
        if type(colSpecsList) != type([]):
            colSpecsList = [colSpecsList]
        try:
            TableSchema.allSchemas[tableName].extend(colSpecsList)
        except KeyError:
            TableSchema.allSchemas[tableName] = colSpecsList
