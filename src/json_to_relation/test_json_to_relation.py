
import StringIO
import os
import unittest

from json_to_relation import JSONToRelation
from output_disposition import OutputDisposition
from input_source import InputSource


class TestJSONToRelation(unittest.TestCase):
    
    def setUp(self):
        super(TestJSONToRelation, self).setUp()
        stringSource = InputSource.InString(os.path.join(os.path.dirname(__file__),"data/twoJSONRecords.json"))
        self.strConverter = JSONToRelation(stringSource, 
                                           OutputDisposition.OutputPipe(),
                                           outputFormat = OutputDisposition.OutputFormat.CSV,
                                           schemaHints = {}
                                           )
        
    def test_ensure_mysql_identifier_legal(self):
        #self.converter.convert();

        # Vanilla, legal name
        newName = self.converter.ensureLegalIdentifierChars("foo")
        self.assertEqual("foo", newName)

        # Comma in name requires quoting
        newName = self.converter.ensureLegalIdentifierChars("foo,")
        self.assertEqual('"foo,"', newName)
        
        # Embedded single quotes:
        newName = self.converter.ensureLegalIdentifierChars("fo'o")
        self.assertEqual('"fo\'o"', newName)

        # Embedded double quotes:
        newName = self.converter.ensureLegalIdentifierChars('fo"o')
        self.assertEqual("'fo\"o'", newName)

        # Embedded double and single quotes:
        newName = self.converter.ensureLegalIdentifierChars('fo"o\'bar')
        self.assertEqual("'fo\"o\'\'bar'", newName)
        
    def test_simple_json(self):
        self.strConverter.convert()
        
if __name__ == "__main__":
    unittest.main()
        