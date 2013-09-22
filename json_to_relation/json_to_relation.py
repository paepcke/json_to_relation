#!/usr/bin/env python

'''
Created on Sep 14, 2013

@author: paepcke
'''

from collections import OrderedDict
from input_source import InputSource
from output_disposition import OutputDisposition, OutputMySQLTable, OutputFile
import StringIO
import ijson
import math
import os
import re
import shutil
import tempfile




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
    
    def __init__(self, jsonSource, destination, outputFormat=OutputDisposition.OutputFormat.CSV, schemaHints={}):
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
        
        @param jsonSource: A file name containing JSON structures, or a URL to such a source
        @type jsonSource: {String | StringIO}
        @param destination: instruction to were resulting rows are to be directed
        @type destination: {OutputPipe | OutputFile | OutputMySQLTable}
        @param outputFormat: format of output. Can be CSV or SQL INSERT statements
        @type outputFormat: OutputFormat
        @param schemaHints: Dict mapping col names to data types (optional)
        @type schemaHints: Map<String,ColDataTYpe>
        '''

        
        self.jsonSource = jsonSource
        self.destination = destination
        self.outputFormat = outputFormat
        self.schemaHints = schemaHints
        
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

        with OutputDisposition(self.destination) as outFd, InputSource(self.jsonSource) as inFd:
            for jsonStr in inFd:
                newRow = []
                newRow = self.processOneJSONObject(jsonStr, newRow)
                self.processFinishedRow(newRow, outFd)

        # If output to other than MySQL table, check whether
        # we are to prepend the column header row:
        if prependColHeader and savedFinalOutDest is not None:
            try:
                with open(self.destination.name, 'rb') as inFd, OutputDisposition(savedFinalOutDest) as finalOutFd:
                    colHeaders = self.getColHeaders()
                    self.processFinishedRow(colHeaders, finalOutFd)
                    shutil.copyfileobj(inFd, finalOutFd)
            except:
                os.remove(tmpFileName)

    def processOneJSONObject(self, jsonStr, row):
        '''
   	    ('null', None)
		('boolean', <True or False>)
		('number', <int or Decimal>)
		('string', <unicode>)
		('map_key', <str>)
		('start_map', None)
		('end_map', None)
		('start_array', None)
		('end_array', None)
		        
		@param jsonStr: string of a single, self contained JSON object
		@type jsonStr: String
        '''
        parser = ijson.parse(StringIO.StringIO(jsonStr))
        # Stack of array index counters for use with
        # nested arrays:
        arrayIndexStack = Stack()
        objectDepth = 0
        prevObjectDepth = 0
        # Not currently processing 
        #for prefix,event,value in self.parser:
        for nestedLabel, event, value in parser:
            #print("Nested label: %s; event: %s; value: %s" % (nestedLabel,event,value))
            if event == "start_map":
                prevObjectDepth = objectDepth
                objectDepth += 1
                continue
            elif event == "end_map":
                objectDepth -= 1
                prevObjectDepth = objectDepth
                continue
            
            if (len(nestedLabel) == 0) or\
               (event == "map_key") or\
               (event == "start_map") or\
               (event == "end_map"):
                continue
            
            # Use the nested label as the MySQL column name.
            # If we are in the middle of an array, append the
            # next array index to the label: 
            if not arrayIndexStack.empty():
                currArrayIndex = arrayIndexStack.pop()
                if prevObjectDepth != objectDepth:     
                    currArrayIndex += 1
                    prevObjectDepth = objectDepth
            if event == "end_map":
                continue

                arrayIndexStack.push(currArrayIndex)
                nestedLabel += "_" + str(currArrayIndex)
                
            # Ensure that label contains only MySQL-legal identifier chars. Else
            # quote the label:                
            nestedLabel = self.ensureLegalIdentifierChars(nestedLabel)
            
            # Check whether caller gave a type hint for this column:
            try:
                colDataType = self.schemaHints[nestedLabel]
            except KeyError:
                colDataType = None
            
            if event == "string":
                if colDataType is None:
                    colDataType = ColDataType.TEXT
                self.ensureColExistence(nestedLabel, colDataType)
                self.setValInRow(row, nestedLabel, value)
                continue

            if event == "boolean":
                raise NotImplementedError("Boolean not yet implemented");
                continue 

            if event == "number":
                if colDataType is None:
                    colDataType = ColDataType.DOUBLE
                self.ensureColExistence(nestedLabel, colDataType)
                self.setValInRow(row, nestedLabel,value)
                continue

            if event == "null":
                if colDataType is None:
                    colDataType = ColDataType.TEXT
                self.ensureColExistence(nestedLabel, colDataType)
                self.setValInRow(row, nestedLabel, '')
                continue

            if event == "start_array":
                # New array index entry for this nested label.
                # Used to generate <label>_0, <label>_1, etc. for
                # column names:
                arrayIndexStack.push(-1)
                continue

            if event == "end_array":
                # Array closed; forget the array counter:
                arrayIndexStack.pop()
                continue

            raise ValueError("Unknown JSON value type at %s for value %s (ijson event: %s)" % (nestedLabel,value,str(event))) 
        return row

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

    def setValInRow(self, theRow, colName, value):
        '''
        Given a column name, a value and a partially filled row,
        add the column to the row, or set the value in an already
        existing row.
        @param theRow: list of values in their proper column positions
        @type theRow: List<<any>>
        @param colName: name of column into which value is to be inserted.
        @type colName: String
        @param value: the field value
        @type value: <any>, as per ColDataType
        '''
        colSpec = self.cols[colName]
        targetPos = colSpec.colPos
        # Is value to go just beyond the current row len?
        if (len(theRow) == 0 or len(theRow) == targetPos):
            theRow.append(value)
            return theRow
        # Is value to go into an already existing column?
        if (len(theRow) > targetPos):
            theRow[targetPos] = value
            return theRow
        
        # Adding a column beyond the current end of the row, but
        # not just by one position.
        # Won't usually happen, as we just keep adding cols as
        # we go, but taking care of this case makes for flexibility:
        # Make a list that spans the missing columns, and fill
        # it with nulls; then concat that list with theRow:
        fillList = ['null']*(targetPos - len(theRow))
        fillList.append(value)
        theRow.extend(fillList)
        return theRow

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
        outFd.write(','.join(map(str,filledNewRow)) + "\n")

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
    
        
class ColDataType:
    '''
    Enum for datatypes that can be converted to 
    MySQL datatypes
    '''
    TEXT=0
    LONGTEXT=1
    SMALLINT=2
    INT=3
    FLOAT=4
    DOUBLE=5
    DATE=6
    TIME=7
    DATETIME=8
    
    strings = {TEXT     : "TEXT",
               LONGTEXT : "LONGTEXT",
               SMALLINT : "SMALLINT",
               INT      : "INT",
               FLOAT    : "FLOAT",
               DOUBLE   : "DOUBLE",
               DATE     : "DATE",
               TIME     : "TIME",
               DATETIME : "DATETIME"
    }
    
    def toString(self, val):
        try:
            return ColDataType.strings[val]
        except KeyError:
            raise ValueError("The code %s does not refer to a known datatype." % str(val))
        
class Stack(object):
    
    def __init__(self):
        self.stackArray = []

    def empty(self):
        return len(self.stackArray) == 0
        
    def push(self, item):
        self.stackArray.append(item)
        
    def pop(self):
        try:
            return self.stackArray.pop()
        except IndexError:
            raise ValueError("Stack empty.")
    
    def top(self, exceptionOnEmpty=False):
        if len(self.stackArray) == 0:
            if exceptionOnEmpty:
                raise ValueError("Call to Stack instance method 'top' when stack is empty.")
            else:
                return None
        return self.stackArray[len(self.stackArray) -1]
    
    def stackHeight(self):
        return len(self.stackArray)
    
