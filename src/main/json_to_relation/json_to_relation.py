#!/usr/bin/env python

from urllib import urlopen
import StringIO
import ijson
import math
import os


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
    
    def __init__(self, urlOrFileName, schemaHints=None):
        '''
        
        @param urlOrFileName: A file name containing JSON structures, or a URL to such a source
        @type urlOrFileName: String
        @param schemaHints: Dict mapping col names to data types (optional)
        @type schemaHints: Map<String,ColDataTYpe>
        '''
        
        self.fileHandle = urlopen(urlOrFileName)
        self.schemaHints = schemaHints
        # Dict col name to ColumnSpec object:
        self.cols = {}
        
        # Position of column for next col name that is
        # newly encountered: 
        self.nextNewColPos = 0;
        
    def processJSONObjsFile(self):
        for jsonStr in self.fileHandle:
            newRow = []
            newRow = self.processOneJSONObject(jsonStr, newRow)
            self.processFinishedRow(newRow)

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
            if event == "map_key":
                self.ensureColExistence(nestedLabel, ColDataType.TEXT)
                self.addValToRow(row, nestedLabel,value, ColDataType.TEXT)
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
                self.addValToRow(row, nestedLabel,value)
            if event == "start_array":
                raise NotImplementedError("Arrays not yet implemented"); 

    def ensureColExistence(self, colName, value, colDataType):
        try:
            colSpec = self.cols[colName]
        except KeyError:
            # New column must be added to table:
            colSpec = ColumnSpec(colName, colDataType, self)
        print(colSpec)

    def addValToRow(self, theRow, colName, value):
        colSpec = self.cols[colName]
        targetPos = colSpec.colPos
        if (len(theRow) == 0 or len(theRow) == targetPos):
            pass

    def processFinishedRow(self, filledNewRow):
        # TODO: add flexible output options
        print(filledNewRow)

    def getNextNewColPos(self):
        return self.nextNewColPos
    
    def bumpNextNewColPos(self):
        self.nextNewColPos += 1

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
    converter.processJSONObjsFile();
     
#    printer = PrintJSONElements(os.path.join(os.path.dirname(__file__),"../../test/json_to_relation/data/twoJSONRecords.json"))
#    printer.printElements()
#    print("--------------------")
#    printer.printElements()
