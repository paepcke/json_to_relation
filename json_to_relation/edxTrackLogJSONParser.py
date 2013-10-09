'''
Created on Oct 2, 2013

@author: paepcke
'''
import datetime
import json
import logging
import uuid

from col_data_type import ColDataType
from generic_json_parser import GenericJSONParser
from output_disposition import ColumnSpec


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
        # each line; Build the schema:
        
        # Fields common to every request:
        self.commonFldNames = ['agent','event_source','event_type','ip','page','session','time','username']
        
        self.schemaHintsMainTable = {}

        self.schemaHintsMainTable['eventID'] = ColDataType.TEXT # we generate this one ourselves.
        self.schemaHintsMainTable['agent'] = ColDataType.TEXT
        self.schemaHintsMainTable['event_source'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['event_type'] = ColDataType.TEXT
        self.schemaHintsMainTable['ip'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['page'] = ColDataType.TEXT
        self.schemaHintsMainTable['session'] = ColDataType.TEXT
        self.schemaHintsMainTable['time'] = ColDataType.DATETIME
        self.schemaHintsMainTable['username'] = ColDataType.TEXT
        self.schemaHintsMainTable['downtime_since'] = ColDataType.DATETIME

        # Students
        self.schemaHintsMainTable['studentID'] = ColDataType.TEXT
        
        # Instructors:
        self.schemaHintsMainTable['instructorID'] = ColDataType.TEXT
        
        # Courses
        self.schemaHintsMainTable['courseID'] = ColDataType.TEXT
        
        # Sequence navigation:
        self.schemaHintsMainTable['seqID'] = ColDataType.TEXT
        self.schemaHintsMainTable['gotoFrom'] = ColDataType.INT
        self.schemaHintsMainTable['gotoDest'] = ColDataType.INT
        
        # Problems:
        self.schemaHintsMainTable['problemID'] = ColDataType.TEXT
        self.schemaHintsMainTable['problemChoice'] = ColDataType.TEXT
        self.schemaHintsMainTable['questionLocation'] = ColDataType.TEXT
        
        # Attempts:
        self.schemaHintsMainTable['attempts'] = ColDataType.TEXT
        
        
        # Answers (in their own table; so this is just a foreign key field):
        # use problemID 
        
        # Feedback
        self.schemaHintsMainTable['feedback'] = ColDataType.TEXT
        self.schemaHintsMainTable['feedbackResponseSelected'] = ColDataType.TINYINT
        
        # Rubrics:
        self.schemaHintsMainTable['rubricSelection'] = ColDataType.INT
        self.schemaHintsMainTable['rubricCategory'] = ColDataType.INT

        # Video:
        self.schemaHintsMainTable['videoID'] = ColDataType.TEXT
        self.schemaHintsMainTable['videoCode'] = ColDataType.TEXT
        self.schemaHintsMainTable['videoCurrentTime'] = ColDataType.FLOAT
        self.schemaHintsMainTable['videoSpeed'] = ColDataType.TINYTEXT

        # Book (PDF) reading:
        self.schemaHintsMainTable['bookInteractionType'] = ColDataType.TINYTEXT
        
        # problem_check:
        self.schemaHintsMainTable['success'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['answer_id'] = ColDataType.TEXT
        self.schemaHintsMainTable['hint'] = ColDataType.TEXT
        self.schemaHintsMainTable['hintmode'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['correctness'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['msg'] = ColDataType.TEXT
        self.schemaHintsMainTable['npoints'] = ColDataType.TINYINT
        self.schemaHintsMainTable['queuestate'] = ColDataType.TEXT
        
        # Schema hints need to be a dict that maps column names to ColumnSpec 
        # instances. The dict we built so far only the the column types. Go through
        # and turn the dict's values into ColumnSpec instances:
        for colName in self.schemaHintsMainTable.keys():
            colType = self.schemaHintsMainTable[colName]
            self.schemaHintsMainTable[colName] = ColumnSpec(colName, colType, self.jsonToRelationConverter)
        
        # Establish the schema for the main table:
        self.jsonToRelationConverter.setSchemaHints(self.schemaHintsMainTable)

        # Dict<IP,Datetime>: record each IP's most recent
        # activity timestamp (heartbeat or any other event).
        # Used to detect server downtimes: 
        self.downtimes = {}
                
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
        self.jsonToRelationConverter.bumpLineCounter()
        try:
            # Turn top level JSON object to dict:
            try:
                record = json.loads(jsonStr)
            except Exception as e:
                logging.warn('Ill formed JSON in track log, line %d: %s' % (self.jsonToRelationConverter.makeFileCitation(), `e`))
                return row
    
            eventID = self.getUniqueEventID()
            self.setValInRow(row, 'eventID', eventID)
                    
            # Dispense with the fields common to all events, except event,
            # which is a nested JSON string. Results will be 
            # in self.resultDict:
            self.handleCommonFields(record, row)
            
            # Now handle the different types of events:
            
            try:
                eventType = record['eventType']
            except KeyError:
                logging.warn("No event type in line %s" % self.jsonToRelationConverter.makeFileCitation())
                return row
            
            # Check whether we had a server downtime:
            try:
                eventTimeStr = record['time']
                ip = record['ip']
                eventDateTime = datetime.datetime.strptime(eventTimeStr, '%Y-%m-%dT%H:%M:%S.%f+00:00')
            except KeyError:
                logging.warn("No event time or server IP in line %s" % self.jsonToRelationConverter.makeFileCitation())
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
                logging.warn("Track log line %d of event type %s has no event field" % (self.jsonToRelationConverter.makeFileCitation(), eventType))
                return row
            
            try:
                event = json.loads(eventJSONStr)
            except Exception as e:
                logging.warn("Track log line %d of event type %s has non-parsable JSON event field: %s" % (self.jsonToRelationConverter.makeFileCitation(), eventType, `e`))
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
            
            elif eventType == 'oe_show_full_feedback' or\
                 eventType == 'oe_show_respond_to_feedback':
                row = self.handleOEShowFeedback(record, row, event)
                return row
                
            elif eventType == 'oe_feedback_response_selected':
                row = self.handleOEFeedbackResponseSelected(record, row, event)
                return row
            
            elif eventType == 'page_close':
                # No additional info in event field
                return row
            
            elif eventType == 'play_video' or\
                 eventType == 'pause_video' or\
                 eventType == 'load_video':
                row = self.handleVideoPlayPause(record, row, event)
                return row
                
            elif eventType == 'book':
                row = self.handleBook(record, row, event)
                return row
    
            elif eventType == 'showanswer' or eventType == 'show_answer':
                row = self.handleShowAnswer(record, row, event)
                return row
    
            elif eventType == 'problem_check_fail':
                self.handleProblemCheckFail(record, row, event)
                return row
            
            # Instructor events:
            elif eventType in ['list-students',  'dump-grades',  'dump-grades-raw',  'dump-grades-csv',
                               'dump-grades-csv-raw', 'dump-answer-dist-csv', 'dump-graded-assignments-config',
                               'list-staff',  'list-instructors',  'list-beta-testers']:
                # These events have no additional info. The event_type says it all,
                # and that's already been stuck into the table:
                return row
              
            elif eventType == 'rescore-all-submissions' or eventType == 'reset-all-attempts':
                self.handleRescoreReset(record, row, event)
                return row
                
            elif eventType == 'delete-student-module-state' or eventType == 'rescore-student-submission':
                self.handleDeleteStateRescoreSubmission(record, row, event)
                return row
                
            elif eventType == 'reset-student-attempts':
                self.handleResetStudentAttempts(record, row, event)
                return row
                
            elif eventType == 'get-student-progress-page':
                self.handleGetStudentProgressPage(record, row, event)
                return row
    
            elif eventType == 'add-instructor' or eventType == 'remove-instructor':        
                self.handleAddRemoveInstructor(record, row, event)
                return row
            
            elif eventType in ['list-forum-admins', 'list-forum-mods', 'list-forum-community-TAs']:
                self.handleListForumMatters(record, row, event)
                return row
    
            elif eventType in ['remove-forum-admin', 'add-forum-admin', 'remove-forum-mod',
                               'add-forum-mod', 'remove-forum-community-TA',  'add-forum-community-TA']:
                self.handleForumManipulations(record, row, event)
                return row
    
            elif eventType == 'psychometrics-histogram-generation':
                self.handlePsychometricsHistogramGen(record, row, event)
                return row
            
            elif eventType == 'add-or-remove-user-group':
                self.handleAddRemoveUserGroup(record, row, event)
                return row
            
            else:
                logging.warn("Unknown event type '%s' in tracklog row %d" % (eventType, self.jsonToRelationConverter.makeFileCitation()))
                return row
        finally:
            self.reportProgressIfNeeded()
        
    def handleCommonFields(self, record, row):
        self.setValInRow(row, 'eventID', self.getUniqueEventID())
        for fldName in self.commonFldNames:
            val = record.get(fldName, None)
            self.setValInRow(row, fldName, val)
        # Create a unique event key  for this event:
        return row

    def handleSeqNav(self, record, row, event, eventType):

        if event is None:
            logging.warn("Track log line %d: missing event text in sequence navigation event." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        oldIndex = event.get('old', 0)
        newIndex = event.get('new', 0)
        try:
            seqID    = event['id']
        except KeyError:
            logging.warn("Track log line %d with event type %s is missing sequence id" %
                         (self.jsonToRelationConverter.makeFileCitation(), eventType)) 
            return row
        self.setValInRow(row, 'seqID', seqID)
        self.setValInRow(row, 'gotoFrom', oldIndex)
        self.setValInRow(row, 'gotoDest', newIndex)
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
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event type problem_reset contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row
        # Get the POST field's problem id array:
        try:
            problemIDs = eventDict['POST']['id']
        except KeyError:
            logging.warn("Track log line %d with event type problem_reset contains event without problem ID array: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), eventDict))
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
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event type problem_show contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row
        # Get the problem id:
        try:
            problemID = eventDict['POST']['problem']
        except KeyError:
            logging.warn("Track log line %d with event type problem_show contains event without problem ID: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), eventDict))
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
                         (self.jsonToRelationConverter.makeFileCitation()))
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
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event type question show/hide contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
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
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event type show_rubric contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row
        try:
            location = eventDict['location']
            selection = eventDict['selection']
            category = eventDict['category']
        except KeyError:
            logging.warn("Track log line %d: missing location, selection, or category in event type select_rubric." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        self.setValInRow(row, 'questionLocation', location)
        self.setValInRow(row, 'rubricSelection', selection)
        self.setValInRow(row, 'rubricCategory', category)
        return row

    def handleOEShowFeedback(self, record, row, event):
        '''
        All examples seen as of this writing had this field empty: "{}"
        '''
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event type oe_show_full_feedback or oe_show_respond_to_feedback contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row
        # Just stringify the dict and make it the field content:
        self.setValInRow(row, 'feedback', str(eventDict))
        
    def handleOEFeedbackResponseSelected(self, record, row, event):
        '''
        Gets a event string like this::
        "event": "{\"value\":\"5\"}"
        After JSON import into Python:
        {u'value': u'5'}
        '''
        if event is None:
            logging.warn("Track log line %d: missing event text in oe_feedback_response_selected." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event type oe_feedback_response_selected contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row
        try:
            value = eventDict['value']
        except KeyError:
            logging.warn("Track log line %d: missing 'value' field in event type oe_feedback_response_selected." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        self.setValInRow(row, 'feedbackResponseSelected', value)

    def handleVideoPlayPause(self, record, row, event):
        '''
        For play_video, event looks like this::
        "{\"id\":\"i4x-Education-EDUC115N-videoalpha-c41e588863ff47bf803f14dec527be70\",\"code\":\"html5\",\"currentTime\":0}"
        For pause_video:
        "{\"id\":\"i4x-Education-EDUC115N-videoalpha-c5f2fd6ee9784df0a26984977658ad1d\",\"code\":\"html5\",\"currentTime\":124.017784}"
        For load_video:
        "{\"id\":\"i4x-Education-EDUC115N-videoalpha-003bc44b4fd64cb79cdfd459e93a8275\",\"code\":\"4GlF1t_5EwI\"}"
        '''
        if event is None:
            logging.warn("Track log line %d: missing event text in video play or pause." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event type play or pause video contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row
        try:
            videoID = eventDict['id']
            videoCode = eventDict['code']
            videoCurrentTime = eventDict['currentTime']
            videoSpeed = eventDict['speed']
        except KeyError:
            logging.warn("Track log line %d: missing location, selection, or category in event type select_rubric." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        self.setValInRow(row, 'videoID', videoID)
        self.setValInRow(row, 'videoCode', videoCode)
        self.setValInRow(row, 'videoCurrentTime', videoCurrentTime)
        self.setValInRow(row, 'videoSpeed', videoSpeed)
        return row
        
    def handleBook(self, record, row, event):
        '''
        No example of book available
        '''
        if event is None:
            logging.warn("Track log line %d: missing event text in book event type." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event type book contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row
        bookInteractionType = eventDict.get('type', None)
        bookOld = eventDict.get('old', None)
        bookNew = eventDict.get('new', None)
        if bookInteractionType is not None:
            self.setValInRow(row, 'bookInteractionType', bookInteractionType)
        if bookOld is not None:            
            self.setValInRow(row, 'gotoFrom', bookOld)
        if bookNew is not None:            
            self.setValInRow(row, 'gotoDest', bookNew)
        return row
        
    def handleShowAnswer(self, record, row, event):
        '''
        Gets a event string like this::
        {"problem_id": "i4x://Medicine/HRP258/problem/28b525192c4e43daa148dc7308ff495e"}
        '''
        if event is None:
            logging.warn("Track log line %d: missing event text in showanswer." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event type showanswer (or show_answer) contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row
        try:
            problem_id = eventDict['problem_id']
        except KeyError:
            logging.warn("Track log line %d: missing problem_id in event type showanswer (or show_answer)." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        self.setValInRow(row, 'problemID', problem_id)
        return row

    def handleProblemSetFail(self, record, row, event):
        '''
        Gets events like this::
        {
          "failure": "unreset",
          "state": {
            "student_answers": {
              "i4x-Education-EDUC115N-problem-ab38a55d2eb145ae8cec26acebaca27f_2_1": "choice_0"
            },
            "seed": 89,
            "done": true,
            "correct_map": {
              "i4x-Education-EDUC115N-problem-ab38a55d2eb145ae8cec26acebaca27f_2_1": {
                "hint": "",
                "hintmode": null,
                "correctness": "correct",
                "msg": "",
                "npoints": null,
                "queuestate": null
              }
            },
            "input_state": {
              "i4x-Education-EDUC115N-problem-ab38a55d2eb145ae8cec26acebaca27f_2_1": {
                
              }
            }
          },
          "problem_id": "i4x:\/\/Education\/EDUC115N\/problem\/ab38a55d2eb145ae8cec26acebaca27f",
          "answers": {
            "i4x-Education-EDUC115N-problem-ab38a55d2eb145ae8cec26acebaca27f_2_1": "choice_0"
          }
        }        
        @param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        raise NotImplementedError("handleProblemCheckFail() not yet implemented")


    def handleRescoreReset(self, record, row, event):
        if event is None:
            logging.warn("Track log line %d: missing event info in rescore-all-submissions or reset-all-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event rescore-all-submissions or reset-all-attempts contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row
        problemID = eventDict.get('problem', None)
        courseID  = eventDict.get('course', None)
        if problemID is None:
            logging.warn("Track log line %d: missing problem ID in rescore-all-submissions or reset-all-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if problemID is None:
            logging.warn("Track log line %d: missing course ID in rescore-all-submissions or reset-all-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        self.setValInRow(row, 'problemID', problemID)
        self.setValInRow(row, 'courseID', courseID)
        return row
                
    def handleDeleteStateRescoreSubmission(self, record, row, event):
        if event is None:
            logging.warn("Track log line %d: missing event info in delete-student-module-state or rescore-student-submission." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event delete-student-module-state or rescore-student-submission contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row

        problemID = eventDict.get('problem', None)
        courseID  = eventDict.get('course', None)
        studentID = eventDict.get('student', None)
        if problemID is None:
            logging.warn("Track log line %d: missing problem ID in delete-student-module-state or rescore-student-submission." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if courseID is None:
            logging.warn("Track log line %d: missing course ID in delete-student-module-state or rescore-student-submission." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if studentID is None:
            logging.warn("Track log line %d: missing student ID in delete-student-module-state or rescore-student-submission." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        self.setValInRow(row, 'problemID', problemID)
        self.setValInRow(row, 'courseID', courseID)
        self.setValInRow(row, 'studentID', studentID)
        return row        
        
    def handleResetStudentAttempts(self, record, row, event):
        if event is None:
            logging.warn("Track log line %d: missing event info in reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event rescore-all-submissions or reset-all-attempts contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row

        problemID = eventDict.get('problem', None)
        courseID  = eventDict.get('course', None)
        studentID = eventDict.get('student', None)
        instructorID = eventDict.get('instructorID', None)
        attempts = eventDict.get('old_attempts', None)
        if problemID is None:
            logging.warn("Track log line %d: missing problem ID in reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if courseID is None:
            logging.warn("Track log line %d: missing course ID in reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if studentID is None:
            logging.warn("Track log line %d: missing student ID in reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if instructorID is None:
            logging.warn("Track log line %d: missing instrucotrIDin reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if attempts is None:
            logging.warn("Track log line %d: missing attempts field in reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            
        self.setValInRow(row, 'problemID', problemID)
        self.setValInRow(row, 'courseID', courseID)
        self.setValInRow(row, 'studentID', studentID)        
        self.setValInRow(row, 'instructorID', instructorID)
        self.setValInRow(row, 'attempts', attempts)
        return row
        
        
    def handleGetStudentProgressPage(self, record, row, event):
        if event is None:
            logging.warn("Track log line %d: missing event info in get-student-progress-page." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event get-student-progress-page contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row
        
        courseID  = eventDict.get('course', None)
        studentID = eventDict.get('student', None)
        instructorID = eventDict.get('instructorID', None)
        
        if courseID is None:
            logging.warn("Track log line %d: missing course ID in get-student-progress-page." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if studentID is None:
            logging.warn("Track log line %d: missing student ID in get-student-progress-page." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if instructorID is None:
            logging.warn("Track log line %d: missing instrucotrID in get-student-progress-page." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            
        self.setValInRow(row, 'courseID', courseID)
        self.setValInRow(row, 'studentID', studentID)        
        self.setValInRow(row, 'instructorID', instructorID)
        return row        

    def handleAddRemoveInstructor(self, record, row, event):
        if event is None:
            logging.warn("Track log line %d: missing event info in add-instructor or remove-instructor." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with add-instructor or remove-instructor contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row

        instructorID = eventDict.get('instructorID', None)

        if instructorID is None:
            logging.warn("Track log line %d: missing instrucotrID add-instructor or remove-instructor." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        self.setValInRow(row, 'instructorID', instructorID)
        return row
        
    def handleListForumMatters(self, record, row, event):
        if event is None:
            logging.warn("Track log line %d: missing event info in list-forum-admins, list-forum-mods, or list-forum-community-TAs." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with list-forum-admins, list-forum-mods, or list-forum-community-TAs contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row

        courseID = eventDict.get('course', None)
        
        if courseID is None:
            logging.warn("Track log line %d: missing course ID in list-forum-admins, list-forum-mods, or list-forum-community-TAs." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        self.setValInRow(row, 'courseID', courseID)
        return row
        
    def handleForumManipulations(self, record, row, event):
        if event is None:
            logging.warn("Track log line %d: missing event info in one of remove-forum-admin, add-forum-admin, " +\
                         "remove-forum-mod, add-forum-mod, remove-forum-community-TA, or add-forum-community-TA." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event remove-forum-admin, add-forum-admin, " +\
                         "remove-forum-mod, add-forum-mod, remove-forum-community-TA, or add-forum-community-T  contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row
        
        courseID  = eventDict.get('course', None)
        username  = eventDict.get('username', None)

        if courseID is None:
            logging.warn("Track log line %d: missing course ID in one of remove-forum-admin, add-forum-admin, " +\
                         "remove-forum-mod, add-forum-mod, remove-forum-community-TA, or add-forum-community-TA." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if username is None:
            logging.warn("Track log line %d: missing username in one of remove-forum-admin, add-forum-admin, " +\
                         "remove-forum-mod, add-forum-mod, remove-forum-community-TA, or add-forum-community-TA." %\
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            
        self.setValInRow(row, 'courseID', courseID)
        self.setValInRow(row, 'username', username)        
        return row        

    def handlePsychometricsHistogramGen(self, record, row, event):
        if event is None:
            logging.warn("Track log line %d: missing event info in pyschometrics-histogram-generation." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event pyschometrics-histogram-generation contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row

        problemID = eventDict.get('problem', None)
        
        if problemID is None:
            logging.warn("Track log line %d: missing problemID in pyschometrics-histogram-generation event." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        self.setValInRow(row, 'problemID', problemID)
        return row
    
    def handleAddRemoveUserGroup(self, record, row, event):
        if event is None:
            logging.warn("Track log line %d: missing event info add-or-remove-user-group" %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        try:
            eventDict = json.loads(event)
        except Exception as e:
            logging.warn("Track log line %d with event_type add-or-remove-user-group contains malformed event field: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), `e`))
            return row
        
        eventName  = eventDict.get('event_name', None)
        user  = eventDict.get('user', None)
        event = eventDict.get('event', None)

        if eventName is None:
            logging.warn("Track log line %d: missing event_name in add-or-remove-user-group." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if user is None:
            logging.warn("Track log line %d: missing user field in add-or-remove-user-group." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if event is None:
            logging.warn("Track log line %d: missing event field in add-or-remove-user-group." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            
        self.setValInRow(row, 'event_name', eventName)
        self.setValInRow(row, 'user', user)
        self.setValInRow(row, 'event', event)
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
        
    def getUniqueEventID(self):
        return str(uuid.uuid4())
        