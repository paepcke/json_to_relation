'''
Created on Oct 2, 2013

@author: paepcke
'''
import StringIO
import ijson

from col_data_type import ColDataType
from generic_json_parser import GenericJSONParser
import generic_json_parser


class EdXTrackLogJSONParser(GenericJSONParser):
    '''
    classdocs
    '''


    def __init__(self, jsonToRelationConverter):
        '''
        Constructor
        @param jsonToRelationConverter: JSONToRelation instance
        @type jsonToRelationConverter: JSONToRelation
        '''
        super(EdXTrackLogJSONParser, self).__init__(jsonToRelationConverter)

    def processOneJSONObject(self, jsonStr, row):
        '''
   	    ('null', None)
		('boolean', <true orfFalse>)
		('number', <int or Decimal>)
		('string', <unicode>)
		('map_key', <str>)
		('start_map', None)
		('end_map', None)
		('start_array', None)
		('end_array', None)
		        
		@param jsonStr: string of a single, self contained JSON object
		@type jsonStr: String
		@param row: partially filled array of values.
		@type row: List<<any>>
        '''
        parser = ijson.parse(StringIO.StringIO(jsonStr))
        # Stack of array index counters for use with
        # nested arrays:
        arrayIndexStack = generic_json_parser.Stack()
        # Not currently processing 
        #for prefix,event,value in self.parser:
        for nestedLabel, event, value in parser:
            #print("Nested label: %s; event: %s; value: %s" % (nestedLabel,event,value))
            if event == "start_map":
                if not arrayIndexStack.empty():
                    # Starting a new attribute/value pair within an array: need
                    # a new number to differentiate column headers                    
                    self.incArrayIndex(arrayIndexStack)
                continue
            
            if (len(nestedLabel) == 0) or\
               (event == "map_key") or\
               (event == "end_map"):
                continue
            
            if not arrayIndexStack.empty():
                # Label is now something like
                # employees.item.firstName. The 'item' is ijson's way of indicating
                # that we are in an array. Remove the '.item.' part; it makes
                # the relation column header unnecessarily long. Then append 
                # our array index number with an underscore:
                nestedLabel = self.removeItemPartOfString(nestedLabel) +\
                              '_' +\
                              str(arrayIndexStack.top(exceptionOnEmpty=True))
            
            # Ensure that label contains only MySQL-legal identifier chars. Else
            # quote the label:                
            nestedLabel = self.jsonToRelationConverter.ensureLegalIdentifierChars(nestedLabel)
            
            # Check whether caller gave a type hint for this column:
            try:
                colDataType = self.jsonToRelationConverter.schemaHints[nestedLabel]
            except KeyError:
                colDataType = None
            
            if event == "string":
                if colDataType is None:
                    colDataType = ColDataType.TEXT
                self.jsonToRelationConverter.ensureColExistence(nestedLabel, colDataType)
                self.setValInRow(row, nestedLabel, value)
                continue

            if event == "boolean":
                if colDataType is None:
                    colDataType = ColDataType.SMALLINT
                self.jsonToRelationConverter.ensureColExistence(nestedLabel, colDataType)
                if value:
                    value = 1
                else:
                    value = 0
                self.setValInRow(row, nestedLabel,value)                                
                continue 

            if event == "number":
                if colDataType is None:
                    colDataType = ColDataType.DOUBLE
                self.jsonToRelationConverter.ensureColExistence(nestedLabel, colDataType)
                self.setValInRow(row, nestedLabel,value)
                continue

            if event == "null":
                if colDataType is None:
                    colDataType = ColDataType.TEXT
                self.jsonToRelationConverter.ensureColExistence(nestedLabel, colDataType)
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
    

        