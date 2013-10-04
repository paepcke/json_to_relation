'''
Created on Oct 2, 2013

@author: paepcke
'''
import json

from col_data_type import ColDataType
from generic_json_parser import GenericJSONParser
import logging


class EdXTrackLogJSONParser(GenericJSONParser):
    '''
    Parser specialized for EdX track logs.
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
		Given one line from the EdX Track log, produce one row
		of relational output. Return is an array of values, the 
		same that is passed in. On the way, the partne JSONToRelation
		object is called to ensure that JSON fields for which new columns
		have not been created yet receive a place in the row array.    
		Different types of JSON records will be passed: server heartbeats,
		dashboard accesses, account creations, user logins. Example record
		for the latter::
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
		     
		@param jsonStr: string of a single, self contained JSON object
		@type jsonStr: String
		@param row: partially filled array of values. Passed by reference
		@type row: List<<any>>
		@return: the filled-in row
		@rtype: [<any>]
        '''
        try:
            record = json.loads(jsonStr)
            for attribute, value in record.iteritems():
                # Find cases in which the 'event' value is a *string* that
                # contains a JSON expression, as opposed to a JSON sub-object,
                # which manifests as a Python dict:
                if (attribute == 'event' and value and not isinstance(value, dict)):
                    # hack to load the record when it is encoded as a string
                    nestedValue = json.loads(value)
                    record['fullCourseRef'] = nestedValue['GET']['next'][0]
            # Dig the course ID out of JSON records that happen to be user logins: 
            (fullCourseName, course_id) = self.get_course_id(record)
            if course_id is not None:
                record['course_id'] = course_id
            if fullCourseName is not None:
                record['fullCourseName'] = fullCourseName
        except Exception as e:
            # TODO: handle different types of exceptions
            logging.error("While importing EdX track log event: " + `e`)

        if record is not None:
            for jsonFldName in record.keys():
                fldValue = record[jsonFldName]
                # Check whether caller gave a type hint for this column:
                try:
                    colDataType = self.jsonToRelationConverter.schemaHints[jsonFldName]
                except KeyError:
                    colDataType = ColDataType.sqlTypeFromValue(fldValue)
                
                self.jsonToRelationConverter.ensureColExistence(jsonFldName, colDataType)
                self.setValInRow(row, jsonFldName, fldValue)
                    
        return row
    
    def get_course_id(self, event):
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
        @type event: Dict<String,Dict<<any>>
        @return: two-tuple: fulle name of course in which event occurred, and descriptive name.
                 None if course ID could not be obtained.
        @rtype: {(String,String) | None} 
        '''
        course_id = None
        if event['event_source'] == 'server':
            # get course_id from event type
            if event['event_type'] == u'/accounts/login':
                post = json.loads(event['event'])
                fullCourseName = post['GET']['next'][0]
            else:
                fullCourseName = event['event_type']
        else:
            fullCourseName = event['page']
        if fullCourseName:
            courseNameFrags = fullCourseName.split('/')
            if 'courses' in courseNameFrags:
                i = courseNameFrags.index('courses')
                course_id = "/".join(map(str, courseNameFrags[i+1:i+4]))
        return (fullCourseName, course_id)
        

        