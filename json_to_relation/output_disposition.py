'''
Created on Sep 14, 2013

@author: paepcke
'''
from collections import OrderedDict
import csv
import sys
import tempfile

from col_data_type import ColDataType


class OutputDisposition(object):
    '''
    Specifications for where completed relation rows
    should be deposited, and in which format. Source
    options are files, stdout, and a MySQL table.
    This class is abstract, but make sure the subclasses
    invoke this super's __init__() when they are initialized.
    
    Also defined here are available output formats, of
    which there are two: CSV, and SQL insert statements. 
    '''
    def __init__(self, outputFormat, outputDestObj=None):
        '''
        @param outputDestObj: instance of one of the subclasses
        @type outputDestObj: Subclass(OutputDisposition)
        
        '''
        self.outputFormat = outputFormat
        if outputDestObj is None:
            self.outputDest = self
        else:
            self.outputDest = outputDestObj
        self.tmpTableFiles = {}
        self.schemas = TableSchemas()
    
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

    def flush(self):
        self.outputDest.flush()

    def getOutputFormat(self):
        return self.outputFormat

    def addSchemaHints(self, tableName, schemaHints):
        '''
        Provide a schema hint dict for the table of the given name.
        @param tableName: name of table to which schema applies. The name may be None, in which case it refers to the main (default) table.
        @type tableName: String
        @param schemaHints: dict mapping column names to SQL types via ColumnSpec instances
        @type schemaHints: [ordered]Dict<String,ColumnSpec>
        '''
        self.schemas.addColSpecs(tableName, schemaHints)

    def getSchemaHint(self, colName, tableName):
        '''
        Given a column name, and a table name, return the ColumnSpec object
        that describes that column. If tableName is None, the main (default)
        table's schema will be searched for a colName entry
        @param colName: name of column whose schema info is sought
        @type colName: String
        @param tableName: name of table in which the given column resides
        @type tableName: String
        @return: list of ColumnSpec instances
        @rtype: (ColumnSpec)
        @raise KeyError: if table or column are not found 
        '''
        return self.schemas[tableName][colName]

    def getSchemaHintByPos(self, pos, tableName):
        try:
            return self.schemas[tableName].values()[pos]
        except ValueError:
            return None
        except IndexError:
            raise ValueError("Attempt to access pos %s in schema for table %s, which is shorter than %s: %s") %\
                (str(pos), tableName, str(pos), self.schemas[tableName].values())

    def getSchema(self, tableName):
        try:
            return self.schemas[tableName].values()
        except ValueError:
            return None
    
    def ensureColExistence(self, colName, colDataType, jsonToRelationConverter, tableName=None):
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
        schemaDict = self.schemas[tableName]
        if schemaDict is None or len(schemaDict) == 0:
            # schema for this table definitely does not have the column:
            colSpecObj = ColumnSpec( colName, colDataType, jsonToRelationConverter)
            self.schemas[tableName] = OrderedDict({colName : colSpecObj})
            return
        # Have schema (dict) for this table. Does that dict contain
        # an entry for the col name?
        try:
            schemaDict[colName]
            # all set:
            return
        except KeyError:
            colSpecObj = ColumnSpec( colName, colDataType, jsonToRelationConverter)
            schemaDict[colName] = colSpecObj

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
    
    def __init__(self, outputFormat):
        super(OutputPipe, self).__init__(outputFormat)
        self.fileHandle = sys.stdout
        # Make file name accessible as property just like 
        # Python file objects do:
        self.name = "<stdout>"  # @UnusedVariable
        self.csvWriter = csv.writer(sys.stdout, dialect='excel', delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        self.tableCSVWriters = {}
        
    def close(self):
        pass # don't close stdout
    
    def flush(self):
        sys.stdout.flush()
    
    def __str__(self):
        return "<OutputPipe:<stdout>"

    def writerow(self, colElementArray, tableName=None):
        # For CSV: make sure everything is a string:
        if self.outputFormat == OutputDisposition.OutputFormat.CSV:
            row = map(str,colElementArray)
            if tableName is None:
                self.csvWriter.writerow(row)
            else:
                self.tableCSVWriters[tableName].writerow(row)
        else:
            print(colElementArray)
            

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

    def write(self, whatToWrite):
        '''
        Write given string straight to the output. No assumption made about the format
        @param whatToWrite:
        @type whatToWrite:
        '''
        sys.stdout.write(whatToWrite)
        sys.stdout.flush()


class OutputFile(OutputDisposition):
    def __init__(self, fileName, outputFormat, options='ab'):
        super(OutputFile, self).__init__(outputFormat)        
        # Make file name accessible as property just like 
        # Python file objects do:
        self.name = fileName  # @UnusedVariable
        self.outputFormat = outputFormat
        # Open the output file as 'append' and 'binary'
        # The latter is needed for Windows.
        self.fileHandle = open(fileName, options)
        if outputFormat == OutputDisposition.OutputFormat.CSV:
            self.csvWriter = csv.writer(self.fileHandle, dialect='excel', delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
            self.tableCSVWriters = {}
        
    def close(self):
        self.fileHandle.close()

    def flush(self):
        self.fileHandle.flush()

    def __str__(self):
        return "<OutputFile:%s>" % self.getFileName()

    def getFileName(self):
        return self.name

    def writerow(self, colElementArray, tableName=None):
        # For CSV: make sure everything is a string:
        if self.outputFormat == OutputDisposition.OutputFormat.CSV:
            row = map(str,colElementArray)
            if tableName is None:
                self.csvWriter.writerow(row)
            else:
                self.tableCSVWriters[tableName].writerow(row)
        else:
            self.fileHandle.write(colElementArray + '\n')

    def write(self, whatToWrite):
        '''
        Write given string straight to the output. No assumption made about the format
        @param whatToWrite:
        @type whatToWrite:
        '''
        self.fileHandle.write(whatToWrite)
        self.fileHandle.flush()
        
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

class ColumnSpec(object):
    '''
    Housekeeping class. Each instance represents the name,
    position, and datatype of one column. These instances are
    used to generate column name headers, and
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
        
    def getDefaultValue(self):
        return ColDataType().defaultValues[self.colDataType]
    
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
        return "    %s %s" % (self.getName(), self.getType())
    
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
    all tables. 
    '''

    def __init__(self):
    
        self.allSchemas = OrderedDict()
        # Add empty schema for main (default) table:
        self.allSchemas[None] = OrderedDict()
    
    def __getitem__(self, tableName):
        return self.allSchemas[tableName]
    
    def __setitem__(self, tableName, colSpecsDict):
        self.allSchemas[tableName] = colSpecsDict

    def addColSpec(self, tableName, colSpec):
        try:
            schema = self.allSchemas[tableName]
        except KeyError:
            self.allSchemas[tableName] = {colSpec.getName() : colSpec}
            schema = self.allSchemas[tableName]
        schema[colSpec.getName()] = colSpec
        
    def addColSpecs(self, tableName, colSpecsDict):
        if not isinstance(colSpecsDict, OrderedDict):
            raise ValueError("ColumSpec parameter must be a dictionary<ColName,ColumnSpec>")
        try:
            schema = self.allSchemas[tableName]
        except KeyError:
            self.allSchemas[tableName] = colSpecsDict
            schema = self.allSchemas[tableName]
        # Change schema to include the new dict:
        schema.update(colSpecsDict)
