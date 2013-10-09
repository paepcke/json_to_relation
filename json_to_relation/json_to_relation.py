#!/usr/bin/env python

#TODO: Edx problem_check_fail
#TODO: Edx problem_check
#TODO: Edx save_problem_check
#TODO: Edx problem_rescore_fail
#TODO: Edx problem_rescore


'''
Created on Sep 14, 2013

@author: paepcke
'''

from collections import OrderedDict
import math
import os
import re
import shutil
import tempfile
import logging

from generic_json_parser import GenericJSONParser
from input_source import InputSource, InURI, InString, InMongoDB, InPipe #@UnusedImport
from output_disposition import OutputDisposition, OutputMySQLDump, OutputFile


#>>> with open('/home/paepcke/tmp/trash.csv', 'wab') as fd:
#...     writer = csv.writer(fd, delimiter=",", dialect="excel")
#...     writer.writerow(info)
class JSONToRelation(object):
    '''
    Given a source with JSON structures, derive a schema, and construct 
    a relational table. Source can be a local file name, a URL, a
    StringIO pseudofile, or a Unix pipe.
    
    JSON structures in the source must be one per line. That is, each line in 
    the source must be a self contained JSON object. Pretty printed strings
    won't work. 
    '''
    
    MAX_SQL_INT = math.pow(2,31) - 1
    MIN_SQL_INT = -math.pow(2,31)
    
    # Regex pattern to check whether a string
    # contains only chars legal in a MySQL identifier
    #, i.e. alphanumeric plus underscore plus dollar sign:
    LEGAL_MYSQL_ATTRIBUTE_PATTERN = re.compile("^[$\w]+$")
        
    def __init__(self, 
                 jsonSource, 
                 destination, 
                 outputFormat=OutputDisposition.OutputFormat.CSV, 
                 schemaHints={},
                 jsonParserInstance=None,
                 loggingLevel=logging.WARN,
                 logFile=None):
        '''
        Create a JSON-to-Relation converter. The JSON source can be
        a file with JSON objects, a StringIO.StringIO string pseudo file,
        stdin, or a MongoDB
        
        The destination can be a file, where CSV is written in Excel-readable
        form, stdout, or a MySQL table specification, where the ouput rows
        will be inserted.
        
        SchemaHints optionally specify the SQL types of particular columns.
        By default the processJSONObs() method will be conservative, and
        specify numeric columns as DOUBLE. Even though all encountered values
        for one column could be examined, and a more appropriate type chosen,
        such as INT when only 4-byte integers are ever seen, future additions
        to the table might exceed the INT capacity for that column. Example
        
        If schemaHints is provided, it is a Dict mapping column names to ColDataType.
        The column names in schemaHints must match the corresponding (fully nested)
        key names in the JSON objects::
            schemaHints dict: {'msg.length' : ColDataType.INT,
                               'chunkSize' : ColDataType.INT}
        
        For unit testing isolated methods in this class, set jsonSource and
        destination to None.

        This constructor can be thought of as creating the main relational
        table that will hold all results from the JSON parsers in relational
        form. However, parsers may call startNewTable() to build any new tables
        they wish.
        
        @param jsonSource: subclass of InputSource that wraps containing JSON structures, or a URL to such a source
        @type jsonSource: {InPipe | InString | InURI | InMongoDB}
        @param destination: instruction to were resulting rows are to be directed
        @type destination: {OutputPipe | OutputFile | OutputMySQLTable}
        @param outputFormat: format of output. Can be CSV or SQL INSERT statements
        @type outputFormat: OutputFormat
        @param schemaHints: Dict mapping col names to data types (optional). Affects the default (main) table.
        @type schemaHints: Map<String,ColDataTYpe>
        @param jsonParserInstance: a parser that takes one JSON string, and returns a CSV row. Parser also must inform this 
                                   parent object of any generated column names.
        @type jsonParserInstance: {GenericJSONParser | EdXTrackLogJSONParser | CourseraTrackLogJSONParser}
        @param loggingLevel: level at which logging output is show. 
        @type loggingLevel: {logging.DEBUG | logging.WARN | logging.INFO | logging.ERROR | logging.CRITICAL}
        @raise ValueErrer: when value of jsonParserInstance is neither None, nor an instance of GenericJSONParser,
                        nor one of its subclasses.
        @raise ValueError: when jsonSource is not an instance of InPipe, InString, InURI, or InMongoDB  
        '''

        # If jsonSource and destination are both None,
        # the caller is just unit testing some of the methods
        # below:
        if jsonSource is None and destination is None:
            return
        if not isinstance(jsonSource, InputSource):
            raise ValueError("JSON source must be an instance of InPipe, InString, InURI, or InMongoDB")
        
        self.jsonSource = jsonSource
        self.destination = destination
        self.outputFormat = outputFormat
        # Establish the schema hints for the main table:
        self.destination.addSchemaHints(None, schemaHints)

        # The following three instance vars are used for accumulating INSERT
        # values when output is a MySQL dump. 
        # Current table for which insert values are being collected:
        self.currOutTable = None
        # Insert values so far (array of value arrays):
        self.currValsArray = []
        # Column names for which INSERT values are being collected.
        # Ex.: 'col1,col2':
        self.currInsertSig = None

        # Count JSON objects (i.e. JSON file lines) as they are passed
        # to us for parsing. Used for logging malformed entries:
        self.lineCounter = -1

        if logFile is not None:
            logging.basicConfig(filename=logFile, level=loggingLevel)
        else:
            logging.basicConfig(level=loggingLevel)

        if jsonParserInstance is None:
            self.jsonParserInstance = GenericJSONParser(self)
        elif isinstance(jsonParserInstance, GenericJSONParser):
            self.jsonParserInstance = jsonParserInstance
        else:
            raise ValueError("Parameter jsonParserInstance needs to be of class GenericJSONParser, or one of its subclasses.")
        
        #************ Unimplemented Options **************
        if self.outputFormat == OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS:
            raise NotImplementedError("Output as MySQL statements not yet implemented")
        #*************************************************
        
        # Dict col name to ColumnSpec object:
        self.cols = OrderedDict()
        
        # Position of column for next col name that is
        # newly encountered: 
        self.nextNewColPos = 0;

    def startNewTable(self, tableName, schemaHintsNewTable):
        '''
        Called by parsers when they need to start a new relational
        table beyond the one that is created for them. Ex: edxTrackLogJSONParser.py
        needs auxiliary tables for deeply embedded JSON structures with unpredictable
        numbers of elements (e.g. problem state). The schemaHintsNewTable 
        is an optionally ordered dict. Parsers may add additional columns later
        via calls to ensureColExistence(). Note that for MySQL load files such
        subsequent addition generates ALTER table, which might be expensive. So,
        completeness of the schemaHintsNewTable dict is recommended for MySQL
        load file outputs.
        @param tableName: name by which parser will refer to this table.
        @type tableName: String
        @param schemaHintsNewTable: dict that map column names to SQL types
        @type schemaHintsNewTable: [Ordered]Dict<String,ColumnSpec>
        '''
        self.outputFormat.startNewTable(tableName, schemaHintsNewTable)
        
    def getSourceName(self):
        '''
        Request a human-readable name of the JSON source, which 
        might be a pipe, or a file, or something else. Each input source
        class knows to provide such a name.
        '''
        return self.jsonSource.getSourceName()
        
    def setSchemaHints(self, schemaHints, tableName=None):
        '''
        Given a schema hint dictionary, set the given table's schema
        to the given dictionary. Any schema fragments already defined
        for table tableName will be removed
        @param schemaHints: dict mapping column names to ColumnSpec instances
        @type schemaHints: [Ordered]Dict<String,ColumnSpec>
        @param tableName: name of table whose schema is to be changed. None changes the main (default) table's schema
        @type tableName: String
        '''
        self.destination.addSchemaHints(tableName, schemaHints)

    def getSchemaHint(self, colName, tableName=None):
        '''
        Given a column name, and a table name, return the ColumnSpec for that column in that table.
        If tableName is None, the table is assumed to be the main (default) table.
        @param colName: name of column whose ColumnSpec instance is wanted
        @type colName: String
        @param tableName: name of table of which the column is a part 
        @type tableName: {String | None}
        @return: a ColumnSpec object that contains the SQL type name of the column
        @rtype: ColumnSpec
        @raise KeyError: if either the table or the column don't exist.  
        '''
        return self.destination.getSchemaHint(colName, tableName)

    def ensureColExistence(self, colName, colDataType, tableName=None):
        self.destination.ensureColExistence(colName, colDataType, self, tableName)

    def convert(self, prependColHeader=False):
        '''
        Main user-facing API method. Read from the JSON source establish
        in the __init__() call. Create a MySQL schema as the JSON is read.
        Convert each JSON object into the requested output format (e.g. CSV),
        and deliver it to the destination (e.g. a file)
        @param prependColHeader: If true, the final destination, if it is stdout or a file,
                will have the column names prepended. Note that this option requires that
                the output file is first written to a temp file, and then merged with the
                completed column name header row to the final destination that was specified
                by the client. 
        @type prependColHeader: Boolean
        '''
        savedFinalOutDest = None
        if not isinstance(self.destination, OutputMySQLDump):
            if prependColHeader:
                savedFinalOutDest = self.destination
                (tmpFd, tmpFileName)  = tempfile.mkstemp(suffix='.csv',prefix='jsonToRelationTmp')
                os.close(tmpFd)
                self.destination = OutputFile(tmpFileName)

        with self.destination as outFd, self.jsonSource as inFd:
            for jsonStr in inFd:
                jsonStr = self.jsonSource.decompress(jsonStr)
                newRow = []
                try:
                    newRow = self.jsonParserInstance.processOneJSONObject(jsonStr, newRow)
                except ValueError as e:
                    #***** Catch here or down in the parser?
                    logging.warn('Line %s: bad JSON: %s' % (self.makeFileCitation(), `e`))
                self.processFinishedRow(newRow, outFd)
                self.bumpLineCounter()

        # If output to other than MySQL table, check whether
        # we are to prepend the column header row:
        if prependColHeader and savedFinalOutDest is not None:
            try:
                with open(self.destination.name, 'rb') as inFd, OutputDisposition(savedFinalOutDest) as finalOutFd:
                    colHeaders = self.getColHeaders()
                    self.processFinishedRow(colHeaders, finalOutFd)
                    shutil.copyfileobj(inFd, finalOutFd.fileHandle)
            finally:
                os.remove(tmpFileName)

    def processFinishedRow(self, filledNewRow, outFd):
        '''
        When a row is finished, this method processes the row as per
        the user's disposition. The method writes the row to a CSV
        file, or pipe, or generates an SQL insert statement for later.
        
        The filledNewRow parameter looks different, depending on whether
        the underlying parser generates MySQL insert statement information,
        or CSV rows. The latter are just written to outFD. MySQL insert info
        looks like this: ('tableName', 'insertSig', [valsArray]). The insertSig
        is a string as needed for the INSERT statement's column names part. 
        Ex.: 'col1,col2'. 
        
        @param filledNewRow: the list of values for one row, possibly including empty fields  
        @type filledNewRow: List<<any>>
        @param outFd: an instance of a class that writes to the destination
        @type outFd: OutputDisposition
        '''
        # We handle 'rows' destined for MySQL dumps differently
        # from rows destined to CSV. Parsers that generate dump
        # information as they translate JSON provide different
        # information than CSV destined parsers. MySQL dumps provide
        # a list 
        if isinstance(outFd, OutputMySQLDump):
            filledNewRow = self.prepareMySQLRow(filledNewRow)
        if filledNewRow is not None:
            outFd.writerow(map(str,filledNewRow))

    def prepareMySQLRow(self, insertInfo):
        '''
        Receives either a triple ('tableName', 'insertSig', [valsArray]),
        or the string 'FLUSH'. Generates either None, or a legal MySQL insert statement. 
        The method is lazy.
        
        It collects values to be inserted into the same table, and the same
        columns within that table, and returns a non-Null string only when
        the incoming insertInfo is for a different table, or a different set
        of columns in the same table (as the previous calls). In that case the
        returned string is a legal MySQL INSERT statement, possibly multi-valued.
        
        If insertInfo is the string 'FLUSH', then an INSERT statement is
        returned for any held-back prior values. 
        
        @param insertInfo: information on what to generate for MySQL dumps
        @type insertInfo: {(String, String, [<any>]) | String)}
        '''
        try:
            (tableName, insertSig, valsArray) = insertInfo
        except ValueError:
            if insertInfo == 'FLUSH':
                return self.finalizeInsertStatement()
            else:
                raise ValueError('Bad argument to prepareMySQLRow: %s' % str(insertInfo))
        # Have we started accumulating values in an earlier call?
        if self.currOutTable is not None: 
            if tableName == self.currOutTable and insertSig == self.currInsertSig:
                # These values are for the same columns in the same table
                # as previous call(s). Accumulate them:
                self.currValsArray.append(valsArray)
                return None
            else:
                # Were accumulating vals, but this call is for a different
                # table or set of columns:
                insertStatement = self.finalizeInsertStatement()
                # Start accumulating values for this new INSERT request:
                self.currOutTable = tableName
                self.currInsertSig = insertSig
                self.valsArray = [valsArray]
                return insertStatement
                
    def finalizeInsertStatement(self):
        '''
        Create a possibly multivalued INSERT statement from what is
        stored in self.currOutTable, self.currInsertSig, and self.currValsArray.
        '''
        res = "INSERT INTO %s (%s) %s;" % (self.currOutTable, self.currInsertSig, self.currValsArray)
        # We are no longer accumulating INSERT values right now:
        self.currOutTable = None
        self.currInsertSig = None
        self.currValsArray = []
        return res

    def getSchema(self, tableName=None):
        '''
        Returns an ordered list of ColumnSpec instances.
        Each such instance holds column name and SQL type.
        @param tableName: name of table for which schema is wanted. None: the main (default) table. 
        @type tableName: String
        @return: ordered list of column information
        @rtype: (ColumnSpec) 
        '''
        return self.destination.getSchema(tableName)

    def getColHeaders(self, tableName=None):
        '''
        Returns a list of column header names collected so far.
        @return: list of column headers that were discovered so far by an 
                 associated JSON parser descending into a JSON structure.
        @rtype: [String]
        '''
        headers = []
        for colSpec in self.getSchema(tableName):
            headers.append(colSpec.colName)
        return headers

    def getNextNewColPos(self):
        '''
        Returns the position of the next new column that
        may need to be added when a previously unseen JSON
        label is encountered.
        @return: position in schema where the next new discovered column header is to go.
        @rtype: int 
        '''
        return self.nextNewColPos
    
    def bumpNextNewColPos(self):
        self.nextNewColPos += 1

    def ensureLegalIdentifierChars(self, proposedMySQLName):
        '''
        Given a proposed MySQL identifier, such as a column name,
        return a possibly modified name that will be acceptable to
        a MySQL database. MySQL accepts alphanumeric, underscore,
        and dollar sign. Identifiers with other chars must be quoted.
        Quote characters embedded within the identifiers must be
        doubled to be escaped. 
        @param proposedMySQLName: input name
        @type proposedMySQLName: String
        @return: the possibly modified, legal MySQL identifier
        @rtype: String
        '''
        if JSONToRelation.LEGAL_MYSQL_ATTRIBUTE_PATTERN.match(proposedMySQLName) is not None:
            return proposedMySQLName
        # Got an illegal char. Quote the name, doubling any
        # embedded quote chars (sick, sick, sick proposed name): 
        quoteChar = '"'
        if proposedMySQLName.find(quoteChar) > -1:
            quoteChar = "'"
            if proposedMySQLName.find(quoteChar) > -1:
                # Need to double each occurrence of quote char in the proposed name;
                # get a list of the chars, i.e. 'explode' the string into letters:
                charList = list(proposedMySQLName)
                newName = ""
                for letter in charList:
                    if letter == quoteChar:
                        letter = quoteChar + quoteChar
                    newName += letter
                proposedMySQLName = newName
        return quoteChar + proposedMySQLName + quoteChar

    def makeFileCitation(self):
        return self.getSourceName() + ':' + str(self.lineCounter)

    def bumpLineCounter(self):
        self.lineCounter += 1