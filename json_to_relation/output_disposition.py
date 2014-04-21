'''
Created on Sep 14, 2013

@author: paepcke

Modifications:
  - Jan 1, 2013: added remove() method to OutputFile
  
'''
import StringIO
from collections import OrderedDict
import csv
import re
import sys
import os
import tempfile

from col_data_type import ColDataType


class OutputDisposition(object):
    '''
    Specifications for where completed relation rows
    should be deposited, and in which format. Current
    output options are to files, and to stdout.
    This class is abstract, but make sure the subclasses
    invoke this super's __init__() when they are initialized.
    
    Also defined here are available output formats, of
    which there are two: CSV, and SQL insert statements AND
    CSV.
    NOTE: currently the CSV-only format option is broken. Not
    enough time to maintain it.
    SQL insert statements that are directed to files will also
    generate equivalent .csv files. The insert statement files
    will look like the result of a mysqldump, and inserts into
    different tables are mixed. The corresponding (values-only)
    csv files are split: one file for each table.  
    '''
    def __init__(self, outputFormat, outputDestObj=None):
        '''

        :param outputDestObj: instance of one of the subclasses
        :type outputDestObj: Subclass(OutputDisposition)
        
        '''
        self.outputFormat = outputFormat
        if outputDestObj is None:
            self.outputDest = self
        else:
            self.outputDest = outputDestObj
        self.csvTableFiles = {}
        self.schemas = TableSchemas()
    
    def __enter__(self):
        return self.outputDest
        
    def __exit__(self,excType, excValue, excTraceback):
        try:
            self.outputDest.close()
        except:
            # If the conversion itself went fine, then
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

        :param tableName: name of table to which schema applies. The name may be None, in which case it refers to the main (default) table.
        :type tableName: String
        :param schemaHints: dict mapping column names to SQL types via ColumnSpec instances
        :type schemaHints: [ordered]Dict<String,ColumnSpec>
        '''
        self.schemas.addColSpecs(tableName, schemaHints)

    def getSchemaHint(self, colName, tableName):
        '''
        Given a column name, and a table name, return the ColumnSpec object
        that describes that column. If tableName is None, the main (default)
        table's schema will be searched for a colName entry

        :param colName: name of column whose schema info is sought
        :type colName: String
        :param tableName: name of table in which the given column resides
        :type tableName: String
        :return: list of ColumnSpec instances

        :rtype: (ColumnSpec)
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

        :param colName: name of the column to consider
        :type colName: String
        :param colDataType: datatype of the column.
        :type colDataType: ColDataType
        :param tableName: name of table to which the column is to belong; None if for main table
        :type tableName: {String | None}
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

        :param tableName: name by which the table file obj can be retrieved 
        :type tableName: String
        :param fileSuffix: suffix for temp file name. Ex. 'csv' for CSV outputs, or 'sql' for SQL dumps
        :type fileSuffix: String
        :return: file object open for writing

        :rtype: File
        '''
        self.csvTableFiles[tableName] = tempfile.NamedTemporaryFile(prefix='tmpTable', 
                                                                    suffix=fileSuffix)
        return self.csvTableFiles[tableName]
        
        
    #--------------------- Available Output Formats
      
    class OutputFormat():
        CSV = 0
        SQL_INSERT_STATEMENTS = 1
        SQL_INSERTS_AND_CSV = 2
            
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

        :param schemaHintsNewTable:
        :type schemaHintsNewTable:
        '''
        self.addSchemaHints(tableName, schemaHintsNewTable)
        tmpTableFile = self.createTmpTableFile(tableName, 'csv')
        self.tableCSVWriters[tableName] = csv.writer(tmpTableFile, 
                                                     dialect='excel', 
                                                     delimiter=',', 
                                                     quotechar='"', 
                                                     quoting=csv.QUOTE_MINIMAL)

    def write(self, whatToWrite):
        '''
        Write given string straight to the output. No assumption made about the format

        :param whatToWrite:
        :type whatToWrite:
        '''
        sys.stdout.write(whatToWrite)
        sys.stdout.flush()


