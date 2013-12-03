'''
Created on Nov 30, 2013

@author: paepcke
'''
import StringIO
import os
import shutil
import tempfile
import unittest

from modulestoreImporter import ModulestoreImporter


TEST_ALL = True

# The following is very Dangerous: If True, no tests are
# performed. Instead, all the reference files, the ones
# ending with 'Truth.sql' will be changed to be whatever
# the test returns. Use only when you made code changes that
# invalidate all the truth files:
UPDATE_TRUTH = False


class TestModuleStore(unittest.TestCase):

    hashLookupDict = None
    
    #@unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testModulestoreImportExportHashInfo(self):
        
        testFilePath = os.path.join(os.path.dirname(__file__), 'data/modulestore_sample.json')
        pickleFilePath = os.path.join(os.path.dirname(__file__), 'data/modulestore_sample.pkl')
        importer = ModulestoreImporter(testFilePath, pickleCachePath=pickleFilePath)
        dest = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.csv')
        importer.exportHashInfo(dest, addHeader=True)
        truthFile = open(os.path.join(os.path.dirname(__file__),'data/modulestore_sampleTruth.csv'),'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)
        dest.close()

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testModulestoreImportLookups(self):

        testFilePath = os.path.join(os.path.dirname(__file__), 'data/modulestore_sample.json')
        pickleFilePath = os.path.join(os.path.dirname(__file__), 'data/modulestore_sample.pkl')
        importer = ModulestoreImporter(testFilePath, useCache=True, pickleCachePath=pickleFilePath)
        
        # The hash info:
        self.assertEqual(importer.getDisplayName("Introduction_to_Sociology"), 'Introduction to Sociology')
        self.assertEqual(importer.getDisplayName("0c6cf38317be42e0829d10cc68e7451b"), 'Quiz')  
        self.assertEqual(importer.getDisplayName("0d6e5f3139e74c88adfdf4c90773f87f"), 'New Unit')
        self.assertEqual(importer.getOrg("0d6e5f3139e74c88adfdf4c90773f87f"), 'Medicine')
        self.assertEqual(importer.getCourseShortName("dc9cb4ff0c9241d2b9e075806490f992"), 'HRP258')
        self.assertEqual(importer.getCategory("Annotation"), 'annotatable')
        self.assertEqual(importer.getRevision("18b21999d6424f4ca04fe2bbe188fc9e"), 'draft')
        
        # Short coursenames to long coursenames:
        self.assertEqual(importer['SOC131'], 'LaneCollege/SOC131/Introduction_to_Sociology')
        self.assertEqual(importer.keys(), [u'SOC131'])
        self.assertEqual(importer.values(), [u'LaneCollege/SOC131/Introduction_to_Sociology'])
        self.assertEqual(importer.items(),  [(u'SOC131', u'LaneCollege/SOC131/Introduction_to_Sociology')])
        

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testCourseNameExport(self):

        testFilePath = os.path.join(os.path.dirname(__file__), 'data/modulestore_sample.json')
        pickleFilePath = os.path.join(os.path.dirname(__file__), 'data/modulestore_sample.pkl')
        importer = ModulestoreImporter(testFilePath, pickleCachePath=pickleFilePath)
        dest = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.csv')
        importer.exportCourseNameLookup(dest, addHeader=True)
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/modulestore_sampleTruth1.csv"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)
        dest.close()
    
    # -----------------------  Utilities  ---------------------
        
    def assertFileContentEquals(self, expected, filePathOrStrToCompareTo):
        '''
        Compares two file or string contents. First arg is either an open file or a string.
        That is the ground truth to compare to. Second argument is the same: file or string.
        @param expected:
        @type expected:
        @param filePathOrStrToCompareTo:
        @type filePathOrStrToCompareTo:
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
                self.assertEqual(expectedLine.strip(), fileLine.strip())
            
            if strFile.readline() != "":
                # expected is longer than what's in the file:
                self.fail("Expected string is longer than content of output file %s" % filePath)
        
    def updateTruth(self, newTruthFilePath, destinationTruthFilePath):
        shutil.copy(newTruthFilePath, destinationTruthFilePath)
        

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testImport']
    unittest.main()