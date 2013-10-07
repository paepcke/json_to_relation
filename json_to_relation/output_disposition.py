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
        @param outputDest: instance of one of the subclasses
        @type outputDest: Subclass(OutputDisposition)
        
        '''
        self.outputDest = outputDest
        self.tmpTableFiles = {}
    
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
        TableSchemas.extendColSpecs(tableName, schemaHints)

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
        schemaDict = TableSchemas[tableName]
        if schemaDict is None or len(schemaDict) == 0:
            # schema for this table definitely does not have the column:
            TableSchemas[tableName] = {colName : colDataType}
            return
        # Have schema (dict) for this table. Does that dict contain
        # an entry for the col name?
        try:
            schemaDict[colName]
            # all set:
            return
        except KeyError:
            schemaDict[colName] = colDataType

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
        super(OutputPipe, self).__init__(self)
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
        super(OutputPipe, self).__init__(self)        
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
        super(OutputPipe, self).__init__(self)        
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

class ColumnSpec(object):
    '''
    Housekeeping class. Each instance represents the name,
    position, and datatype of one column. These instances are
    used to generate column name headers, Django models, and
    SQL insert statements.
    '''

    def __init__(self, colName, colDataType, jsonToRelationProcessor):
        '''
        Create a ColumnSpec instance.
        @param colName: name of column
        @type colName: String
        @param colDataType: data type of column (an enum)
        @type colDataType: ColumnSpec
        @param jsonToRelationProcessor: associated JSON to relation JSONToRelation instance
        @type jsonToRelationProcessor: JSONToRelation
        '''
        self.colName = colName
        self.colDataType = colDataType
        self.colPos = jsonToRelationProcessor.getNextNewColPos()
        jsonToRelationProcessor.bumpNextNewColPos()
        
    def getName(self):
        '''
        Return column name
        @return: name of column
        @rtype: String
        '''
        return self.colName
    
    def getType(self):
        '''
        Return SQL type
        @return: SQL type of colum in upper case
        @rtype: String
        '''
        return ColDataType().toString(self.colDataType).upper()
    
    def getSQLDefSnippet(self):
        '''
        Return string snippet to use in SQL CREATE TABLE or ALTER TABLE
        statement
        '''
        return "%s %s" % (self.getName(), self.getType())
    
    def __str__(self):
        return "<Col %s: %s (position %s)>" % (self.colName, 
                                               self.getType(),
                                               self.colPos)
    
    def __repr__(self):
        return self.__str__()
    
class TableSchemas(object):
    '''
    Repository for the schemas of all tables. A schema is an 
    array ColumnSpec instances. Each such list is associated with
    one relational table. A class var dict holds the schemas for
    all tables. The class 
    '''

    singleObj = None    
    # Class var:
    allSchemas = {}
    # Add empty schema for main (default) table:
    allSchemas[None] = {}
    
    def __init__(self):
        raise ValueError("TableSchemas cannot be instantiated; use class methods on class TableSchemas")
    
    @classmethod    
    def __getitem__(cls, tableName):
        return TableSchemas.allSchemas[tableName]
    
    @classmethod    
    def __setitem__(cls, tableName, colSpecsDict):
        TableSchemas.allSchemas[tableName] = colSpecsDict

    @classmethod
    def addColSpec(cls, tableName, colSpec):
        try:
            schema = TableSchemas.allSchemas[tableName]
        except KeyError:
            TableSchemas.allSchemas[tableName] = {colSpec.getName(), colSpec}
        schema[colSpec.getName()] = colSpec
        
    @classmethod
    def extendColSpecs(cls, tableName, colSpecsDict):
        if type(colSpecsDict) != type({}):
            raise ValueError("ColumSpec parameter must be a dictionary<ColName,ColumnSpec>")
        try:
            schema = TableSchemas.allSchemas[tableName]
        except KeyError:
            TableSchemas.allSchemas[tableName] = colSpecsDict
        # Change schema to include the new dict:
        schema.update(colSpecsDict)
