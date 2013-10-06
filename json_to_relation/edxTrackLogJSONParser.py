'''
Created on Oct 2, 2013

@author: paepcke
'''
import datetime
import json
import logging

from col_data_type import ColDataType
from generic_json_parser import GenericJSONParser


EDX_HEARTBEAT_PERIOD = 6 # seconds

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
        
        # Prepare as much as possible outside parsing of
        # each line:
        
        # Fields common to all track log entries:
        self.jsonToRelationConverter.schemaHints['agent'] = ColDataType.TEXT
        self.jsonToRelationConverter.schemaHints['event'] = ColDataType.TEXT
        self.jsonToRelationConverter.schemaHints['event_source'] = ColDataType.TINYTEXT
        self.jsonToRelationConverter.schemaHints['event_type'] = ColDataType.TEXT
        self.jsonToRelationConverter.schemaHints['ip'] = ColDataType.TINYTEXT
        self.jsonToRelationConverter.schemaHints['page'] = ColDataType.TEXT
        self.jsonToRelationConverter.schemaHints['session'] = ColDataType.TEXT
        self.jsonToRelationConverter.schemaHints['time'] = ColDataType.DATETIME
        self.jsonToRelationConverter.schemaHints['username'] = ColDataType.TEXT
        self.jsonToRelationConverter.schemaHints['downtime_since'] = ColDataType.DATETIME
        
        # Sequence navigation:
        self.jsonToRelationConverter.schemaHints['seqID'] = ColDataType.TEXT
        self.jsonToRelationConverter.schemaHints['seqGotoFrom'] = ColDataType.INT
        self.jsonToRelationConverter.schemaHints['seqGotoNew'] = ColDataType.INT
        
        # Problems:
        self.jsonToRelationConverter.schemaHints['problemID'] = ColDataType.TEXT
        self.jsonToRelationConverter.schemaHints['problemChoice'] = ColDataType.TEXT
        self.jsonToRelationConverter.schemaHints['questionLocation'] = ColDataType.TEXT
        
        # Rubrics:
        self.jsonToRelationConverter.schemaHints['rubricSelection'] = ColDataType.INT
        self.jsonToRelationConverter.schemaHints['rubricCategory'] = ColDataType.INT
        
        # problem_check:
        self.jsonToRelationConverter.schemaHints['success'] = ColDataType.TINYTEXT
        self.jsonToRelationConverter.schemaHints['answer_id'] = ColDataType.TEXT
        self.jsonToRelationConverter.schemaHints['hint'] = ColDataType.TEXT
        self.jsonToRelationConverter.schemaHints['hintmode'] = ColDataType.TINYTEXT
        self.jsonToRelationConverter.schemaHints['correctness'] = ColDataType.TINYTEXT
        self.jsonToRelationConverter.schemaHints['msg'] = ColDataType.TEXT
        self.jsonToRelationConverter.schemaHints['npoints'] = ColDataType.TINYINT
        self.jsonToRelationConverter.schemaHints['queuestate'] = ColDataType.TEXT
        
        # Dict<IP,Datetime>: record each IP's most recent
        # activity timestamp (heartbeat or any other event).
        # Used to detect server downtimes: 
        self.downtimes = {}
        
        # Make sure the schema knows about the fields we'll encounter all the time
        # in track logs:
        self.commonFldNames = ['agent', 'event_source', 'event_type', 'ip', 'session', 'username', 'heartbeat_stopped', 'heartbeat_started']
        for fldName in self.commonFldNames:
            self.jsonToRelationConverter.ensureColExistence(fldName, self.jsonToRelationConverter.schemaHints[fldName])
                
        # Place to keep history for some rows, for which we want
        # to computer some on-the-fly aggregations:
        self.resultDict = {}

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

        Two more examples to show the variance in the format. Note "event" field:
		
		Second example::
		{"username": "jane", 
		 "host": "class.stanford.edu", 
		 "event_source": "server", 
		 "event_type": "/courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/combinedopenended/c415227048464571a99c2c430843a4d6/get_results", 
		 "time": "2013-07-31T06:27:06.222843+00:00", 
		 "ip": "67.166.146.73", 
		 "event": "{\"POST\": {
		                        \"task_number\": [\"0\"]}, 
		                        \"GET\": {}}",
		 "agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.71 Safari/537.36", 
		 "page": null}
				
	    Third example:
		{"username": "miller", 
		 "host": "class.stanford.edu", 
		 "session": "fa715506e8eccc99fddffc6280328c8b", 
		 "event_source": "browser", 
		 "event_type": "hide_transcript", 
		 "time": "2013-07-31T06:27:10.877992+00:00", 
		 "ip": "27.7.56.215", 
		 "event": "{\"id\":\"i4x-Medicine-HRP258-videoalpha-09839728fc9c48b5b580f17b5b348edd\",
		            \"code\":\"fQ3-TeuyTOY\",
		            \"currentTime\":0}", 
		 "agent": "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.72 Safari/537.36", 
		 "page": "https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/495757ee7b25401599b1ef0495b068e4/6fd116e15ab9436fa70b8c22474b3c17/"}
				
		@param jsonStr: string of a single, self contained JSON object
		@type jsonStr: String
		@param row: partially filled array of values. Passed by reference
		@type row: List<<any>>
		@return: the filled-in row
		@rtype: [<any>]
        '''
        self.lineCounter += 1
        # Turn top level JSON object to dict:
        try:
            record = json.loads(jsonStr)
        except Exception as e:
            logging.warn('Ill formed JSON in track log, line %d: %s' % (self.makeFileCitation(self.lineCounter), `e`))
            return row
        
        # Dispense with the fields common to all events, except event,
        # which is a nested JSON string. Results will be 
        # in self.resultDict:
        self.handleCommonFields(record, row)
        
        # Now handle the different types of events:
        
        try:
            eventType = record['eventType']
        except KeyError:
            logging.warn("No event type in line %d" % self.makeFileCitation(self.lineCounter))
            return row
        
        # Check whether we had a server downtime:
        try:
            eventTimeStr = record['time']
            ip = record['ip']
            eventDateTime = datetime.datetime.strptime(eventTimeStr, '%Y-%m-%dT%H:%M:%S.%f+00:00')
        except KeyError:
            logging.warn("No event time or server IP in line %d" % self.makeFileCitation(self.lineCounter))
            return row
        
        try:
            recentSignOfLife = self.downtimes[ip]
            # Get a timedelta obj w/ duration of time
            # during which nothing was heard from server:
            serverQuietTime = eventDateTime - recentSignOfLife
            if serverQuietTime.seconds > EDX_HEARTBEAT_PERIOD:
                self.setValInRow(row, 'downtime_since', str(serverQuietTime))
            # New recently-heard from this IP:
            self.downtimes[ip] = eventDateTime
        except KeyError:
            # First sign of life for this IP:
            self.downtimes[ip] = eventDateTime
            # Record a time of 0 in downtime detection column:
            self.setValInRow(row, 'downtime_since', str(datetime.timedelta()))
            
        
        if eventType == 'heartbeat':
            # Handled heartbeat above, no further entry needed
            return row
        
        # For any event other than heartbeat, we need to look
        # at the event field, which is an embedded JSON *string*
        # Turn that string into a (nested) Python dict:
        try:
            eventJSONStr = record['event']
        except KeyError:
            logging.warn("Track log line %d of event type %s has no event field" % (self.makeFileCitation(self.lineCounter), eventType))
            return row
        
        try:
            event = json.loads(eventJSONStr)
        except Exception as e:
            logging.warn("Track log line %d of event type %s has non-parsable JSON event field: %s" % (self.makeFileCitation(self.lineCounter), eventType, `e`))
            return row
        
        if eventType == 'seq_goto' or\
           eventType == 'seq_next' or\
           eventType == 'seq_prev':
        
            row = self.handleSeqNav(record, row, event, eventType)
            return row
        
        elif eventType == 'problem_check':
            row = self.handleProblemCheck(record, row, event)
            return row
         
        elif eventType == 'problem_reset':
            row = self.handleProblemReset(record, row, event)
            return row
        
        elif eventType == 'problem_show':
            row = self.handleProblemShow(record, row, event)
            return row
        
        elif eventType == 'problem_save':
            row = self.handleProblemSave(record, row, event)
            return row
        
        elif eventType == 'oe_hide_question' or\
             eventType == 'oe_hide_problem' or\
             eventType == 'peer_grading_hide_question' or\
             eventType == 'peer_grading_hide_problem' or\
             eventType == 'staff_grading_hide_question' or\
             eventType == 'staff_grading_hide_problem' or\
             eventType == 'oe_show_question' or\
             eventType == 'oe_show_problem' or\
             eventType == 'peer_grading_show_question' or\
             eventType == 'peer_grading_show_problem' or\
             eventType == 'staff_grading_show_question' or\
             eventType == 'staff_grading_show_problem':
             
            row = self.handleQuestionProblemHidingShowing(record, row, event)
            return row

        elif eventType == 'rubric_select':
            row = self.handleRubricSelect(record, row, event)
            return row
        
        else:
            logging.warn("Unknown event type '%s' in tracklog row %d" % (eventType, self.makeFileCitation(self.lineCounter)))
            return row
        
        
    def handleCommonFields(self, record, row):
        for fldName in self.commonFldNames:
            try:
                val = record[fldName]
            except KeyError:
                # This JSON object/track log row doesn't have a value for this common fld:
                val = None
            self.setValInRow(row, fldName, val)
        return row

    def handleSeqNav(self, record, row, event, eventType):

        if event is None:
            logging.warn("Track log line %d: missing event text in sequence navigation event." %\
                         (self.makeFileCitation(self.lineCounter)))
            return row

        oldIndex = event.get('old', 0)
        newIndex = event.get('new', 0)
        try:
            seqID    = event['id']
        except KeyError:
            logging.warn("Track log line %d with event type %s is missing sequence id" %
                         (self.makeFileCitation(self.lineCounter), eventType)) 
            return row
        self.setValInRow(row, 'seqID', seqID)
        self.setValInRow(row, 'seqGotoFrom', oldIndex)
        self.setValInRow(row, 'seqGotoNew', newIndex)
        return row
        
    def handleProblemCheck(self, record, row, event):
        raise NotImplementedError("Problem_check not implemented yet.")
    
    def handleProblemReset(self, record, row, event):
        '''
        Gets a event string like this::
        "{\"POST\": {\"id\": [\"i4x://Engineering/EE222/problem/e68cfc1abc494dfba585115792a7a750@draft\"]}, \"GET\": {}}"
        After turning this JSON into Python::
        {u'POST': {u'id': [u'i4x://Engineering/EE222/problem/e68cfc1abc494dfba585115792a7a750@draft']}, u'GET': {}}
        @param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        if event is None:
            logging.warn("Track log line %d: missing event text in event type problem_reset." %\
                         (self.makeFileCitation(self.lineCounter)))
            return row
        
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event type problem_reset contains malformed event field: '%s'" %
                         (self.makeFileCitation(self.lineCounter), `e`))
            return row
        # Get the POST field's problem id array:
        try:
            problemIDs = eventDict['POST']['id']
        except KeyError:
            logging.warn("Track log line %d with event type problem_reset contains event without problem ID array: '%s'" %
                         (self.makeFileCitation(self.lineCounter), eventDict))
        self.setValInRow(row, 'problemID', problemIDs)
        return row

    def handleProblemShow(self, record, row, event):
        '''
        Gets a event string like this::
         "{\"problem\":\"i4x://Medicine/HRP258/problem/c5cf8f02282544729aadd1f9c7ccbc87\"}"
        
        After turning this JSON into Python::
        {u'problem': u'i4x://Medicine/HRP258/problem/c5cf8f02282544729aadd1f9c7ccbc87'}

        @param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        if event is None:
            logging.warn("Track log line %d: missing event text in event type problem_show." %\
                         (self.makeFileCitation(self.lineCounter)))
            return row
        
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event type problem_show contains malformed event field: '%s'" %
                         (self.makeFileCitation(self.lineCounter), `e`))
            return row
        # Get the problem id:
        try:
            problemID = eventDict['POST']['problem']
        except KeyError:
            logging.warn("Track log line %d with event type problem_show contains event without problem ID: '%s'" %
                         (self.makeFileCitation(self.lineCounter), eventDict))
        self.setValInRow(row, 'problemID', problemID)
        return row

    def handleProblemSave(self, record, row, event):
        '''
        Gets a event string like this::
        "\"input_i4x-Education-EDUC115N-problem-44b3fb5f49884be7bc35712b176e50c4_2_1=choice_1\""
        
        After splitting this string on '=':
        ['"input_i4x-Education-EDUC115N-problem-44b3fb5f49884be7bc35712b176e50c4_2_1', 'choice_1"']

        @param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        if event is None:
            logging.warn("Track log line %d: missing event text in event type problem_save." %\
                         (self.makeFileCitation(self.lineCounter)))
            return row
        (problemID, choice) = event.split('=')
        self.setValInRow(row, 'problemID', problemID[1:])  # remove leading double quote
        self.setValInRow(row, 'problemChoice', choice)
        return row

    def handleQuestionProblemHidingShowing(self, record, row, event):
        '''
        Gets a event string like this::
        "{\"location\":\"i4x://Education/EDUC115N/combinedopenended/c8af7daea1f54436b0b25930b1631845\"}"
        After importing from JSON into Python::
        {u'location': u'i4x://Education/EDUC115N/combinedopenended/c8af7daea1f54436b0b25930b1631845'}
        '''
        if event is None:
            logging.warn("Track log line %d: missing event text in question hide or show." %\
                         (self.makeFileCitation(self.lineCounter)))
            return row
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event type question show/hide contains malformed event field: '%s'" %
                         (self.makeFileCitation(self.lineCounter), `e`))
            return row
        # Get location:
        location = eventDict['location']
        self.setValInRow(row, 'questionLocation', location)
        return row
        
        
    def handleRubricSelect(self, record, row, event):
        '''
        Gets a event string like this::
        "{\"location\":\"i4x://Education/EDUC115N/combinedopenended/4abb8b47b03d4e3b8c8189b3487f4e8d\",\"selection\":\"1\",\"category\":0}"
        {u'category': 0, u'selection': u'1', u'location': u'i4x://Education/EDUC115N/combinedopenended/4abb8b47b03d4e3b8c8189b3487f4e8d'}
        '''
        if event is None:
            logging.warn("Track log line %d: missing event text in select_rubric." %\
                         (self.makeFileCitation(self.lineCounter)))
            return row
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event type show_rubric contains malformed event field: '%s'" %
                         (self.makeFileCitation(self.lineCounter), `e`))
            return row
        try:
            location = eventDict['location']
            selection = eventDict['selection']
            category = eventDict['category']
        except KeyError:
            logging.warn("Track log line %d: missing location, selection, or category in event type select_rubric." %\
                         (self.makeFileCitation(self.lineCounter)))
            return row
        self.setValInRow(row, 'questionLocation', location)
        self.setValInRow(row, 'rubricSelection', selection)
        self.setValInRow(row, 'rubricCategory', category)
        return row
    
        
        
        
