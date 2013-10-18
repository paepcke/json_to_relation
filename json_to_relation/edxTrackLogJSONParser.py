'''
Created on Oct 2, 2013

@author: paepcke
'''
from collections import OrderedDict
import datetime
import json
import uuid

from col_data_type import ColDataType
from generic_json_parser import GenericJSONParser
from output_disposition import ColumnSpec


EDX_HEARTBEAT_PERIOD = 360 # seconds

class EdXTrackLogJSONParser(GenericJSONParser):
    '''
    Parser specialized for EdX track logs.
    '''

    def __init__(self, jsonToRelationConverter, mainTableName, logfileID='', progressEvery=1000, replaceTables=False, dbName='test'):
        '''
        Constructor
        @param jsonToRelationConverter: JSONToRelation instance
        @type jsonToRelationConverter: JSONToRelation
        @param mainTableName: name wanted for the table into which the bulk of event data is placed
        @type mainTableName: String
        @param logfileID: an identfier of the tracking log file being processed. Used 
               to build error/warning msgs that cite a file and line number in
               their text
        @type logfileID: String
        @param progressEvery: number of input lines, a.k.a. JSON objects after which logging should report total done
        @type progressEvery: int
        @param replaceTables: determines whether the tables that constitute EdX track logs are to be deleted before inserting entries. Default: False
        @type  replaceTables: bool
        @param dbName: database name into which tables will be created (if replaceTables is True), and into which insertions will take place.
        @type dbName: String
        '''
        super(EdXTrackLogJSONParser, self).__init__(jsonToRelationConverter, 
                                                    logfileID=logfileID, 
                                                    progressEvery=progressEvery
                                                    )
        
        self.mainTableName = mainTableName
        self.dbName = dbName
        # Prepare as much as possible outside parsing of
        # each line; Build the schema:
        
        # Fields common to every request:
        self.commonFldNames = ['agent','event_source','event_type','ip','page','session','time','username']
        
        self.schemaHintsMainTable = OrderedDict()

        self.schemaHintsMainTable['eventID'] = ColDataType.UUID # we generate this one ourselves; xlates to VARCHAR(32)
        self.schemaHintsMainTable['agent'] = ColDataType.TEXT
        self.schemaHintsMainTable['event_source'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['event_type'] = ColDataType.TEXT
        self.schemaHintsMainTable['ip'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['page'] = ColDataType.TEXT
        self.schemaHintsMainTable['session'] = ColDataType.TEXT
        self.schemaHintsMainTable['time'] = ColDataType.DATETIME
        self.schemaHintsMainTable['username'] = ColDataType.TEXT
        self.schemaHintsMainTable['downtime_for'] = ColDataType.DATETIME

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
        self.schemaHintsMainTable['attempts'] = ColDataType.TINYINT
        
        
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
        self.schemaHintsMainTable['correctMapFK'] = ColDataType.UUID
        self.schemaHintsMainTable['answerFK'] = ColDataType.UUID
        self.schemaHintsMainTable['stateFK'] = ColDataType.UUID
        
        # Schema hints need to be a dict that maps column names to ColumnSpec 
        # instances. The dict we built so far only the the column types. Go through
        # and turn the dict's values into ColumnSpec instances:
        for colName in self.schemaHintsMainTable.keys():
            colType = self.schemaHintsMainTable[colName]
            self.schemaHintsMainTable[colName] = ColumnSpec(colName, colType, self.jsonToRelationConverter)
        
        # Establish the schema for the main table:
        self.jsonToRelationConverter.setSchemaHints(self.schemaHintsMainTable)

        # Schema for State table:
        self.schemaStateTbl = OrderedDict()
        self.schemaStateTbl['state_id'] = ColDataType.UUID
        self.schemaStateTbl['seed'] = ColDataType.TINYINT
        self.schemaStateTbl['done'] = ColDataType.BOOL
        self.schemaStateTbl['problem_id'] = ColDataType.TEXT
        self.schemaStateTbl['student_answer'] = ColDataType.UUID
        self.schemaStateTbl['correct_map'] = ColDataType.UUID
        self.schemaStateTbl['input_state'] = ColDataType.UUID

        # Turn the SQL data types in the dict to column spec objects:
        for colName in self.schemaStateTbl.keys():
            colType = self.schemaStateTbl[colName]
            self.schemaStateTbl[colName] = ColumnSpec(colName, colType, self.jsonToRelationConverter)
        
        
        # Schema for Answer table:
        self.schemaAnswerTbl = OrderedDict()
        self.schemaAnswerTbl['answer_id'] = ColDataType.UUID
        self.schemaAnswerTbl['problem_id'] = ColDataType.TEXT
        self.schemaAnswerTbl['answer'] = ColDataType.TEXT

        # Turn the SQL data types in the dict to column spec objects:
        for colName in self.schemaAnswerTbl.keys():
            colType = self.schemaAnswerTbl[colName]
            self.schemaAnswerTbl[colName] = ColumnSpec(colName, colType, self.jsonToRelationConverter)

        
        # Schema for CorrectMap table:
        self.schemaCorrectMapTbl = OrderedDict()
        self.schemaCorrectMapTbl['correct_map_id'] = ColDataType.UUID
        self.schemaCorrectMapTbl['answer_id'] = ColDataType.TEXT
        self.schemaCorrectMapTbl['correctness'] = ColDataType.BOOL
        self.schemaCorrectMapTbl['npoints'] = ColDataType.INT
        self.schemaCorrectMapTbl['msg'] = ColDataType.TEXT
        self.schemaCorrectMapTbl['hint'] = ColDataType.TEXT
        self.schemaCorrectMapTbl['hintmode'] = ColDataType.TINYTEXT
        self.schemaCorrectMapTbl['queuestate'] = ColDataType.TEXT

        # Turn the SQL data types in the dict to column spec objects:
        for colName in self.schemaCorrectMapTbl.keys():
            colType = self.schemaCorrectMapTbl[colName]
            self.schemaCorrectMapTbl[colName] = ColumnSpec(colName, colType, self.jsonToRelationConverter)


        # Schema for InputState table:
        self.schemaInputStateTbl = OrderedDict()
        self.schemaInputStateTbl['input_state_id'] = ColDataType.UUID
        self.schemaInputStateTbl['problem_id'] = ColDataType.TEXT
        self.schemaInputStateTbl['state'] = ColDataType.TEXT

        # Turn the SQL data types in the dict to column spec objects:
        for colName in self.schemaInputStateTbl.keys():
            colType = self.schemaInputStateTbl[colName]
            self.schemaInputStateTbl[colName] = ColumnSpec(colName, colType, self.jsonToRelationConverter)


        # Dict<IP,Datetime>: record each IP's most recent
        # activity timestamp (heartbeat or any other event).
        # Used to detect server downtimes: 
        self.downtimes = {}
                
        # Place to keep history for some rows, for which we want
        # to computer some on-the-fly aggregations:
        self.resultDict = {}

        # Create main and auxiliary tables if appropriate:
        self.pushTableCreations(replaceTables)
        
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
             "page": null
             }
                
        Third example::
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
             "page": "https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/495757ee7b25401599b1ef0495b068e4/6fd116e15ab9436fa70b8c22474b3c17/"
             }
                
        @param jsonStr: string of a single, self contained JSON object
        @type jsonStr: String
        @param row: partially filled array of values. Passed by reference
        @type row: List<<any>>
        @return: the filled-in row
        @rtype: [<any>]
        '''
        self.jsonToRelationConverter.bumpLineCounter()
        # Collect the columns whose values need to be set in 
        # the INSERT statement that results from this event:
        #********colsToSet = ['eventID'] + self.commonFldNames
        #********self.colNamesByTable[self.mainTableName] = colsToSet
        try:
            # Turn top level JSON object to dict:
            try:
                record = json.loads(jsonStr)
            except ValueError as e:
                raise ValueError('Ill formed JSON in track log, line %s: %s' % (self.jsonToRelationConverter.makeFileCitation(), `e`))
    
            #******eventID = self.getUniqueID()
            #******self.setValInRow(row, 'eventID', eventID)
                    
            # Dispense with the fields common to all events, except event,
            # which is a nested JSON string. Results will be 
            # in self.resultDict:
            self.handleCommonFields(record, row)
            
            # Now handle the different types of events:
            
            try:
                eventType = record['event_type']
            except KeyError:
                raise KeyError("No event type in line %s" % self.jsonToRelationConverter.makeFileCitation())
            
            # Check whether we had a server downtime:
            try:
                eventTimeStr = record['time']
                ip = record['ip']
                # Time strings in the log may or may not have a UTF extension:
                # '2013-07-18T08:43:32.573390:+00:00' vs '2013-07-18T08:43:32.573390'
                # For now we ignore time zone. Observed log samples are
                # all universal +/- 0:
                maybeOffsetDir = eventTimeStr[-6]
                if maybeOffsetDir == '+' or maybeOffsetDir == '-': 
                    eventTimeStr = eventTimeStr[0:-6]
                eventDateTime = datetime.datetime.strptime(eventTimeStr, '%Y-%m-%dT%H:%M:%S.%f')
            except KeyError:
                raise ValueError("No event time or server IP in line %s" % self.jsonToRelationConverter.makeFileCitation())
            except ValueError:
                raise ValueError("Bad event time format at %s: '%s'" % (self.jsonToRelationConverter.makeFileCitation(),
                                                                        eventTimeStr))
            
            try:
                doRecordHeartbeat = False
                recentSignOfLife = self.downtimes[ip]
                # Get a timedelta obj w/ duration of time
                # during which nothing was heard from server:
                serverQuietTime = eventDateTime - recentSignOfLife
                if serverQuietTime.seconds > EDX_HEARTBEAT_PERIOD:
                    self.setValInRow(row, 'downtime_for', str(serverQuietTime))
                    doRecordHeartbeat = True
                # New recently-heard from this IP:
                self.downtimes[ip] = eventDateTime
            except KeyError:
                # First sign of life for this IP:
                self.downtimes[ip] = eventDateTime
                # Record a time of 0 in downtime detection column:
                self.setValInRow(row, 'downtime_for', str(datetime.timedelta()))
                doRecordHeartbeat = True
                
            
            if eventType == '/heartbeat':
                # Handled heartbeat above, we don't transfer the heartbeats
                # themselves into the relational world. If a server
                # downtime was detected from the timestamp of this
                # heartbeat, then above code added a respective warning
                # into the row, else we just ignore the heartbeat
                if not doRecordHeartbeat:
                    row = []
                return
            
            # For any event other than heartbeat, we need to look
            # at the event field, which is an embedded JSON *string*
            # Turn that string into a (nested) Python dict:
            try:
                eventJSONStr = record['event']
            except KeyError:
                raise ValueError("Track log line %s of event type %s has no event field" % (self.jsonToRelationConverter.makeFileCitation(), eventType))
            
            try:
                event = json.loads(eventJSONStr)
            except Exception as e:
                raise ValueError("Track log line %s of event type %s has non-parsable JSON event field: %s" %\
                                 (self.jsonToRelationConverter.makeFileCitation(), eventType, `e`))
            
            if eventType == 'seq_goto' or\
               eventType == 'seq_next' or\
               eventType == 'seq_prev':
            
                row = self.handleSeqNav(record, row, event, eventType)
                return
            
            elif eventType == '/accounts/login':
                # Already recorded everything needed in common-fields
                return
            
            elif eventType == 'problem_check':
                row = self.handleProblemCheck(record, row, event)
                return
             
            elif eventType == 'problem_reset':
                row = self.handleProblemReset(record, row, event)
                return
            
            elif eventType == 'problem_show':
                row = self.handleProblemShow(record, row, event)
                return
            
            elif eventType == 'problem_save':
                row = self.handleProblemSave(record, row, event)
                return
            
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
                return
    
            elif eventType == 'rubric_select':
                row = self.handleRubricSelect(record, row, event)
                return
            
            elif eventType == 'oe_show_full_feedback' or\
                 eventType == 'oe_show_respond_to_feedback':
                row = self.handleOEShowFeedback(record, row, event)
                return
                
            elif eventType == 'oe_feedback_response_selected':
                row = self.handleOEFeedbackResponseSelected(record, row, event)
                return
            
            elif eventType == 'page_close':
                # No additional info in event field
                return
            
            elif eventType == 'play_video' or\
                 eventType == 'pause_video' or\
                 eventType == 'load_video':
                row = self.handleVideoPlayPause(record, row, event)
                return
                
            elif eventType == 'book':
                row = self.handleBook(record, row, event)
                return
    
            elif eventType == 'showanswer' or eventType == 'show_answer':
                row = self.handleShowAnswer(record, row, event)
                return
    
            elif eventType == 'problem_check_fail':
                self.handleProblemCheckFail(record, row, event)
                return
            
            # Instructor events:
            elif eventType in ['list-students',  'dump-grades',  'dump-grades-raw',  'dump-grades-csv',
                               'dump-grades-csv-raw', 'dump-answer-dist-csv', 'dump-graded-assignments-config',
                               'list-staff',  'list-instructors',  'list-beta-testers']:
                # These events have no additional info. The event_type says it all,
                # and that's already been stuck into the table:
                return
              
            elif eventType == 'rescore-all-submissions' or eventType == 'reset-all-attempts':
                self.handleRescoreReset(record, row, event)
                return
                
            elif eventType == 'delete-student-module-state' or eventType == 'rescore-student-submission':
                self.handleDeleteStateRescoreSubmission(record, row, event)
                return
                
            elif eventType == 'reset-student-attempts':
                self.handleResetStudentAttempts(record, row, event)
                return
                
            elif eventType == 'get-student-progress-page':
                self.handleGetStudentProgressPage(record, row, event)
                return
    
            elif eventType == 'add-instructor' or eventType == 'remove-instructor':        
                self.handleAddRemoveInstructor(record, row, event)
                return
            
            elif eventType in ['list-forum-admins', 'list-forum-mods', 'list-forum-community-TAs']:
                self.handleListForumMatters(record, row, event)
                return
    
            elif eventType in ['remove-forum-admin', 'add-forum-admin', 'remove-forum-mod',
                               'add-forum-mod', 'remove-forum-community-TA',  'add-forum-community-TA']:
                self.handleForumManipulations(record, row, event)
                return
    
            elif eventType == 'psychometrics-histogram-generation':
                self.handlePsychometricsHistogramGen(record, row, event)
                return
            
            elif eventType == 'add-or-remove-user-group':
                self.handleAddRemoveUserGroup(record, row, event)
                return
            
            else:
                self.logWarn("Unknown event type '%s' in tracklog row %s" % (eventType, self.jsonToRelationConverter.makeFileCitation()))
                return
        finally:
            self.reportProgressIfNeeded()
            # If above code generated anything to INSERT into SQL
            # table, do that now. If row is None, then nothing needs
            # to be inserted (e.g. heartbeats):
            if row is not None and len(row) != 0:
                self.jsonToRelationConverter.pushToTable(self.resultTriplet(row, self.mainTableName))
            # Clean out data structures in preparation for next 
            # call to this method:
            self.getReadyForNextRow()
        
    def resultTriplet(self, row, targetTableName, colNamesToSet=None):
        '''
        Given an array of column names, and an array of column values,
        construct the return triplet needed for JSONToRelation instance
        to generate its INSERT statements (see JSONToRelation.prepareMySQLRow()).
        @param row: array of column values 
        @type row: [<any>]
        @param targetTableName: name of SQL table to which the result is directed. The caller
                            of processOneJSONObject() will create an INSERT statement
                            for that table.
        @type targetTableName: String
        @param colNamesToSet: array of strings listing column names in the order in which
                              their values appear in the row parameter. If None, we assume
                              the values are destined for the main event table, whose
                              schema is 'well known'.
        @type colNamesToSet: [String]
        '''
        if colNamesToSet is None and targetTableName != self.mainTableName:
            raise ValueError("If colNamesToSet is None, the target table must be the main table whose name was passed into __init__(); was %s" % targetTableName)
        
        if colNamesToSet is not None:
            return (targetTableName, ','.join(colNamesToSet), row)
        else:
            return (targetTableName, ','.join(self.colNamesByTable[targetTableName]), row)
        
        
    def pushTableCreations(self, replaceTables):  # @NoSelf
        '''
        Pushes SQL statements to caller that create all tables, main and
        auxiliary. After these CREATE statements, 'START TRANSACTION;\n' is
        pushed. The caller is responsible for pushing 'COMMIT;\n' when all
        subsequent INSERT statements have been pushed.  
        @param replaceTables: if True, then generated CREATE statements will first DROP the various tables.
                              if False, the CREATE statements will be IF NOT EXISTS
        @type replaceTables: Boolean
        '''
        self.jsonToRelationConverter.pushString('USE %s;\n' % self.dbName)
        if replaceTables:
            # Need to suppress foreign key checks, so that we
            # can DROP the tables:
            self.jsonToRelationConverter.pushString('SET foreign_key_checks = 0;\n')
            self.jsonToRelationConverter.pushString('DROP TABLE IF EXISTS %s, Answer, InputState, CorrectMap, State;\n' % self.mainTableName)
            self.jsonToRelationConverter.pushString('SET foreign_key_checks = 1;\n')        

        # Initialize col row arrays for each table. These
        # are used in GenericJSONParser.setValInRow(), where
        # the column names are added as values for them are
        # set:
        self.colNamesByTable[self.mainTableName] = []
        self.colNamesByTable['Answer'] = []
        self.colNamesByTable['CorrectMap'] = []
        self.colNamesByTable['InputState'] = []
        self.colNamesByTable['State'] = []

        self.createAnswerTable()
        self.createCorrectMapTable()
        self.createInputStateTable()
        self.createStateTable()
        self.createMainTable()
        
        self.jsonToRelationConverter.pushString('START TRANSACTION;\n')
    
    def genOneCreateStatement(self, tableName, schemaDict, primaryKeyName=None, foreignKeyColNames=None):
        '''
        Given a table name and its ordered schema dict, generate
        a basic SQL CREATE TABLE statement. Primary and foreign key names may
        optionally be provided. An example of the most complex create statement generated
        by this method is::
        CREATE TABLE myTable
            col1 VARCHAR(32) NOT NULL Primary Key,
			col2 TEXT,
			col3 INT,
			col4 VARCHAR(32),
			FOREIGN KEY(col3) REFERENCES OtherTable(int_col_name_there),
			FOREIGN KEY(col4) REFERENCES YetOtherTable(varchar_col_name_there),
			);
		Example for the optional foreign key specification parameter
		that would create the above example::
		{'OtherTable' : ('col3', 'int_col_name_there'),
		 'YetOtherTable : ('col4', 'varchar_col_name_there')
		 }
        @param tableName: name of table to be created
        @type tableName: String
        @param schemaDict: dict mapping column names to ColumnSpec objects
        @type schemaDict: Dict<String,ColumnSpec>
        @param primaryKeyName: name of the primary key column, if any
        @type primaryKeyName: String
        @param foreignKeyColNames: dict mapping foreign table names to tuples (localColName, foreignColName)
        @type foreignKeyColNames: Dict<String,(String,String)>
        '''
        createStatement = "CREATE TABLE IF NOT EXISTS %s (\n" % tableName
        for colname in schemaDict.keys():
            if colname == primaryKeyName:
                createStatement += "%s NOT NULL Primary Key,\n" % schemaDict[colname].getSQLDefSnippet()
            else:
                createStatement += "%s,\n" % schemaDict[colname].getSQLDefSnippet()
        if foreignKeyColNames is not None:
            for foreignTableName in foreignKeyColNames.keys():
                (localFldName, foreignKeyName) = foreignKeyColNames[foreignTableName]
                createStatement += "    FOREIGN KEY(%s) REFERENCES %s(%s),\n" % (localFldName, foreignTableName, foreignKeyName) 
                 
        # Cut away the comma and newline after the last column spec,
        # and add newline, closing paren, and semicolon:
        createStatement = createStatement[0:-2] + '\n    );\n'
        return createStatement 
            

    def createAnswerTable(self):
        createStatement = self.genOneCreateStatement('Answer', self.schemaAnswerTbl, primaryKeyName='answer_id')
        self.jsonToRelationConverter.pushString(createStatement)

    def createCorrectMapTable(self):
        createStatement = self.genOneCreateStatement('CorrectMap', 
                                                     self.schemaCorrectMapTbl, 
                                                     primaryKeyName='correct_map_id')        
        self.jsonToRelationConverter.pushString(createStatement)

    def createInputStateTable(self):
        createStatement = self.genOneCreateStatement('InputState', 
                                                     self.schemaInputStateTbl, 
                                                     primaryKeyName='input_state_id')        
        self.jsonToRelationConverter.pushString(createStatement)
        
    def createStateTable(self):
        # Make the foreign keys information dict ordered. Doesn't
        # matter to SQL engine, but makes unittesting easier, b/c
        # order of foreign key declarations will be constant on
        # each run:
        foreignKeysDict = OrderedDict()
        foreignKeysDict['Answer'] = ('student_answer', 'answer_id')
        foreignKeysDict['CorrectMap'] = ('correct_map', 'correct_map_id')
        foreignKeysDict['InputState'] = ('input_state', 'input_state_id')
        createStatement = self.genOneCreateStatement('State', 
                                                     self.schemaStateTbl, 
                                                     primaryKeyName='state_id', 
                                                     foreignKeyColNames=foreignKeysDict)        
        self.jsonToRelationConverter.pushString(createStatement)

    def createMainTable(self):
        # Make the foreign keys information dict ordered. Doesn't
        # matter to SQL engine, but makes unittesting easier, b/c
        # order of foreign key declarations will be constant on
        # each run:
        foreignKeysDict = OrderedDict()
        foreignKeysDict['CorrectMap'] = ('correctMapFK', 'correct_map_id')
        foreignKeysDict['Answer'] = ('answerFK', 'answer_id')
        foreignKeysDict['State'] = ('stateFK', 'state_id')
        createStatement = self.genOneCreateStatement(self.mainTableName, 
                                                     self.schemaHintsMainTable, 
                                                     primaryKeyName='event_id', 
                                                     foreignKeyColNames=foreignKeysDict)        
        self.jsonToRelationConverter.pushString(createStatement)
        
    def handleCommonFields(self, record, row):
        # Create a unique event key  for this event:
        self.setValInRow(row, 'eventID', self.getUniqueID())
        for fldName in self.commonFldNames:
            # Default non-existing flds to null:
            val = record.get(fldName, None)
            self.setValInRow(row, fldName, val)
        return row

    def handleSeqNav(self, record, row, event, eventType):
        '''
        Video navigation. Events look like this::
            {"username": "BetaTester1", 
             "host": "class.stanford.edu", 
             "session": "009e5b5e1bd4ab5a800cafc48bad9e44", 
             "event_source": "browser", "
             event_type": "seq_goto", 
             "time": "2013-06-08T23:29:58.346222", 
             "ip": "24.5.14.103", 
             "event": "{\"old\":2,\"new\":1,\"id\":\"i4x://Medicine/HRP258/sequential/53b0357680d24191a60156e74e184be3\"}", 
             "agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0", 
             "page": "https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/ac6d006c4bc84fc1a9cec412734fd5ca/53b0357680d24191a60156e74e184be3/"
             }        
        
        @param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        @param eventType:
        @type eventType:
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event text in sequence navigation event." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in sequence navigation event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))

        oldIndex = event.get('old', 0)
        newIndex = event.get('new', 0)
        try:
            seqID    = event['id']
        except KeyError:
            self.logWarn("Track log line %s with event type %s is missing sequence id" %
                         (self.jsonToRelationConverter.makeFileCitation(), eventType)) 
            return row
        self.setValInRow(row, 'seqID', seqID)
        self.setValInRow(row, 'gotoFrom', oldIndex)
        self.setValInRow(row, 'gotoDest', newIndex)
        return row
        
    def handleProblemCheck(self, record, row, event):
        '''
        The problem_check event comes in two flavors (assertained by observation):
        The most complex is this one::
		  {       
		    "success": "correct",
		    "correct_map": {
		        "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1": {
		            "hint": "",
		            "hintmode": null,
		            "correctness": "correct",
		            "msg": "",
		            "npoints": null,
		            "queuestate": null
		        },
		        "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1": {
		            "hint": "",
		            "hintmode": null,
		            "correctness": "correct",
		            "msg": "",
		            "npoints": null,
		            "queuestate": null
		        }
		    },
		    "attempts": 2,
		    "answers": {
		        "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1": "choice_0",
		        "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1": "choice_3"
		    },
		    "state": {
		        "student_answers": {
		            "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1": "choice_3",
		            "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1": "choice_1"
		        },
		        "seed": 1,
		        "done": true,
		        "correct_map": {
		            "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1": {
		                "hint": "",
		                "hintmode": null,
		                "correctness": "incorrect",
		                "msg": "",
		                "npoints": null,
		                "queuestate": null
		            },
		            "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1": {
		                "hint": "",
		                "hintmode": null,
		                "correctness": "incorrect",
		                "msg": "",
		                "npoints": null,
		                "queuestate": null
		            }
		        },
		        "input_state": {
		            "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1": {},
		            "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1": {}
		        }
		    },
		    "problem_id": "i4x://Medicine/HRP258/problem/e194bcb477104d849691d8b336b65ff6"
		  }
		  
		The simpler version is like this, in which the answers are styled as HTTP GET parameters::
		  {"username": "smitch", 
		   "host": "class.stanford.edu", 
		   "session": "75a8c9042ba10156301728f61e487414", 
		   "event_source": "browser", 
		   "event_type": "problem_check", 
		   "time": "2013-08-04T06:27:13.660689+00:00", 
		   "ip": "66.172.116.216", 
		   "event": "\"input_i4x-Medicine-HRP258-problem-7451f8fe15a642e1820767db411a4a3e_2_1=choice_2&
		               input_i4x-Medicine-HRP258-problem-7451f8fe15a642e1820767db411a4a3e_3_1=choice_2\"", 
		   "agent": "Mozilla/5.0 (Windows NT 6.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.95 Safari/537.36", 
		   "page": "https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/de472d1448a74e639a41fa584c49b91e/ed52812e4f96445383bfc556d15cb902/"
		   }	        

        We handle the complex version here, but call problemCheckSimpleCase() 
        for the simple case.
		@param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event text in problem_check event." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        if isinstance(event, basestring):
            # Simple case:
            return self.handleProblemCheckSimpleCase(row, event)

        # Complex case: event field should be a dict:
        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in problem_check event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
        

        # Go through all the top-level problem_check event fields first;
        # we ignore non-existing fields.
        success = event.get('success', None)
        if success is not None:
            self.setValInRow(row, 'success', success, self.mainTableName)
        attempts = event.get('attempts', None)
        if attempts is not None:
            self.setValInRow(row, 'attempts', attempts, self.mainTableName)
        seed = event.get('seed', None)
        if seed is not None:
            self.setValInRow(row, 'seed', seed)
        problem_id = event.get('problem_id', None)
        if seed is not None:
            self.setValInRow(row, 'problemID', problem_id, self.mainTableName)

        # correctMap field may consist of many correct maps.
        # Create an entry for each in the CorrectMap table,
        # collecting the resulting foreign keys:
        
        correctMapsDict = event.get('correct_map', None)
        if correctMapsDict is not None:
            correctMapFKeys = self.pushCorrectMaps(correctMapsDict)
        else:
            correctMapFKeys = []    
        
        answersDict = event.get('answers', None)
        if answersDict is not None:
            answersFKeys = self.pushAnswers(answersDict)
        else:
            answersFKeys = []
        
        stateDict = event.get('state', None)
        if stateDict is not None:
            stateFKeys = self.pushState(stateDict)
        else:
            stateFKeys = []

        # Now need to generate enough near-replicas of event
        # entries to cover all correctMap, answers, and state 
        # foreign key entries that were created:
        
        generatedAllRows = False
        indexToFKeys = 0
        # Generate main table rows that refer to all the
        # foreign entries we made above to Answer, CorrectMap, and State
        # We make as few rows as possible by filling in 
        # columns in all three foreign key entries, until
        # we run out of all references:
        while not generatedAllRows:
            try:
                correctMapFKey = correctMapFKeys[indexToFKeys]
            except IndexError:
                correctMapFKey = None
            try:
                answerFKey = answersFKeys[indexToFKeys]
            except IndexError:
                answerFKey = None
            try:
                stateFKey = stateFKeys[indexToFKeys]
            except IndexError:
                stateFKey = None
            
            # Have we created rows to cover all student_answers, correct_maps, and input_states?
            if correctMapFKey is None and answerFKey is None and stateFKey is None:
                generatedAllRows = True
                continue

            # Fill in one main table row.
            self.setValInRow(row, 'correctMapFK', correctMapFKey, self.mainTableName)
            self.setValInRow(row, 'answerFK', answerFKey, self.mainTableName)
            self.setValInRow(row, 'stateFK', stateFKey, self.mainTableName)
            rowInfoTriplet = self.resultTriplet(row, self.mainTableName, self.schemaHintsMainTable.keys())
            self.jsonToRelationConverter.pushToTable(rowInfoTriplet)
            indexToFKeys += 1
        # Return empty row, b/c we already pushed all necessary rows:
        return []

    def handleProblemCheckSimpleCase(self, row, event):
        '''
        Handle the simple case of problem_check type events. 
        Their event field has this form::
		   "event": "\"input_i4x-Medicine-HRP258-problem-7451f8fe15a642e1820767db411a4a3e_2_1=choice_2&
		               input_i4x-Medicine-HRP258-problem-7451f8fe15a642e1820767db411a4a3e_3_1=choice_2\"", 
        The problems and proposed solutions are styled like HTTP GET request parameters.        
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        # Easy case: event field is GET-styled list of problem ID/choices.
        # Separate all (&-separated) answers into strings like 'problem10=choice_2':
        problemAnswers = event.split('&')
        # Build a map problemID-->answer:
        answersDict = {}            
        for problemID_choice in problemAnswers:
            try:
                # Pull elements out from GET parameter strings like 'problemID=choice_2' 
                (problemID, answerChoice) = problemID_choice.split('=')
                answersDict[problemID] = answerChoice
            except ValueError:
                # Badly formatted GET parameter element:
                self.logWarn("Track log line %s: badly formatted problemID/answerChoice GET parameter pair: %s." %\
                             (self.jsonToRelationConverter.makeFileCitation(), str(event)))
                return row
        if len(answersDict) > 0:
            # Enter all answers into the Answer table,
            # receiving an array of the Answer table's keys
            # that were generated:
            answersFKeys = self.pushAnswers(answersDict)
        else:
            answersFKeys = []
        # Now need to generate enough near-replicas of event
        # entries to cover all answers, putting one Answer
        # table key into the answers foreign key column each
        # time:
        for answerFKey in answersFKeys:
            # Fill in one main table row.
            self.setValInRow(row, 'answerFK', answerFKey, self.mainTableName)
            rowInfoTriplet = self.resultTriplet(row, self.mainTableName, self.schemaHintsMainTable.keys())
            self.jsonToRelationConverter.pushToTable(rowInfoTriplet)
        # Return empty row, b/c we already pushed all necessary rows:
        return []

    def pushCorrectMaps(self, correctMapsDict):
        '''
        Get dicts like this::
		{"i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1": {
		        "hint": "",
		        "hintmode": null,
		        "correctness": "correct",
		        "msg": "",
		        "npoints": null,
		        "queuestate": null
		    },
		    "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1": {
		        "hint": "",
		        "hintmode": null,
		        "correctness": "correct",
		        "msg": "",
		        "npoints": null,
		        "queuestate": null
		    }
		}
		The above has two correctmaps.
        @param correctMapsDict: dict of CorrectMap dicts
        @type correctMapsDict: Dict<String, Dict<String,String>>
        @return: array of unique keys, one key for each CorrectMap row the method has added.
                 In case of the above example that would be two keys (uuids)
        @rtype: [String]
        '''
        # We'll create uuids for each new CorrectMap row
        # we create. We collect these uuids in the following
        # array, and return them to the caller. The caller
        # will then use them as foreign keys in the Event
        # table:
        correctMapUniqKeys = []
        for answerKey in correctMapsDict.keys():
            answer_id = answerKey
            oneCorrectMapDict = correctMapsDict[answerKey]
            hint = oneCorrectMapDict.get('hint', None)
            hintmode = oneCorrectMapDict.get('hintmode', None)
            correctness = oneCorrectMapDict.get('correctness', None)
            msg = oneCorrectMapDict.get('msg', None)
            npoints = oneCorrectMapDict.get('npoints', None)
            queuestate = oneCorrectMapDict.get('queuestate', None)

            # Unique key for the CorrectMap entry (and foreign
            # key for the Event table):
            correct_map_id = self.getUniqueID()
            correctMapUniqKeys.append(correct_map_id)
            correctMapValues = [correct_map_id,
                                answer_id,
                                correctness,
                                npoints,
                                msg,
                                hint,
                                hintmode,
                                queuestate]
            self.jsonToRelationConverter.pushToTable(self.resultTriplet(correctMapValues, 'CorrectMap', self.schemaCorrectMapTbl.keys()))
        # Return the array of RorrectMap row unique ids we just
        # created and pushed:
        return correctMapUniqKeys 

    def pushAnswers(self, answersDict):
        '''
        Gets structure like this::
            "answers": {
                "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1": "choice_0",
                "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1": "choice_3"
            }
        @param answersDict:
        @type answersDict:
        @return: array of keys created for answers in answersDict
        @rtype: [String]
        '''
        answersKeys = []
        for problemID in answersDict.keys():
            answer = answersDict.get(problemID, None)
            if answer is not None:
                answersKey = self.getUniqueID()
                answersKeys.append(answersKey)
                answerValues = [answersKey,          # answer_id fld 
                                problemID,             # problem_id fld
                                answer
                                ]
                self.jsonToRelationConverter.pushToTable(self.resultTriplet(answerValues, 'Answer', self.schemaAnswerTbl.keys()))
        return answersKeys

    def pushState(self, stateDict):
        '''
        We get a structure like this::
	    {   
	        "student_answers": {
	            "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1": "choice_3",
	            "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1": "choice_1"
	        },
	        "seed": 1,
	        "done": true,
	        "correct_map": {
	            "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1": {
	                "hint": "",
	                "hintmode": null,
	                "correctness": "incorrect",
	                "msg": "",
	                "npoints": null,
	                "queuestate": null
	            },
	            "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1": {
	                "hint": "",
	                "hintmode": null,
	                "correctness": "incorrect",
	                "msg": "",
	                "npoints": null,
	                "queuestate": null
	            }
	        },
	        "input_state": {
	            "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1": {},
	            "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1": {}
	        }
	    }        
        @param stateDict:
        @type stateDict:
        @return: array of keys into State table that were created in this method
        @rtype: [String]
        '''
        stateFKeys = []
        studentAnswersDict = stateDict.get('student_answers', None)
        if studentAnswersDict is not None:
            studentAnswersFKeys = self.pushAnswers(studentAnswersDict)
        else:
            studentAnswersFKeys = []
        seed = stateDict.get('seed', None)
        done = stateDict.get('done', None)
        problemID = stateDict.get('problem_id', None)
        correctMapsDict = stateDict.get('correct_map', None)
        if correctMapsDict is not None:
            correctMapFKeys = self.pushCorrectMaps(correctMapsDict)
        else:
            correctMapFKeys = []
        inputStatesDict = stateDict.get('input_state', None)
        if inputStatesDict is not None:
            inputStatesFKeys = self.pushInputStates(inputStatesDict)
        else:
            inputStatesFKeys = []

        # Now generate enough State rows to reference all student_answers,
        # correctMap, and input_state entries. That is, flatten the JSON
        # structure across relations State, Answer, CorrectMap, and InputState:
        generatedAllRows = False
        
        # Unique ID that ties all these related rows together:
        state_id = self.getUniqueID()
        stateFKeys.append(state_id)
        indexToFKeys = 0
        while not generatedAllRows:
            try:
                studentAnswerFKey = studentAnswersFKeys[indexToFKeys]
            except IndexError:
                studentAnswerFKey = None
            try:
                correctMapFKey = correctMapFKeys[indexToFKeys]
            except IndexError:
                correctMapFKey = None
            try:
                inputStateFKey = inputStatesFKeys[indexToFKeys]
            except IndexError:
                inputStateFKey = None
                
            # Have we created rows to cover all student_answers, correct_maps, and input_states?
            if studentAnswerFKey is None and correctMapFKey is None and inputStateFKey is None:
                generatedAllRows = True
                continue

            stateValues = [state_id, seed, done, problemID, studentAnswerFKey, correctMapFKey, inputStateFKey]
            rowInfoTriplet = self.resultTriplet(stateValues, 'State', self.schemaStateTbl.keys())
            self.jsonToRelationConverter.pushToTable(rowInfoTriplet)
            indexToFKeys += 1
            
        return stateFKeys
        
    def pushInputStates(self, inputStatesDict):
        '''
        Gets structure like this::
            {
                "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_3_1": {},
                "i4x-Medicine-HRP258-problem-e194bcb477104d849691d8b336b65ff6_2_1": {}
            }        
        @param inputStatesDict:
        @type inputStatesDict:
        @return: array of keys created for input state problems.
        @rtype: [String]
        '''
        inputStateKeys = []
        for problemID in inputStatesDict.keys():
            inputStateProbVal = inputStatesDict.get(problemID, None)
            if inputStateProbVal is not None:
                inputStateKey = self.getUniqueID()
                inputStateKeys.append(inputStateKey)
                inputStateValues = [inputStateKey,
                                    problemID,
                                    inputStateProbVal
                                    ]
                self.jsonToRelationConverter.pushToTable(self.resultTriplet(inputStateValues, 'InputState', self.schemaInputStateTbl.keys()))
        return inputStateKeys
        
    
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
            self.logWarn("Track log line %s: missing event text in event type problem_reset." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in problem_reset event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
    
        # Get the POST field's problem id array:
        try:
            problemIDs = event['POST']['id']
        except KeyError:
            self.logWarn("Track log line %s with event type problem_reset contains event without problem ID array: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), event))
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
            self.logWarn("Track log line %s: missing event text in event type problem_show." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in problem_show event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
        
        # Get the problem id:
        try:
            problemID = event['POST']['problem']
        except KeyError:
            self.logWarn("Track log line %s with event type problem_show contains event without problem ID: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), event))
            return row
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
            self.logWarn("Track log line %s: missing event text in event type problem_save." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in problem_save event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))

        
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
            self.logWarn("Track log line %s: missing event text in question hide or show." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in problem hide or show event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        # Get location:
        try:
            location = event['location']
        except KeyError:
            self.logWarn("Track log line %s: no location field provided in problem hide or show event: '%s'" %\
             (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        self.setValInRow(row, 'questionLocation', location)
        return row
        
        
    def handleRubricSelect(self, record, row, event):
        '''
        Gets a event string like this::
        "{\"location\":\"i4x://Education/EDUC115N/combinedopenended/4abb8b47b03d4e3b8c8189b3487f4e8d\",\"selection\":\"1\",\"category\":0}"
        {u'category': 0, u'selection': u'1', u'location': u'i4x://Education/EDUC115N/combinedopenended/4abb8b47b03d4e3b8c8189b3487f4e8d'}
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event text in select_rubric." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in select rubric event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        try:
            location = event['location']
            selection = event['selection']
            category = event['category']
        except KeyError:
            self.logWarn("Track log line %s: missing location, selection, or category in event type select_rubric." %\
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
        # Just stringify the dict and make it the field content:
        self.setValInRow(row, 'feedback', str(event))
        
    def handleOEFeedbackResponseSelected(self, record, row, event):
        '''
        Gets a event string like this::
        "event": "{\"value\":\"5\"}"
        After JSON import into Python:
        {u'value': u'5'}
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event text in oe_feedback_response_selected." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in oe_feedback_response event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        try:
            value = event['value']
        except KeyError:
            self.logWarn("Track log line %s: missing 'value' field in event type oe_feedback_response_selected." %\
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
            self.logWarn("Track log line %s: missing event text in video play or pause." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in video play/pause event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        try:
            videoID = event['id']
            videoCode = event['code']
            videoCurrentTime = event['currentTime']
            videoSpeed = event['speed']
        except KeyError:
            self.logWarn("Track log line %s: missing location, selection, or category in event type select_rubric." %\
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
            self.logWarn("Track log line %s: missing event text in book event type." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in book event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        bookInteractionType = event.get('type', None)
        bookOld = event.get('old', None)
        bookNew = event.get('new', None)
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
            self.logWarn("Track log line %s: missing event text in showanswer." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in show answer event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        try:
            problem_id = event['problem_id']
        except KeyError:
            self.logWarn("Track log line %s: missing problem_id in event type showanswer (or show_answer)." %\
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
            self.logWarn("Track log line %s: missing event info in rescore-all-submissions or reset-all-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in handle resource event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        problemID = event.get('problem', None)
        courseID  = event.get('course', None)
        if problemID is None:
            self.logWarn("Track log line %s: missing problem ID in rescore-all-submissions or reset-all-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if problemID is None:
            self.logWarn("Track log line %s: missing course ID in rescore-all-submissions or reset-all-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        self.setValInRow(row, 'problemID', problemID)
        self.setValInRow(row, 'courseID', courseID)
        return row
                
    def handleDeleteStateRescoreSubmission(self, record, row, event):
        if event is None:
            self.logWarn("Track log line %s: missing event info in delete-student-module-state or rescore-student-submission." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in delete-student-module-state event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        problemID = event.get('problem', None)
        courseID  = event.get('course', None)
        studentID = event.get('student', None)
        if problemID is None:
            self.logWarn("Track log line %s: missing problem ID in delete-student-module-state or rescore-student-submission." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if courseID is None:
            self.logWarn("Track log line %s: missing course ID in delete-student-module-state or rescore-student-submission." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if studentID is None:
            self.logWarn("Track log line %s: missing student ID in delete-student-module-state or rescore-student-submission." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        self.setValInRow(row, 'problemID', problemID)
        self.setValInRow(row, 'courseID', courseID)
        self.setValInRow(row, 'studentID', studentID)
        return row        
        
    def handleResetStudentAttempts(self, record, row, event):
        if event is None:
            self.logWarn("Track log line %s: missing event info in reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in reset-student-attempt event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        problemID = event.get('problem', None)
        courseID  = event.get('course', None)
        studentID = event.get('student', None)
        instructorID = event.get('instructorID', None)
        attempts = event.get('old_attempts', None)
        if problemID is None:
            self.logWarn("Track log line %s: missing problem ID in reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if courseID is None:
            self.logWarn("Track log line %s: missing course ID in reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if studentID is None:
            self.logWarn("Track log line %s: missing student ID in reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if instructorID is None:
            self.logWarn("Track log line %s: missing instrucotrIDin reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if attempts is None:
            self.logWarn("Track log line %s: missing attempts field in reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            
        self.setValInRow(row, 'problemID', problemID)
        self.setValInRow(row, 'courseID', courseID)
        self.setValInRow(row, 'studentID', studentID)        
        self.setValInRow(row, 'instructorID', instructorID)
        self.setValInRow(row, 'attempts', attempts)
        return row
        
    def handleGetStudentProgressPage(self, record, row, event):
        if event is None:
            self.logWarn("Track log line %s: missing event info in get-student-progress-page." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in get-student-progress-page event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        courseID  = event.get('course', None)
        studentID = event.get('student', None)
        instructorID = event.get('instructorID', None)
        
        if courseID is None:
            self.logWarn("Track log line %s: missing course ID in get-student-progress-page." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if studentID is None:
            self.logWarn("Track log line %s: missing student ID in get-student-progress-page." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if instructorID is None:
            self.logWarn("Track log line %s: missing instrucotrID in get-student-progress-page." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            
        self.setValInRow(row, 'courseID', courseID)
        self.setValInRow(row, 'studentID', studentID)        
        self.setValInRow(row, 'instructorID', instructorID)
        return row        

    def handleAddRemoveInstructor(self, record, row, event):
        if event is None:
            self.logWarn("Track log line %s: missing event info in add-instructor or remove-instructor." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in add-instructor or remove-instructor event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        instructorID = event.get('instructorID', None)

        if instructorID is None:
            self.logWarn("Track log line %s: missing instrucotrID add-instructor or remove-instructor." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        self.setValInRow(row, 'instructorID', instructorID)
        return row
        
    def handleListForumMatters(self, record, row, event):
        if event is None:
            self.logWarn("Track log line %s: missing event info in list-forum-admins, list-forum-mods, or list-forum-community-TAs." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in list-forum-admins, list-forum-mods, or list-forum-community-TAs event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        courseID = event.get('course', None)
        
        if courseID is None:
            self.logWarn("Track log line %s: missing course ID in list-forum-admins, list-forum-mods, or list-forum-community-TAs." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        self.setValInRow(row, 'courseID', courseID)
        return row
        
    def handleForumManipulations(self, record, row, event):
        if event is None:
            self.logWarn("Track log line %s: missing event info in one of remove-forum-admin, add-forum-admin, " +\
                         "remove-forum-mod, add-forum-mod, remove-forum-community-TA, or add-forum-community-TA." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in one of handle forum manipulations event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        courseID  = event.get('course', None)
        username  = event.get('username', None)

        if courseID is None:
            self.logWarn("Track log line %s: missing course ID in one of remove-forum-admin, add-forum-admin, " +\
                         "remove-forum-mod, add-forum-mod, remove-forum-community-TA, or add-forum-community-TA." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if username is None:
            self.logWarn("Track log line %s: missing username in one of remove-forum-admin, add-forum-admin, " +\
                         "remove-forum-mod, add-forum-mod, remove-forum-community-TA, or add-forum-community-TA." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            
        self.setValInRow(row, 'courseID', courseID)
        self.setValInRow(row, 'username', username)        
        return row        

    def handlePsychometricsHistogramGen(self, record, row, event):
        if event is None:
            self.logWarn("Track log line %s: missing event info in psychometrics-histogram-generation." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in psychometrics-histogram-generation event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        problemID = event.get('problem', None)
        
        if problemID is None:
            self.logWarn("Track log line %s: missing problemID in pyschometrics-histogram-generation event." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        self.setValInRow(row, 'problemID', problemID)
        return row
    
    def handleAddRemoveUserGroup(self, record, row, event):
        if event is None:
            self.logWarn("Track log line %s: missing event info add-or-remove-user-group" %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        if not isinstance(event, dict):
            self.logWarn("Track log line %s: event is not a dict in add-or-remove-user-group event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        eventName  = event.get('event_name', None)
        user  = event.get('user', None)
        event = event.get('event', None)

        if eventName is None:
            self.logWarn("Track log line %s: missing event_name in add-or-remove-user-group." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if user is None:
            self.logWarn("Track log line %s: missing user field in add-or-remove-user-group." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if event is None:
            self.logWarn("Track log line %s: missing event field in add-or-remove-user-group." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            
        self.setValInRow(row, 'event_name', eventName)
        self.setValInRow(row, 'user', user)
        self.setValInRow(row, 'event', event)
        return row        
        
    def get_course_id(self, event):
        '''
        Given a 'pythonized' JSON tracking event object, find
        the course URL, and extract the course name from it.
        A number of different events occur, which do not contain
        course IDs: server heartbeats, account creation, dashboard
        accesses. Among them are logins, which look like this::
        
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
             "page": null
             }
        
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
        if course_id is None:
            fullCourseName = None
        return (fullCourseName, course_id)
        
    def getUniqueID(self):
        '''
        Generate a universally unique key with
        all characters being legal in MySQL identifiers. 
        '''
        return str(uuid.uuid4()).replace('-','_')
        
