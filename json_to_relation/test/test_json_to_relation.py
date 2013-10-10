
import StringIO
from collections import OrderedDict
import os
import tempfile
import unittest

from json_to_relation.col_data_type import ColDataType
from json_to_relation.input_source import InputSource, InURI, InString, InMongoDB, InPipe #@UnusedImport
from json_to_relation.json_to_relation import JSONToRelation
from json_to_relation.output_disposition import ColumnSpec, OutputPipe, \
    OutputDisposition, OutputFile


#from input_source import InURI
TEST_ALL = False

class TestJSONToRelation(unittest.TestCase):
    
    def setUp(self):
        super(TestJSONToRelation, self).setUp()
        self.tmpLogFile = tempfile.NamedTemporaryFile()
        self.stringSource = InURI(os.path.join(os.path.dirname(__file__),"data/twoJSONRecords.json"))
        self.fileConverter = JSONToRelation(self.stringSource, 
                                            OutputPipe(),
                                            outputFormat=OutputDisposition.OutputFormat.CSV,
                                            logFile=self.tmpLogFile.name
                                            )
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
                                            OutputFile("testOutput.csv"),
                                            outputFormat = OutputDisposition.OutputFormat.CSV,
                                            )
        self.fileConverter.convert()
        expected = "asset,sainani.jpg,HRP258,c4x,Medicine,,image/jpeg,sainani.jpg,262144,/c4x/Medicine/HRP258/asset/sainani.jpg," +\
                    "22333,,2013-05-08T22:47:09.762Z,,ebcb2a60b0d6b7475c4e9a102b82637b\n" +\
                    "asset,medstats.png,HRP258,c4x,Medicine,,image/png,medstats.png,262144,/c4x/Medicine/HRP258/asset/medstats.png," +\
                    "86597,,2013-05-08T22:48:38.174Z,,db47f263ac3532874b8f442ad8937d02"
        self.assertFileContentEquals(expected, "testOutput.csv")

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def test_json_to_file_with_col_header(self):
        self.fileConverter = JSONToRelation(self.stringSource, 
                                            OutputFile("testOutputWithHeader.csv"),
                                            outputFormat = OutputDisposition.OutputFormat.CSV,
                                            )
        self.fileConverter.convert(prependColHeader=True)
        expected = '"""_id.category""","""_id.name""","""_id.course""","""_id.tag""","""_id.org""","""_id.revision""",contentType,' +\
                   'displayname,chunkSize,filename,length,import_path,"""uploadDate.$date""",thumbnail_location,md5\n' +\
                    "asset,sainani.jpg,HRP258,c4x,Medicine,,image/jpeg,sainani.jpg,262144,/c4x/Medicine/HRP258/asset/sainani.jpg," +\
                    "22333,,2013-05-08T22:47:09.762Z,,ebcb2a60b0d6b7475c4e9a102b82637b\n" +\
                    "asset,medstats.png,HRP258,c4x,Medicine,,image/png,medstats.png,262144,/c4x/Medicine/HRP258/asset/medstats.png," +\
                    "86597,,2013-05-08T22:48:38.174Z,,db47f263ac3532874b8f442ad8937d02"
        self.assertFileContentEquals(expected, "testOutputWithHeader.csv")


    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def test_arrays(self):
        source = InURI(os.path.join(os.path.dirname(__file__),"data/jsonArray.json"))
        self.fileConverter = JSONToRelation(source, 
                                            OutputFile("testArrays.csv"),
                                            outputFormat = OutputDisposition.OutputFormat.CSV,
                                            )
        self.fileConverter.convert(prependColHeader=True)


    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def test_embedded_json_strings_comma_escaping(self):
        source = InURI(os.path.join(os.path.dirname(__file__),"data/tinyEdXTrackLog.json"))
        self.fileConverter = JSONToRelation(source, 
                                            OutputFile("testTinyEdXImport.csv"),
                                            outputFormat = OutputDisposition.OutputFormat.CSV,
                                            )
        self.fileConverter.convert(prependColHeader=True)
    
    
    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def test_edX_tracking_import(self):
        source = InURI(os.path.join(os.path.dirname(__file__),"data/edxTrackLogSample.json"))
        self.fileConverter = JSONToRelation(source, 
                                            OutputFile("testEdXImport.csv"),
                                            outputFormat = OutputDisposition.OutputFormat.CSV,
                                            )
        self.fileConverter.convert(prependColHeader=True)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def test_edX_stress_import(self):
        source = InURI(os.path.join(os.path.dirname(__file__),"data/tracking.log-20130609.gz"))

        print("Stress test: importing lots...")
        self.fileConverter = JSONToRelation(source, 
                                            OutputFile("testEdXStressImport.csv"),
                                            outputFormat = OutputDisposition.OutputFormat.CSV,
                                            progressEvery=10
                                            )
        self.fileConverter.convert(prependColHeader=True)
        print("Stress test done")
        

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def test_schema_hints(self):
        self.fileConverter = JSONToRelation(self.stringSource, 
                                            OutputFile("testOutput.csv"),
                                            outputFormat = OutputDisposition.OutputFormat.CSV,
                                            schemaHints = OrderedDict()
                                            )
        self.fileConverter.convert()
        schema = self.fileConverter.getSchema()
        #print schema
        #print map(ColumnSpec.getType, schema)
        self.assertEqual(['TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT', 'DOUBLE', 'TEXT', 'DOUBLE', 'TEXT', 'TEXT', 'TEXT', 'TEXT'],
                         map(ColumnSpec.getType, schema))

        self.stringSource = InURI(os.path.join(os.path.dirname(__file__),"data/twoJSONRecords.json"))
        self.fileConverter = JSONToRelation(self.stringSource, 
                                            OutputFile("testOutput.csv"),
                                            outputFormat = OutputDisposition.OutputFormat.CSV,
                                            schemaHints = OrderedDict({'chunkSize' : ColDataType.INT,
                                                           'length' : ColDataType.INT})
                                            )
        self.fileConverter.convert()
        schema = self.fileConverter.getSchema()
        self.assertEqual(['TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT', 'INT', 'TEXT', 'INT', 'TEXT', 'TEXT', 'TEXT', 'TEXT'],
                         map(ColumnSpec.getType, schema))


    #@unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testInsertStatementConstruction(self):
        
        # No value array in hold-back buffer:
        self.fileConverter.currInsertSig = 'col1, col2'
        self.fileConverter.currOutTable = 'TestTable'
        self.fileConverter.currValsArray = []
        try:
            self.fileConverter.finalizeInsertStatement()
            self.fail("Expected ValueError for empty hold-back buffer")
        except ValueError:
            pass

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
        
    #@unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testPrepareMySQLRow(self):
        
        # Pretend to be the edx parser, sending one insert's worth of
        # info. This will fit into the hold-back buffer, and return None:
        insertInfo = ('MyTable', 'col1, col2', [['foo', 10],['bar',20]])
        res = self.fileConverter.prepareMySQLRow(insertInfo)
        self.assertIsNone(res)
        self.assertEqual('MyTable', self.fileConverter.currOutTable)
        self.assertEqual('col1, col2', self.fileConverter.currInsertSig)
        self.assertEqual([['foo', 10], ['bar', 20]], self.fileConverter.currValsArray)
        
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
        self.fileConverter.__class__.MAX_ALLOWED_PACKET_SIZE = 60
        self.fileConverter.currInsertSig = None
        self.fileConverter.currOutTable = None
        self.fileConverter.currValsArray = []
        res = self.fileConverter.prepareMySQLRow(insertInfo)
        self.assertIsNone(res)
        self.assertEqual('MyTable', self.fileConverter.currOutTable)
        self.assertEqual('col1, col2', self.fileConverter.currInsertSig)
        self.assertEqual([['foo', 10], ['bar', 20]], self.fileConverter.currValsArray)

        # Second call:
        insertMoreInfo = ('MyTable', 'col1, col2', [['blue', 30.1],['green',40.99]])
        res = self.fileConverter.prepareMySQLRow(insertMoreInfo)
        # Should have insert statement for the prior submission...
        self.assertEqual("INSERT INTO MyTable (col1, col2) VALUES \n    ('foo',10),\n    ('bar',20);", res)
        # ... and the hold-back buffer should have the new submission:
        self.assertEqual('MyTable', self.fileConverter.currOutTable)
        self.assertEqual('col1, col2', self.fileConverter.currInsertSig)
        self.assertEqual([['blue', 30.1], ['green', 40.99]], self.fileConverter.currValsArray)
         
        # Call FLUSH to get the held-back values:
        res = self.fileConverter.prepareMySQLRow('FLUSH')
        self.assertEqual("INSERT INTO MyTable (col1, col2) VALUES \n    ('blue',30.1),\n    ('green',40.99);", res)
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
            
if __name__ == "__main__":
    unittest.main()
        