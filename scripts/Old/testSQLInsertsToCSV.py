'''
Created on Nov 14, 2013

@author: paepcke
'''
import StringIO
import os
import tempfile
import unittest

from sqlInsert2CSV import SQLInserts2CSVConverter


class Test(unittest.TestCase):


    def testSQLInserts2CSV(self):
        converter = SQLInserts2CSVConverter('/tmp', 'data/insertsSQLFile.sql')
        converter.sqlInserts2CSV()
        self.assertFileContentEquals(file('data/insertsSQLFile_EdxTrackEventTruth.csv'), '/tmp/insertsSQLFile_EdxTrackEvent.csv')
        self.assertFileContentEquals(file('data/insertsSQLFile_AnswerTruth.csv'), '/tmp/insertsSQLFile_Answer.csv')
        os.remove('/tmp/insertsSQLFile_EdxTrackEvent.csv')
        os.remove('/tmp/insertsSQLFile_Answer.csv')
        
        
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
                self.assertEqual(expectedLine.strip(), fileLine.strip())
            
            if strFile.readline() != "":
                # expected is longer than what's in the file:
                self.fail("Expected string is longer than content of output file %s" % filePath)
        


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testSQLInserts2CSV']
    unittest.main()