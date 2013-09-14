
import StringIO
import os
import unittest

from json_to_relation import JSONToRelation
import output_disposition


class TestJSONToRelation(unittest.TestCase):
    
    def setUp(self):
        super(TestJSONToRelation, self).setUp()
        self.converter = JSONToRelation(os.path.join(os.path.dirname(__file__),"data/twoJSONRecords.json"))
        
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
        strFile = StringIO.StringIO('{"name" : "bloomberg"}')
        strConverter = JSONToRelation(strFile, output_disposition.OutputPipe())
        strConverter.convert()
        
if __name__ == "__main__":
    unittest.main()
        