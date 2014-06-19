import StringIO
from collections import OrderedDict
import os
import shutil
import tempfile
import unittest

from json_to_relation.col_data_type import ColDataType
from json_to_relation.edxTrackLogJSONParser import EdXTrackLogJSONParser
from json_to_relation.input_source import InputSource, InURI, InString, InMongoDB, InPipe #@UnusedImport
from json_to_relation.json_to_relation import JSONToRelation
from json_to_relation.modulestoreImporter import ModulestoreImporter
from json_to_relation.output_disposition import ColumnSpec, OutputPipe, \
    OutputDisposition, OutputFile


# To speed up modulestore lookups during testing:
#from input_source import InURI
TEST_ALL = True

# The following is very Dangerous: If True, no tests are
# performed. Instead, all the reference files, the ones
# ending with 'Truth.sql' will be changed to be whatever
# the test returns. Use only when you made code changes that
# invalidate all the truth files:
UPDATE_TRUTH = False

class TestJSONToRelation(unittest.TestCase):
    
    def setUp(self):
        super(TestJSONToRelation, self).setUp()
        self.currDir = os.path.dirname(__file__)
        self.tmpLogFile = tempfile.NamedTemporaryFile()
        self.stringSource = InURI(os.path.join(os.path.dirname(__file__),"data/twoJSONRecords.json"))
        self.fileConverter = JSONToRelation(self.stringSource, 
                                            OutputPipe(OutputDisposition.OutputFormat.CSV),
                                            mainTableName='EdxTrackEvent',
                                            logFile=self.tmpLogFile.name
                                            )
        edxJsonToRelParser = EdXTrackLogJSONParser(self.fileConverter, "EdxTrackEvent", useDisplayNameCache=True)
        self.fileConverter.jsonParserInstance = edxJsonToRelParser
        # Remove various test output files if it exists:
        try:
            os.remove("testOutput.csv")
        except:
            pass
        try:
            os.remove("testOutputWithHeader.csv")
        except:
            pass
        try:
            os.remove("testArrays.csv")
        except:
            pass
        try:
            os.remove("testTinyEdXImport.csv")
        except:
            pass
        try:
            os.remove("testEdXImport.csv")
        except:
            pass
        try:
            os.remove("testEdXStressImport.csv")
        except:
            pass
        

        
    def tearDown(self):
        super(TestJSONToRelation, self).tearDown()
        self.tmpLogFile.close()
    
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def test_ensure_mysql_identifier_legal(self):

        # Vanilla, legal name
        newName = self.fileConverter.ensureLegalIdentifierChars("foo")
        self.assertEqual("foo", newName)

        # Comma in name requires quoting
        newName = self.fileConverter.ensureLegalIdentifierChars("foo,")
        self.assertEqual('"foo,"', newName)
        
        # Embedded single quotes:
        newName = self.fileConverter.ensureLegalIdentifierChars("fo'o")
        self.assertEqual('"fo\'o"', newName)

        # Embedded double quotes:
        newName = self.fileConverter.ensureLegalIdentifierChars('fo"o')
        self.assertEqual("'fo\"o'", newName)

        # Embedded double and single quotes:
        newName = self.fileConverter.ensureLegalIdentifierChars('fo"o\'bar')
        self.assertEqual("'fo\"o\'\'bar'", newName)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")        
    def test_simple_json(self):
        # Prints output to display, which we can't catch without
        # fuzzing with stdout. So just ensure no error happens: 
        self.fileConverter.convert()

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def test_simple_json_to_file(self):
        self.fileConverter = JSONToRelation(self.stringSource, 
                                            OutputFile("testOutput.csv", OutputDisposition.OutputFormat.CSV)
                                            )
        edxJsonToRelParser = EdXTrackLogJSONParser(self.fileConverter, "EdxTrackEvent", useDisplayNameCache=True)
        self.fileConverter.jsonParserInstance = edxJsonToRelParser
        self.fileConverter.convert()
        with open(os.path.join(self.currDir, 'data/simpleJsonToFileTruth.txt'), 'r') as fd:
            expected = fd.read()
#         expected = "asset,sainani.jpg,HRP258,c4x,Medicine,,image/jpeg,sainani.jpg,262144,/c4x/Medicine/HRP258/asset/sainani.jpg," +\
#                     "22333,,2013-05-08T22:47:09.762Z,,ebcb2a60b0d6b7475c4e9a102b82637b\n" +\
#                     "asset,medstats.png,HRP258,c4x,Medicine,,image/png,medstats.png,262144,/c4x/Medicine/HRP258/asset/medstats.png," +\
#                     "86597,,2013-05-08T22:48:38.174Z,,db47f263ac3532874b8f442ad8937d02"
        if UPDATE_TRUTH:
            self.updateTruthFromFile(os.path.join(self.curDir,'testOutput.csv'), 
                                     os.path.join(self.curDir, 'data/rescueJSONTruth1.txt'))
        else:
            self.assertFileContentEquals(expected, "testOutput.csv")

