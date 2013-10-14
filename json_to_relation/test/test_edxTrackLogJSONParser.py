'''
Created on Oct 3, 2013

@author: paepcke
'''
import StringIO
from collections import OrderedDict
import json
import os
import re
import sys
import tempfile
import unittest

from json_to_relation.edxTrackLogJSONParser import EdXTrackLogJSONParser
from json_to_relation.input_source import InURI, InString
from json_to_relation.json_to_relation import JSONToRelation
from json_to_relation.output_disposition import OutputPipe, OutputDisposition, \
    ColDataType, TableSchemas, ColumnSpec, OutputFile


TEST_ALL = True

class TestEdxTrackLogJSONParser(unittest.TestCase):
    
    def setUp(self):
        super(TestEdxTrackLogJSONParser, self).setUp()  
        self.uuidRegex = '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}'
        self.pattern   = re.compile(self.uuidRegex)
        self.loginEvent = '{"username": "",   "host": "class.stanford.edu",   "event_source": "server",   "event_type": "/accounts/login",   "time": "2013-06-14T00:31:57.661338",   "ip": "98.230.189.66",   "event": "{\\"POST\\": {}, \\"GET\\": {\\"next\\": [\\"/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/80160exxx/\\"]}}",   "agent": "Mozilla/5.0 (Windows NT 5.1; rv:21.0) Gecko/20100101  Firefox/21.0",   "page": null}' 
        self.dashboardEvent = '{"username": "", "host": "class.stanford.edu", "event_source": "server", "event_type": "/accounts/login", "time": "2013-06-10T05:13:37.499008", "ip": "91.210.228.6", "event": "{\\"POST\\": {}, \\"GET\\": {\\"next\\": [\\"/dashboard\\"]}}", "agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1", "page": null}'
        self.videoEvent = '{"username": "smith", "host": "class.stanford.edu", "session": "f011450e5f78d954ce5a475de473a454", "event_source": "browser", "event_type": "speed_change_video",  "time": "2013-06-21T06:31:11.804290+00:00", "ip": "80.216.21.147", "event": "{\\"id\\":\\"i4x-Medicine-HRP258-videoalpha-be496fded4f8424da9aacc553f480fa5\\",\\"code\\": \\"html5\\",\\"currentTime\\":474.524041,\\"old_speed\\":\\"0.25\\",\\"new_speed\\":\\"1.0\\"}", "agent": "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like  Gecko) Chrome/28.0.1500.44 Safari/537.36", "page": "https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/64abcdd9afc54c6089a284e985 3da6ea/2a8de59355e349b7ae40aba97c59736f/"}' 
        self.heartbeatEvent = '{"username": "", "host": "10.0.10.32", "event_source": "server", "event_type": "/heartbeat", "time": "2013-06-21T06:32:09.881521+00:00", "ip": "127.0.0.1", "event": "{\\"POST\\": {}, \\"GET\\": {}}", "agent": "ELB-HealthChecker/1.0", "page": null}'

        self.stringSource = None

        self.stringSource = InURI(os.path.join(os.path.dirname(__file__),"data/twoJSONRecords.json"))
        self.fileConverter = JSONToRelation(self.stringSource,
                                            OutputPipe(OutputDisposition.OutputFormat.CSV),
                                            mainTableName='Main'

                                            )
         
        self.edxParser = EdXTrackLogJSONParser(self.fileConverter, 'Main')

    def tearDown(self):
        if self.stringSource is not None:
            self.stringSource.close()

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testTableSchemaRepo(self):
        tblRepo = TableSchemas()
        
        # Should initially have an empty schema for main (default) table:
        self.assertTrue(isinstance(tblRepo[None], OrderedDict))
        self.assertEquals(len(tblRepo[None]), 0)
        
        # Add single schema item to an empty repo
        tblRepo.addColSpec('myTbl', ColumnSpec('myCol', ColDataType.INT, self.fileConverter))
        self.assertEqual('INT', tblRepo['myTbl']['myCol'].getType())
        
        # Add single schema item to a non-empty repo:
        tblRepo.addColSpec('myTbl', ColumnSpec('yourCol', ColDataType.FLOAT, self.fileConverter))
        self.assertEqual('FLOAT', tblRepo['myTbl']['yourCol'].getType())
        
        # Add a dict with one spec to the existing schema:
        schemaAddition = OrderedDict({'hisCol' : ColumnSpec('hisCol', ColDataType.DATETIME, self.fileConverter)})
        tblRepo.addColSpecs('myTbl', schemaAddition)
        self.assertEqual('DATETIME', tblRepo['myTbl']['hisCol'].getType())
        
        # Add a dict with multiple specs to the existing schema:
        schemaAddition = OrderedDict({'hisCol' : ColumnSpec('hisCol', ColDataType.DATETIME, self.fileConverter),
                                      'herCol' : ColumnSpec('herCol', ColDataType.LONGTEXT, self.fileConverter)})
        tblRepo.addColSpecs('myTbl', schemaAddition)        
        self.assertEqual('DATETIME', tblRepo['myTbl']['hisCol'].getType())         
        self.assertEqual('LONGTEXT', tblRepo['myTbl']['herCol'].getType())                 
        

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testGetCourseID(self):
        #print self.edxParser.get_course_id(json.loads(self.loginEvent))
        (fullCourseName, courseName) = self.edxParser.get_course_id(json.loads(self.loginEvent))
        self.assertEqual('/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/80160exxx/', fullCourseName)
        self.assertEqual('Medicine/HRP258/Statistics_in_Medicine', courseName)
        
        (fullCourseName, courseName) = self.edxParser.get_course_id(json.loads(self.videoEvent))
        self.assertEqual('https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/64abcdd9afc54c6089a284e985 3da6ea/2a8de59355e349b7ae40aba97c59736f/', fullCourseName)
        self.assertEqual('Medicine/HRP258/Statistics_in_Medicine', courseName)
        
        (fullCourseName, courseName) = self.edxParser.get_course_id(json.loads(self.dashboardEvent))
        self.assertIsNone(fullCourseName)        
        self.assertIsNone(courseName)        

        (fullCourseName, courseName) = self.edxParser.get_course_id(json.loads(self.heartbeatEvent))
        self.assertIsNone(fullCourseName)        
        self.assertIsNone(courseName)        

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testProcessOneJSONObject(self):
        row = []
        self.edxParser.processOneJSONObject(self.loginEvent, row)
        #print row
        
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testEdxHeartbeat(self):
        # Test series of heartbeats that did not experience a server outage:
        inFileSource = InURI(os.path.join(os.path.dirname(__file__),"data/edxHeartbeatEvent.json"))
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        self.fileConverter = JSONToRelation(inFileSource, 
                                            dest
                                            )
        
        self.edxParser = EdXTrackLogJSONParser(self.fileConverter, 'Main')
        self.fileConverter.setParser(self.edxParser)
        self.fileConverter.convert(prependColHeader=False)
        # We should find no heartbeat info in the table,
        # except for this heartbeat's IP's first-time-alive
        # record:
        self.assertFileContentEquals(file('data/edxHeartbeatEventTruth.sql'), dest.getFileName())
        
        # Detecting server downtime:
        inFileSource = InURI(os.path.join(os.path.dirname(__file__),"data/edxHeartbeatEventDownTime.json"))
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        self.fileConverter = JSONToRelation(inFileSource, 
                                            dest
                                            )
        
        self.edxParser = EdXTrackLogJSONParser(self.fileConverter, 'Main')
        self.fileConverter.setParser(self.edxParser)
        self.fileConverter.convert(prependColHeader=False)
        self.assertFileContentEquals(file('data/edxHeartbeatEventDownTimeTruth.sql'), dest.getFileName())
        
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testTableCreation(self):
        resultFile = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.sql')
        # Just use the file name of the tmp file.
        resultFileName = resultFile.name
        resultFile.close()
        dest = OutputFile(resultFileName, OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS)
        self.fileConverter = JSONToRelation(InString('This text is unimportant'), 
                                            dest
                                            )
        
        self.edxParser = EdXTrackLogJSONParser(self.fileConverter, 'Main', replaceTables=True)

        with open(dest.getFileName()) as fd:
            for line in fd:
                sys.stdout.write(line)
    
                #--------------------------------------------------------------------------------------------------    
    def assertFileContentEquals(self, expected, filePath):
        if isinstance(expected, file):
            strFile = expected
        else:
            strFile = StringIO.StringIO(expected)
        with open(filePath, 'r') as fd:
            for fileLine in fd:
                # Some events have UUIDs, which are different with each run.
                # Cut those out of both expected and what we got:
                uuidMatch = self.pattern.search(fileLine)
                expectedLine = strFile.readline()
                if uuidMatch:
                    expectedLine = expectedLine[0:uuidMatch.start()] + expectedLine[uuidMatch.end():]
                    fileLine = fileLine[0:uuidMatch.start()] + fileLine[uuidMatch.end():]
                self.assertEqual(expectedLine.strip(), fileLine.strip())
            
            if strFile.readline() != "":
                # expected is longer than what's in the file:
                self.fail("Expected string is longer than content of output file %s" % filePath)

    
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testGetCourseID']
    unittest.main()