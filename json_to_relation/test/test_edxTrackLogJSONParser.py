'''
Created on Oct 3, 2013

The following tests were bad before column 'quarter' was introduced:
   testCourseIdGetsProbId
   testEnrollmentActivatedDeactivated
   testGotoPosition
   testIsStudentCalibrated
   testKeyErrorHRP259
   testNoCourseIDInProblemCheck
   testProblem
   testProblemCheckInPath
   testProcessSeq_Goto
   testRescueJSON
   testSaveAnswer
   testTableCreationStatementConstruction

So they need attention. At least some of the other tests need adjustment of 
truth to the new column being presents.   

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

from json_to_relation.edxTrackLogJSONParser import EdXTrackLogJSONParser
from json_to_relation.input_source import InURI
from json_to_relation.json_to_relation import JSONToRelation
from json_to_relation.locationManager import LocationManager
from json_to_relation.modulestoreImporter import ModulestoreImporter
from json_to_relation.output_disposition import OutputDisposition, ColDataType, TableSchemas, \
    ColumnSpec, OutputFile, OutputPipe # @UnusedImport


TEST_ALL = False
PRINT_OUTS = False  # Set True to get printouts of CREATE TABLE statements

# The following is very Dangerous: If True, no tests are
# performed. Instead, all the reference files, the ones
# ending with 'Truth.sql' will be changed to be whatever
# the test returns. Use only when you made code changes that
# invalidate all the truth files:
UPDATE_TRUTH = False

class TestEdxTrackLogJSONParser(unittest.TestCase):
    
    hashLookupDict = None
    
    @classmethod
    def setUpClass(cls):
        '''
        Called once, pulling a fresh version of the full modulestore 
        JSON file, to see whether that succeeds. Subsequent instantiations 
        of ModulestoreImporter then use the resulting cache, or use
        a smaller excerpt.
        @param cls: TestEdxTrackLogJSONParser
        @type cls: Class
        '''
        # Hash dict pickle doesn't exist yet. Make it exist:
        jsonModulestoreExcerpt = os.path.join(os.path.dirname(__file__), '../data/modulestore_latest.json')
        #jsonModulestoreExcerpt = os.path.join(os.path.dirname(__file__), 'data/modulestore_sample.json')
        if not os.path.exists(jsonModulestoreExcerpt):
            raise IOError('Neither OpenEdx hash-to-displayName JSON excerpt from modulestore, nor a cache thereof is available. You need to run cronRefreshModuleStore.sh')
        print("About to load modulestore JSON lookup dict from %s" % jsonModulestoreExcerpt)
        ModulestoreImporter(jsonModulestoreExcerpt, useCache=True)
        print('Done loading modulestore JSON lookup dict')
    
    def setUp(self):
        
        super(TestEdxTrackLogJSONParser, self).setUp()
        self.currDir = os.path.dirname(__file__)
        self.hashLookupDict = TestEdxTrackLogJSONParser.hashLookupDict  
        self.uuidRegex = '[a-f0-9]{8}_[a-f0-9]{4}_[a-f0-9]{4}_[a-f0-9]{4}_[a-f0-9]{12}'
        self.pattern   = re.compile(self.uuidRegex)
        # Match ISO 8601 strings:
        #self.timestampRegex = r'[1-2][0-9][0-1][0-9][0-1][0-9][0-3][0-9][0-2][0-9][0-5][0-9][0-5][0-9][0-9]{8}'
        #self.timestampRegex = r'[1-2][0-9]{3}-[0-1][1-9]-[0-3]{2}T[0-2][0-9]:[0-6][0-9]:[0-6][0-9].[0-9]{0:6}Z'
        #self.timestampRegex = r'[1-2][0-9]{3}-[0-1][1-9]-[0-3]{2}T[0-2][0-9]:[0-6][0-9]:[0-6][0-9]\.[0-9]{0,6}Z{0,1}'
        #self.timestampRegex = r'[1-2][0-9]{3}-[0-1][1-9]-[0-3][0-9]T[0-2][0-9]:[0-6][0-9]:[0-6][0-9]\.[0-9]{0,6}Z{0,1}'
        self.timestampRegex = r'[1-2][0-9]{3}-[0-1][0-9]-[0-3][0-9]T[0-2][0-9]:[0-6][0-9]:[0-6][0-9]\.[0-9]{0,6}Z{0,1}'
        self.timestampPattern = re.compile(self.timestampRegex)
        # Pattern that recognizes our tmp files. They start with
        # 'oolala', followed by random junk, followed by a period and
        # 0 to 3 file extension letters (always 3, I believe):
        self.tmpFileNamePattern = re.compile('/tmp/oolala[^.]*\..{0,3}')
        
        self.loginEvent = '{"username": "",   "host": "class.stanford.edu",   "event_source": "server",   "event_type": "/accounts/login",   "time": "2013-06-14T00:31:57.661338",   "ip": "98.230.189.66",   "event": "{\\"POST\\": {}, \\"GET\\": {\\"next\\": [\\"/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/80160exxx/\\"]}}",   "agent": "Mozilla/5.0 (Windows NT 5.1; rv:21.0) Gecko/20100101  Firefox/21.0",   "page": null}' 
        self.dashboardEvent = '{"username": "", "host": "class.stanford.edu", "event_source": "server", "event_type": "/accounts/login", "time": "2013-06-10T05:13:37.499008", "ip": "91.210.228.6", "event": "{\\"POST\\": {}, \\"GET\\": {\\"next\\": [\\"/dashboard\\"]}}", "agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1", "page": null}'
        self.videoEvent = '{"username": "smith", "host": "class.stanford.edu", "session": "f011450e5f78d954ce5a475de473a454", "event_source": "browser", "event_type": "speed_change_video",  "time": "2013-06-21T06:31:11.804290+00:00", "ip": "80.216.21.147", "event": "{\\"id\\":\\"i4x-Medicine-HRP258-videoalpha-be496fded4f8424da9aacc553f480fa5\\",\\"code\\": \\"html5\\",\\"currentTime\\":474.524041,\\"old_speed\\":\\"0.25\\",\\"new_speed\\":\\"1.0\\"}", "agent": "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like  Gecko) Chrome/28.0.1500.44 Safari/537.36", "page": "https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/64abcdd9afc54c6089a284e985 3da6ea/2a8de59355e349b7ae40aba97c59736f/"}' 
        self.heartbeatEvent = '{"username": "", "host": "10.0.10.32", "event_source": "server", "event_type": "/heartbeat", "time": "2013-06-21T06:32:09.881521+00:00", "ip": "127.0.0.1", "event": "{\\"POST\\": {}, \\"GET\\": {}}", "agent": "ELB-HealthChecker/1.0", "page": null}'

        self.stringSource = None
        self.stringSource = InURI(os.path.join(self.currDir ,"data/twoJSONRecords.json"))

    def tearDown(self):
        if self.stringSource is not None:
            self.stringSource.close()

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testLocationManager(self):
        lm = LocationManager()
        self.assertTrue(lm.isCountry('senegal'))
        self.assertTrue(lm.isCountry('Senegal'))
        self.assertEqual(len(lm.isCountry('brrooohaha')), 0)


    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testMakeJSONSafe(self):
        fileConverter = JSONToRelation(self.stringSource,
                                       OutputFile(os.devnull, OutputDisposition.OutputFormat.CSV),
                                       mainTableName='Main'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Main', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Main', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        badJSONStr = '{"username": "Gvnmaele", "host": "class.stanford.edu", "session": "ec36da02f42320bd1686a4f5a43daf0b", "event_source": "browser", "event_type": "problem_graded", "time": "2013-08-04T07:41:16.220676+00:00", "ip": "81.165.215.195", "event": "the event..."'        
        row = []
        edxParser.rescueBadJSON(badJSONStr, row=row)
        if UPDATE_TRUTH:
            self.updateTruthFromString(str(row), os.path.join(self.currDir, 'data/rescueJSONTruth1.txt'))
        else:
            self.assertFileContentEquals(os.path.join(self.currDir, 'data/rescueJSONTruth1.txt'), 
                                         str(row))
        
        badJSONStr = "{u'username': u'Magistra', u'event_source': u'server', u'event_type': u'/courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/peergrading/ef6ba7f803bb46ebaaf008cde737e3e9/save_grade', u'ip': u'209.216.182.65', u'agent': u'Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.66 Safari/537.36', u'page': None, u'host': u'class.stanford.edu', u'time': u'2013-09-14T06:55:57.003501+00:00', u'event': u'{\"POST\": {\"submission_id\": [\"51255\"], \"feedback\": [\"The thumbs up does seem like a great idea. How do you think she manages to communicate to students that she does take each answer seriously? Is it that she takes time to record each way of thinking accurately? This seems very important in engaging all students.\"], \"rubric_scores[]\": [\"1\"], \"answer_unknown\": [\"false\"], \"location\": [\"i4x://Education/EDUC115N/combinedopenended/0d67667941cd4e14ba29abd1542a9c5f\"], \"submission_key\": [\"414b8d746627f6db8d705605b16'}"
        row = []
        edxParser.rescueBadJSON(badJSONStr, row=row)
        if UPDATE_TRUTH:
            self.updateTruthFromString(str(row), os.path.join(self.currDir, 'data/rescueJSONTruth2.txt'))
        else:
            self.assertFileContentEquals(os.path.join(self.currDir, 'data/rescueJSONTruth2.txt'), str(row))

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testExtractCourseIDFromProblemXEvent(self):
        fileConverter = JSONToRelation(self.stringSource,
                                       OutputFile(os.devnull, OutputDisposition.OutputFormat.CSV),
                                       mainTableName='Main'                                       
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Main', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fakeEvent = '"event": {"success": "correct", "correct_map": {"i4x-Medicine-HRP258-problem-8dd11b4339884ab78bc844ce45847141_2_1": {"hint": "", "hintmode": null,'
        courseID = edxParser.extractCourseIDFromProblemXEvent(fakeEvent)
        self.assertEqual(courseID, 'Medicine-HRP258')
    
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
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Main', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
          
        courseName = edxParser.extractShortCourseID('/courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/combinedopenended/3aa97047991b4e208ebb1a72cc9ff579/')          
        self.assertEqual('Education/EDUC115N/How_to_Learn_Math', courseName)

        courseName = edxParser.extractShortCourseID('/courses/OpenEdX/200/Stanford_Sandbox/modx/i4x://OpenEdX/200/combinedopenended/5fb3b40e76a14752846008eeaca05bdf/check_for_score')
        self.assertEqual('OpenEdX/200/Stanford_Sandbox', courseName)

        (longName, courseName, display_name) = edxParser.get_course_id({"username": "RayRal", "host": "class.stanford.edu", "event_source": "server", "event_type": "save_problem_check", "time": "2013-06-11T16:49:54.047852", "ip": "79.100.83.89", "event": {"success": "correct", "correct_map": {"i4x-Medicine-HRP258-problem-0c6cf38317be42e0829d10cc68e7451b_2_1": {"hint": "", "hintmode": "null", "correctness": "correct", "msg": "", "npoints": "null", "queuestate": "null"}}, "attempts": 1, "answers": {"i4x-Medicine-HRP258-problem-0c6cf38317be42e0829d10cc68e7451b_2_1": "choice_1"}, "state": {"student_answers": {}, "seed": 1, "done": "null", "correct_map": {}, "input_state": {"i4x-Medicine-HRP258-problem-0c6cf38317be42e0829d10cc68e7451b_2_1": {}}}, "problem_id": "i4x://Medicine/HRP258/problem/0c6cf38317be42e0829d10cc68e7451b"}, "agent": "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36", "page": "x_module"})  # @UnusedVariable
        self.assertEqual('Medicine-HRP258', courseName)

        courseName = edxParser.extractShortCourseID('i4x://Education/EDUC115N/combinedopenended/0d67667941cd4e14ba29abd1542a9c5f')
        self.assertEqual('', courseName)

        (fullCourseName, courseName, display_name) = edxParser.get_course_id(json.loads(self.loginEvent))  # @UnusedVariable
        self.assertEqual('/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/80160exxx/', fullCourseName)
        self.assertEqual('Medicine/HRP258/Statistics_in_Medicine', display_name)
        
        (fullCourseName, courseName, display_name) = edxParser.get_course_id(json.loads(self.videoEvent))  # @UnusedVariable
        self.assertEqual('https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/64abcdd9afc54c6089a284e985 3da6ea/2a8de59355e349b7ae40aba97c59736f/', fullCourseName)
        self.assertEqual('Medicine/HRP258/Statistics_in_Medicine', display_name)
        
        (fullCourseName, courseName, display_name) = edxParser.get_course_id(json.loads(self.dashboardEvent))  # @UnusedVariable
        self.assertEqual('', fullCourseName)        
        self.assertEqual('', courseName)        

        (fullCourseName, courseName, display_name) = edxParser.get_course_id(json.loads(self.heartbeatEvent))  # @UnusedVariable
        self.assertEqual('', fullCourseName)        
        self.assertEqual('', courseName)
        
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testProcessOneJSONObject(self):
        fileConverter = JSONToRelation(self.stringSource,
                                       OutputFile(os.devnull, OutputDisposition.OutputFormat.CSV),
                                       mainTableName='Main'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Main', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        
        row = []
        edxParser.processOneJSONObject(self.loginEvent, row)
        #print row
        
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testEdxHeartbeat(self):        
        # Test series of heartbeats that did not experience a server outage:
        inputSourcePath = os.path.join(os.path.join(self.currDir, "data/edxHeartbeatEvent.json"))
        inFileSource = InURI(inputSourcePath)
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(inFileSource, 
                                       dest
                                       )
        
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Main', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert(prependColHeader=False)
        # We should find no heartbeat info in the table,
        # except for this heartbeat's IP's first-time-alive
        # record:
        if UPDATE_TRUTH:
            self.updateTruth(dest.getFileName(), os.path.join(self.currDir, 'data/edxHeartbeatEventTruth.sql'))
        else:
            with open(os.path.join(self.currDir, 'data/edxHeartbeatEventTruth.sql'),'r') as truthFd:
                self.assertFileContentEquals(truthFd, dest.getFileName())
        
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
        
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Main', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert(prependColHeader=False)
        if UPDATE_TRUTH:
            self.updateTruth(dest.getFileName(), os.path.join(self.currDir, 'data/edxHeartbeatEventDownTimeTruth.sql'))
        else:
            with open(os.path.join(self.currDir, 'data/edxHeartbeatEventDownTimeTruth.sql'),'r') as truthFd:
                self.assertFileContentEquals(truthFd, dest.getFileName())

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testTableCreationStatementConstruction(self):
        fileConverter = JSONToRelation(self.stringSource,
                                       OutputFile(os.devnull, OutputDisposition.OutputFormat.CSV),
                                       mainTableName='Main'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'Main', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        createStatement = edxParser.genOneCreateStatement('Answer', edxParser.schemaAnswerTbl, primaryKeyName='answer_id')
        
        if UPDATE_TRUTH:
            self.updateTruthFromString(createStatement, os.path.join(self.currDir, 'data/answerTblCreateTruth.sql'))
        else:
            with open(os.path.join(self.currDir, 'data/answerTblCreateTruth.sql'),'r') as truthFd:
                self.assertFileContentEquals(truthFd, createStatement) 
       
        
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
    def testExtractCanonicalCourseName(self):

        testFilePath = os.path.join(os.path.dirname(__file__),"data/dummyInput.json")
        stringSource = InURI(testFilePath)
        
        dest = OutputFile('/dev/null', OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        self.assertEqual('Medicine/HRP258/Statistics_in_Medicine', edxParser.extractCanonicalCourseName('Medicine/HRP258/Statistics_in_Medicine'))
        self.assertEqual('Education/EDUC115N/How_to_Learn_Math', edxParser.extractCanonicalCourseName('/courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/sequential/1b3ac347ca064b3eaaddbc27d4200964/goto_position'))
 
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/problem_checkSimpleCaseTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)
        
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testProblemCheckWithEmbeddedQuotes(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/problem_checkSingleQuoteInside.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/problem_checkSingleQuoteInsideTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)
        
        
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testProcessSeq_Goto(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/processSeq_Goto.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/processSeq_GotoTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)
   
   
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/addRemoveUserGroupTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testCreateAccountZipNoCountry(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/createAccountTest.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/createAccountTestTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testCreateAccountZipWithOtherCountry(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/createAccountZipOtherCountry.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/createAccountZipOtherCountryTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testCreateAccountTrueZipWithOtherCountry(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/createAccountNearCountryMiss.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/createAccountNearCountryMissTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testCreateAccountUnitedArabEmirates(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/createAccountUnitedArabEmirates.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/createAccountUnitedArabEmiratesTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)


    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testCreateAccountUS(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/createAccountUS.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/createAccountUSTruth.sql"), 'r')
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
#                                        mainTableName='EdxTrackEvent'
#                                        )
#         edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
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
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/problemGradedSeveralProblemsTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testUnicodeOutOfBounds(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/unicodeOutOfBound.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/unicodeOutOfBoundTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testLoadInfo(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/problemGradedOneProblemWithStatus.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/problemGradedOneProblemWithStatusTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testOCallaghan(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/ocallaghan.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/ocallaghanTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")        
    def testProblemCheckSimpleCaseCSV(self):        
        # Another case that gave problems at some point; this 
        # time go through entire machinery:
        testFilePath = os.path.join(os.path.dirname(__file__),"data/csvSimpleProblemCheck.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.CSV)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        if UPDATE_TRUTH:
            # The main file (which loads the constituent CSV files):
            truthFileMainTableName = os.path.join(os.path.dirname(__file__),"data/csvSimpleProblemCheckMainTableTruth.sql")
            self.updateTruth(dest.name, truthFileMainTableName)
            
            # New truth for the EdxTrackEven table:
            truthFileEdxTrackEventName = os.path.join(os.path.dirname(__file__),"data/csvSimpleProblemCheckEdxTrackEventTableTruth.csv")
            self.updateTruth(dest.name + '_EdxTrackEventTable.csv', truthFileEdxTrackEventName)
            
            # New truth for the Answer table:
            truthFileAnswerName = os.path.join(os.path.dirname(__file__),"data/csvSimpleProblemCheckAnswerTableTruth.csv")
            self.updateTruth(dest.name + '_AnswerTable.csv', truthFileAnswerName)
            
            # New truth for the LoadInfo table:
            truthFileLoadInfoName = os.path.join(os.path.dirname(__file__),"data/csvSimpleProblemCheckLoadInfoTableTruth.csv")
            self.updateTruth(dest.name + '_LoadInfoTable.csv', truthFileLoadInfoName)
        else:
            truthFile = open(os.path.join(os.path.dirname(__file__),"data/csvSimpleProblemCheckMainTableTruth.sql"), 'r')
            self.assertFileContentEquals(truthFile, dest.name)

            truthFile = open(os.path.join(os.path.dirname(__file__),"data/csvSimpleProblemCheckAnswerTableTruth.csv"), 'r')                        
            self.assertFileContentEquals(truthFile, dest.name + '_AnswerTable.csv')
            
            truthFile = open(os.path.join(os.path.dirname(__file__),"data/csvSimpleProblemCheckLoadInfoTableTruth.csv"), 'r')
            self.assertFileContentEquals(truthFile, dest.name + '_LoadInfoTable.csv')
            
            truthFile = open(os.path.join(os.path.dirname(__file__),"data/csvSimpleProblemCheckEdxTrackEventTableTruth.csv"), 'r')
            self.assertFileContentEquals(truthFile, dest.name + '_EdxTrackEventTable.csv')            

            self.assertEqual(os.stat(dest.name + '_AccountTable.csv').st_size, 0)
            self.assertEqual(os.stat(dest.name + '_CorrectMapTable.csv').st_size, 0)
            self.assertEqual(os.stat(dest.name + '_InputStateTable.csv').st_size, 0)
            self.assertEqual(os.stat(dest.name + '_StateTable.csv').st_size, 0)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testCourseIdGetsProbId(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/courseIdGetsProbId.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/courseIdGetsProbIdTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testNoCourseIDInProblemCheck(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/noCourseIDInProblemCheck.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/noCourseIDInProblemCheckTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testKeyErrorHRP259(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/keyErrorHRP259.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/keyErrorHRP259Truth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testABExperimentAssigned_user_to_partition(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/abExpAssignUser.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/abExpAssignUserTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testABExperimentRenderChild(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/abExpChildRender.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/abExpChildRenderTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testABExperimentSomeEventAfterAssignmentToGroup(self):
 
        # Fire two events: an assigned_user_to_partition event
        # followed by a fullscreen event:
        testFilePath = os.path.join(os.path.dirname(__file__),"data/fullScreenForAbExperimentStudent.json")
        stringSource = InURI(testFilePath)
         
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
         
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/fullScreenForAbExperimentStudentTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testEnrollmentActivatedDeactivated(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/enrollActivated.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/enrollActivatedTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    #@unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testQuarter(self):
        testFilePath = os.path.join(os.path.dirname(__file__),"data/quarter.json")
        stringSource = InURI(testFilePath)
        
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/quarterTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)


    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testInstructorEventsOnlyCommonFields(self):
 
        # Several instructor events have only the common fields; event field is empty.
        # Examples: dump_answer_dist_csv, dump_grades, list_beta_testers, list_students:
        testFilePath = os.path.join(os.path.dirname(__file__),"data/eventsWithOnlyCommonFields.json")
        stringSource = InURI(testFilePath)
         
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
         
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/eventsWithOnlyCommonFieldsTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testForumEvent(self):
 
        testFilePath = os.path.join(os.path.dirname(__file__),"data/forumEvent.json")
        stringSource = InURI(testFilePath)
         
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        fileConverter = JSONToRelation(stringSource,
                                       dest,
                                       mainTableName='EdxTrackEvent'
                                       )
        edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
        fileConverter.setParser(edxParser)
        fileConverter.convert()
        dest.close()
         
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/forumEventTruth.sql"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)


#     @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
#     def testHuntDupKey(self):
#         testFilePath = os.path.join(os.path.dirname(__file__),"data/huntDupKey.json")
#         stringSource = InURI(testFilePath)
#         
#         resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
#         # Just use the file name of the tmp file.
#         resultFileName = resultFile.name
#         resultFile.close()
#         dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
#         fileConverter = JSONToRelation(stringSource,
#                                        dest,
#                                        mainTableName='EdxTrackEvent'
#                                        )
#         edxParser = EdXTrackLogJSONParser(fileConverter, 'EdxTrackEvent', replaceTables=True, dbName='Edx', useDisplayNameCache=True)
#         fileConverter.setParser(edxParser)
#         fileConverter.convert()
#         dest.close()
#         truthFile = open(os.path.join(os.path.dirname(__file__),"data/huntDupKeyTruth.sql"), 'r')
#         if UPDATE_TRUTH:
#             self.updateTruth(dest.name, truthFile.name)
#         else:,


    #--------------------------------------------------------------------------------------------------    
    def assertFileContentEquals(self, expected, filePathOrStrToCompareTo):
        '''
        Compares two file or string contents. First arg is either an open file or a string.
        That is the ground truth to compare to. Second argument is the same: file or string.
        @param expected: the file that contains the ground truth
        @type expected: {File | String }
        @param filePathOrStrToCompareTo: the actual file as constructed by the module being tested
        @type filePathOrStrToCompareTo: { File | String }
        '''
        # Ensure that 'expected' is a File-like object:
        if isinstance(expected, file):
            # It's a file, just use it:
            strFile = expected
        else:
            # Turn into a string 'file':
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
                # The timestamp in the LoadInfo table changes on each run,
                # similar to UUIDs:
                timestampMatch = self.timestampPattern.search(fileLine)
                if timestampMatch is not None:
                    expectedLine = expectedLine[0:timestampMatch.start()] + expectedLine[timestampMatch.end():]
                    fileLine = fileLine[0:timestampMatch.start()] + fileLine[timestampMatch.end():]

                # Temp file names also change from run to run.
                # Replace the variable parts (ollalaxxxxx.yyy) with "foo":
                fileLine = self.tmpFileNamePattern.sub("foo", fileLine)
                expectedLine = self.tmpFileNamePattern.sub("foo", expectedLine)
                
                try:
                    self.assertEqual(expectedLine.strip(), fileLine.strip())
                except:
                    #print(expectedLine + '\n' + fileLine)
                    raise
            
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
    #*************8
    #unittest.main()
    suite = unittest.TestLoader().loadTestsFromTestCase(TestEdxTrackLogJSONParser)
    unittest.TextTestRunner(verbosity=2).run(suite)
    #*************8