#     @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
#     def test_json_to_file_with_col_header(self):
#         self.fileConverter = JSONToRelation(self.stringSource, 
#                                             OutputFile("testOutputWithHeader.csv", OutputDisposition.OutputFormat.CSV),
#                                             mainTableName='EdxTrackEvent'
#                                             )
#         edxJsonToRelParser = EdXTrackLogJSONParser(self.fileConverter, "EdxTrackEvent", useDisplayNameCache=True)
#         edxJsonToRelParser.unittesting = True
#         self.fileConverter.jsonParserInstance = edxJsonToRelParser
#         self.fileConverter.convert(prependColHeader=True)
#         expected = '"""_id.category""","""_id.name""","""_id.course""","""_id.tag""","""_id.org""","""_id.revision""",contentType,' +\
#                    'displayname,chunkSize,filename,length,import_path,"""uploadDate.$date""",thumbnail_location,md5\n' +\
#                     "asset,sainani.jpg,HRP258,c4x,Medicine,,image/jpeg,sainani.jpg,262144,/c4x/Medicine/HRP258/asset/sainani.jpg," +\
#                     "22333,,2013-05-08T22:47:09.762Z,,ebcb2a60b0d6b7475c4e9a102b82637b\n" +\
#                     "asset,medstats.png,HRP258,c4x,Medicine,,image/png,medstats.png,262144,/c4x/Medicine/HRP258/asset/medstats.png," +\
#                     "86597,,2013-05-08T22:48:38.174Z,,db47f263ac3532874b8f442ad8937d02"
#         *******self.assertFileContentEquals(expected, "testOutputWithHeader.csv")


    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def test_arrays(self):
        source = InURI(os.path.join(os.path.dirname(__file__),"data/jsonArray.json"))
        self.fileConverter = JSONToRelation(source, 
                                            OutputFile("testArrays.csv", OutputDisposition.OutputFormat.CSV),
                                            mainTableName='EdxTrackEvent'
                                            )
        edxJsonToRelParser = EdXTrackLogJSONParser(self.fileConverter, "EdxTrackEvent", useDisplayNameCache=True)
        edxJsonToRelParser.unittesting = True
        self.fileConverter.jsonParserInstance = edxJsonToRelParser
        self.fileConverter.convert(prependColHeader=True)


    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def test_embedded_json_strings_comma_escaping(self):
        source = InURI(os.path.join(os.path.dirname(__file__),"data/tinyEdXTrackLog.json"))
        self.fileConverter = JSONToRelation(source, 
                                            OutputFile("testTinyEdXImport.csv", OutputDisposition.OutputFormat.CSV),
                                            mainTableName='EdxTrackEvent'
                                            )
        edxJsonToRelParser = EdXTrackLogJSONParser(self.fileConverter, "EdxTrackEvent", useDisplayNameCache=True)
        self.fileConverter.jsonParserInstance = edxJsonToRelParser
        self.fileConverter.convert(prependColHeader=True)
    
    
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def test_edX_tracking_import(self):
        source = InURI(os.path.join(os.path.dirname(__file__),"data/edxTrackLogSample.json"))
        self.fileConverter = JSONToRelation(source, 
                                            OutputFile("testEdXImport.csv", OutputDisposition.OutputFormat.CSV),
                                            mainTableName='EdxTrackEvent'                                            )
        edxJsonToRelParser = EdXTrackLogJSONParser(self.fileConverter, "EdxTrackEvent", useDisplayNameCache=True)
        self.fileConverter.jsonParserInstance = edxJsonToRelParser
        self.fileConverter.convert(prependColHeader=True)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def test_edX_stress_import(self):
        source = InURI(os.path.join(os.path.dirname(__file__),"data/tracking.log-20130609.gz"))

        print("Stress test: importing lots...")
        self.fileConverter = JSONToRelation(source, 
                                            OutputFile("testEdXStressImport.csv", OutputDisposition.OutputFormat.CSV),
                                            mainTableName='EdxTrackEvent',
                                            progressEvery=10
                                            )
        edxJsonToRelParser = EdXTrackLogJSONParser(self.fileConverter, "EdxTrackEvent", useDisplayNameCache=True)
        self.fileConverter.jsonParserInstance = edxJsonToRelParser
        self.fileConverter.convert(prependColHeader=True)
        print("Stress test done")
        

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def test_schema_hints(self):
        self.fileConverter = JSONToRelation(self.stringSource, 
                                            OutputFile("testOutput.csv", OutputDisposition.OutputFormat.CSV),
                                            mainTableName='EdxTrackEvent',
                                            schemaHints = OrderedDict()
                                            )
        edxJsonToRelParser = EdXTrackLogJSONParser(self.fileConverter, "EdxTrackEvent", useDisplayNameCache=True)
        self.fileConverter.jsonParserInstance = edxJsonToRelParser
        self.fileConverter.convert()
        schema = self.fileConverter.getSchema()
        #print schema
        #print map(ColumnSpec.getType, schema)
        self.assertEqual(['VARCHAR(40)', 'VARCHAR(40)', 'TEXT', 'VARCHAR(255)', 'TEXT', 'VARCHAR(255)', 'TEXT', 'TEXT', 'DATETIME', 'TEXT', 'DATETIME', 'TEXT', 'TEXT', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'INT', 'INT', 'VARCHAR(255)', 'TEXT', 'TEXT', 'TEXT', 'INT', 'TEXT', 'TEXT', 'VARCHAR(255)', 'TEXT', 'TINYINT', 'TEXT', 'VARCHAR(255)', 'INT', 'INT', 'VARCHAR(255)', 'TEXT', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'TEXT', 'TEXT', 'VARCHAR(255)', 'TEXT', 'TINYINT', 'TEXT', 'INT', 'INT', 'INT', 'INT', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'INT', 'TEXT', 'VARCHAR(40)', 'VARCHAR(40)', 'VARCHAR(40)', 'VARCHAR(40)'],
                         map(ColumnSpec.getType, schema))

        self.stringSource = InURI(os.path.join(os.path.dirname(__file__),"data/twoJSONRecords.json"))
        self.fileConverter = JSONToRelation(self.stringSource, 
                                            OutputFile("testOutput.csv", OutputDisposition.OutputFormat.CSV),
                                            mainTableName='EdxTrackEvent',
                                            schemaHints = OrderedDict({'chunkSize' : ColDataType.INT,
                                                           'length' : ColDataType.INT})
                                            )
        edxJsonToRelParser = EdXTrackLogJSONParser(self.fileConverter, "EdxTrackEvent", useDisplayNameCache=True)
        self.fileConverter.jsonParserInstance = edxJsonToRelParser
        self.fileConverter.convert()
        schema = self.fileConverter.getSchema()
        self.assertEqual(['VARCHAR(40)', 'VARCHAR(40)', 'TEXT', 'VARCHAR(255)', 'TEXT', 'VARCHAR(255)', 'TEXT', 'TEXT', 'DATETIME', 'TEXT', 'DATETIME', 'TEXT', 'TEXT', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'INT', 'INT', 'VARCHAR(255)', 'TEXT', 'TEXT', 'TEXT', 'INT', 'TEXT', 'TEXT', 'VARCHAR(255)', 'TEXT', 'TINYINT', 'TEXT', 'VARCHAR(255)', 'INT', 'INT', 'VARCHAR(255)', 'TEXT', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'TEXT', 'TEXT', 'VARCHAR(255)', 'TEXT', 'TINYINT', 'TEXT', 'INT', 'INT', 'INT', 'INT', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'INT', 'TEXT', 'VARCHAR(40)', 'VARCHAR(40)', 'VARCHAR(40)', 'VARCHAR(40)'],
                         map(ColumnSpec.getType, schema))


    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testInsertStatementConstruction(self):
        
        # No value array in hold-back buffer:
        self.fileConverter.currInsertSig = 'col1, col2'
        self.fileConverter.currOutTable = 'TestTable'
        self.fileConverter.currValsArray = []
        self.assertIsNone(self.fileConverter.finalizeInsertStatement())

        # One value array in hold-back buffer:
        self.fileConverter.currInsertSig = 'col1, col2'
        self.fileConverter.currOutTable = 'MyTable'
        self.fileConverter.currValsArray = [['foo', 10]]
        res = self.fileConverter.finalizeInsertStatement()
        #print res
        self.assertEqual("INSERT INTO MyTable (col1, col2) VALUES \n    ('foo',10);", res)
        
        self.fileConverter.currInsertSig = 'col1, col2'
        self.fileConverter.currOutTable = 'MyTable'
        self.fileConverter.currValsArray = [['foo', 10], ['bar', 20]]
        res = self.fileConverter.finalizeInsertStatement()
        #print res
        self.assertEqual("INSERT INTO MyTable (col1, col2) VALUES \n    ('foo',10),\n    ('bar',20);", res)
        
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testPrepareMySQLRow(self):
        
        # Pretend to be the edx parser, sending one insert's worth of
        # info. This will fit into the hold-back buffer, and return None:
        insertInfo = ('MyTable', 'col1, col2', [['foo', 10],['bar',20]])
        #print(res)
        self.assertEqual('LoadInfo', self.fileConverter.currOutTable)
        self.assertEqual('load_info_id,load_date_time,load_file', self.fileConverter.currInsertSig)
        currValsArr = self.fileConverter.currValsArray
        self.assertEqual('d4e622ff221b1eec00405f1b69893ff544ac5d75', currValsArr[0][0])
        self.assertEqual('file:///home/paepcke/EclipseWorkspaces/json_to_relation/json_to_relation/test/data/twoJSONRecords.json', currValsArr[0][2])
        
        # Lower the allowed MySQL packet size to force immediate creation of INSERT statement:
        self.fileConverter.__class__.MAX_ALLOWED_PACKET_SIZE = 3
        self.fileConverter.currInsertSig = None
        self.fileConverter.currOutTable = None
        self.fileConverter.currValsArray = []
        res = self.fileConverter.prepareMySQLRow(insertInfo)
        self.assertEqual("INSERT INTO MyTable (col1, col2) VALUES \n    ('foo',10),\n    ('bar',20);", res)

        # Set the allowed MySQL packet size to allow a first INSERT statement to be 
        # held back, but a second call must trigger sending of the held back
        # values, holding back the newly submitted values: 
        
        # First call:
        self.fileConverter.__class__.MAX_ALLOWED_PACKET_SIZE = 211
        self.fileConverter.currInsertSig = None
        self.fileConverter.currOutTable = None
        self.fileConverter.currValsArray = []
        res = self.fileConverter.prepareMySQLRow(insertInfo)
        self.assertIsNone(res)
        self.assertEqual('MyTable', self.fileConverter.currOutTable)
        self.assertEqual('col1, col2', self.fileConverter.currInsertSig)
        self.assertEqual([[['foo', 10], ['bar', 20]]], self.fileConverter.currValsArray)

        # Second call:
        insertMoreInfo = ('MyTable', 'col1, col2', [['blue', 30.1],['green',40.99]])
        res = self.fileConverter.prepareMySQLRow(insertMoreInfo)
        # Should have insert statement for the prior submission...
        self.assertEqual("INSERT INTO MyTable (col1, col2) VALUES \n    (['foo', 10],['bar', 20]);", res)
        # ... and the hold-back buffer should have the new submission:
        self.assertEqual('MyTable', self.fileConverter.currOutTable)
        self.assertEqual('col1, col2', self.fileConverter.currInsertSig)
        self.assertEqual([[['blue', 30.1], ['green', 40.99]]], self.fileConverter.currValsArray)
         
        # Call FLUSH to get the held-back values:
        res = self.fileConverter.prepareMySQLRow('FLUSH')
        self.assertEqual("INSERT INTO MyTable (col1, col2) VALUES \n    (['blue', 30.1],['green', 40.99]);", res)
        self.assertIsNone(self.fileConverter.currOutTable)
        self.assertIsNone(self.fileConverter.currInsertSig)
        self.assertEqual([], self.fileConverter.currValsArray)
        
#--------------------------------------------------------------------------------------------------    
    def assertFileContentEquals(self, expected, filePath):
        strFile = StringIO.StringIO(expected)
        with open(filePath, 'r') as fd:
            for fileLine in fd:
                expectedLine = strFile.readline()
                self.assertEqual(expectedLine.strip(), fileLine.strip())
            
            if strFile.readline() != "":
                # expected is longer than what's in the file:
                self.fail("Expected string is longer than content of output file %s" % filePath)
        
    def updateTruthFromFile(self, referenceFileName, actualTruthFileName):
        '''
        Copy actualTruthFileName content to referenceFileName. 
        ReferenceFileName is a ground truth file to which test run
        results are compared. When the code changes so much that editing
        that ground truth file to match the new correct output of the
        test, then accept the test output as the future ground truth.
        :param referenceFileName: File to be overwritten
        :type referenceFileName: String
        :param actualTruthFileName: Source file
        :type actualTruthFileName: String
        '''
        shutil.copyfile(actualTruthFileName, referenceFileName)
            
if __name__ == "__main__":
    unittest.main()
        