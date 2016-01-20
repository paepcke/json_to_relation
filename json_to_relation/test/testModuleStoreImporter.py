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
Created on Jul 2, 2014

@author: paepcke
'''
import StringIO
import os
import re
import shutil
import tempfile
import unittest

from json_to_relation.modulestoreImporter import ModulestoreImporter


TEST_ALL = True

class TestModulestoreImporter(unittest.TestCase):

    # Setup method called once:
    @classmethod
    def setUpClass(cls):
        # Move the existing, full-sized modulestore_latest.json
        # aside, and replace it with a smaller test version:

        # Dir of currently running test script:
        currDir = os.path.dirname(__file__)

        # Where the modulestore_latest.json is stored: 
        TestModulestoreImporter.dataDir = os.path.join(currDir, '..', 'data')
        TestModulestoreImporter.currModStoreLatest = os.path.join(TestModulestoreImporter.dataDir, 'modulestore_latest.json')
        
        # Save current, full-size modulestore_latest.json
        # (preserving its symlink):
        TestModulestoreImporter.savedModStoreLatest = TestModulestoreImporter.currModStoreLatest + '.SAVED'
        try:
            shutil.move(TestModulestoreImporter.currModStoreLatest, TestModulestoreImporter.savedModStoreLatest)
        except IOError:
            pass
        
        # Do the replacement with the test version:
        testModStoreLatest  = os.path.join(currDir, 'data', 'mini_modulestore_latest.json')
        shutil.copy(testModStoreLatest, TestModulestoreImporter.currModStoreLatest)
        
        # The hashLookup.pkl, if it exists, is moved to a save-copy:
        TestModulestoreImporter.hashLookupPicklePath = os.path.join(TestModulestoreImporter.dataDir, 'hashLookup.pkl')
        TestModulestoreImporter.savedHashLookupPicklePath = TestModulestoreImporter.hashLookupPicklePath + '.SAVED'
        if (os.path.exists(TestModulestoreImporter.hashLookupPicklePath)):
            shutil.move(TestModulestoreImporter.hashLookupPicklePath, TestModulestoreImporter.savedHashLookupPicklePath) 

        TestModulestoreImporter.csvTestOutPath = os.path.join(TestModulestoreImporter.dataDir, 'tmpCacheCSVFile.csv') 

    # Teardown method called once:
    @classmethod
    def tearDownClass(cls):
        # Put the true, full size modulestore_latest.json back
        # into its place (preserving its symlink):
        try:
            shutil.move(TestModulestoreImporter.savedModStoreLatest, TestModulestoreImporter.currModStoreLatest)
        except IOError:
            print('NOTE: no modulestore_latest.json found in <projRoot>/json_to_relation/data; run scripts/cronRefreshModuleStore.sh.')
        
        # If hashLookup.pkl existed at the the outset, and was saved,
        # restore it:
        try:
            shutil.move(TestModulestoreImporter.savedHashLookupPicklePath, TestModulestoreImporter.hashLookupPicklePath)
        except:
            pass
        # Remove the csv test output:
        try:
            os.remove(TestModulestoreImporter.csvTestOutPath)
        except:
            pass
         


    def setUp(self):
        jsonFileName = os.path.join(TestModulestoreImporter.dataDir, 'modulestore_latest.json')
        self.importer = ModulestoreImporter(jsonFileName)
        self.pickleCachePath = os.path.join(TestModulestoreImporter.dataDir, 'tmpTestHashLookup.pkl')
        self.uuidRegex = '[a-f0-9]{8}_[a-f0-9]{4}_[a-f0-9]{4}_[a-f0-9]{4}_[a-f0-9]{12}'
        self.pattern   = re.compile(self.uuidRegex)
        self.timestampRegex = r'[1-2][0-9]{3}-[0-1][1-9]-[0-3][0-9]T[0-2][0-9]:[0-6][0-9]:[0-6][0-9]\.[0-9]{0,6}Z{0,1}'
        self.timestampPattern = re.compile(self.timestampRegex)
        # Pattern that recognizes our tmp files. They start with
        # 'oolala', followed by random junk, followed by a period and
        # 0 to 3 file extension letters (always 3, I believe):
        self.tmpFileNamePattern = re.compile('/tmp/oolala[^.]*\..{0,3}')
        
    def tearDown(self):
        # Some of the tests create a temporary
        # pickle file; remove it:
        try:
            os.remove(TestModulestoreImporter.hashLookupPicklePath)
        except:
            pass

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testModuleStoreImporter(self):
        self.useTheDict()

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")    
    def testExportHashInfoToCSV(self):

        csvOutFile = TestModulestoreImporter.csvTestOutPath        
        # Write the current cache out to csv:
        self.importer.exportHashInfo(csvOutFile)
        
        csvOutExpected = os.path.join(os.path.dirname(__file__), 'data/modulestoreImporterCsvTruth.csv') 
        self.assertFileContentEquals(csvOutExpected, csvOutFile)
        
        # Check whether dict ops still work:
        self.useTheDict()
        
    def useTheDict(self):
        self.assertEqual('Module One video', self.importer.getDisplayName('c89417444f4443f9a34039be3054962e'))
        self.assertEqual('Medicine', self.importer.getOrg('c89417444f4443f9a34039be3054962e'))
        self.assertEqual('HRP258', self.importer.getCourseShortName('c89417444f4443f9a34039be3054962e'))
        self.assertEqual('video', self.importer.getCategory('c89417444f4443f9a34039be3054962e'))
        self.assertIsNone(self.importer.getRevision('c89417444f4443f9a34039be3054962e'))
        
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
            with open(expected, 'r') as fd:
                strFile = StringIO.StringIO(fd.read())
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


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testModuleStoreImporter']
    unittest.main()