class OutputFile(OutputDisposition):
    
    # When looking at INSERT INTO tableName (...,
    # grab 'tableName':
    TABLE_NAME_PATTERN = re.compile(r'[^\s]*\s[^\s]*\s([^\s]*)\s')
    
    # When looking at:"     ('7a286e24_b578_4741_b6e0_c0e8596bd456','Mozil...);\n"
    # grab everything inside the parens, including the trailing ');\n', which
    # we'll cut out in the code:
    VALUES_PATTERN = re.compile(r'^[\s]{4}\(([^\n]*)\n{0,1}')
    
    def __init__(self, fileName, outputFormat, options='ab'):
        '''
        Create instance of an output file destination for converted log files.
        Such an instance is created both for OutputFormat.SQL_INSERT_STATEMENTS and
        for OutputFormat.CSV. In the Insert statements case the fileName is the file
        where all INSERT statements are placed; i.e. the entire dump. If the output format
        is CSV, then the fileName is a prefix for the file names of each generated CSV file
        (one file for each table).
                   
        :param fileName: fully qualified name of output file for CSV (in case of CSV-only), 
                   or MySQL INSERT statement dump 
        :type fileName: String
        :param outputFormat: whether to output CSV or MySQL INSERT statements
        :type outputFormat: OutputDisposition.OutputFormat
        :param options: output file options as per Python built-in 'open()'. Defaults to append/binary. The
                  latter for compatibility with Windows
        :type options: String
        '''
        super(OutputFile, self).__init__(outputFormat)        
        # Make file name accessible as property just like 
        # Python file objects do:
        self.name = fileName  # @UnusedVariable
        self.outputFormat = outputFormat
        # Open the output file as 'append' and 'binary'
        # The latter is needed for Windows.
        self.fileHandle = open(fileName, options)
        if outputFormat == OutputDisposition.OutputFormat.CSV or\
            outputFormat == OutputDisposition.OutputFormat.SQL_INSERTS_AND_CSV:
            # Prepare for CSV files needed for the tables:
            self.tableCSVWriters = {}
        
    def close(self):
        self.fileHandle.close()
        # Also close any CSV out files that might exist:
        try:
            for csvFD in self.csvTableFiles.values():
                csvFD.close()
        except:
            pass

    def flush(self):
        self.fileHandle.flush()
        for csvFD in self.tableCSVWriters.values():
            try:
                csvFD.flush()
            except:
                pass
            
    def remove(self):
        try:
            os.remove(self.fileHandle.name)
        except:
            pass

    def __str__(self):
        return "<OutputFile:%s>" % self.getFileName()

    def getFileName(self, tableName=None):
        '''
        Get file name of a MySQL INSERT statement outfile,
        or, given a table name, the name of the outfile
        for CSV destined to the given table.

        :param tableName:
        :type tableName:
        '''
        if tableName is None:
            return self.name
        else:
            fd = self.csvTableFiles.get(tableName, None)
            if fd is None:
                return None
            return fd.name

    def writerow(self, colElementArray, tableName=None):
        '''
        How I wish Python had parameter type based polymorphism. Life
        would be so much cleaner.
        
        ColElementArray is either an array of values (coming from
        a CSV-only parser), or a string that contains a complete
        MySQL INSERT statement (from MySQL dump-creating parsers).
        In the first case, we ensure all elements in the array are
        strings, and write to output. In the latter case we write
        the INSERT statements to their output file. Then, if output
        format is SQL_INSERTS_AND_CSV, we also extract the MySQL
        values and write them to the proper CSV file.

        :param colElementArray: either a MySQL INSERT statement, or an array of values
        :type colElementArray: {String | [string]}
        :param tableName: name of table to which output is destined. Only needed for 
                  value arrays from CSV-only parsers. Their value arrays don't contain
                  info on the destination table. INSERT statements do contain the destination table
                  name.
        :type tableName: String
        '''
        if isinstance(colElementArray, list):
            # Simple CSV array of values; 
            # make sure every array element is a string:
            row = map(str,colElementArray)
            if tableName is None:
                # The main (and maybe only) table:
                self.csvWriter.writerow(row)
            else:
                # One of the other tables for which files
                # were opened during calls to startNewTable():
                self.tableCSVWriters[tableName].writerow(row)
        else:
            # We are either outputting INSERT statements, or
            # both those and CSV, or just CSV derived from a 
            # full MySQL INSERT parser, like edxTrackLogJSONParser. 
            # Start with the INSERTS:
            if self.outputFormat == OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS or\
                self.outputFormat == OutputDisposition.OutputFormat.SQL_INSERTS_AND_CSV:
                self.fileHandle.write(colElementArray + '\n')

            # If we are outputting either CSV or INSERTs and CSV, do the CSV
            # part now:
            if self.outputFormat != OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS:
                # Strip the CSV parts out from the INSERT statement, which may
                # contain multiple VALUE statements:
                self.writeCSVRowsFromInsertStatement(colElementArray) 
        
    def write(self, whatToWrite):
        '''
        Write given string straight to the output. No assumption made about the format

        :param whatToWrite:
        :type whatToWrite:
        '''
        self.fileHandle.write(whatToWrite)
        self.fileHandle.flush()
        
    def startNewTable(self, tableName, schemaHintsNewTable):
        '''
        Called when parser needs to create a table beyond
        the main table (in case of CSV-Only), or any table
        in case of SQLInsert+CSV. 

        :param tableName: name of new table
        :type tableName: string
        :param schemaHintsNewTable: map column name to column SQL type
        :type schemaHintsNewTable: {String,ColDataType}
        '''
        self.addSchemaHints(tableName, schemaHintsNewTable)
        if self.outputFormat == OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS:
            return
        # We are producing CSV (possibly in addition to Inserts):
        try:
            # Already have a table writer for this table?
            self.tableCSVWriters[tableName]
            return # yep
        except KeyError:
            # OK, really is a new table caller is starting:
            pass
        # Ensure that we have an open FD to write to for this table:
        if self.outputFormat == OutputDisposition.OutputFormat.CSV or\
           self.outputFormat == OutputDisposition.OutputFormat.SQL_INSERTS_AND_CSV:
            self.ensureOpenCSVOutFileFromTableName(tableName)

    def ensureOpenCSVOutFileFromTableName(self, tableName):
        '''
        Checks whether an open File object exists for the given
        table. If not, creates one. Returns the FD. The output
        file is created in the same directory as self.out

        :param tableName: name of table whose CSV output file we are to check for, or create
        :type tableName: String
        :return: a File object open for writing/appending

        :rtype: File
        '''
        try:
            # If we already have an FD for this table, return:
            return self.tableCSVWriters[tableName]
        except KeyError:
            # Else create one below:
            pass
        outFileName = self.getFileName()
        if outFileName == '/dev/null':
            outFile = open('/dev/null', 'ab')
            self.csvTableFiles[tableName] = outFile 
            return outFile
        csvOutFileName = self.getCSVTableOutFileName(tableName)
        outFile = open(csvOutFileName, 'w')
        self.csvTableFiles[tableName] = outFile
        self.tableCSVWriters[tableName] = csv.writer(outFile, 
                                                     dialect='excel', 
                                                     delimiter=',', 
                                                     quotechar='"', 
                                                     quoting=csv.QUOTE_MINIMAL)
        return self.tableCSVWriters[tableName]
    
    def getCSVTableOutFileName(self, tableName):
        # The 'None' below ensures that we get the
        # main file's name back:
        return "%s_%sTable.csv" % (self.getFileName(None), tableName) 

    def writeCSVRowsFromInsertStatement(self, insertStatement):
        '''
        Takes one SQL INSERT INTO Statement, possibly including multiple VALUES
        lines. Extracts the destination table and the values list(s), and writes
        them to disk via the appropriate CSVWriter. The INSERT statements are
        expected to be very regular, generated by json_to_relation. Don't use
        this method for arbitrary INSERT statements, b/c it relies on regular
        expressions that expect the specific format. Prerequisite: self.tableCSVWriters
        is a dictionary that maps table names into File objects that are open
        for writing.

        :param insertStatement: Well-formed MySQL INSERT statement 
        :type insertStatement: String
        @raise ValueError: if table name could not be extracted from the
               INSERT statement, or if the insertStatement contains no VALUES
               clause. 
        '''
        inFD = StringIO.StringIO(insertStatement)
        try:
            firstLine = inFD.readline()
            # Pick out the name of the table to which CSV is to be added:
            tblNameMatch = OutputFile.TABLE_NAME_PATTERN.search(firstLine)
            if tblNameMatch is None:
                raise ValueError('No match when trying to extract table name from "%s"' % insertStatement)
            tblName = tblNameMatch.group(1)
        except IndexError:
            raise ValueError('Could not extract table name from "%s"' % insertStatement)
        
        readAllValueTuples = False
        while not readAllValueTuples:
            # Get values list that belongs to this insert statement:
            valuesLine = inFD.readline()
            if not valuesLine.startswith('    ('):
                readAllValueTuples = True
                continue
            # Extract the comma-separated values list out from the parens;
            # first get "'fasdrew_fdsaf...',...);\n":
            oneValuesLineMatch = OutputFile.VALUES_PATTERN.search(valuesLine)
            if oneValuesLineMatch is None:
                # Hopefully never happens:
                raise ValueError('No match for values line "%s"' % insertStatement)
            # Get just the comma-separated values list from
            # 'abfd_sfd,...);\n
            valuesList = oneValuesLineMatch.group(1)[:-2] + '\n'
            # Make sure we've seen additions to this table before or,
            # if not, have a CSV writer and a file created to receive
            # the CSV lines:
            self.ensureOpenCSVOutFileFromTableName(tblName)
            theOutFd = self.csvTableFiles[tblName]
            theOutFd.write(valuesList)

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

        :param colName: name of column
        :type colName: String
        :param colDataType: data type of column (an enum)
        :type colDataType: ColumnSpec
        :param jsonToRelationProcessor: associated JSON to relation JSONToRelation instance
        :type jsonToRelationProcessor: JSONToRelation
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

        :return: name of column

        :rtype: String
        '''
        return self.colName
    
    def getType(self):
        '''
        Return SQL type

        :return: SQL type of colum in upper case

        :rtype: String
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
