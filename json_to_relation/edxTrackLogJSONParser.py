'''
Created on Oct 2, 2013

@author: paepcke
'''
import StringIO
import json

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
        try:
            record = json.loads(jsonStr)
            for attribute, value in record.iteritems():
                if (attribute == 'event' and value and not isinstance(value, dict)):
                    # hack to load the record when it is encoded as a string
                    record["event"] = json.loads(value)
            course_id = get_course_id(record)
            if course_id:
                record['course_id'] = course_id
            res = events.insert(record)
        except Exception as e:
            # TODO: handle different types of exceptions
            this_error += 1
        else:
            this_success += 1        
        
        
        
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
    
        def get_course_id(event):
            '''
            Given a 'pythonized' JSON tracking event object, find
            the course URL, and extract the course name from it.
            A number of different events occur, which do not contain
            course IDs: server heartbeats, account creation, dashboard
            accesses. Among them are logins, which look like this:
            
            {"username": "", 
             "host": "class.stanford.edu", 
             "event_source": "server", 
             "event_type": "/accounts/login", 
             "time": "2013-06-14T00:31:57.661338", 
             "ip": "98.230.189.66", 
             "event": "{
                        \"POST\": {}, 
                        \"GET\": {
                             \"next\": [\"/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/80160e.../\"]}}", 
             "agent": "Mozilla/5.0 (Windows NT 5.1; rv:21.0) Gecko/20100101
             Firefox/21.0", 
             "page": null}
            
            Notice the 'event' key's value being a *string* containing JSON, rather than 
            a nested JSON object. This requires special attention. Buried inside
            that string is the 'next' tag, whose value is an array with a long (here
            partially elided) hex number. This is where the course number is
            extracted.
            
            @param event: JSON record of an edx tracking event as internalized dict
            @type event: Dict
            @return: name of course in which event occurred, or None if course ID could not be obtained.
            @rtype: {String | None} 
            '''
            course_id = None
            if event['event_source'] == 'server':
                # get course_id from event type
                if event['event_type'] == '/accounts/login/':
                    s = event['event']['GET']['next'][0]
                else:
                    s = event['event_type']
            else:
                s = event['page']
            if s:
                a = s.split('/')
                if 'courses' in a:
                    i = a.index('courses')
                    course_id = "/".join(map(str, a[i+1:i+4]))
            return course_id
        
        def canonical_name(filepath):
            """
        Save only the filename and the subdirectory it is in, strip off all prior
        paths. If the file ends in .gz, remove that too. Convert to lower case.
        """
            fname = '/'.join(filepath.lower().split('/')[-2:])
            if len(fname) > 3 and fname[-3:] == ".gz":
                fname = fname[:-3]
            return fname
        

        