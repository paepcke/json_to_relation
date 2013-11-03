'''
Created on Oct 3, 2013

@author: paepcke
'''
import StringIO
from collections import OrderedDict
import json
import os
import re
import shutil
import sys
import tempfile
import unittest

from json_to_relation import JSONToRelation
from edxTrackLogJSONParser import EdXTrackLogJSONParser
from input_source import InURI, InString
from output_disposition import OutputDisposition, ColDataType, \
    TableSchemas, ColumnSpec, OutputFile, OutputPipe # @UnusedImport


TEST_ALL = True
PRINT_OUTS = False  # Set True to get printouts of CREATE TABLE statements

# The following is very Dangerous: If True, no tests are
# performed. Instead, all the reference files, the ones
# ending with 'Truth.sql' will be changed to be whatever
# the test returns. Use only when you made code changes that
# invalidate all the truth files:
UPDATE_TRUTH = False

class TestEdxTrackLogJSONParser(unittest.TestCase):
    
    def setUp(self):
        super(TestEdxTrackLogJSONParser, self).setUp()  
        self.uuidRegex = '[a-f0-9]{8}_[a-f0-9]{4}_[a-f0-9]{4}_[a-f0-9]{4}_[a-f0-9]{12}'
        self.pattern   = re.compile(self.uuidRegex)
        self.loginEvent = '{"username": "",   "host": "class.stanford.edu",   "event_source": "server",   "event_type": "/accounts/login",   "time": "2013-06-14T00:31:57.661338",   "ip": "98.230.189.66",   "event": "{\\"POST\\": {}, \\"GET\\": {\\"next\\": [\\"/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/80160exxx/\\"]}}",   "agent": "Mozilla/5.0 (Windows NT 5.1; rv:21.0) Gecko/20100101  Firefox/21.0",   "page": null}' 
        self.dashboardEvent = '{"username": "", "host": "class.stanford.edu", "event_source": "server", "event_type": "/accounts/login", "time": "2013-06-10T05:13:37.499008", "ip": "91.210.228.6", "event": "{\\"POST\\": {}, \\"GET\\": {\\"next\\": [\\"/dashboard\\"]}}", "agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1", "page": null}'
        self.videoEvent = '{"username": "smith", "host": "class.stanford.edu", "session": "f011450e5f78d954ce5a475de473a454", "event_source": "browser", "event_type": "speed_change_video",  "time": "2013-06-21T06:31:11.804290+00:00", "ip": "80.216.21.147", "event": "{\\"id\\":\\"i4x-Medicine-HRP258-videoalpha-be496fded4f8424da9aacc553f480fa5\\",\\"code\\": \\"html5\\",\\"currentTime\\":474.524041,\\"old_speed\\":\\"0.25\\",\\"new_speed\\":\\"1.0\\"}", "agent": "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like  Gecko) Chrome/28.0.1500.44 Safari/537.36", "page": "https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/64abcdd9afc54c6089a284e985 3da6ea/2a8de59355e349b7ae40aba97c59736f/"}' 
        self.heartbeatEvent = '{"username": "", "host": "10.0.10.32", "event_source": "server", "event_type": "/heartbeat", "time": "2013-06-21T06:32:09.881521+00:00", "ip": "127.0.0.1", "event": "{\\"POST\\": {}, \\"GET\\": {}}", "agent": "ELB-HealthChecker/1.0", "page": null}'

        self.stringSource = None
        self.curDir = os.path.dirname(__file__)

        self.stringSource = InURI(os.path.join(self.curDir ,"data/twoJSONRecords.json"))

    def tearDown(self):
        if self.stringSource is not None:
            self.stringSource.close()

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testMakeJSONSafe(self):
        fileConverter = JSONToRelation(self.stringSource,
                                       OutputFile(os.devnull, OutputDisposition.OutputFormat.CSV),
                                       mainTableName='Main'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Main', replaceTables=True)
        s = "d\\'Orsay"
        res = edxParser.makeJSONSafe(s)
        # res should be d\\'Orsay:         
        self.assertEquals("d\\\\'Orsay", res)
        # Test len to ensure the proper number
        # of backslashes are escaped:
        self.assertEquals(len(res), 9)
         
        s += " and g\lobber"
        res = edxParser.makeJSONSafe(s)
        self.assertEqual("d\\\\'Orsay and g\\\\lobber", res)
        # Test len to ensure the proper number
        # of backslashes are escaped:
        self.assertEquals(len(res), 23)        
        
        # Now a *legal* char following a backslash:
        s = "Legal \\b back \\u0x390 slashes"
        res = edxParser.makeJSONSafe(s)
        self.assertEqual("Legal \\\\b back \\\\u0x390 slashes", res)
        jsonStr = "{\"key\" : \"" + res + "\"}"
        j = json.loads(jsonStr)
        self.assertEqual(len(j['key']), 29)



        #sys.stdout.write(res)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testRescueJSON(self):
        fileConverter = JSONToRelation(self.stringSource,
                                       OutputFile(os.devnull, OutputDisposition.OutputFormat.CSV),
                                       mainTableName='Main'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Main', replaceTables=True)
        badJSONStr = '{"username": "Gvnmaele", "host": "class.stanford.edu", "session": "ec36da02f42320bd1686a4f5a43daf0b", "event_source": "browser", "event_type": "problem_graded", "time": "2013-08-04T07:41:16.220676+00:00", "ip": "81.165.215.195", "event": "the event..."'        
        row = []
        edxParser.rescueBadJSON(badJSONStr, row=row)
        self.assertEqual(row, ['null', 'null', 'browser', 'problem_graded', '81.165.215.195', 'null', 'ec36da02f42320bd1686a4f5a43daf0b', '2013-08-04T07:41:16.220676+00:00', 'Gvnmaele', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', ' "the event..."']
)
        
        badJSONStr = "{u'username': u'Magistra', u'event_source': u'server', u'event_type': u'/courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/peergrading/ef6ba7f803bb46ebaaf008cde737e3e9/save_grade', u'ip': u'209.216.182.65', u'agent': u'Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.66 Safari/537.36', u'page': None, u'host': u'class.stanford.edu', u'time': u'2013-09-14T06:55:57.003501+00:00', u'event': u'{\"POST\": {\"submission_id\": [\"51255\"], \"feedback\": [\"The thumbs up does seem like a great idea. How do you think she manages to communicate to students that she does take each answer seriously? Is it that she takes time to record each way of thinking accurately? This seems very important in engaging all students.\"], \"rubric_scores[]\": [\"1\"], \"answer_unknown\": [\"false\"], \"location\": [\"i4x://Education/EDUC115N/combinedopenended/0d67667941cd4e14ba29abd1542a9c5f\"], \"submission_key\": [\"414b8d746627f6db8d705605b16'}"
        row = []
        edxParser.rescueBadJSON(badJSONStr, row=row)
        self.assertEqual(row, ['null', 'null', 'server', '/courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/peergrading/ef6ba7f803bb46ebaaf008cde737e3e9/save_grade', '209.216.182.65', 'null', 'null', '2013-09-14T06:55:57.003501+00:00', 'Magistra', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', 'null', ' u\\\'{"POST": {"submission_id": ["51255"], "feedback": ["The thumbs up does seem like a great idea. How do you think she manages to communicate to students that she does take each answer seriously? Is it that she takes time to record each way of thinking accurately? This seems very important in engaging all students."], "rubric_scores[]": ["1"], "answer_unknown": ["false"], "location": ["i4x://Education/EDUC115N/combinedopenended/0d67667941cd4e14ba29abd1542a9c5f"], "submission_key": ["414b8d746627f6db8d705605b16\\\'}']
)


    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testTableSchemaRepo(self):
        fileConverter = JSONToRelation(self.stringSource,
                                       OutputFile(os.devnull, OutputDisposition.OutputFormat.CSV),
                                       mainTableName='Main'
                                       )
        tblRepo = TableSchemas()
        
        # Should initially have an empty schema for main (default) table:
        self.assertTrue(isinstance(tblRepo[None], OrderedDict))
        self.assertEquals(len(tblRepo[None]), 0)
        
        # Add single schema item to an empty repo
        tblRepo.addColSpec('myTbl', ColumnSpec('myCol', ColDataType.INT, fileConverter))
        self.assertEqual('INT', tblRepo['myTbl']['myCol'].getType())
        
        # Add single schema item to a non-empty repo:
        tblRepo.addColSpec('myTbl', ColumnSpec('yourCol', ColDataType.FLOAT, fileConverter))
        self.assertEqual('FLOAT', tblRepo['myTbl']['yourCol'].getType())
        
        # Add a dict with one spec to the existing schema:
        schemaAddition = OrderedDict({'hisCol' : ColumnSpec('hisCol', ColDataType.DATETIME, fileConverter)})
        tblRepo.addColSpecs('myTbl', schemaAddition)
        self.assertEqual('DATETIME', tblRepo['myTbl']['hisCol'].getType())
        
        # Add a dict with multiple specs to the existing schema:
        schemaAddition = OrderedDict({'hisCol' : ColumnSpec('hisCol', ColDataType.DATETIME, fileConverter),
                                      'herCol' : ColumnSpec('herCol', ColDataType.LONGTEXT, fileConverter)})
        tblRepo.addColSpecs('myTbl', schemaAddition)        
        self.assertEqual('DATETIME', tblRepo['myTbl']['hisCol'].getType())         
        self.assertEqual('LONGTEXT', tblRepo['myTbl']['herCol'].getType())                 
        

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testGetCourseID(self):
        #print self.edxParser.get_course_id(json.loads(self.loginEvent))
        fileConverter = JSONToRelation(self.stringSource,
                                       OutputFile(os.devnull, OutputDisposition.OutputFormat.CSV),
                                       mainTableName='Main'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Main', replaceTables=True)
        fileConverter.setParser(edxParser)
          
        courseName = edxParser.extractShortCourseID('/courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/combinedopenended/3aa97047991b4e208ebb1a72cc9ff579/')          
        self.assertEqual('Education/EDUC115N/How_to_Learn_Math', courseName)

        courseName = edxParser.extractShortCourseID('/courses/OpenEdX/200/Stanford_Sandbox/modx/i4x://OpenEdX/200/combinedopenended/5fb3b40e76a14752846008eeaca05bdf/check_for_score')
        self.assertEqual('OpenEdX/200/Stanford_Sandbox', courseName)

        courseName = edxParser.extractShortCourseID('i4x://Education/EDUC115N/combinedopenended/0d67667941cd4e14ba29abd1542a9c5f')
        self.assertIsNone(courseName)

        (fullCourseName, courseName) = edxParser.get_course_id(json.loads(self.loginEvent))
        self.assertEqual('/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/80160exxx/', fullCourseName)
        self.assertEqual('Medicine/HRP258/Statistics_in_Medicine', courseName)
        
        (fullCourseName, courseName) = edxParser.get_course_id(json.loads(self.videoEvent))
        self.assertEqual('https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/64abcdd9afc54c6089a284e985 3da6ea/2a8de59355e349b7ae40aba97c59736f/', fullCourseName)
        self.assertEqual('Medicine/HRP258/Statistics_in_Medicine', courseName)
        
        (fullCourseName, courseName) = edxParser.get_course_id(json.loads(self.dashboardEvent))
        self.assertIsNone(fullCourseName)        
        self.assertIsNone(courseName)        

        (fullCourseName, courseName) = edxParser.get_course_id(json.loads(self.heartbeatEvent))
        self.assertIsNone(fullCourseName)        
        self.assertIsNone(courseName)        

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testProcessOneJSONObject(self):
        fileConverter = JSONToRelation(self.stringSource,
                                       OutputFile(os.devnull, OutputDisposition.OutputFormat.CSV),
                                       mainTableName='Main'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Main', replaceTables=True)
        fileConverter.setParser(edxParser)
        
        row = []
        edxParser.processOneJSONObject(self.loginEvent, row)
        #print row
        
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testEdxHeartbeat(self):        
        # Test series of heartbeats that did not experience a server outage:
        inputSourcePath = os.path.join(os.path.join(self.curDir, "data/edxHeartbeatEvent.json"))
        inFileSource = InURI(inputSourcePath)
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(inFileSource, 
                                       dest
                                       )
        
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Main', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert(prependColHeader=False)
        # We should find no heartbeat info in the table,
        # except for this heartbeat's IP's first-time-alive
        # record:
        if UPDATE_TRUTH:
            self.updateTruth(dest.getFileName(), os.path.join(self.curDir, 'data/edxHeartbeatEventTruth.sql'))
        else:
            self.assertFileContentEquals(file('data/edxHeartbeatEventTruth.sql'), dest.getFileName())
        
        # Detecting server downtime:
        inputSourcePath = os.path.join(os.path.dirname(__file__),"data/edxHeartbeatEventDownTime.json")
        inFileSource = InURI(inputSourcePath)
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(inFileSource, 
                                       dest
                                       )
        
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Main', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert(prependColHeader=False)
        if UPDATE_TRUTH:
            self.updateTruth(dest.getFileName(), os.path.join(self.curDir, 'data/edxHeartbeatEventDownTimeTruth.sql'))
        else:
            self.assertFileContentEquals(file('data/edxHeartbeatEventDownTimeTruth.sql'), dest.getFileName())

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testTableCreationStatementConstruction(self):
        fileConverter = JSONToRelation(self.stringSource,
                                       OutputFile(os.devnull, OutputDisposition.OutputFormat.CSV),
                                       mainTableName='Main'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Main', replaceTables=True)
        createStatement = edxParser.genOneCreateStatement('Answer', edxParser.schemaAnswerTbl, primaryKeyName='answer_id')
        
        if UPDATE_TRUTH:
            self.updateTruthFromString(createStatement, os.path.join(self.curDir, 'data/answerTblCreateTruth.sql'))
        else:
            self.assertFileContentEquals(file('data/answerTblCreateTruth.sql'), createStatement)
       
        
    @unittest.skipIf(not PRINT_OUTS, "Temporarily disabled")
    def testAllTableCreation(self):
        '''
        This test is being skipped by the decorator above.
        It would fail any time any of the tables change. But
        Running it nicely prints all the CREATE TABLE statements
        that are created.
        '''
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
            
        with open(dest.getFileName()) as fd:
            for line in fd:
                sys.stdout.write(line)
 
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testProblemCheckEventTypeComplexCase(self):

        testFilePath = os.path.join(os.path.dirname(__file__),"data/problem_checkEventFldOnly.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        # Read the isolated problem_check event:
        with open(testFilePath) as fd:
            testProblemCheckEventJSON = fd.readline()
        event = json.loads(testProblemCheckEventJSON)
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        # Pretend a problem_check event had just been found.
        # Here: record is None, row to fill still empty (would
        # normally be the main table, partially filled row).
        edxParser.handleProblemCheck(None, [], event)

        fileConverter.flush()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/problem_checkEventFldOnlyTruth.sql"), 'r')

        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)
        
        
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")        
    def testProblemCheckSimpleCase(self):        
        # Another case that gave problems at some point; this 
        # time go through entire machinery:
        testFilePath = os.path.join(os.path.dirname(__file__),"data/problem_checkSimpleCase.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/problem_checkSimpleCaseTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)
        
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testProcessSeq_Goto(self):
        jsonStr = '{"username": "BetaTester1", "host": "class.stanford.edu", "session": "009e5b5e1bd4ab5a800cafc48bad9e44", "event_source": "browser", "event_type": "seq_goto", "time": "2013-06-08T23:29:58.346222", "ip": "24.5.14.103", "event": "{\\"old\\":2,\\"new\\":1,\\"id\\":\\"i4x://Medicine/HRP258/sequential/53b0357680d24191a60156e74e184be3\\"}", "agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0", "page": "https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/ac6d006c4bc84fc1a9cec412734fd5ca/53b0357680d24191a60156e74e184be3/"}'
        fileConverter = JSONToRelation(InString(jsonStr),
                                       OutputFile(os.devnull, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS),
                                       #OutputPipe(OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS),
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        
        row = []
        edxParser.processOneJSONObject(jsonStr, row)
        expected = str(['7634a6e1-a5e5-4758-9b6e-1f64b3696c1a', u'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0', u'browser', u'seq_goto', u'24.5.14.103', u'https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/ac6d006c4bc84fc1a9cec412734fd5ca/53b0357680d24191a60156e74e184be3/', u'009e5b5e1bd4ab5a800cafc48bad9e44', u'2013-06-08T23:29:58.346222', u'BetaTester1', '0:00:00', 'null', 'null', 'null', u'i4x://Medicine/HRP258/sequential/53b0357680d24191a60156e74e184be3', 2, 1])
        self.assertFileContentEquals(expected, str(row))
   
   
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testProblemSave(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/problemSaveTest.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/problemSaveTestTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testProblemCheckFail(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/problemCheckFailTest.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/problemCheckFailTestTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)
       

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testResetProblem(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/resetProblemTest.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/resetProblemTestTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)
       
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testAddRemoveUserGroup(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/addRemoveUserGroup.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/addRemoveUserGroupTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testCreateAccount(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/createAccountTest.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/createAccountTestTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testAbout(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/aboutTest.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/aboutTestTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testSeekVideo(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/seekVideo.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/seekVideoTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)
        
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testSeekVideoAnother(self):
        # Another case, which gave trouble at some point:
        testFilePath = os.path.join(os.path.dirname(__file__),"data/seekVideoOther.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/seekVideoOtherTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testShowTranscript(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/showTranscript.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/showTranscriptTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testIsStudentCalibrated(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/isStudentCalibrated.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/isStudentCalibratedTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testGotoPosition(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/gotoPosition.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/gotoPositionTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testProblem(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/problem.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/problemTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testSaveAnswer(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/saveAnswer.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/saveAnswerTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testSaveAnswerInPath(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/unterminatedString.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/unterminatedStringTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)


    
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testProblemCheckInPath(self):
        # Sometimes problem_check in event_type is styled as
        # a path: /foo/bar/problem_check
        testFilePath = os.path.join(os.path.dirname(__file__),"data/problemCheckInPath.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/problemCheckInPathTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)
       
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testAjaxLogin(self):
        # Sometimes problem_check in event_type is styled as
        # a path: /foo/bar/problem_check
        testFilePath = os.path.join(os.path.dirname(__file__),"data/loginAjax.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/loginAjaxTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testUnicode(self):
        # Sometimes problem_check in event_type is styled as
        # a path: /foo/bar/problem_check
        testFilePath = os.path.join(os.path.dirname(__file__),"data/unicode.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/unicodeTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

#     @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
#     def testProblemGraded(self):
#         testFilePath = os.path.join(os.path.dirname(__file__),"data/problemGraded.json")
#         stringSource = InURI(testFilePath)
#         
#         resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
#         # Just use the file name of the tmp file.
#         resultFileName = resultFile.name
#         resultFile.close()
#         dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
#         fileConverter = JSONToRelation(stringSource,
#                                        dest,
#                                        mainTableName='Event'
#                                        )
#         edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
#         fileConverter.setParser(edxParser)
#         fileConverter.convert()
#         dest.close()
#         truthFile = open(os.path.join(os.path.dirname(__file__),"data/problemGradedTruth.sql"), 'r')
#         if UPDATE_TRUTH:
#             self.updateTruth(dest.name, truthFile.name)
#         else:
#             self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testNotFullscreen(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/notFullscreen.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/notFullscreenTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testFullscreen(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/fullscreen.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/fullscreenTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testVideoSpeedChange(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/speedChangeVideo.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/speedChangeVideoTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testChangeEmailSettings(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/changeEmailSettings.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/changeEmailSettingsTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testProblemReset(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/problemReset.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/problemResetTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)
        
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testUnicodeOutOfRange(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/unicodeOutOfRange.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/unicodeOutOfRangeTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testScottishNames(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/insertForScots.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/insertForScotsTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testSaveProblemCheck(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/saveProblemCheck.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/saveProblemCheckTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testURLEscapedAnswerChoice(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/urlEscapedAnswerChoice.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/urlEscapedAnswerChoiceTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)


    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testProblemGradedOneProblemNoStatus(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/problemGradedOneProblemNoStatus.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/problemGradedOneProblemNoStatusTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testProblemGradedOneProblemWithStatus(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/problemGradedOneProblemWithStatus.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/problemGradedOneProblemWithStatusTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testProblemGradedThreeProblemsIncompleteJSON(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/problemGradedSeveralProblems.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='Event'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Event', replaceTables=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/problemGradedSeveralProblemsTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)


        
    #--------------------------------------------------------------------------------------------------    
    def assertFileContentEquals(self, expected, filePathOrStrToCompareTo):
        if isinstance(expected, file):
            strFile = expected
        else:
            strFile = StringIO.StringIO(expected)
        # Check whether filePathOrStrToCompareTo is a file path or a string:
        try:
            open(filePathOrStrToCompareTo, 'r').close()
            filePath = filePathOrStrToCompareTo
        except IOError:
            # We are to compare against a string. Just
            # write it to a tmp file that deletes itself:
            tmpFile = tempfile.NamedTemporaryFile()
            tmpFile.write(filePathOrStrToCompareTo)
            tmpFile.flush()
            filePath = tmpFile.name
        
        with open(filePath, 'r') as fd:
            for fileLine in fd:
                expectedLine = strFile.readline()
                # Some events have one or more UUIDs, which are different with each run.
                # Cut those out of both expected and what we got:
                uuidsRemoved = False
                while not uuidsRemoved:
                    uuidMatch = self.pattern.search(fileLine)
                    if uuidMatch is None:
                        uuidsRemoved = True
                        continue
                    expectedLine = expectedLine[0:uuidMatch.start()] + expectedLine[uuidMatch.end():]
                    fileLine = fileLine[0:uuidMatch.start()] + fileLine[uuidMatch.end():]
                self.assertEqual(expectedLine.strip(), fileLine.strip())
            
            if strFile.readline() != "":
                # expected is longer than what's in the file:
                self.fail("Expected string is longer than content of output file %s" % filePath)

    def printFile(self, fileName):
        with open(fileName, 'r') as fd:
            print(fd.readline())
             
    def updateTruth(self, newTruthFilePath, destinationTruthFilePath):
        shutil.copy(newTruthFilePath, destinationTruthFilePath)
        
    def updateTruthFromString(self, newTruthStr, destinationTruthFilePath):
        with open(destinationTruthFilePath, 'w') as fd:
            fd.write(newTruthStr)
             
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testGetCourseID']
    unittest.main()
    