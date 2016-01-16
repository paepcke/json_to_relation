# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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