#         try:
#             record = json.loads(jsonStr)
#             for attribute, value in record.iteritems():
#                  Find cases in which the 'event' value is a *string* that
#                  contains a JSON expression, as opposed to a JSON sub-object,
#                  which manifests as a Python dict:
#                 if (attribute == 'event' and value and not isinstance(value, dict)):
#                      hack to load the event value when it is encoded as a JSON string:
#                     nestedValue = json.loads(value)
#                     record['fullCourseRef'] = nestedValue['GET']['next'][0]
#              Dig the course ID out of JSON records that happen to be user logins: 
#             (fullCourseName, course_id) = self.get_course_id(record)
#             if course_id is not None:
#                 record['course_id'] = course_id
#             if fullCourseName is not None:
#                 record['fullCourseName'] = fullCourseName
#         except Exception as e:
#              TODO: handle different types of exceptions
#             logging.error("While importing EdX track log event: " + `e`)
# 
#         if record is not None:
#             for jsonFldName in record.keys():
#                 fldValue = record[jsonFldName]
#                  Check whether caller gave a type hint for this column:
#                 try:
#                     colDataType = self.jsonToRelationConverter.schemaHints[jsonFldName]
#                 except KeyError:
#                     colDataType = ColDataType.sqlTypeFromValue(fldValue)
#                 
#                 self.jsonToRelationConverter.ensureColExistence(jsonFldName, colDataType)
#                 self.setValInRow(row, jsonFldName, fldValue)
#                     
#         return row
    
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
        

        