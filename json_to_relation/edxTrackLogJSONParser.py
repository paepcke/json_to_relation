'''
Created on Oct 2, 2013

@author: paepcke
'''
from collections import OrderedDict
import datetime
import hashlib
import json
import os
import re
import string
from unidecode import unidecode
import uuid

from col_data_type import ColDataType
from generic_json_parser import GenericJSONParser
from locationManager import LocationManager
from modulestoreImporter import ModulestoreImporter
from output_disposition import ColumnSpec


EDX_HEARTBEAT_PERIOD = 360 # seconds

class EdXTrackLogJSONParser(GenericJSONParser):
    '''
    Parser specialized for EdX track logs.
    '''
    # Class var to detect JSON strings that contain backslashes 
    # in front of chars other than \bfnrtu/. JSON allows backslashes
    # only before those. But: /b, /f, /n, /r, /t, /u, and \\ also need to
    # be escaped.
    # Pattern used in makeSafeJSON()
    #JSON_BAD_BACKSLASH_PATTERN = re.compile(r'\\([^\\bfnrtu/])')
    JSON_BAD_BACKSLASH_PATTERN = re.compile(r'\\([^/"])')

    # Regex patterns for extracting fields from bad JSON:
    searchPatternDict = {}
    searchPatternDict['username'] = re.compile(r"""
                                    username[^:]*       # The screen_name key
                                    [^"']*              # up to opening quote of the value 
                                    ["']                # opening quote of the value 
                                    ([^"']*)            # the value
                                    """, re.VERBOSE)
    searchPatternDict['host'] = re.compile(r"""
                                    host[^:]*
                                    [^"']*
                                    ["']
                                    ([^"']*)
                                    """, re.VERBOSE)
    searchPatternDict['session'] = re.compile(r"""
                                    session[^:]*
                                    [^"']*
                                    ["']
                                    ([^"']*)
                                    """, re.VERBOSE)
    searchPatternDict['event_source'] = re.compile(r"""
                                    event_source[^:]*
                                    [^"']*
                                    ["']
                                    ([^"']*)
                                    """, re.VERBOSE)
    searchPatternDict['event_type'] = re.compile(r"""
                                    event_type[^:]*
                                    [^"']*
                                    ["']
                                    ([^"']*)
                                    """, re.VERBOSE)
    searchPatternDict['time'] = re.compile(r"""
                                    time[^:]*
                                    [^"']*
                                    ["']
                                    ([^"']*)
                                    """, re.VERBOSE)
    searchPatternDict['ip'] = re.compile(r"""
                                    ip[^:]*
                                    [^"']*
                                    ["']
                                    ([^"']*)
                                    """, re.VERBOSE)
    
    searchPatternDict['event'] = re.compile(r"""
                                    [\\"']event[\\"']   # Event with possibly backslashed quotes
                                    [^:]*               # up to the colon
                                    :                   # colon that separates key and value
                                    (.*)                # all of the rest of the string.
                                    """, re.VERBOSE)
    
    # Picking (likely) zip codes out of a string:
    zipCodePattern = re.compile(r'[^0-9]([0-9]{5})')
    
    # Finding the word 'status' in problem_graded events:
    # Extract problem ID and 'correct' or 'incorrect' from 
    # a messy problem_graded event string. Two cases:
    #     ' aria-describedby=\\"input_i4x-Medicine-SciWrite-problem-c3266c76a7854d02b881250a49054ddb_2_1\\">\\n        incorrect\\n      </p>\\n\\n'
    # and
    #     'aria-describedby=\\"input_i4x-Medicine-HRP258-problem-068a71cb1a1a4da39da093da2778f000_3_1_choice_2\\">Status: incorrect</span>'
    # with lots of HTML and other junk around it.
    problemGradedComplexPattern = re.compile(r'aria-describedby=[\\"]*(input[^\\">]*)[\\"]*[>nStatus\\:\s"]*([iIn]{0,2}correct)')

    # isolate '-Medicine-HRP258-problem-8dd11b4339884ab78bc844ce45847141_2_1":' from:
    # ' {"success": "correct", "correct_map": {"i4x-Medicine-HRP258-problem-8dd11b4339884ab78bc844ce45847141_2_1": {"hint": "", "hintmode": null'
    problemXFindCourseID = re.compile(r'[^-]*([^:]*)')

    # Isolate 32-bit hash inside any string, e.g.:
    #   i4x-Medicine-HRP258-videoalpha-7cd4bf0813904612bcd583a73ade1d54
    # or:
    #   input_i4x-Medicine-HRP258-problem-98ca37dbf24849debcc29eb36811cb68_3_1_choice_3'
    findHashPattern = re.compile(r'([a-f0-9]{32})')
    
    def __init__(self, jsonToRelationConverter, mainTableName, logfileID='', progressEvery=1000, replaceTables=False, dbName='test', useDisplayNameCache=False, testLookupDict=None):
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
        @param useDisplayNameCache: if True then use an existing cache for mapping
                    OpenEdx hashes to human readable display names is used. Else
                    the required information is read and parsed from a JSON file name
                    that contains the needed information from modulestore. See
                    modulestoreImporter.py for details. 
        @type useDisplayNameCache: Bool      
        @param testLookupDict: strictly for use by unittests. They pass in a ready-made OpenEdx hash-to-DisplayName dictionary
                    to avoid rebuilding that every time a test is run. 
        @type testLookupDict: {<String> : <String>}               
        '''
        super(EdXTrackLogJSONParser, self).__init__(jsonToRelationConverter, 
                                                    logfileID=logfileID, 
                                                    progressEvery=progressEvery
                                                    )
        
        self.mainTableName = mainTableName
        self.dbName = dbName
        
        self.setupMySqlDumpControlInstructions()
                
        # Prepare as much as possible outside parsing of
        # each line; Build the schema:
        
        # Fields common to every request:
        self.commonFldNames = ['agent','event_source','event_type','ip','page','session','time','username', 'course_id', 'course_display_name']

        # A Country lookup facility:
        self.countryChecker = LocationManager()
    
        # Lookup table from OpenEdx 32-bit hash values to
        # corresponding problem, course, or video display_names:
        self.hashMapper = ModulestoreImporter(os.path.join(os.path.dirname(__file__),'data/modulestore_latest.json'), useCache=useDisplayNameCache, testLookupDict=testLookupDict)
                
        self.schemaHintsMainTable = OrderedDict()

        self.schemaHintsMainTable['_id'] = ColDataType.UUID
        self.schemaHintsMainTable['event_id'] = ColDataType.UUID # we generate this one ourselves; xlates to VARCHAR(40). Not unique!
        self.schemaHintsMainTable['agent'] = ColDataType.TEXT
        self.schemaHintsMainTable['event_source'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['event_type'] = ColDataType.TEXT
        self.schemaHintsMainTable['ip'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['page'] = ColDataType.TEXT
        self.schemaHintsMainTable['session'] = ColDataType.TEXT
        self.schemaHintsMainTable['time'] = ColDataType.DATETIME
        self.schemaHintsMainTable['anon_screen_name'] = ColDataType.TEXT
        self.schemaHintsMainTable['downtime_for'] = ColDataType.DATETIME

        # Students
        self.schemaHintsMainTable['student_id'] = ColDataType.TEXT
        
        # Instructors:
        self.schemaHintsMainTable['instructor_id'] = ColDataType.TEXT
        
        # Courses
        self.schemaHintsMainTable['course_id'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['course_display_name'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['resource_display_name'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['organization'] = ColDataType.TINYTEXT
        
        # Sequence navigation:
        self.schemaHintsMainTable['sequence_id'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['goto_from'] = ColDataType.INT
        self.schemaHintsMainTable['goto_dest'] = ColDataType.INT
        
        # Problems:
        self.schemaHintsMainTable['problem_id'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['problem_choice'] = ColDataType.TEXT
        self.schemaHintsMainTable['question_location'] = ColDataType.TEXT
        
        # Submissions:
        self.schemaHintsMainTable['submission_id'] = ColDataType.TEXT
        
        # Attempts:
        self.schemaHintsMainTable['attempts'] = ColDataType.INT
        
        
        # Answers 
        # Multiple choice answers are in their own table,
        # called Answer. In this main table answerFK points
        # to one entry in that table.
        
        self.schemaHintsMainTable['long_answer'] = ColDataType.TEXT # essay answers
        self.schemaHintsMainTable['student_file'] = ColDataType.TEXT
        self.schemaHintsMainTable['can_upload_file'] = ColDataType.TINYTEXT
        
        # Feedback
        self.schemaHintsMainTable['feedback'] = ColDataType.TEXT
        self.schemaHintsMainTable['feedback_response_selected'] = ColDataType.TINYINT
        
        # Transcript
        self.schemaHintsMainTable['transcript_id'] = ColDataType.TEXT
        self.schemaHintsMainTable['transcript_code'] = ColDataType.TINYTEXT
        
        # Rubrics:
        self.schemaHintsMainTable['rubric_selection'] = ColDataType.INT
        self.schemaHintsMainTable['rubric_category'] = ColDataType.INT

        # Video:
        self.schemaHintsMainTable['video_id'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['video_code'] = ColDataType.TEXT
        self.schemaHintsMainTable['video_current_time'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['video_speed'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['video_old_time'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['video_new_time'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['video_seek_type'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['video_new_speed'] = ColDataType.TINYTEXT      
        self.schemaHintsMainTable['video_old_speed'] = ColDataType.TINYTEXT     

        # Book (PDF) reading:
        self.schemaHintsMainTable['book_interaction_type'] = ColDataType.TINYTEXT
        
        # problem_check:
        self.schemaHintsMainTable['success'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['answer_id'] = ColDataType.TEXT
        self.schemaHintsMainTable['hint'] = ColDataType.TEXT
        self.schemaHintsMainTable['hintmode'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['msg'] = ColDataType.TEXT
        self.schemaHintsMainTable['npoints'] = ColDataType.TINYINT
        self.schemaHintsMainTable['queuestate'] = ColDataType.TEXT
        
        # Used in problem_rescore:
        self.schemaHintsMainTable['orig_score'] = ColDataType.INT
        self.schemaHintsMainTable['new_score'] = ColDataType.INT
        self.schemaHintsMainTable['orig_total'] = ColDataType.INT
        self.schemaHintsMainTable['new_total'] = ColDataType.INT
        
        # For user group manipulations:
        self.schemaHintsMainTable['event_name'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['group_user'] = ColDataType.TINYTEXT
        self.schemaHintsMainTable['group_action'] = ColDataType.TINYTEXT #'add', 'remove'; called 'event' in JSON
        
        # ajax
        self.schemaHintsMainTable['position'] = ColDataType.INT # used in event ajax goto_position
        
        # When bad JSON is encountered, it gets put 
        # into the following field:
        self.schemaHintsMainTable['badly_formatted'] = ColDataType.TEXT
        
        # Foreign keys to auxiliary tables:
        self.schemaHintsMainTable['correctMap_fk'] = ColDataType.UUID
        self.schemaHintsMainTable['answer_fk'] = ColDataType.UUID
        self.schemaHintsMainTable['state_fk'] = ColDataType.UUID
        self.schemaHintsMainTable['load_info_fk'] = ColDataType.INT

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
        self.schemaStateTbl['done'] = ColDataType.TINYTEXT
        self.schemaStateTbl['problem_id'] = ColDataType.TINYTEXT
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
        self.schemaAnswerTbl['problem_id'] = ColDataType.TINYTEXT
        self.schemaAnswerTbl['answer'] = ColDataType.TEXT
        self.schemaAnswerTbl['course_id'] = ColDataType.TINYTEXT

        # Turn the SQL data types in the dict to column spec objects:
        for colName in self.schemaAnswerTbl.keys():
            colType = self.schemaAnswerTbl[colName]
            self.schemaAnswerTbl[colName] = ColumnSpec(colName, colType, self.jsonToRelationConverter)

        
        # Schema for CorrectMap table:
        self.schemaCorrectMapTbl = OrderedDict()
        self.schemaCorrectMapTbl['correct_map_id'] = ColDataType.UUID
        self.schemaCorrectMapTbl['answer_identifier'] = ColDataType.TEXT
        self.schemaCorrectMapTbl['correctness'] = ColDataType.TINYTEXT
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
        self.schemaInputStateTbl['problem_id'] = ColDataType.TINYTEXT
        self.schemaInputStateTbl['state'] = ColDataType.TEXT

        # Turn the SQL data types in the dict to column spec objects:
        for colName in self.schemaInputStateTbl.keys():
            colType = self.schemaInputStateTbl[colName]
            self.schemaInputStateTbl[colName] = ColumnSpec(colName, colType, self.jsonToRelationConverter)

        # Schema for Account table:
        self.schemaAccountTbl = OrderedDict()
        self.schemaAccountTbl['account_id'] = ColDataType.UUID
        self.schemaAccountTbl['screen_name'] = ColDataType.TEXT    # chosen screen name
        self.schemaAccountTbl['name'] = ColDataType.TEXT        # actual name
        self.schemaAccountTbl['anon_screen_name'] = ColDataType.TEXT
        self.schemaAccountTbl['mailing_address'] = ColDataType.TEXT
        self.schemaAccountTbl['zipcode'] = ColDataType.TINYTEXT      # Picked out from mailing_address
        self.schemaAccountTbl['country'] = ColDataType.TINYTEXT      # Picked out from mailing_address
        self.schemaAccountTbl['gender'] = ColDataType.TINYTEXT
        self.schemaAccountTbl['year_of_birth'] = ColDataType.TINYINT
        self.schemaAccountTbl['level_of_education'] = ColDataType.TINYTEXT
        self.schemaAccountTbl['goals'] = ColDataType.TEXT
        self.schemaAccountTbl['honor_code'] = ColDataType.TINYINT
        self.schemaAccountTbl['terms_of_service'] = ColDataType.TINYINT
        self.schemaAccountTbl['course_id'] = ColDataType.TEXT
        self.schemaAccountTbl['enrollment_action'] = ColDataType.TINYTEXT
        self.schemaAccountTbl['email'] = ColDataType.TEXT
        self.schemaAccountTbl['receive_emails'] = ColDataType.TINYTEXT

        # Turn the SQL data types in the dict to column spec objects:
        for colName in self.schemaAccountTbl.keys():
            colType = self.schemaAccountTbl[colName]
            self.schemaAccountTbl[colName] = ColumnSpec(colName, colType, self.jsonToRelationConverter)

        # Schema for LoadInfo table:
        self.schemaLoadInfoTbl = OrderedDict()
        self.schemaLoadInfoTbl['load_info_id'] = ColDataType.UUID
        self.schemaLoadInfoTbl['load_date_time'] = ColDataType.DATETIME
        self.schemaLoadInfoTbl['load_file'] = ColDataType.TEXT

        # Turn the SQL data types in the dict to column spec objects:
        for colName in self.schemaLoadInfoTbl.keys():
            colType = self.schemaLoadInfoTbl[colName]
            self.schemaLoadInfoTbl[colName] = ColumnSpec(colName, colType, self.jsonToRelationConverter)

        # Dict<IP,Datetime>: record each IP's most recent
        # activity timestamp (heartbeat or any other event).
        # Used to detect server downtimes: 
        self.downtimes = {}
                
        # Place to keep history for some rows, for which we want
        # to computer some on-the-fly aggregations:
        self.resultDict = {}

        # Create databases if needed:
        self.pushDBCreations()
        
        # Create main and auxiliary tables if appropriate:
        self.pushTableCreations(replaceTables)
        
        # Add an entry to the load_info table to reflect this
        # load file and start of load:
        loadInfoDict = OrderedDict()
        loadInfoDict['load_info_id'] = None # filled in by pushLoadInfo()
        loadInfoDict['load_date_time'] = self.jsonToRelationConverter.loadDateTime
        loadInfoDict['load_file'] = self.jsonToRelationConverter.loadFile
        self.currLoadInfoFK = self.pushLoadInfo(loadInfoDict)
        
    def setupMySqlDumpControlInstructions(self):

        # Preamble for MySQL dumps to make loads fast:
        self.dumpPreamble       = "/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;\n" +\
                        		  "/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;\n" +\
                        		  "/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;\n" +\
                        		  "/*!40101 SET NAMES utf8 */;\n" +\
                        		  "/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;\n" +\
                        		  "/*!40103 SET TIME_ZONE='+00:00' */;\n" +\
                        		  "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n" +\
                        		  "/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" +\
                        		  "/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;\n" +\
                        		  "/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;\n"
            
        # Preamble to table creation:
        self.dumpTableCreationPreamble = "/*!40101 SET @saved_cs_client     = @@character_set_client */;\n" +\
                                         "/*!40101 SET character_set_client = utf8 */;\n"
        
        # Construct the SQL statement that precedes INSERT statements:
        self.dumpInsertPreamble = "LOCK TABLES `%s` WRITE, `State` WRITE, `InputState` WRITE, `Answer` WRITE, `CorrectMap` WRITE, `LoadInfo` WRITE, `Account` WRITE;\n" % self.mainTableName +\
                            	  "/*!40000 ALTER TABLE `%s` DISABLE KEYS */;\n" % self.mainTableName +\
                            	  "/*!40000 ALTER TABLE `State` DISABLE KEYS */;\n" +\
                            	  "/*!40000 ALTER TABLE `InputState` DISABLE KEYS */;\n" +\
                            	  "/*!40000 ALTER TABLE `Answer` DISABLE KEYS */;\n" +\
                            	  "/*!40000 ALTER TABLE `CorrectMap` DISABLE KEYS */;\n" +\
                            	  "/*!40000 ALTER TABLE `LoadInfo` DISABLE KEYS */;\n" +\
                            	  "/*!40000 ALTER TABLE `Account` DISABLE KEYS */;\n"
             
        
        self.dumpPostscript1    =  "/*!40000 ALTER TABLE `%s` ENABLE KEYS */;\n" % self.mainTableName +\
                            		"/*!40000 ALTER TABLE `State` ENABLE KEYS */;\n" +\
                            		"/*!40000 ALTER TABLE `InputState` ENABLE KEYS */;\n" +\
                            		"/*!40000 ALTER TABLE `Answer` ENABLE KEYS */;\n" +\
                            		"/*!40000 ALTER TABLE `CorrectMap` ENABLE KEYS */;\n" +\
                            		"/*!40000 ALTER TABLE `LoadInfo` ENABLE KEYS */;\n" +\
                            		"/*!40000 ALTER TABLE `Account` ENABLE KEYS */;\n" +\
                            		"UNLOCK TABLES;\n"           


        # In between Postscript1 and Postscript 2goes the Account table copy-to-private-db, and drop in Edx:
        self.dumpPostscript2 =  	"/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;\n" +\
		                    	    "/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;\n" +\
		                    	    "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n" +\
		                    	    "/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;\n" +\
		                    	    "/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;\n" +\
		                    	    "/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;\n" +\
		                    	    "/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;\n" +\
		                    	    "/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;\n"

        
    def processOneJSONObject(self, jsonStr, row):
        '''
        This method is the main dispatch for track log event_types.
        It's a long method, and should be partitioned. First, bookkeeping
        fields are filled in that are common to all events, such as the 
        user agent, and the reference into the LoadInfo table that shows
        on which date this row was loaded. Then a long 'case' statement
        calls handler methods depending on the incoming track log's event_type.  
        
        Given one line from the EdX Track log, produce one row
        of relational output. Return is an array of values, the 
        same that is passed in. On the way, the partner JSONToRelation
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
        # No error has occurred yet in processing this JSON str:
        self.errorOccurred = False
        self.jsonToRelationConverter.bumpLineCounter()
        try:
            # Turn top level JSON object to dict:
            try:
                record = json.loads(str(jsonStr))
            except ValueError as e:
                # Try it again after cleaning up the JSON
                # We don't do the cleanup routinely to save
                # time.
                try:
                    cleanJsonStr = self.makeJSONSafe(jsonStr)
                    record = json.loads(cleanJsonStr)
                except ValueError as e:
                    # Pull out what we can, and place in 'badly_formatted' column
                    self.rescueBadJSON(jsonStr, row=row)                
                    raise ValueError('Ill formed JSON: %s' % `e`)
    
            # Dispense with the fields common to all events, except event,
            # which is a nested JSON string. Results will be 
            # in self.resultDict:
            self.handleCommonFields(record, row)
            
            # If the event was fully handled in
            # handleCommonFields(), then we're done:
            if self.finishedRow:
                return
            
            # Now handle the different types of events:
            
            try:
                eventType = record['event_type']
            except KeyError:
                raise KeyError("No event type")
            
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
                raise ValueError("No event time or server IP.")
            except ValueError:
                raise ValueError("Bad event time format: '%s'" % eventTimeStr)
            
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
            
            # If eventType is "/" then it was a ping, no more to be done:
            if eventType == '/':
                row = []
                return
            elif eventType == 'page_close':
                # The page ID was already recorded in the common fields:
                return
            
            # For any event other than heartbeat, we need to look
            # at the event field, which is an embedded JSON *string*
            # Turn that string into a (nested) Python dict. Though
            # *sometimes* the even *is* a dict, not a string, as in
            # problem_check_fail:
            try:
                eventJSONStrOrDict = record['event']
            except KeyError:
                raise ValueError("Event of type %s has no event field" % eventType)
            
            try:
                event = json.loads(eventJSONStrOrDict)
            except TypeError:
                # Was already a dict
                event = eventJSONStrOrDict
            except Exception as e:
                # Try it again after cleaning up the JSON
                # We don't do the cleanup routinely to save
                # time.
                try:
                    cleanJSONStr = self.makeJSONSafe(eventJSONStrOrDict)
                    event = json.loads(cleanJSONStr)
                except ValueError:
                    # Last ditch: event types like goto_seq, need backslashes removed:
                    event = json.loads(re.sub(r'\\','',eventJSONStrOrDict))
                except Exception as e1:                
                    row = self.rescueBadJSON(str(record), row=row)
                    raise ValueError('Bad JSON; saved in col badlyFormatted: event_type %s (%s)' % (eventType, `e1`))
                    return
            
            if eventType == 'seq_goto' or\
               eventType == 'seq_next' or\
               eventType == 'seq_prev':
            
                row = self.handleSeqNav(record, row, event, eventType)
                return
            
            elif eventType == '/accounts/login':
                # Already recorded everything needed in common-fields
                return
            
            elif eventType == '/login_ajax':
                row = self.handleAjaxLogin(record, row, event, eventType)
                return
            
            elif eventType == 'problem_check':
                # Note: some problem_check cases are also handled in handleAjaxLogin()
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
            
            elif eventType == 'show_transcript' or eventType == 'hide_transcript':
                row = self.handleShowHideTranscript(record, row, event)
                return
            
            elif eventType == 'play_video' or\
                 eventType == 'pause_video' or\
                 eventType == 'load_video':
                row = self.handleVideoPlayPause(record, row, event)
                return

            elif eventType == 'seek_video':
                row = self.handleVideoSeek(record, row, event)
                return
                
            elif eventType == 'speed_change_video':
                row = self.handleVideoSpeedChange(record, row, event)
                return
                
            elif eventType == 'fullscreen':
                row = self.handleFullscreen(record, row, event)
                return
                
            elif eventType == 'not_fullscreen':
                row = self.handleNotFullscreen(record, row, event)
                return
                
            elif eventType == '/dashboard':
                # Nothing additional to grab:
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
            
            elif eventType == 'problem_rescore_fail':
                row = self.handleProblemRescoreFail(record, row, event)
                return
            
            elif eventType == 'problem_rescore':
                row = self.handleProblemRescore(record, row, event)
                return
            
            elif eventType == 'save_problem_fail' or\
                 eventType == 'save_problem_success' or\
                 eventType == 'save_problem_check' or\
                 eventType == 'reset_problem_fail':
                row = self.handleSaveProblemFailSuccessCheckOrReset(record, row, event)
                return
            
            elif eventType == 'reset_problem':
                row = self.handleResetProblem(record, row, event)
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
            
            elif eventType == '/create_account':
                self.handleCreateAccount(record, row, event)
                return
            
            elif eventType == 'problem_graded':
                # Need to look at return, b/c this
                # method handles all its own pushing:
                row = self.handleProblemGraded(record, row, event)
                return

            elif eventType == 'change-email-settings':
                self.handleReceiveEmail(record, row, event)
                return
                
            
            elif eventType[0] == '/':
                self.handlePathStyledEventTypes(record, row, event)
                return
            
            else:
                self.logWarn("Unknown event type '%s' in tracklog row %s" % (eventType, self.jsonToRelationConverter.makeFileCitation()))
                return
        except Exception as e:
            # Note whether any error occurred, so that
            # the finally clause can act accordingly:
            self.errorOccurred = True
            # Re-raise same error:
            raise
        finally:
            self.reportProgressIfNeeded()
            # If above code generated anything to INSERT into SQL
            # table, do that now. If row is None, then nothing needs
            # to be inserted (e.g. heartbeats):
            if row is not None and len(row) != 0 and not self.errorOccurred:
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
        @return: table name, string with all comma-separated column names, and values as a 3-tuple
        @rtype: (String, String, [<any>])
        '''
        if colNamesToSet is None and targetTableName != self.mainTableName:
            raise ValueError("If colNamesToSet is None, the target table must be the main table whose name was passed into __init__(); was %s" % targetTableName)
        
        if colNamesToSet is not None:
            return (targetTableName, ','.join(colNamesToSet), row)
        else:
            return (targetTableName, ','.join(self.colNamesByTable[targetTableName]), row)
    
    def pushDBCreations(self):
        createStatement = "CREATE DATABASE IF NOT EXISTS %s;\n" % 'Edx'
        self.jsonToRelationConverter.pushString(createStatement)
        
        createStatement = "CREATE DATABASE IF NOT EXISTS %s;\n" % 'EdxPrivate'
        self.jsonToRelationConverter.pushString(createStatement)
        
        
    def pushTableCreations(self, replaceTables):
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
        self.jsonToRelationConverter.pushString(self.dumpPreamble)
        if replaceTables:
            # Need to suppress foreign key checks, so that we
            # can DROP the tables; this includes the main Account tbl in db EdxPrivate
            # and any left-over tmp Account tbl in Edx:
            self.jsonToRelationConverter.pushString('DROP TABLE IF EXISTS %s, Answer, InputState, CorrectMap, State, Account, EdxPrivate.Account, LoadInfo;\n' % self.mainTableName)


        # Initialize col row arrays for each table. These
        # are used in GenericJSONParser.setValInRow(), where
        # the column names are added as values for them are
        # set:
        self.colNamesByTable[self.mainTableName] = []
        self.colNamesByTable['Answer'] = []
        self.colNamesByTable['CorrectMap'] = []
        self.colNamesByTable['InputState'] = []
        self.colNamesByTable['State'] = []
        self.colNamesByTable['Account'] = []
        self.colNamesByTable['LoadInfo'] = []

        # Load acceleration for table creation:
        self.jsonToRelationConverter.pushString(self.dumpTableCreationPreamble)

        self.createAnswerTable()
        self.createCorrectMapTable()
        self.createInputStateTable()
        self.createStateTable()
        self.createAccountTable()
        self.createLoadInfoTable()        
        self.createMainTable()
        
        # Several switches to speed up the bulk load:
        self.jsonToRelationConverter.pushString(self.dumpInsertPreamble)
    
    def genOneCreateStatement(self, tableName, schemaDict, primaryKeyName=None, foreignKeyColNames=None, autoincrement=False):
        '''
        Given a table name and its ordered schema dict, generate
        a basic SQL CREATE TABLE statement. Primary and foreign key names may
        optionally be provided. An example of the most complex create statement generated
        by this method is::
        CREATE TABLE myTable
            col1 VARCHAR(40) NOT NULL Primary Key,
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
        @param autoincrement: whether this table's primary key is autoincrement
        @type autoincrement: Boolean
        '''
        createStatement = "CREATE TABLE IF NOT EXISTS %s (\n" % tableName
        for colname in schemaDict.keys():
            if colname == primaryKeyName:
                if autoincrement:
                    createStatement += "%s NOT NULL PRIMARY KEY AUTO_INCREMENT,\n" % schemaDict[colname].getSQLDefSnippet()
                else:
                    createStatement += "%s NOT NULL PRIMARY KEY,\n" % schemaDict[colname].getSQLDefSnippet()
            else:
                createStatement += "%s NOT NULL,\n" % schemaDict[colname].getSQLDefSnippet()
        if foreignKeyColNames is not None:
            for foreignTableName in foreignKeyColNames.keys():
                (localFldName, foreignKeyName) = foreignKeyColNames[foreignTableName]
                createStatement += "    FOREIGN KEY(%s) REFERENCES %s(%s) ON DELETE CASCADE,\n" % (localFldName, foreignTableName, foreignKeyName) 
                 
        # Cut away the comma and newline after the last column spec,
        # and add newline, closing paren, and semicolon:
        createStatement = createStatement[0:-2] + '\n    ) ENGINE=MyISAM;\n'
        return createStatement 
            

    def createAnswerTable(self):
        createStatement = self.genOneCreateStatement('Answer', self.schemaAnswerTbl, primaryKeyName='answer_id')
        self.jsonToRelationConverter.pushString(createStatement)
        # Tell the output module (output_disposition.OutputFile) that
        # it needs to know about a new table. That module will create
        # a CSV file and CSV writer to which rows destined for this
        # table will be written:
        self.jsonToRelationConverter.startNewTable('Answer', self.schemaAnswerTbl)
        

    def createCorrectMapTable(self):
        createStatement = self.genOneCreateStatement('CorrectMap', 
                                                     self.schemaCorrectMapTbl, 
                                                     primaryKeyName='correct_map_id')        
        self.jsonToRelationConverter.pushString(createStatement)
        # Tell the output module (output_disposition.OutputFile) that
        # it needs to know about a new table. That module will create
        # a CSV file and CSV writer to which rows destined for this
        # table will be written:
        self.jsonToRelationConverter.startNewTable('CorrectMap', self.schemaCorrectMapTbl)

    def createInputStateTable(self):
        createStatement = self.genOneCreateStatement('InputState', 
                                                     self.schemaInputStateTbl, 
                                                     primaryKeyName='input_state_id')        
        self.jsonToRelationConverter.pushString(createStatement)
        # Tell the output module (output_disposition.OutputFile) that
        # it needs to know about a new table. That module will create
        # a CSV file and CSV writer to which rows destined for this
        # table will be written:
        self.jsonToRelationConverter.startNewTable('InputState', self.schemaInputStateTbl)

        
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
        # Tell the output module (output_disposition.OutputFile) that
        # it needs to know about a new table. That module will create
        # a CSV file and CSV writer to which rows destined for this
        # table will be written:
        self.jsonToRelationConverter.startNewTable('State', self.schemaStateTbl)
        

    def createAccountTable(self):
        # Create a tmp Account tbl in the Edx db for the load
        # process:
        createStatement = self.genOneCreateStatement('Account', 
                                                     self.schemaAccountTbl, 
                                                     primaryKeyName='account_id'
                                                     ) 
        self.jsonToRelationConverter.pushString(createStatement)

        # And one in db EdxPrivate, if it doesn't exist:
        createStatement = self.genOneCreateStatement('EdxPrivate.Account', 
                                                     self.schemaAccountTbl, 
                                                     primaryKeyName='account_id'
                                                     ) 
        self.jsonToRelationConverter.pushString(createStatement)
        # Tell the output module (output_disposition.OutputFile) that
        # it needs to know about a new table. That module will create
        # a CSV file and CSV writer to which rows destined for this
        # table will be written:
        self.jsonToRelationConverter.startNewTable('Account', self.schemaAccountTbl)
        

    def createLoadInfoTable(self):
        createStatement = self.genOneCreateStatement('LoadInfo', 
                                                     self.schemaLoadInfoTbl,
                                                     primaryKeyName='load_info_id'
                                                     ) 
        self.jsonToRelationConverter.pushString(createStatement)
        # Tell the output module (output_disposition.OutputFile) that
        # it needs to know about a new table. That module will create
        # a CSV file and CSV writer to which rows destined for this
        # table will be written:
        self.jsonToRelationConverter.startNewTable('LoadInfo', self.schemaLoadInfoTbl)

    def createMainTable(self):
        # Make the foreign keys information dict ordered. Doesn't
        # matter to SQL engine, but makes unittesting easier, b/c
        # order of foreign key declarations will be constant on
        # each run:
        foreignKeysDict = OrderedDict()
        foreignKeysDict['CorrectMap'] = ('correctMap_fk', 'correct_map_id')
        foreignKeysDict['Answer'] = ('answer_fk', 'answer_id')
        foreignKeysDict['State'] = ('state_fk', 'state_id')
        foreignKeysDict['LoadInfo'] = ('load_info_fk', 'load_info_id')
        createStatement = self.genOneCreateStatement(self.mainTableName, 
                                                     self.schemaHintsMainTable,
                                                     primaryKeyName='_id', 
                                                     foreignKeyColNames=foreignKeysDict,
                                                     autoincrement=False)        
        self.jsonToRelationConverter.pushString(createStatement)
        # Tell the output module (output_disposition.OutputFile) that
        # it needs to know about a new table. That module will create
        # a CSV file and CSV writer to which rows destined for this
        # table will be written:
        self.jsonToRelationConverter.startNewTable(self.mainTableName, self.schemaHintsMainTable)

    def handleCommonFields(self, record, row):
        self.currCourseDisplayName = None
        # Create a unique tuple key and event key  for this event:
        self.setValInRow(row, '_id', self.getUniqueID())
        self.setValInRow(row, 'event_id', self.getUniqueID())
        self.finishedRow = False
        for fldName in self.commonFldNames:
            # Default non-existing flds to null:
            val = record.get(fldName, None)
            # Ensure there are no embedded single quotes or CR/LFs;
            # takes care of name = O'Brian 
            if isinstance(val, basestring):
                val = self.makeInsertSafe(val)
            # if the event_type starts with a '/', followed by a 
            # class ID and '/about', treat separately:
            if fldName == 'event_type' and val is not None:
                if val[0] == '/' and val[-6:] == '/about':
                    self.setValInRow(row, 'course_id', val[0:-6])
                    val = 'about'
                    self.finishedRow = True
                elif val.find('/password_reset_confirm') == 0:
                    val = 'password_reset_confirm'
                    self.finishedRow = True
                elif val == '/networking/':
                    val = 'networking'
                    self.finishedRow = True
            elif fldName == 'course_id':
                #(fullCourseName, course_id) = self.get_course_id(record.get('event', None))  # @UnusedVariable
                (fullCourseName, course_id, displayName) = self.get_course_id(record)  # @UnusedVariable
                val = course_id
                # Make course_id available for places where rows are added to the Answer table.
                # We stick the course_id there for convenience.
                self.currCourseID = course_id
                self.currCourseDisplayName = displayName
            elif fldName == 'course_display_name':
                if self.currCourseDisplayName is not None:
                    val = self.currCourseDisplayName
                else:
                    (fullCourseName, course_id, displayName) = self.get_course_id(record)  # @UnusedVariable
                    val = displayName
            elif fldName == 'username':
                # Hash the name, and store in MySQL col 'anon_screen_name':
                val = self.hashGeneral(val)
                fldName = 'anon_screen_name'
                
            self.setValInRow(row, fldName, val)
        # Add the foreign key that points to the current row in the load info table:
        self.setValInRow(row, 'load_info_fk', self.currLoadInfoFK)
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

        event = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in sequence navigation event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        oldIndex = event.get('old', 0)
        newIndex = event.get('new', 0)
        try:
            seqID    = event['id']
        except KeyError:
            self.logWarn("Track log line %s with event type %s is missing sequence id" %
                         (self.jsonToRelationConverter.makeFileCitation(), eventType)) 
            return row
        self.setValInRow(row, 'sequence_id', seqID)
        self.setValInRow(row, 'goto_from', oldIndex)
        self.setValInRow(row, 'goto_dest', newIndex)
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
        event = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in problem_check event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        # Go through all the top-level problem_check event fields first:
        self.setValInRow(row, 'success', event.get('success', '')) 
        self.setValInRow(row, 'attempts', event.get('attempts', -1))
        problem_id = event.get('problem_id', '')
        self.setValInRow(row, 'problem_id', problem_id)
        # Try to look up the human readable display name
        # of the problem, and insert it into the main
        # table's resource_display_name field:
        self.setResourceDisplayName(row, problem_id)

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
            # Receive all the Answer table keys generated for
            # the answers, and a dict mapping each key
            # to the problem ID to which that key's row
            # in the Answer refers:
            (answersFKeys, answerToProblemMap) = self.pushAnswers(answersDict)
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
            self.setValInRow(row, 'correctMap_fk', correctMapFKey if correctMapFKey is not None else '')
            self.setValInRow(row, 'answer_fk', answerFKey if answerFKey is not None else '')
            if answerFKey is not None:
                # For convenience: enter the Answer's problem ID 
                # in the main table's problemID field:
                problemID = answerToProblemMap[answerFKey] if answerToProblemMap[answerFKey] is not None else ''
                self.setValInRow(row, 'problem_id', problemID) 
            self.setValInRow(row, 'state_fk', stateFKey if stateFKey is not None else '')
            rowInfoTriplet = self.resultTriplet(row, self.mainTableName)
            self.jsonToRelationConverter.pushToTable(rowInfoTriplet)
            # The next row keeps its eventID, but needs its own
            # primary key (in _id):
            self.setValInRow(row, '_id', self.getUniqueID())
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
                answersDict[problemID] = self.makeInsertSafe(answerChoice)
            except ValueError:
                # Badly formatted GET parameter element:
                self.logWarn("Track log line %s: badly formatted problemID/answerChoice GET parameter pair: '%s'." %\
                             (self.jsonToRelationConverter.makeFileCitation(), str(event)))
                return row
        if len(answersDict) > 0:
            # Receive all the Answer table keys generated for
            # the answers, and a dict mapping each key
            # to the problem ID to which that key's row
            # in the Answer refers:
            
            (answersFKeys, answerToProblemMap) = self.pushAnswers(answersDict)
        else:
            answersFKeys = []
        # Now need to generate enough near-replicas of event
        # entries to cover all answers, putting one Answer
        # table key into the answers foreign key column each
        # time:
        for answerFKey in answersFKeys:
            # Fill in one main table row.
            self.setValInRow(row, 'answer_fk', answerFKey, self.mainTableName)
            if answerFKey is not None:
                # For convenience: enter the Answer's problem ID 
                # in the main table's problemID field:
                problemID = answerToProblemMap[answerFKey]
                self.setValInRow(row, 'problem_id', problemID)
                # Try to look up the human readable display name
                # of the problem, and insert it into the main
                # table's resource_display_name field:
                self.setResourceDisplayName(row, problemID)
                
            rowInfoTriplet = self.resultTriplet(row, self.mainTableName)
            self.jsonToRelationConverter.pushToTable(rowInfoTriplet)
            # The next row keeps its eventID, but needs its own
            # primary key (in _id):
            self.setValInRow(row, '_id', self.getUniqueID())
            
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
            hint = oneCorrectMapDict.get('hint', '')
            if hint is None:
                hint = ''
            hintmode = oneCorrectMapDict.get('hintmode', '')
            if hintmode is None:
                hintmode = ''
            correctness = oneCorrectMapDict.get('correctness', '')
            if correctness is None:
                correctness = ''
            msg = oneCorrectMapDict.get('msg', '')
            if msg is None:
                msg = ''
            else:
                msg = self.makeInsertSafe(msg)
            npoints = oneCorrectMapDict.get('npoints', -1)
            if npoints is None:
                npoints = -1
            # queuestate:
            # Dict {key:'', time:''} where key is a secret string, and time is a string dump
            #        of a DateTime object in the format '%Y%m%d%H%M%S'. Is None when not queued
            queuestate = oneCorrectMapDict.get('queuestate', '')
            if queuestate is None:
                queuestate = ''
            if len(queuestate) > 0:
                queuestate_key  = queuestate.get('key', '')
                queuestate_time = queuestate.get('time', '')
                queuestate = queuestate_key + ":" + queuestate_time 
            
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
        @return: array of keys created for answers in answersDict, and a dict mapping each key to the 
                 corresponding problem ID
        @rtype: ([String], Dict<String,String>
        '''
        answersKeys = []
        answerToProblemMap = {}
        for problemID in answersDict.keys():
            answer = answersDict.get(problemID, None)
            # answer could be an array of Unicode strings, or
            # a single string: u'choice_1', or [u'choice_1'] or [u'choice_1', u'choice_2']
            # below: turn into latin1, comma separated single string.
            # Else Python prints the "u'" into the INSERT statement
            # and makes MySQL unhappy:
            if answer is not None:
                if isinstance(answer, list):
                    answer = self.makeInsertSafe(','.join(answer))
                else:
                    answer = self.makeInsertSafe(answer)
                answersKey = self.getUniqueID()
                answerToProblemMap[answersKey] = problemID
                answersKeys.append(answersKey)
                answerValues = [answersKey,          # answer_id fld 
                                problemID,           # problem_id fld
                                answer,
                                self.currCourseID
                                ]
                self.jsonToRelationConverter.pushToTable(self.resultTriplet(answerValues, 'Answer', self.schemaAnswerTbl.keys()))
        return (answersKeys, answerToProblemMap)

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
            # Receive all the Answer table keys generated for
            # the answers, and a dict mapping each key
            # to the problem ID to which that key's row
            # in the Answer refers:
            (studentAnswersFKeys, answerToProblemMap) = self.pushAnswers(studentAnswersDict)  # @UnusedVariable
        else:
            studentAnswersFKeys = []
        seed = stateDict.get('seed', '')
        done = stateDict.get('done', '')
        # Can't use int for SQL, b/c Python writes as 'True'
        done = str(done)
        problemID = stateDict.get('problem_id', '')
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
            
            studentAnswerFKey = studentAnswerFKey if studentAnswerFKey is not None else ''
            correctMapFKey = correctMapFKey if correctMapFKey is not None else ''
            inputStateFKey = inputStateFKey if inputStateFKey is not None else ''
            # Unique ID that ties all these related rows together:
            state_id = self.getUniqueID()
            stateFKeys.append(state_id)
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
                # If prob value is an empty dict (as in example above),
                # then make it an empty str, else the value will show up as
                # {} in the VALUES part of the INSERT statements, and
                # MySQL will get cranky:
                try:
                    if len(inputStateProbVal) == 0:
                        inputStateProbVal = ''
                except:
                    pass
                inputStateKey = self.getUniqueID()
                inputStateKeys.append(inputStateKey)
                inputStateValues = [inputStateKey,
                                    problemID,
                                    inputStateProbVal
                                    ]
                self.jsonToRelationConverter.pushToTable(self.resultTriplet(inputStateValues, 'InputState', self.schemaInputStateTbl.keys()))
        return inputStateKeys
        
    def pushAccountInfo(self, accountDict):
        '''
        Takes an ordered dict with the fields of
        a create_account event. Pushes the values
        (name, address, email, etc.) as a row to the
        Account table, and returns the resulting row
        primary key for inclusion in the main table's
        accountFKey field. 
        @param accountDict:
        @type accountDict:
        '''
        accountDict['account_id'] = self.getUniqueID()
        self.jsonToRelationConverter.pushToTable(self.resultTriplet(accountDict.values(), 'Account', self.schemaAccountTbl.keys()))
        return
        
    def pushLoadInfo(self, loadDict):
        loadDict['load_info_id'] = self.getUniqueID()
        self.jsonToRelationConverter.pushToTable(self.resultTriplet(loadDict.values(), 'LoadInfo', self.schemaLoadInfoTbl.keys()))
        return loadDict['load_info_id']
    
    def handleProblemReset(self, record, row, event):
        '''
        Gets a event string like this::
           "{\"POST\": {\"id\": [\"i4x://Engineering/EE222/problem/e68cfc1abc494dfba585115792a7a750@draft\"]}, \"GET\": {}}"
        After turning this JSON into Python::
           {u'POST': {u'id': [u'i4x://Engineering/EE222/problem/e68cfc1abc494dfba585115792a7a750@draft']}, u'GET': {}}
        
        Or the event could be simpler, like this::
           u'input_i4x-Engineering-QMSE01-problem-dce5fe9e04be4bc1932efb05a2d6db68_2_1=2'
           
        In the latter case we just put that string into the problemID field
        of the main table
        
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
        
        # From "{\"POST\": {\"id\": [\"i4x://Engineering/EE368/problem/ab656f3cb49e4c48a6122dc724267cb6@draft\"]}, \"GET\": {}}"
        # make a dict:
        postGetDict = self.ensureDict(event)
        if postGetDict is None:
            if isinstance(event, basestring):
                self.setValInRow(row, 'problem_id', event)
                # Try to look up the human readable display name
                # of the problem, and insert it into the main
                # table's resource_display_name field:
                self.setResourceDisplayName(row, event)
                
                return row
            else:
                self.logWarn("Track log line %s: event is not a dict in problem_reset event: '%s'" %\
                             (self.jsonToRelationConverter.makeFileCitation(), str(event)))
                return row
    
        # Get the POST field's problem id array:
        try:
            problemIDs = postGetDict['POST']['id']
        except KeyError:
            self.logWarn("Track log line %s with event type problem_reset contains event without problem ID array: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), event))
        self.setValInRow(row, 'problem_id', problemIDs)
        # Try to look up the human readable display name
        # of the problem, and insert it into the main
        # table's resource_display_name field:
        self.setResourceDisplayName(row, problemIDs)
        
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

        # From "{\"POST\": {\"id\": [\"i4x://Engineering/EE368/problem/ab656f3cb49e4c48a6122dc724267cb6@draft\"]}, \"GET\": {}}"
        # make a dict:
        postGetDict = self.ensureDict(event)
        if postGetDict is None:
            self.logWarn("Track log line %s: event is not a dict in problem_show event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        # Get the problem id:
        try:
            problemID = postGetDict['problem']
        except KeyError:
            self.logWarn("Track log line %s with event type problem_show contains event without problem ID: '%s'" %
                         (self.jsonToRelationConverter.makeFileCitation(), event))
            return row
        self.setValInRow(row, 'problem_id', problemID)
        # Try to look up the human readable display name
        # of the problem, and insert it into the main
        # table's resource_display_name field:
        self.setResourceDisplayName(row, problemID)
        return row

    def handleProblemSave(self, record, row, event):
        '''
        Gets a event string like this::
		   "\"input_i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_2_1=13.4&
		      input_i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_3_1=2.49&
		      input_i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_4_1=13.5&
		      input_i4x-Medicine-HRP258-problem-44c1ef4e92f648b08adbdcd61d64d558_5_1=3\""        
		           
        After splitting this string on '&', and then each result on '=', we add the 
        problemID/solution pairs to the Answer table:

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

        if not isinstance(event, basestring):
            self.logWarn("Track log line %s: event is not a string in problem save event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        probIDSolPairs = event.split('&')
        answersDict = {}
        for probIDSolPair in probIDSolPairs: 
            (problemID, choice) = probIDSolPair.split('=')
            answersDict[problemID] = choice

        # Add answer/solutions to Answer table.
        # Receive all the Answer table keys generated for
        # the answers, and a dict mapping each key
        # to the problem ID to which that key's row
        # in the Answer refers:
        if len(answersDict) > 0:
            (answersFKeys, answerToProblemMap) = self.pushAnswers(answersDict)
        else:
            answersFKeys = []

        # Now need to generate enough near-replicas of event
        # entries to cover all answer 
        # foreign key entries that were created:
        for answerFKey in answersFKeys: 
            # Fill in one main table row.
            self.setValInRow(row, 'answer_fk', answerFKey)
            if answerFKey is not None:
                # For convenience: enter the Answer's problem ID 
                # in the main table's problemID field:
                problemID = answerToProblemMap[answerFKey]
                self.setValInRow(row, 'problem_id', problemID)
                # Try to look up the human readable display name
                # of the problem, and insert it into the main
                # table's resource_display_name field:
                self.setResourceDisplayName(row, problemID)
                
                rowInfoTriplet = self.resultTriplet(row, self.mainTableName)
                self.jsonToRelationConverter.pushToTable(rowInfoTriplet)
                # The next row keeps its eventID, but needs its own
                # primary key (in _id):
                self.setValInRow(row, '_id', self.getUniqueID())

        # Return empty row, b/c we already pushed all necessary rows:
        return []


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

        "{\"location\":\"i4x://Education/EDUC115N/combinedopenended/4abb8b47b03d4e3b8c8189b3487f4e8d\"}"
        # make a dict:
        locationDict = self.ensureDict(event)
        if locationDict is None:
            self.logWarn("Track log line %s: event is not a dict in problem_show/hide event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        # Get location:
        try:
            location = locationDict['location']
        except KeyError:
            self.logWarn("Track log line %s: no location field provided in problem hide or show event: '%s'" %\
             (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        self.setValInRow(row, 'question_location', location)
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

        # From "{\"location\":\"i4x://Education/EDUC115N/combinedopenended/4abb8b47b03d4e3b8c8189b3487f4e8d\",\"selection\":\"1\",\"category\":0}"
        # make a dict:
        locationDict = self.ensureDict(event)
        if locationDict is None:
            self.logWarn("Track log line %s: event is not a dict in select_rubric event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        try:
            location = locationDict['location']
            selection = locationDict['selection']
            category = locationDict['category']
        except KeyError:
            self.logWarn("Track log line %s: missing location, selection, or category in event type select_rubric." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        self.setValInRow(row, 'question_location', location)
        self.setValInRow(row, 'rubric_selection', selection)
        self.setValInRow(row, 'rubric_category', category)
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
        
        # From "{\"value\":\"5\"}"
        # make a dict:
        valDict = self.ensureDict(event)
        if valDict is None:
            self.logWarn("Track log line %s: event is not a dict in oe_feedback_response_selected event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        try:
            value = valDict['value']
        except KeyError:
            self.logWarn("Track log line %s: missing 'value' field in event type oe_feedback_response_selected." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        self.setValInRow(row, 'feedback_response_selected', value)

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

        valsDict = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in video play/pause: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        videoID = valsDict.get('id', None)
        videoCode = valsDict.get('code', None)
        videoCurrentTime = str(valsDict.get('currentTime', None))
        videoSpeed = str(valsDict.get('speed', None))

        self.setValInRow(row, 'video_id', str(videoID))
        self.setValInRow(row, 'video_code', str(videoCode))
        self.setValInRow(row, 'video_current_time', str(videoCurrentTime))
        self.setValInRow(row, 'video_speed', str(videoSpeed))
        return row

    def handleVideoSeek(self, record, row, event):
        '''
        For play_video, event looks like this::
           "{\"id\":\"i4x-Medicine-HRP258-videoalpha-413d6a45b82848339ab5fd3836dfb928\",
             \"code\":\"html5\",
             \"old_time\":308.506103515625,
             \"new_time\":290,
             \"type\":\"slide_seek\"}"        
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event text in video seek." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        valsDict = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in video play/pause: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        videoID = valsDict.get('id', None)
        videoCode = valsDict.get('code', None)
        videoOldTime = str(valsDict.get('old_time', None))
        videoNewTime = str(valsDict.get('new_time', None))
        videoSeekType = valsDict.get('type', None)
            
        self.setValInRow(row, 'video_id', videoID)
        self.setValInRow(row, 'video_code', videoCode)
        self.setValInRow(row, 'video_old_time', videoOldTime)
        self.setValInRow(row, 'video_new_time', videoNewTime)
        self.setValInRow(row, 'video_seek_type', videoSeekType)
        return row

    def handleVideoSpeedChange(self, record, row, event):
        '''
        Events look like this::
           "{\"id\":\"i4x-Medicine-HRP258-videoalpha-7cd4bf0813904612bcd583a73ade1d54\",
             \"code\":\"html5\",
             \"currentTime\":1.6694719791412354,
             \"old_speed\":\"1.50\",
             \"new_speed\":\"2.0\"}"        
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event text in video speed change." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        valsDict = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in video speed change: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        videoID = valsDict.get('id', None)
        videoCode = valsDict.get('code', None)
        videoCurrentTime = str(valsDict.get('currentTime', None))
        videoOldSpeed = str(valsDict.get('old_speed', None))
        videoNewSpeed = str(valsDict.get('new_speed', None))
            
        self.setValInRow(row, 'video_id', videoID)
        self.setValInRow(row, 'video_code', videoCode)
        self.setValInRow(row, 'video_current_time', videoCurrentTime)
        self.setValInRow(row, 'video_old_speed', videoOldSpeed)
        self.setValInRow(row, 'video_new_speed', videoNewSpeed)
                
        return row


    def handleFullscreen(self, record, row, event):
        '''
        Events look like this::
           "{\"id\":\"i4x-Medicine-HRP258-videoalpha-4b200d3944cc47e5ae3ad142c1006075\",\"code\":\"html5\",\"currentTime\":348.4132080078125}"    
        @param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event text event type fullscreen." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        valsDict = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in fullscreen: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        videoID = valsDict.get('id', None)
        videoCode = valsDict.get('code', None)
        videoCurrentTime = str(valsDict.get('currentTime', None))

        self.setValInRow(row, 'video_id', videoID)
        self.setValInRow(row, 'video_code', videoCode)
        self.setValInRow(row, 'video_current_time', videoCurrentTime)
        return row
        
    def handleNotFullscreen(self, record, row, event):
        '''
        Events look like this::
           "{\"id\":\"i4x-Medicine-HRP258-videoalpha-c5cbefddbd55429b8a796a6521b9b752\",\"code\":\"html5\",\"currentTime\":661.1010131835938}"        
        @param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event text event type fullscreen." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        valsDict = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in not_fullscreen: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        videoID = valsDict.get('id', None)
        videoCode = valsDict.get('code', None)
        videoCurrentTime = str(valsDict.get('currentTime', None))

        self.setValInRow(row, 'video_id', videoID)
        self.setValInRow(row, 'video_code', videoCode)
        self.setValInRow(row, 'video_current_time', videoCurrentTime)
        return row
    
    def handleBook(self, record, row, event):
        '''
        No example of book available
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event text in book event type." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        # Make a dict from the string:
        valsDict = self.ensureDict(event)
        if valsDict is None:
            self.logWarn("Track log line %s: event is not a dict in book event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        bookInteractionType = valsDict.get('type', None)
        bookOld = valsDict.get('old', None)
        bookNew = valsDict.get('new', None)
        if bookInteractionType is not None:
            self.setValInRow(row, 'book_interaction_type', bookInteractionType)
        if bookOld is not None:            
            self.setValInRow(row, 'goto_from', bookOld)
        if bookNew is not None:            
            self.setValInRow(row, 'goto_dest', bookNew)
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
        
        event = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in handle showanswer event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        try:
            problem_id = event['problem_id']
        except KeyError:
            self.logWarn("Track log line %s: showanswer event does not include a problem ID: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        self.setValInRow(row, 'problem_id', problem_id)
        # Try to look up the human readable display name
        # of the problem, and insert it into the main
        # table's resource_display_name field:
        self.setResourceDisplayName(row, problem_id)

        return row

    def handleShowHideTranscript(self, record, row, event):
        '''
        Events look like this::
            "{\"id\":\"i4x-Medicine-HRP258-videoalpha-c26e4247f7724cc3bc407a7a3541ed90\",
              \"code\":\"q3cxPJGX4gc\",
              \"currentTime\":0}"
              
        Same for hide_transcript
        @param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event info in show_transcript or hide_transcript." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        event = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in show_transcript or hide_transcript: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        xcriptID = event.get('id', None)
        code  = event.get('code', None)
        self.setValInRow(row, 'transcript_id', xcriptID)
        self.setValInRow(row, 'transcript_code', code)
        return row
        

    def handleProblemCheckFail(self, record, row, event):
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
        if event is None:
            self.logWarn("Track log line %s: missing event text in problem_check event." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        event = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in handle problem_check event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        problem_id = event.get('problem_id', None)
        success    = event.get('failure', None)  # 'closed' or 'unreset'
        self.setValInRow(row, 'problem_id', problem_id)
        # Try to look up the human readable display name
        # of the problem, and insert it into the main
        # table's resource_display_name field:
        self.setResourceDisplayName(row, problem_id)
        
        self.setValInRow(row, 'success', success)
        
        answersDict = event.get('answers', None)
        stateDict = event.get('state', None)
        
        if isinstance(answersDict, dict) and len(answersDict) > 0:
            # Receive all the Answer table keys generated for
            # the answers, and a dict mapping each key
            # to the problem ID to which that key's row
            # in the Answer refers:
            (answersFKeys, answerToProblemMap) = self.pushAnswers(answersDict)
        else:
            answersFKeys = []
            
        if isinstance(stateDict, dict) and len(stateDict) > 0:
            stateFKeys = self.pushState(stateDict)
        else:
            stateFKeys = []
            
        generatedAllRows = False
        indexToFKeys = 0
        # Generate main table rows that refer to all the
        # foreign entries we made above to tables Answer, and State
        # We make as few rows as possible by filling in 
        # columns in all three foreign key entries, until
        # we run out of all references:
        while not generatedAllRows:
            try:
                answerFKey = answersFKeys[indexToFKeys]
            except IndexError:
                answerFKey = None
            try:
                stateFKey = stateFKeys[indexToFKeys]
            except IndexError:
                stateFKey = None
            
            # Have we created rows to cover all answers, and states?
            if answerFKey is None and stateFKey is None:
                generatedAllRows = True
                continue

            # Fill in one main table row.
            self.setValInRow(row, 'answer_fk', answerFKey if answerFKey is not None else '')
            if answerFKey is not None:
                # For convenience: enter the Answer's problem ID 
                # in the main table's problemID field:
                problemID = answerToProblemMap[answerFKey] if answerToProblemMap[answerFKey] is not None else ''
                self.setValInRow(row, 'problem_id', problemID)
                # Try to look up the human readable display name
                # of the problem, and insert it into the main
                # table's resource_display_name field:
                self.setResourceDisplayName(row, problemID)
                
            self.setValInRow(row, 'state_fk', stateFKey if stateFKey is not None else '')
            rowInfoTriplet = self.resultTriplet(row, self.mainTableName)
            self.jsonToRelationConverter.pushToTable(rowInfoTriplet)
            # The next row keeps its eventID, but needs its own
            # primary key (in _id):
            self.setValInRow(row, '_id', self.getUniqueID())
            indexToFKeys += 1
        return row

    def handleProblemRescoreFail(self, record, row, event):
        '''
        No example available. Records reportedly include:
        state, problem_id, and failure reason
        @param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event info in problem_rescore_fail." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        problem_id = event.get('problem_id', None)
        failure    = event.get('failure', None)  # 'closed' or 'unreset'
        self.setValInRow(row, 'problem_id', problem_id)
        # Try to look up the human readable display name
        # of the problem, and insert it into the main
        # table's resource_display_name field:
        self.setResourceDisplayName(row, problem_id)
        
        self.setValInRow(row, 'failure', failure)
        
        stateDict = event.get('state', None)
        
        if isinstance(stateDict, dict) and len(stateDict) > 0:
            stateFKeys = self.pushState(stateDict)
        else:
            stateFKeys = []
        for stateFKey in stateFKeys:
            # Fill in one main table row.
            self.setValInRow(row, 'state_fk', stateFKey, self.mainTableName)
            rowInfoTriplet = self.resultTriplet(row, self.mainTableName)
            self.jsonToRelationConverter.pushToTable(rowInfoTriplet)
            # The next row keeps its eventID, but needs its own
            # primary key (in _id):
            self.setValInRow(row, '_id', self.getUniqueID())
        return []

    def handleProblemRescore(self, record, row, event):
        '''
        No example available
        Fields: state, problemID, orig_score (int), orig_total(int), new_score(int),
        new_total(int), correct_map, success (string 'correct' or 'incorrect'), and
        attempts(int)
        @param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event text in problem_rescore event." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        event = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in handle problem_rescore event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        problem_id = event.get('problem_id', None)
        success    = event.get('success', None)  # 'correct' or 'incorrect'
        attempts   = event.get('attempts', None)
        orig_score = event.get('orig_score', None)
        orig_total = event.get('orig_total', None)
        new_score  = event.get('new_score', None)
        new_total  = event.get('new_total', None)
        correctMapsDict = event.get('correct_map', None)
        
        # Store the top-level vals in the main table:
        self.setValInRow(row, 'problem_id', problem_id)
        # Try to look up the human readable display name
        # of the problem, and insert it into the main
        # table's resource_display_name field:
        self.setResourceDisplayName(row, problem_id)
        self.setValInRow(row, 'success', success)
        self.setValInRow(row, 'attempts', attempts)
        self.setValInRow(row, 'orig_score', orig_score)
        self.setValInRow(row, 'orig_total', orig_total)
        self.setValInRow(row, 'new_score', new_score)
        self.setValInRow(row, 'new_total', new_total)
        
        # And the correctMap, which goes into a different table:
        if isinstance(correctMapsDict, dict) and len(correctMapsDict) > 0:
            correctMapsFKeys = self.pushCorrectMaps(correctMapsDict)
        else:
            correctMapsFKeys = []

        # Replicate main table row if needed:            
        for correctMapFKey in correctMapsFKeys:
            # Fill in one main table row.
            self.setValInRow(row, 'correctMap_fk', correctMapFKey, self.mainTableName)
            rowInfoTriplet = self.resultTriplet(row, self.mainTableName)
            self.jsonToRelationConverter.pushToTable(rowInfoTriplet)
            # The next row keeps its eventID, but needs its own
            # primary key (in _id):
            self.setValInRow(row, '_id', self.getUniqueID())
        return []
         
    def handleSaveProblemFailSuccessCheckOrReset(self, record, row, event):
        '''
        Do have examples. event has fields state, problem_id, failure, and answers.
        For save_problem_success or save_problem_check there is no failure field 
        @param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event text in save_problem_fail, save_problem_success, or reset_problem_fail." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        event = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in handle save_problem_fail, save_problem_success, or reset_problem_fail event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        problem_id = event.get('problem_id', None)
        success    = event.get('failure', None)  # 'closed' or 'unreset'
        if success is None:
            success = event.get('success', None) # 'incorrect' or 'correct'
        self.setValInRow(row, 'problem_id', problem_id)
        # Try to look up the human readable display name
        # of the problem, and insert it into the main
        # table's resource_display_name field:
        self.setResourceDisplayName(row, problem_id)
        
        self.setValInRow(row, 'success', success)
        
        answersDict = event.get('answers', None)
        stateDict = event.get('state', None)
        
        if isinstance(answersDict, dict) and len(answersDict) > 0:
            # Receive all the Answer table keys generated for
            # the answers, and a dict mapping each key
            # to the problem ID to which that key's row
            # in the Answer refers:
            (answersFKeys, answerToProblemMap) = self.pushAnswers(answersDict)
        else:
            answersFKeys = []
            
        if isinstance(stateDict, dict) and len(stateDict) > 0:
            stateFKeys = self.pushState(stateDict)
        else:
            stateFKeys = []
            
        generatedAllRows = False
        indexToFKeys = 0
        # Generate main table rows that refer to all the
        # foreign entries we made above to tables Answer, and State
        # We make as few rows as possible by filling in 
        # columns in all three foreign key entries, until
        # we run out of all references:
        while not generatedAllRows:
            try:
                answerFKey = answersFKeys[indexToFKeys]
            except IndexError:
                answerFKey = None
            try:
                stateFKey = stateFKeys[indexToFKeys]
            except IndexError:
                stateFKey = None
            
            # Have we created rows to cover all answers, and states?
            if answerFKey is None and stateFKey is None:
                generatedAllRows = True
                continue

            # Fill in one main table row.
            self.setValInRow(row, 'answer_fk', answerFKey if answerFKey is not None else '')
            if answerFKey is not None:
                # For convenience: enter the Answer's problem ID 
                # in the main table's problemID field:
                problemID = answerToProblemMap[answerFKey] if answerToProblemMap[answerFKey] is not None else ''
                self.setValInRow(row, 'problem_id', problemID)
                # Try to look up the human readable display name
                # of the problem, and insert it into the main
                # table's resource_display_name field:
                self.setResourceDisplayName(row, problemID)
            self.setValInRow(row, 'state_fk', stateFKey if stateFKey is not None else '')
            rowInfoTriplet = self.resultTriplet(row, self.mainTableName)
            self.jsonToRelationConverter.pushToTable(rowInfoTriplet)
            # The next row keeps its eventID, but needs its own
            # primary key (in _id):
            self.setValInRow(row, '_id', self.getUniqueID())
            indexToFKeys += 1
        return []
        
    def handleResetProblem(self, record, row, event):
        '''
        Events look like this::
            {"old_state": 
                {"student_answers": {"i4x-HMC-MyCS-problem-d457165577d34e5aac6fbb55c8b7ad33_2_1": "choice_2"}, 
                 "seed": 811, 
                 "done": true, 
                 "correct_map": {"i4x-HMC-MyCS-problem-d457165577d34e5aac6fbb55c8b7ad33_2_1": {"hint": "", 
                                                                                               "hintmode": null, 
                                                                                               ...
                                                    }}, 
                
              "problem_id": "i4x://HMC/MyCS/problem/d457165577d34e5aac6fbb55c8b7ad33", 
              "new_state": {"student_answers": {}, "seed": 93, "done": false, "correct_map": {}, "input_state": {"i4x-HMC-MyCS-problem-d457165577d34e5aac6fbb55c8b7ad33_2_1": {}}}}   
        @param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event text in reset_problem." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        event = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in handle reset_problem event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        self.setValInRow(row, 'problem_id',event.get('problem_id', '')) 
        # Try to look up the human readable display name
        # of the problem, and insert it into the main
        # table's resource_display_name field:
        self.setResourceDisplayName(row, event.get('problem_id', ''))
        
        oldStateDict = event.get('old_state', None)
        newStateDict = event.get('new_state', None)
        
        stateFKeys = []
        if isinstance(oldStateDict, dict) and len(oldStateDict) > 0:
            stateFKeys.extend(self.pushState(oldStateDict))
        if isinstance(newStateDict, dict) and len(newStateDict) > 0:
            stateFKeys.extend(self.pushState(newStateDict))
            
        for stateFKey in stateFKeys:
            # Fill in one main table row.
            self.setValInRow(row, 'state_fk', stateFKey if stateFKey is not None else '')
            rowInfoTriplet = self.resultTriplet(row, self.mainTableName)
            self.jsonToRelationConverter.pushToTable(rowInfoTriplet)
            # The next row keeps its eventID, but needs its own
            # primary key (in _id):
            self.setValInRow(row, '_id', self.getUniqueID())
        return []

    def handleRescoreReset(self, record, row, event):
        if event is None:
            self.logWarn("Track log line %s: missing event info in rescore-all-submissions or reset-all-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        event = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in handle resource event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        courseID = event.get('course', '')
        if len(courseID) == 0:
            self.logWarn("Track log line %s: missing course ID in rescore-all-submissions or reset-all-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        problemID = event.get('problem', '')
        if len(problemID) == 0:
            self.logWarn("Track log line %s: missing problem ID in rescore-all-submissions or reset-all-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        
        self.setValInRow(row, 'course_id', courseID)
        self.setValInRow(row, 'problem_id', problemID)
        # Try to look up the human readable display name
        # of the problem, and insert it into the main
        # table's resource_display_name field:
        self.setResourceDisplayName(row, problemID)
        
        return row
                
                
    def handleDeleteStateRescoreSubmission(self, record, row, event):
        if event is None:
            self.logWarn("Track log line %s: missing event info in delete-student-module-state or rescore-student-submission." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        event = self.ensureDict(event) 
        if event is None:

            self.logWarn("Track log line %s: event is not a dict in delete-student-module-state or rescore-student-submission event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        courseID  = event.get('course', '')
        problemID = event.get('problem', '')
        studentID = event.get('student', '')
        if courseID is None:
            self.logWarn("Track log line %s: missing course ID in delete-student-module-state or rescore-student-submission." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if problemID is None:
            self.logWarn("Track log line %s: missing problem ID in delete-student-module-state or rescore-student-submission." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if studentID is None:
            self.logWarn("Track log line %s: missing student ID in delete-student-module-state or rescore-student-submission." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        self.setValInRow(row, 'course_id', courseID)
        self.setValInRow(row, 'problem_id', problemID)
        # Try to look up the human readable display name
        # of the problem, and insert it into the main
        # table's resource_display_name field:
        self.setResourceDisplayName(row, problemID)
        
        self.setValInRow(row, 'student_id', studentID)
        return row        
        
    def handleResetStudentAttempts(self, record, row, event):
        if event is None:
            self.logWarn("Track log line %s: missing event info in reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        event = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in reset-student-attempt event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        problemID = event.get('problem', '')
        studentID = event.get('student', '')
        instructorID = event.get('instructor_id', '')
        attempts = event.get('old_attempts', -1)
        if len(problemID) == 0:
            self.logWarn("Track log line %s: missing problem ID in reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if len(studentID) == 0:
            self.logWarn("Track log line %s: missing student ID in reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if len(instructorID) == 0:
            self.logWarn("Track log line %s: missing instrucotrIDin reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if attempts < 0:
            self.logWarn("Track log line %s: missing attempts field in reset-student-attempts." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            
        self.setValInRow(row, 'problem_id', problemID)
        # Try to look up the human readable display name
        # of the problem, and insert it into the main
        # table's resource_display_name field:
        self.setResourceDisplayName(row, problemID)
        self.setValInRow(row, 'student_id', studentID)        
        self.setValInRow(row, 'instructor_id', instructorID)
        self.setValInRow(row, 'attempts', attempts)
        return row
        
    def handleGetStudentProgressPage(self, record, row, event):
        if event is None:
            self.logWarn("Track log line %s: missing event info in get-student-progress-page." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        event = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in get-student-progress-page event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        studentID = event.get('student', None)
        instructorID = event.get('instructor_id', None)
        
        if studentID is None:
            self.logWarn("Track log line %s: missing student ID in get-student-progress-page." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        if instructorID is None:
            self.logWarn("Track log line %s: missing instrucotrID in get-student-progress-page." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            
        self.setValInRow(row, 'student_id', studentID)        
        self.setValInRow(row, 'instructor_id', instructorID)
        return row        

    def handleAddRemoveInstructor(self, record, row, event):
        if event is None:
            self.logWarn("Track log line %s: missing event info in add-instructor or remove-instructor." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        event = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in add-instructor or remove-instructor event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        instructorID = event.get('instructor_id', None)

        if instructorID is None:
            self.logWarn("Track log line %s: missing instrucotrID add-instructor or remove-instructor." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        self.setValInRow(row, 'instructor_id', instructorID)
        return row
        
    def handleListForumMatters(self, record, row, event):
        if event is None:
            self.logWarn("Track log line %s: missing event info in list-forum-admins, list-forum-mods, or list-forum-community-TAs." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        event = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in list-forum-admins, list-forum-mods, or list-forum-community-TAs event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        return row
        
    def handleForumManipulations(self, record, row, event):
        if event is None:
            self.logWarn("Track log line %s: missing event info in one of remove-forum-admin, add-forum-admin, " +\
                         "remove-forum-mod, add-forum-mod, remove-forum-community-TA, or add-forum-community-TA." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        event = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in one of handle forum manipulations event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        screen_name  = event.get('username', None)

        if screen_name is None:
            self.logWarn("Track log line %s: missing screen_name in one of remove-forum-admin, add-forum-admin, " +\
                         "remove-forum-mod, add-forum-mod, remove-forum-community-TA, or add-forum-community-TA." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            
        self.setValInRow(row, 'screen_name', self.hashGeneral(screen_name))        
        return row        

    def handlePsychometricsHistogramGen(self, record, row, event):
        if event is None:
            self.logWarn("Track log line %s: missing event info in psychometrics-histogram-generation." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        event = self.ensureDict(event) 
        if event is None:
            self.logWarn("Track log line %s: event is not a dict in psychometrics-histogram-generation event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        problemID = event.get('problem', None)
        
        if problemID is None:
            self.logWarn("Track log line %s: missing problemID in pyschometrics-histogram-generation event." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
        self.setValInRow(row, 'problem_id', problemID)
        # Try to look up the human readable display name
        # of the problem, and insert it into the main
        # table's resource_display_name field:
        self.setResourceDisplayName(row, problemID)
                
        return row
    
    def handleAddRemoveUserGroup(self, record, row, event):
        '''
        This event looks like this::
           {"event_name": "beta-tester", 
            "user": "smith", 
            "event": "add"}
        Note that the 'user' is different from the screen_name. The latter triggered
        the event. User is the group member being talked about. For clarity,
        'user' is called 'group_user', and 'event' is called 'group_event' in the
        main table.
        @param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event info add-or-remove-user-group" %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row

        event = self.ensureDict(event) 
        if event is None:
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
        self.setValInRow(row, 'group_user', user)
        self.setValInRow(row, 'group_action', event)
        return row        
    
    def handleCreateAccount(self, record, row, event):
        '''
        Get event structure like this (fictitious values)::
           "{\"POST\": {\"username\": [\"luisXIV\"], 
                        \"name\": [\"Roy Luigi Cannon\"], 
                        \"mailing_address\": [\"3208 Dead St\\r\\nParis, GA 30243\"], 
                        \"gender\": [\"f\"], 
                        \"year_of_birth\": [\"1986\"], 
                        \"level_of_education\": [\"p\"], 
                        \"goals\": [\"flexibility, cost, 'prestige' and course of study\"], 
                        \"honor_code\": [\"true\"], 
                        \"terms_of_service\": [\"true\"], 
                        \"course_id\": [\"Medicine/HRP258/Statistics_in_Medicine\"], 
                        \"password\": \"********\", 
                        \"enrollment_action\": [\"enroll\"], 
                        \"email\": [\"luig.cannon@yahoo.com\"]}, \"GET\": {}}"        
        @param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event text in event type create_account." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        try:
            # From {\"POST\": {\"username\": ... , \"GET\": {}}
            # get the inner dict, i.e. the value of 'POST':
            # Like this:
            # {'username': ['luisXIV'], 
            #  'mailing_address': ['3208 Dead St\r\nParis, GA 30243'], 
            #  ...
            # }
            postDict = event['POST']
        except Exception as e:
            self.logWarn("Track log line %s: event is not a dict in create_account event: '%s' (%s)" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event), `e`))
            return row

        # Get the POST field's entries into an ordered
        # dict as expected by pushAccountInfo():
        accountDict = OrderedDict()
        accountDict['account_id'] = None # filled in by pushAccountInfo()
        userScreenName = postDict.get('username', '')
        accountDict['screen_name'] = userScreenName
        accountDict['name'] = postDict.get('name', '')
        if isinstance(userScreenName, list):
            userScreenName = userScreenName[0]
        accountDict['anon_screen_name'] = self.hashGeneral(userScreenName)
        accountDict['mailing_address'] = postDict.get('mailing_address', '')
        # Mailing addresses are enclosed in brackets, making them 
        # an array. Pull the addr string out:
        mailAddr = accountDict['mailing_address']
        if isinstance(mailAddr, list):
            mailAddr = mailAddr[0]
            accountDict = self.getZipAndCountryFromMailAddr(mailAddr, accountDict)
        else:
            accountDict['zipcode'] = ''
            accountDict['country'] = ''
            
        # Make sure that zip code is null unless address is USA:
        if accountDict['country'] != 'USA':
            accountDict['zipcode'] = ''
            
        accountDict['gender'] = postDict.get('gender', '')
        accountDict['year_of_birth'] = postDict.get('year_of_birth', -1)
        accountDict['level_of_education'] = postDict.get('level_of_education', '')
        accountDict['goals'] = postDict.get('goals', '')
        accountDict['honor_code'] = postDict.get('honor_code', -1)
        accountDict['terms_of_service'] = postDict.get('terms_of_service', -1)
        accountDict['course_id'] = postDict.get('course_id', '')
        accountDict['enrollment_action'] = postDict.get('enrollment', '')
        accountDict['email'] = postDict.get('email', '') 
        accountDict['receive_emails'] = postDict.get('receive_emails', '') 

        # Some values in create_account are arrays. Replace those
        # values' entries in accountDict with the arrays' first element:
        for fldName in accountDict.keys():
            if isinstance(accountDict[fldName], list):
                accountDict[fldName] = accountDict[fldName][0]

        # Convert some values into more convenient types
        # (that conform to the SQL types we declared in
        # self.schemaAccountTbl:
        try:
            accountDict['year_of_birth'] = int(accountDict['year_of_birth'])
        except:
            accountDict['year_of_birth'] = 0

        try:
            accountDict['terms_of_service'] = 1 if accountDict['terms_of_service'] == 'true' else 0
        except:
            pass

        try:
            accountDict['honor_code'] = 1 if accountDict['honor_code'] == 'true' else 0
        except:
            pass
        
        # Escape single quotes and CR/LFs in the various fields, so that MySQL won't throw up.
        # Also replace newlines with ", ":
        if len(accountDict['goals']) > 0:
            accountDict['goals'] = self.makeInsertSafe(accountDict['goals'])
        if len(accountDict['screen_name']) > 0:            
            accountDict['screen_name'] = self.makeInsertSafe(accountDict['screen_name'])
        if len(accountDict['name']) > 0:                        
            accountDict['name'] = self.makeInsertSafe(accountDict['name'])
        if len(accountDict['mailing_address']) > 0:                                    
            accountDict['mailing_address'] = self.makeInsertSafe(accountDict['mailing_address'])
        
        # Get the (only) Account table foreign key.
        # Returned in an array for conformance with the
        # other push<TableName>Info()
        self.pushAccountInfo(accountDict)
                
        return row

    def handleProblemGraded(self, record, row, event):
        '''
        Events look like this::
     		'[...#8217;t improve or get worse. Calculate the 95% confidence interval for the true proportion of heart disease patients who improve their fitness using this particular exercise regimen. Recall that proportions are normally distributed with a standard error of </p><p>\\\\[ \\\\sqrt{\\\\frac{p(1-p)}{n}} \\\\]</p><p>(You may use the observed proportion to calculate the standard error.)</p><span><form class=\\\"choicegroup capa_inputtype\\\" id=\\\"inputtype_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_1\\\"><div class=\\\"indicator_container\\\">\\n    </div><fieldset><label for=\\\"input_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_1_choice_0\\\"><input type=\\\"radio\\\" name=\\\"input_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_1\\\" id=\\\"input_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_1_choice_0\\\" aria-describedby=\\\"answer_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_1\\\" value=\\\"choice_0\\\"/> 66%\\n\\n        </label><label for=\\\"input_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_1_choice_1\\\"><input type=\\\"radio\\\" name=\\\"input_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_1\\\" id=\\\"input_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_1_choice_1\\\" aria-describedby=\\\"answer_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_1\\\" value=\\\"choice_1\\\"/> 66%-70%\\n\\n        </label><label for=\\\"input_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_1_choice_2\\\" class=\\\"choicegroup_correct\\\"><input type=\\\"radio\\\" name=\\\"input_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_1\\\" id=\\\"input_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_1_choice_2\\\" aria-describedby=\\\"answer_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_1\\\" value=\\\"choice_2\\\" checked=\\\"true\\\"/> 50%-84%\\n\\n            \\n            <span class=\\\"sr\\\" aria-describedby=\\\"input_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_1_choice_2\\\">Status: correct</span>\\n        </label><label for=\\\"input_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_1_choice_3\\\"><input type=\\\"radio\\\" name=\\\"input_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_1\\\" id=\\\"input_i4x-Medicine-HRP258-problem-fc217b7c689a40938dd55ebc44cb6f9a_4_...        
    		]'
    	@param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event text in save_problem_fail, save_problem_success, or reset_problem_fail." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        answersDict = {}
        # The following will go through the mess, and
        # pull out all pairs problemID/(in)correct. Those
        # will live in each Match obj's group(1) and group(2)
        # respectively:
        probIdCorrectIterator = EdXTrackLogJSONParser.problemGradedComplexPattern.finditer(str(event))
        if probIdCorrectIterator is None:
            # Should have found at least one probID/correctness pair:
            self.logWarn("Track log line %s: could not parse out problemID/correctness pairs from '%s'. (stuffed into badlyFormatted)" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            self.setValInRow(row, 'badly_formatted', str(event))
            return row
        # Go through each match:
        for searchMatch in probIdCorrectIterator:
            answersDict[searchMatch.group(1)] = searchMatch.group(2)
        
        if len(answersDict) > 0:
            # Receive all the Answer table keys generated for
            # the answers, and a dict mapping each key
            # to the problem ID to which that key's row
            # in the Answer refers:
            (answersFKeys, answerToProblemMap) = self.pushAnswers(answersDict)
        else:
            answersFKeys = []
        
        if len(answersFKeys) > 0:
            # Now need to generate enough near-replicas of event
            # entries to cover all answer 
            # foreign key entries that were created:
            for answerFKey in answersFKeys: 
                # Fill in one main table row.
                self.setValInRow(row, 'answer_fk', answerFKey)
                if answerFKey is not None:
                    # For convenience: enter the Answer's problem ID 
                    # in the main table's problemID field:
                    problemID = answerToProblemMap[answerFKey]
                    self.setValInRow(row, 'problem_id', problemID)
                    # Try to look up the human readable display name
                    # of the problem, and insert it into the main
                    # table's resource_display_name field:
                    self.setResourceDisplayName(row, problemID)
                    
                    rowInfoTriplet = self.resultTriplet(row, self.mainTableName)
                    self.jsonToRelationConverter.pushToTable(rowInfoTriplet)
                    # The next row keeps its eventID, but needs its own
                    # primary key (in _id):
                    self.setValInRow(row, '_id', self.getUniqueID())
            
        # Return empty row, b/c we already pushed all necessary rows:
        return []

    def handleReceiveEmail(self, record, row, event):
        '''
        Event is something like this::
            {"course": "Medicine/SciWrite/Fall2013", "receive_emails": "yes"}
        @param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event text in event type change-email-settings." %\
                         (self.jsonToRelationConverter.makeFileCitation()))
            return row
        
        accountDict = self.ensureDict(event)
        if accountDict is None:
            self.logWarn("Track log line %s: event is not a dict in change-email-settings event: '%s' (%s)" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        course_id = accountDict.get('course', None)
        receive_emails = accountDict.get('receive_emails', None)
        screen_name = record.get('username', None)

        # Get the event fields and put them in their place:
        # dict as expected by pushAccountInfo():
        accountDict = OrderedDict()
        accountDict['account_id'] = None # filled in by pushAccountInfo()
        accountDict['anon_screen_name'] = self.hashGeneral(screen_name)
        accountDict['name'] = None
        accountDict['mailing_address'] = None
        
        mailAddr = accountDict['mailing_address']
        if mailAddr is not None:
            # Mailing addresses are enclosed in brackets, making them 
            # an array. Pull the addr string out:
            if isinstance(mailAddr, list):
                mailAddr = mailAddr[0] 
            accountDict = self.getZipAndCountryFromMailAddr(mailAddr, accountDict)
        else:
            accountDict['zipcode'] = None
            accountDict['country'] = None
        accountDict['gender'] = None
        accountDict['year_of_birth'] = None
        accountDict['level_of_education'] = None
        accountDict['goals'] = None
        accountDict['honor_code'] = None
        accountDict['terms_of_service'] = None
        accountDict['course_id'] = course_id
        accountDict['enrollment_action'] = None
        accountDict['email'] = None
        accountDict['receive_emails'] = receive_emails

        return row
        

    def handlePathStyledEventTypes(self, record, row, event):
        '''
        Called when an event type is a long path-like string.
        Examples::
          /courses/OpenEdX/200/Stanford_Sandbox/modx/i4x://OpenEdX/200/combinedopenended/5fb3b40e76a14752846008eeaca05bdf/check_for_score
          /courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/peergrading/ef6ba7f803bb46ebaaf008cde737e3e9/is_student_calibrated",
          /courses/Education/EDUC115N/How_to_Learn_Math/courseware
        Most have action instructions at the end, some don't. The ones that don't 
        have no additional information. We drop those events.
        @param record:
        @type record:
        @param row:
        @type row:
        @param event:
        @type event:
        '''
        if event is None:
            self.logWarn("Track log line %s: missing event text in event %s." %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        eventDict = self.ensureDict(event) 
        if eventDict is None:
            self.logWarn("Track log line %s: event is not a dict in path-styled event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        
        try:
            postDict = eventDict['POST']
        except KeyError:
            self.logWarn("Track log line %s: event in path-styled event is not GET styled: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
            
        # Grab the 'verb' at the end, if there is one:
        eventType = record['event_type']
        if eventType is None or not isinstance(eventType, basestring):
            return row 
        pieces = eventType.split('/')
        verb   = pieces[-1]
        if verb == 'is_student_calibrated':
            return self.subHandleIsStudentCalibrated(row, postDict)
        elif verb == 'goto_position':
            return self.subHandleGotoPosition(row, postDict)
        elif verb == 'get_last_response':
            # No additional info to get
            return row
        elif verb == 'problem':
            return self.subHandleProblem(row, postDict)
        elif verb == 'save_answer':
            return self.subHandleSaveAnswer(row, postDict)
        elif verb == 'check_for_score':
            # No additional info to get
            return row
        elif verb == 'problem_get':
            # No additional info to get
            return row
        elif verb == 'get_legend':
            # No additional info to get
            return row
        elif verb == 'problem_show':
            # No additional info to get
            return row
        elif verb == 'problem_check':
            return self.subHandleProblemCheckInPath(row, postDict)
        elif verb == 'save_grade':
            return self.subHandleSaveGrade(row, postDict)
        
    def subHandleIsStudentCalibrated(self, row, eventDict):
        '''
        Called from handlePathStyledEventTypes(). Event dict looks like this::
           {\"location\": [\"i4x://Education/EDUC115N/combinedopenended/0d67667941cd4e14ba29abd1542a9c5f\"]}, \"GET\": {}"        
        The caller is expected to have verified the legitimacy of EventDict
        @param row:
        @type row:
        @param event:
        @type event:
        '''

        # Get location:
        try:
            location = eventDict['location']
        except KeyError:
            self.logWarn("Track log line %s: no location field provided in is_student_calibrated event: '%s'" %\
             (self.jsonToRelationConverter.makeFileCitation(), str(eventDict)))
            return row
        try:
            # The 'location' is an array of strings. Turn them into one string:
            location = '; '.join(location)
            self.setValInRow(row, 'question_location', location)
        except TypeError:
            self.logWarn("Track log line %s: location field provided in is_student_calibrated event contains a non-string: '%s'" %\
             (self.jsonToRelationConverter.makeFileCitation(), str(eventDict)))
            return row
            
        return row

    def subHandleGotoPosition(self, row, eventDict):
        '''
        Called from handlePathStyledEventTypes(). Event dict looks like this::
           {\"position\": [\"2\"]}, \"GET\": {}}"
        The caller is expected to have verified the legitimacy of EventDict
        @param row:
        @type row:
        @param event:
        @type event:
        '''

        # Get location:
        try:
            position = eventDict['position']
        except KeyError:
            self.logWarn("Track log line %s: no position field provided in got_position event: '%s'" %\
             (self.jsonToRelationConverter.makeFileCitation(), str(eventDict)))
            return row
        try:
            # The 'position' is an array of ints. Turn them into one string:
            position = '; '.join(position)
            self.setValInRow(row, 'position', position)
        except TypeError:
            self.logWarn("Track log line %s: position field provided in goto_position event contains a non-string: '%s'" %\
             (self.jsonToRelationConverter.makeFileCitation(), str(eventDict)))
            return row
            
        return row

    def subHandleProblem(self, row, eventDict):
        '''
        Called from handlePathStyledEventTypes(). Event dict looks like this::
           {\"location\": [\"i4x://Education/EDUC115N/combinedopenended/0d67667941cd4e14ba29abd1542a9c5f\"]}, \"GET\": {}}"
        The caller is expected to have verified the legitimacy of EventDict
        @param row:
        @type row:
        @param event:
        @type event:
        '''

        # Get location:
        try:
            location = eventDict['location']
        except KeyError:
            self.logWarn("Track log line %s: no location field provided in is_student_calibrated event: '%s'" %\
             (self.jsonToRelationConverter.makeFileCitation(), str(eventDict)))
            return row
        try:
            # The 'location' is an array of strings. Turn them into one string:
            location = '; '.join(location)
            self.setValInRow(row, 'question_location', location)
        except TypeError:
            self.logWarn("Track log line %s: location field provided in is_student_calibrated event contains a non-string: '%s'" %\
             (self.jsonToRelationConverter.makeFileCitation(), str(eventDict)))
            return row
            
        return row

    def subHandleSaveAnswer(self, row, eventDict):
        '''
        Called from handlePathStyledEventTypes(). Event dict looks like this::
           {\"student_file\": [\"\"], 
            \"student_answer\": [\"Students will have to use higher level thinking to describe the...in the race. \"], 
            \"can_upload_files\": [\"false\"]}, \"GET\": {}}"        
        The caller is expected to have verified the legitimacy of EventDict
        @param row:
        @type row:
        @param event:
        @type event:
        '''

        student_file = eventDict.get('student_file', [''])
        student_answer = eventDict.get('student_answer', [''])
        can_upload_file = eventDict.get('can_upload_files', [''])

        # All three values are arrays. Turn them each into a semicolon-
        # separated string:
        try:
            student_file = '; '.join(student_file)
        except TypeError:
            self.logWarn("Track log line %s: student_file field provided in save_answer event contains a non-string: '%s'" %\
             (self.jsonToRelationConverter.makeFileCitation(), str(eventDict)))
            student_file = ''
        self.setValInRow(row, 'student_file', student_file)

        try:
            student_answer = '; '.join(student_answer)
            # Ensure escape of comma, quotes, and CR/LF:
            student_answer = self.makeInsertSafe(student_answer)
        except TypeError:
            self.logWarn("Track log line %s: student_answer field provided in save_answer event contains a non-string: '%s'" %\
             (self.jsonToRelationConverter.makeFileCitation(), str(eventDict)))
            student_answer = ''
        self.setValInRow(row, 'long_answer', student_answer)
            
        try:
            can_upload_file = '; '.join(can_upload_file)
        except TypeError:
            #self.logWarn("Track log line %s: can_upload_file field provided in save_answer event contains a non-string: '%s'" %\
            # (self.jsonToRelationConverter.makeFileCitation(), str(eventDict)))
            can_upload_file = str(can_upload_file)
        self.setValInRow(row, 'can_upload_file', can_upload_file)
            
        return row

    def subHandleSaveGrade(self, row, postDict):
        '''
        Get something like:
           "{\"POST\": {\"submission_id\": [\"60611\"], 
                        \"feedback\": [\"<p>This is a summary of a paper stating the positive effects of a certain hormone on face recognition for people with disrupted face processing [1].\\n<br>\\n<br>Face recognition is essential for social interaction and most people perform it effortlessly. But a surprisingly high number of people \\u2013 one in forty \\u2013 are impaired since birth in their ability to recognize faces [2]. This condition is called 'developmental prosopagnosia'. Its cause isn\\u2"        
        @param row:
        @type row:
        @param postDict:
        @type postDict:
        '''
        if postDict is None:
            return row
        submissionID = postDict.get('submission', None) 
        feedback = postDict.get('feedback', None)
        if feedback is not None:
            feedback = self.makeInsertSafe(str(feedback))
        self.setValInRow(row, 'submission_id', submissionID)
        self.setValInRow(row, 'long_answer', feedback)
        return row

    def subHandleProblemCheckInPath(self, row, answersDict):
        '''
        Get dict like this:
           {\"input_i4x-Medicine-HRP258-problem-f0b292c175f54714b41a1b05d905dbd3_2_1\": [\"choice_3\"]}, 
            \"GET\": {}}"        
        @param row:
        @type row:
        @param answersDict:
        @type answersDict:
        '''
        if answersDict is not None:
            # Receive all the Answer table keys generated for
            # the answers, and a dict mapping each key
            # to the problem ID to which that key's row
            # in the Answer refers:
            (answersFKeys, answerToProblemMap) = self.pushAnswers(answersDict)
        for answerFKey in answersFKeys:
            self.setValInRow(row, 'answer_fk', answerFKey, self.mainTableName)
            if answerFKey is not None:
                # For convenience: enter the Answer's problem ID 
                # in the main table's problemID field:
                problemID = answerToProblemMap[answerFKey]
                self.setValInRow(row, 'problem_id', problemID)
                # Try to look up the human readable display name
                # of the problem, and insert it into the main
                # table's resource_display_name field:
                self.setResourceDisplayName(row, problemID)
                
                rowInfoTriplet = self.resultTriplet(row, self.mainTableName)
                self.jsonToRelationConverter.pushToTable(rowInfoTriplet)
                # The next row keeps its eventID, but needs its own
                # primary key (in _id):
                self.setValInRow(row, '_id', self.getUniqueID())
        return []

    def handleAjaxLogin(self, record, row, event, eventType):
        '''
        Events look like this:
            "{\"POST\": {\"password\": \"********\", \"email\": [\"emil.smith@gmail.com\"], \"remember\": [\"true\"]}, \"GET\": {}}"        
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
            self.logWarn("Track log line %s: missing event text in event %s." %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        eventDict = self.ensureDict(event) 
        if eventDict is None:
            self.logWarn("Track log line %s: event is not a dict in event: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row

        try:
            postDict = eventDict['POST']
        except KeyError:
            self.logWarn("Track log line %s: event in login_ajax is not GET styled: '%s'" %\
                         (self.jsonToRelationConverter.makeFileCitation(), str(event)))
            return row
        email = postDict.get('email', None)
        # We get remember here, but don't carry it to the relational world:
        remember = postDict.get('remember', None)  # @UnusedVariable
        if email is not None:
            # Stick email into the screen_name field. But flatten
            # the array of email addresses to a string (I've only
            # seen single-element arrays anyway):
            try:
                email = '; '.join(email)
            except TypeError:
                pass
            self.setValInRow(row, 'anon_screen_name', self.hashGeneral(email))
        return row
        
    def finish(self, includeCSVLoadCommands=False, outputDisposition=None):
        '''
        Called by json_to_relation parent after 
        the last insert for one file is done.
        We do what's needed to close out the transform.
        @param includeCSVLoadCommands: if True, then the main output file will just have
                  table locking, and turning off consistency checks. In that case we
                  insert CSV file load statements. Otherwise the output file already
                  has INSERT statements, and we just add table unlocking, etc.:
        @type includeCSVLoadCommands: Boolean
        @param outputDisposition: an OutputDisposition that offers a method getCSVTableOutFileName(tableName),
                  which provides the fully qualified file name that is the 
                  destination for CSV rows destined for a given table.
        @type outputDispostion: OutputDisposition
        '''
        if includeCSVLoadCommands:
            self.jsonToRelationConverter.pushString(self.createCSVTableLoadCommands(outputDisposition))
        # Unlock tables, and return foreign key checking to its normal behavior:
        self.jsonToRelationConverter.pushString(self.dumpPostscript1)
        # Copy the temporary Account entries from
        # the tmp table in Edx to the final dest
        # in EdxPrivate:
        self.createMergeAccountTbl()
        # Restore various defaults:
        self.jsonToRelationConverter.pushString(self.dumpPostscript2)

    def createCSVTableLoadCommands(self, outputDisposition):
        '''
        Create a series of LOAD INFILE commands as a string. One load command
        for each of the Edx track log tables.
        @param outputDisposition: an OutputDisposition that offers a method getCSVTableOutFileName(tableName),
                  which provides the fully qualified file name that is the 
                  destination for CSV rows destined for a given table.
        @type outputDisposition: OutputDisposition
        '''
        csvLoadCommands    = "SET sql_log_bin=0;\n"
        for tableName in ['LoadInfo', 'InputState', 'State', 'CorrectMap', 'Answer', 'Account', 'EdxTrackEvent']:
            filename = outputDisposition.getCSVTableOutFileName(tableName)
            # SQL statements for LOAD INFILE all .csv tables in turn. Only used
            # when no INSERT statement dump is being generated:
            csvLoadCommands += "LOAD DATA LOCAL INFILE '%s' IGNORE INTO TABLE %s FIELDS OPTIONALLY ENCLOSED BY \"'\" TERMINATED BY ','; \n" %\
                               (filename, tableName)
        
        csvLoadCommands += "SET sql_log_bin=1;\n"
        return csvLoadCommands        
    
    def createMergeAccountTbl(self):
        '''
        Called at the very end of a load: copies all the entries
        from the temporary Account table in the Edx db to the permanent
        Account table in EdxPrivate. Then DROPs the tmp Account table:
        '''
        colNameList = ''
        for colName in self.schemaAccountTbl.keys():
            colNameList += colName + ','
        # Snip off the last comma:
        colNameList = colNameList[:-1]
        
        copyStatement = "INSERT INTO EdxPrivate.Account (" + colNameList + ")" +\
                        " SELECT " + colNameList + " FROM Edx.Account;\n" +\
                        "DROP TABLE Edx.Account;\n" 
        self.jsonToRelationConverter.pushString(copyStatement)
        
        
    def handleBadJSON(self, row, offendingText):
        '''
        When JSON parsing fails, place the offending text into 
        longAnswer. Happens, for instance, when student answers have embedded
        quotes that confused some upstream load process.
        @param row:
        @type row:
        @param offendingText:
        @type offendingText:
        '''
        self.setValInRow(row, 'badly_formatted', self.makeInsertSafe(offendingText))
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
    
        But also::
            {"username": "RobbieH", 
             "host": "class.stanford.edu", 
            ...
            "event": {"failure": "closed", "state": {"student_answers": {"i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_7_1": "choice_1", "i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_2_1": "choice_3", "i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_9_1": ["choice_0", "choice_1"], "i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_6_1": "choice_0", "i4x-Medicine-HRP258-problem-4cd47ea861f542488a20691ac424a002_8_1": ["choice_0", "choice_1", "choice_2", "choice_3", "choice_4"], 
        
        Notice the 'event' key's value being a *string* containing JSON, rather than 
        a nested JSON object. This requires special attention. Buried inside
        that string is the 'next' tag, whose value is an array with a long (here
        partially elided) hex number. This is where the course number is
        extracted.
        
        @param event: JSON record of an edx tracking event as internalized dict
        @type event: Dict<String,Dict<<any>>
        @return: two-tuple: full name of course in which event occurred, and descriptive name.
                 None if course ID could not be obtained.
        @rtype: {(String,String) | None} 
        '''
        course_id = ''
        eventSource = event.get('event_source', None)
        if eventSource is None:
            return ('','','')
        if eventSource == 'server':
            # get course_id from event type
            eventType = event.get('event_type', None)
            if eventType is None:
                return('','','')
            if eventType == u'/accounts/login':
                try:
                    post = json.loads(str(event.get('event', None)))
                except:
                    return('','','')
                if post is not None:
                    getEntry = post.get('GET', None)
                    if getEntry is not None:
                        try:
                            fullCourseName = getEntry.get('next', [''])[0]
                        except:
                            return('','','')
                    else:
                        return('','','')
                else:
                    return('','','')
                
            elif eventType.startswith('/courses'):
                courseID = self.extractShortCourseID(eventType)
                return(courseID, courseID, self.getCourseDisplayName(eventType))
                 
            elif eventType.find('problem_') > -1:
                event = event.get('event', None)
                if event is None:
                    return('','','')
                courseID = self.extractCourseIDFromProblemXEvent(event)
                return(courseID, courseID, '')
            else:
                fullCourseName = event.get('event_type', '')
        else:
            fullCourseName = event.get('page', '')
        if len(fullCourseName) > 0:
            course_id = self.extractShortCourseID(fullCourseName)
            course_display_name = self.getCourseDisplayName(fullCourseName)
        else:
            course_display_name = ''
        if len(course_id) == 0:
            fullCourseName = ''
        return (fullCourseName, course_id, course_display_name)
        
    def getCourseDisplayName(self, fullCourseName):
        '''
        Given a 
        @param fullCourseName:
        @type fullCourseName:
        '''
        courseHash = self.extractOpenEdxHash(fullCourseName)
        if courseHash is None:
            return None
        return self.hashMapper.getDisplayName(courseHash)
        
        
    def extractShortCourseID(self, fullCourseStr):
        if fullCourseStr is None:
            return ''
        courseNameFrags = fullCourseStr.split('/')
        course_id = ''
        if 'courses' in courseNameFrags:
            i = courseNameFrags.index('courses')
            course_id = "/".join(map(str, courseNameFrags[i+1:i+4]))
        return course_id        

    def extractCourseIDFromProblemXEvent(self, event):
        '''
        Given the 'event' field of an event of type problem_check, problem_check_fail, problem_save...,
        extract the course ID. Ex from save_problem_check::
            "event": {"success": "correct", "correct_map": {"i4x-Medicine-HRP258-problem-8dd11b4339884ab78bc844ce45847141_2_1": {"hint": "", "hintmode": null,...
        @param event:
        @type event:
        '''
        if event is None:
            return None
        # isolate '-Medicine-HRP258-problem-8dd11b4339884ab78bc844ce45847141_2_1":' from:
        # ' {"success": "correct", "correct_map": {"i4x-Medicine-HRP258-problem-8dd11b4339884ab78bc844ce45847141_2_1": {"hint": "", "hintmode": null'
        match = EdXTrackLogJSONParser.problemXFindCourseID.search(str(event))
        if match is None:
            return None
        # the match obj's groups is now: '-Medicine-HRP258-problem-8dd11b4339884ab78bc844ce45847141_2_1"'
        # Split into ['', 'Medicine', 'HRP258', 'problem', '8dd11b4339884ab78bc844ce45847141_2_1"'] 
        parts = match.groups()[0].split('-')
        try:
            return "-".join([parts[1], parts[2]])
        except IndexError:
            return None

    def ensureDict(self, event):
        '''
        If event is either a dict, or a string with a dict
        definition inside, returns a dict. Else returns None
        
        @param event:
        @type event:
        '''
        if isinstance(event, dict):
            return event
        else:
            try:
                # Maybe it's a string: make a dict from the string:
                res = eval(event)
                if isinstance(res, dict):
                    return res
                else:
                    return None
            except Exception:
                return None
        
    def ensureArray(self, event):
        '''
        If event is either a Python array, or a string with an array
        definition inside, returns the array. Else returns None
        
        @param event:
        @type event:
        '''
        if isinstance(event, list):
            return event
        else:
            try:
                # Maybe it's a string: make an array from the string:
                res = eval(event)
                if isinstance(res, list):
                    return res
                else:
                    return None
            except Exception:
                return None
            
    def makeInsertSafe(self, unsafeStr):
        '''
        Makes the given string safe for use as a value in a MySQL INSERT
        statement. Looks for embedded CR or LFs, and turns them into 
        semicolons. Escapes commas and single quotes. Backslash is
        replaced by double backslash. This is needed for unicode, like
        \0245 (invented example)
        @param unsafeStr: string that possibly contains unsafe chars
        @type unsafeStr: String
        @return: same string, with unsafe chars properly replaced or escaped
        @rtype: String
        '''
        #return unsafeStr.replace("'", "\\'").replace('\n', "; ").replace('\r', "; ").replace(',', "\\,").replace('\\', '\\\\')
        if unsafeStr is None or not isinstance(unsafeStr, basestring) or len(unsafeStr) == 0:
            return ''
        # Check for chars > 128 (illegal for standard ASCII):
        for oneChar in unsafeStr:
            if ord(oneChar) > 128:
                # unidecode() replaces unicode with approximations. 
                # I tried all sorts of escapes, and nothing worked
                # for all cases, except this:
                unsafeStr = unidecode(unicode(unsafeStr))
                break
        return unsafeStr.replace('\n', "; ").replace('\r', "; ").replace('\\', '').replace("'", r"\'")
    
    def makeJSONSafe(self, jsonStr):
        '''
        Given a JSON string, make it safe for loading via
        json.loads(). Backslashes before chars other than 
        any of \bfnrtu/ are escaped with a second backslash 
        @param jsonStr:
        @type jsonStr:
        '''
        res = EdXTrackLogJSONParser.JSON_BAD_BACKSLASH_PATTERN.sub(self.fixOneJSONBackslashProblem, jsonStr)
        return res

    
    def fixOneJSONBackslashProblem(self, matchObj):
        '''
        Called from the pattern.sub() method in makeJSONSafe for
        each match of a bad backslash in jsonStr there. Returns
        the replacement string to use by the caller for the substitution. 
        Ex. a match received from the original string "\d'Orsay" returns
        "\\d".    
        @param matchObj: a Match object resulting from a regex search/replace
                         call.
        @type matchObj: Match
        '''
        return "\\\\" + matchObj.group(1)

    def rescueBadJSON(self, badJSONStr, row=[]):
        '''
        When JSON strings are not legal, we at least try to extract 
        the username, host, session, event_type, event_source, and event fields
        verbatim, i.e. without real parsing. We place those in the proper 
        fields, and leave it at that.
        @param badJSONStr:
        @type badJSONStr:
        '''
        screen_name = self.tryJSONExtraction(EdXTrackLogJSONParser.searchPatternDict['username'], badJSONStr)
        #host = self.tryJSONExtraction(EdXTrackLogJSONParser.searchPatternDict['host'], badJSONStr)
        session = self.tryJSONExtraction(EdXTrackLogJSONParser.searchPatternDict['session'], badJSONStr)
        event_source = self.tryJSONExtraction(EdXTrackLogJSONParser.searchPatternDict['event_source'], badJSONStr)        
        event_type = self.tryJSONExtraction(EdXTrackLogJSONParser.searchPatternDict['event_type'], badJSONStr)        
        time = self.tryJSONExtraction(EdXTrackLogJSONParser.searchPatternDict['time'], badJSONStr)        
        ip = self.tryJSONExtraction(EdXTrackLogJSONParser.searchPatternDict['ip'], badJSONStr)                
        event = self.tryJSONExtraction(EdXTrackLogJSONParser.searchPatternDict['event'], badJSONStr)                
        
        if isinstance(screen_name, basestring):
            self.setValInRow(row, 'anon_screen_name', self.hashGeneral(screen_name))
        else:
            self.setValInRow(row, 'anon_screen_name', '')
        #self.setValInRow(row, 'host', host)
        self.setValInRow(row, 'session', session)
        self.setValInRow(row, 'event_source', event_source)
        self.setValInRow(row, 'event_type', event_type)
        self.setValInRow(row, 'time', time)
        self.setValInRow(row, 'ip', ip)
        self.setValInRow(row, 'badly_formatted', self.makeInsertSafe(event))
    
    def tryJSONExtraction(self, pattern, theStr):
        m = pattern.search(theStr)
        try:
            return None if m is None else m.group(1)
        except:
            return None
        
    def getUniqueID(self):
        '''
        Generate a universally unique key with
        all characters being legal in MySQL identifiers. 
        '''
        return str(uuid.uuid4()).replace('-','_')

    def getZipAndCountryFromMailAddr(self, mailAddr, accountDict):
        
            zipCodeMatch = EdXTrackLogJSONParser.zipCodePattern.findall(mailAddr)
            if len(zipCodeMatch) > 0:
                accountDict['zipcode'] = zipCodeMatch[-1]
            else:
                accountDict['zipcode'] = ''
                
            # See whether the address includes a country:
            # Last ditch: if we think we found a zip code, 
            # start out thinking US for the country:
            if len(accountDict['zipcode']) > 0:
                accountDict['country'] = 'USA'
            else:
                accountDict['country'] = ''
            # Our zip code might be a different number,
            # so do look for an explicit country:
            splitMailAddr = re.split(r'\W+', mailAddr)
            # Surely not the fastest, but I'm tired: pass
            # a sliding window of four,three,bi, and unigrams
            # over the mailing address to find a country
            # specification:
            for mailWordIndx in range(len(splitMailAddr)):
                try: 
                    fourgram = string.join([splitMailAddr[mailWordIndx], 
                                            splitMailAddr[mailWordIndx + 1], 
                                            splitMailAddr[mailWordIndx + 2],
                                            splitMailAddr[mailWordIndx + 3]])
                    country = self.countryChecker.isCountry(fourgram)
                    if len(country) > 0:
                        accountDict['country'] = country
                        break 
                except IndexError:
                    pass
                try: 
                    trigram = string.join([splitMailAddr[mailWordIndx], splitMailAddr[mailWordIndx + 1], splitMailAddr[mailWordIndx + 2]])
                    country = self.countryChecker.isCountry(trigram)
                    if len(country) > 0:
                        accountDict['country'] = country
                        break 
                except IndexError:
                    pass
                
                try:
                    bigram = string.join([splitMailAddr[mailWordIndx], splitMailAddr[mailWordIndx + 1]])
                    country = self.countryChecker.isCountry(bigram)
                    if len(country) > 0:
                        accountDict['country'] = country
                        break 
                except IndexError:
                    pass
                
                unigram = splitMailAddr[mailWordIndx]
                country = self.countryChecker.isCountry(unigram)
                if len(country) > 0:
                    accountDict['country'] = country
                    break 
            # Make sure that zip code is empty unless address is USA:
            if accountDict['country'] != 'USA':
                accountDict['zipcode'] = ''
                
            return accountDict

    def hashGeneral(self, username):
        '''
        Returns a ripemd160 40 char hash of the given name. 
        @param username: name to be hashed
        @type username: String
        @return: hashed equivalent. Calling this function multiple times returns the same string
        @rtype: String
        '''
        #return hashlib.sha224(username).hexdigest()
        oneHash = hashlib.new('ripemd160')
        oneHash.update(username)
        return oneHash.hexdigest()
    
    def extractOpenEdxHash(self, idStr):
        '''
        Given a string, such as::
            i4x-Medicine-HRP258-videoalpha-7cd4bf0813904612bcd583a73ade1d54
            or:
            input_i4x-Medicine-HRP258-problem-98ca37dbf24849debcc29eb36811cb68_3_1_choice_3'
        extract and return the 32 bit hash portion. If none is found,
        return None. Method takes any string and finds a 32 bit hex number.
        It is up to the caller to ensure that the return is meaningful. As
        a minimal check, the method does ensure that there is at most one 
        qualifying string present; we know that this is the case with problem_id
        and other strings.
        @param idStr: problem, module, video ID and others that might contain a 32 bit OpenEdx platform hash
        @type idStr: string
        '''
        match = EdXTrackLogJSONParser.findHashPattern.search(idStr)
        if match is not None:
            return match.group(1)
        else:
            return None

    def setResourceDisplayName(self, row, openEdxHash):
        '''
        Given an OpenEdx hash of problem ID, video ID, or course ID,
        set the resource_display_name in the given row. The value
        passed in may have the actual hash embedded in a larger
        string, as in::
            input_i4x-Medicine-HRP258-problem-7451f8fe15a642e1820767db411a4a3e_2_1
        We fish it out of there.            
        @param row: current row's values
        @type row: [<any>]
        @param openEdxHash: 32-bit hash string encoding a problem, video, or class, or 
                       such a 32-bit hash embedded in a larger string.
        @type openEdxHash: String
        '''
        if openEdxHash is not None and len(openEdxHash) > 0:
            # Fish out the actual 32-bit hash:
            hashNum = self.extractOpenEdxHash(openEdxHash)
            # Get display name and add to main table as resource_display_name:
            displayName = self.hashMapper.getDisplayName(hashNum)
            if displayName is not None:
                self.setValInRow(row, 'resource_display_name', self.makeInsertSafe(displayName))
        
    def getCanonicalCourseName(self, trackLogStr):
        '''
        Given a string believed to be the best course name
        snippet from a log entry, use the modulestoreImporter's
        facilities to get a canonical name. Inputs look like::
            Medicine/HRP258/Statistics_in_Medicine
            /courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/sequential/1b3ac347ca064b3eaaddbc27d4200964/goto_position
        @param trackLogStr: string that hopefully contains a course short name
        @type trackLogStr: String
        @return: a string of the form org/courseShortName/courseTitle
        @rtype: String
        '''
        