
import StringIO
import os
import unittest
from unittest.case import TestCase

from input_source import InputSource, InString, InPipe, InURI, InMongoDB
from json_to_relation import JSONToRelation
from output_disposition import OutputDisposition, OutputPipe, OutputFile, \
    OutputMySQLTable


class TestJSONToRelation(unittest.TestCase):
    
    def setUp(self):
        super(TestJSONToRelation, self).setUp()
        self.stringSource = InURI(os.path.join(os.path.dirname(__file__),"data/twoJSONRecords.json"))
        self.fileConverter = JSONToRelation(self.stringSource, 
                                            OutputPipe(),
                                            outputFormat = OutputDisposition.OutputFormat.CSV,
                                            schemaHints = {}
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
        
    def tearDown(self):
        super(TestJSONToRelation, self).tearDown()
    
    
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
        
    def test_simple_json(self):
        # Prints output to display, which we can't catch without
        # fuzzing with stdout. So just ensure no error happens: 
        self.fileConverter.convert()

    def test_simple_json_to_file(self):
        self.fileConverter = JSONToRelation(self.stringSource, 
                                            OutputFile("testOutput.csv"),
                                            outputFormat = OutputDisposition.OutputFormat.CSV,
                                            schemaHints = {}
                                            )
        self.fileConverter.convert()
        expected = "asset,sainani.jpg,HRP258,c4x,Medicine,,image/jpeg,sainani.jpg,262144,/c4x/Medicine/HRP258/asset/sainani.jpg," +\
                    "22333,,2013-05-08T22:47:09.762Z,,ebcb2a60b0d6b7475c4e9a102b82637b\n" +\
                    "asset,medstats.png,HRP258,c4x,Medicine,,image/png,medstats.png,262144,/c4x/Medicine/HRP258/asset/medstats.png," +\
                    "86597,,2013-05-08T22:48:38.174Z,,db47f263ac3532874b8f442ad8937d02"
        self.assertFileContentEquals(expected, "testOutput.csv")

    def test_json_to_file_with_col_header(self):
        self.fileConverter = JSONToRelation(self.stringSource, 
                                            OutputFile("testOutputWithHeader.csv"),
                                            outputFormat = OutputDisposition.OutputFormat.CSV,
                                            schemaHints = {}
                                            )
        self.fileConverter.convert(prependColHeader=True)
        expected = '"_id.category","_id.name","_id.course","_id.tag","_id.org","_id.revision",contentType,' +\
                   'displayname,chunkSize,filename,length,import_path,"uploadDate.$date",thumbnail_location,md5' +\
                   "asset,sainani.jpg,HRP258,c4x,Medicine,,image/jpeg,sainani.jpg,262144,/c4x/Medicine/HRP258/asset/sainani.jpg," +\
                    "22333,,2013-05-08T22:47:09.762Z,,ebcb2a60b0d6b7475c4e9a102b82637b\n" +\
                    "asset,medstats.png,HRP258,c4x,Medicine,,image/png,medstats.png,262144,/c4x/Medicine/HRP258/asset/medstats.png," +\
                    "86597,,2013-05-08T22:48:38.174Z,,db47f263ac3532874b8f442ad8937d02"
        self.assertFileContentEquals(expected, "testOutputWithHeader.csv")

        
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
        