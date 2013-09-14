#!/usr/bin/env python

'''
Created on Sep 14, 2013

@author: paepcke
'''

from collections import OrderedDict
from urllib import urlopen
import StringIO
import ijson
import math
import os
import re

from output_disposition import OutputFormat
from output_disposition import OutputMySQLTable, OutputFile, OutputPipe

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
    
    def __init__(self, jsonSource, destination, outputFormat=OutputFormat.CSV, schemaHints={}):
        '''
        Create a JSON-to-Relation converter. The JSON source can be
        a file with JSON objects, StringIO.StringIO string pseudo file,
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
        if isinstance(jsonSource, StringIO.StringIO):
            self.fileHandle = jsonSource
        else:
            self.fileHandle = urlopen(jsonSource)
        self.destination = destination
        self.outputFormat = outputFormat
        self.schemaHints = schemaHints
        
        #************ Unimplemented Options **************
        if isinstance(self.destination, OutputMySQLTable):
            raise NotImplementedError("Output to MySQL table not yet implemented")
        if isinstance(self.outputFormat, OutputFormat.SQL_INSERT_STATEMENTS):
            raise NotImplementedError("Output as MySQL statements not yet implemented")
        #*************************************************
        
        # Dict col name to ColumnSpec object:
        self.cols = OrderedDict()
        
        # Position of column for next col name that is
        # newly encountered: 
        self.nextNewColPos = 0;
        
    def convert(self):
        for jsonStr in self.fileHandle:
            newRow = []
            newRow = self.processOneJSONObject(jsonStr, newRow)
            self.processFinishedRow(newRow)
        print self.getColHeaders()

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
        '''
        parser = ijson.parse(StringIO.StringIO(jsonStr))
        #for prefix,event,value in self.parser:
        for nestedLabel, event, value in parser:
            #print("Nested label: %s; event: %s; value: %s" % (nestedLabel,event,value))
            if len(nestedLabel) == 0:
                continue
            # Use the nested label as the MySQL column name. But ensure
            # that it contains only MySQL-legal identifier chars. Else
            # quote the label:
            nestedLabel = self.ensureLegalIdentifierChars(nestedLabel)
            if event == "string":
                self.ensureColExistence(nestedLabel, ColDataType.TEXT)
                self.setValInRow(row, nestedLabel, value)
                continue
            if event == "boolean":
                raise NotImplementedError("Boolean not yet implemented"); 
            if event == "number":
                try:
                    colDataType = self.schemaHints[nestedLabel]
                    self.ensureColExistence(nestedLabel, colDataType)
                except KeyError:
                    colDataType = ColDataType.DOUBLE
                self.ensureColExistence(nestedLabel, colDataType)
                self.setValInRow(row, nestedLabel,value)
            if event == "start_array":
                raise NotImplementedError("Arrays not yet implemented"); 
        return row

    def ensureColExistence(self, colName, colDataType):
        try:
            self.cols[colName]
        except KeyError:
            # New column must be added to table:
            self.cols[colName] = ColumnSpec(colName, colDataType, self)

    def setValInRow(self, theRow, colName, value):
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

    def processFinishedRow(self, filledNewRow):
        # TODO: add flexible output options
        print(filledNewRow)

    def getColHeaders(self):
        headers = []
        for colSpec in self.cols.values():
            headers.append(colSpec.colName)
        return headers

    def getNextNewColPos(self):
        return self.nextNewColPos
    
    def bumpNextNewColPos(self):
        self.nextNewColPos += 1
        
    def ensureLegalIdentifierChars(self, proposedMySQLName):
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
        
# -----------------------------  Misc Tests --------------------
class PrintJSONElements(object):
    
    def __init__(self, url):
        self.parser = ijson.parse(urlopen(url))
        
    def printElements(self):
        for prefix,event,value in self.parser:
            print("Prefix: %s; event: %s; value: %s" % (prefix,event,value))

if __name__ == '__main__':
    converter = JSONToRelation(os.path.join(os.path.dirname(__file__),"../../test/json_to_relation/data/twoJSONRecords.json"))
    converter.convert();
     
#    printer = PrintJSONElements(os.path.join(os.path.dirname(__file__),"../../test/json_to_relation/data/twoJSONRecords.json"))
#    printer.printElements()
#    print("--------------------")
#    printer.printElements()
