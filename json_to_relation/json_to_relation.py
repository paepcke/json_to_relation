#!/usr/bin/env python

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

from generic_json_parser import GenericJSONParser
from input_source import InputSource, InURI, InString, InMongoDB, InPipe #@UnusedImport
from col_data_type import ColDataType
from output_disposition import OutputDisposition, OutputMySQLTable, OutputFile


#>>> with open('/home/paepcke/tmp/trash.csv', 'wab') as fd:
#...     writer = csv.writer(fd, delimiter=",", dialect="excel")
#...     writer.writerow(info)
class JSONToRelation(object):
    '''
    Given a source with JSON structures, derive a schema, and construct 
    a relational table. Source can be a local file name, a URL, or an
    StringIO pseudofile. 
    
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
                 jsonParserInstance=None):
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
        to the table might exceed the INT capacity for that column.
        
        If schemaHints is provided, it is a Dict mapping column names to ColDataType.
        The column names in schemaHints must match the corresponding (fully nested)
        key names in the JSON objects.
        
        For unit testing isolated methods in this class, set jsonSource and
        destination to None.
        
        @param jsonSource: subclass of InputSource that wraps containing JSON structures, or a URL to such a source
        @type jsonSource: {InPipe | InString | InURI | InMongoDB}
        @param destination: instruction to were resulting rows are to be directed
        @type destination: {OutputPipe | OutputFile | OutputMySQLTable}
        @param outputFormat: format of output. Can be CSV or SQL INSERT statements
        @type outputFormat: OutputFormat
        @param schemaHints: Dict mapping col names to data types (optional)
        @type schemaHints: Map<String,ColDataTYpe>
        @param jsonParserInstance: a parser that takes one JSON string, and returns a CSV row. Parser also must inform this 
                                   parent object of any generated column names.
        @type {GenericJSONParser | EdXTrackLogJSONParser | CourseraTrackLogJSONParser}
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
        self.schemaHints = schemaHints

        if jsonParserInstance is None:
            self.jsonParserInstance = GenericJSONParser(self)
        else:
            self.jsonParserInstance = jsonParserInstance
        
        #************ Unimplemented Options **************
        if self.outputFormat == OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS:
            raise NotImplementedError("Output as MySQL statements not yet implemented")
        #*************************************************
        
        # Dict col name to ColumnSpec object:
        self.cols = OrderedDict()
        
        # Position of column for next col name that is
        # newly encountered: 
        self.nextNewColPos = 0;

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
        if not isinstance(self.destination, OutputMySQLTable):
            if prependColHeader:
                savedFinalOutDest = self.destination
                (tmpFd, tmpFileName)  = tempfile.mkstemp(suffix='.csv',prefix='jsonToRelationTmp')
                os.close(tmpFd)
                self.destination = OutputFile(tmpFileName)

        with OutputDisposition(self.destination) as outFd, self.jsonSource as inFd:
            for jsonStr in inFd:
                jsonStr = self.jsonSource.decompress(jsonStr)
                newRow = []
                newRow = self.jsonParserInstance.processOneJSONObject(jsonStr, newRow)
                self.processFinishedRow(newRow, outFd)

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

    def ensureColExistence(self, colName, colDataType):
        '''
        Given a column name and MySQL datatype name, check whether this
        column has previously been encountered. If not, a column information
        object is created, which will eventually be used to create the column
        header, Django model, or SQL create statements.
        @param colName: name of the column to consider
        @type colName: String
        @param colDataType: datatype of the column.
        @type colDataType: ColDataType
        '''
        try:
            self.cols[colName]
        except KeyError:
            # New column must be added to table:
            self.cols[colName] = ColumnSpec(colName, colDataType, self)

    def processFinishedRow(self, filledNewRow, outFd):
        '''
        When a row is finished, this method processes the row as per
        the user's disposition. The method writes the row to a CSV
        file, inserts it into a MySQL table, and generates an SQL 
        insert statement for later.
        @param filledNewRow: the list of values for one row, possibly including empty fields  
        @type filledNewRow: List<<any>>
        @param outFd: an instance of a class that writes to the destination
        @type outFd: OutputDisposition
        '''
        # TODO: handle out to MySQL db
        #outFd.write(','.join(map(str,filledNewRow)) + "\n")
        outFd.writerow(map(str,filledNewRow))

    def getColHeaders(self):
        '''
        Returns a list of column header names collected so far.
        '''
        headers = []
        for colSpec in self.cols.values():
            headers.append(colSpec.colName)
        return headers

    def getNextNewColPos(self):
        '''
        Returns the position of the next new column that
        may need to be added when a previously unseen JSON
        label is encountered.
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

class ColumnSpec(object):
    '''
    Housekeeping class. Each instance represents the name,
    position, and datatype of one column. These instances are
    used to generate column name headers, Django models, and
    SQL insert statements.
    '''

    def __init__(self, colName, colDataType, jsonToRelationProcessor):
        self.colName = colName
        self.colDataType = colDataType
        self.colPos = jsonToRelationProcessor.getNextNewColPos()
        jsonToRelationProcessor.bumpNextNewColPos()
        
    def __str__(self):
        return "<Col %s: %s (position %s)>" % (self.colName, 
                                               ColDataType().toString(self.colDataType), self.colPos)
    
    def __repr__(self):
        return self.__str__()
    
