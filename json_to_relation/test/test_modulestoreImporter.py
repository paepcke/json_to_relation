'''
Created on Nov 30, 2013

@author: paepcke
'''
import StringIO
import os
import pickle
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
    
    @classmethod
    def setUpClass(cls):
        '''
        Called once, sets up a class variable with an OpenEdx hash-to-ModulestoreInfo
        dict, which is then reused for each test.
        @param cls: TestModuleStore
        @type cls: Class
        '''
        pickleFile = os.path.join(os.path.dirname(__file__), '../data/hashLookup.pkl')
        if os.path.exists(pickleFile):
            with open(pickleFile, 'r') as pickleFd:
                TestModuleStore.hashLookupDict = pickle.load(pickleFd)
        else:
            # Hash dict pickle doesn't exist yet. Make it exist:
            jsonModulestoreExcerpt = os.path.join(os.path.dirname(__file__), '../data/modulestore_latest.json')
            if not os.path.exists(jsonModulestoreExcerpt):
                raise('IOError: neither OpenEdx hash-to-displayName JSON excerpt from modulestore, nor a cache thereof is available. You need to run cronRefreshModuleStore.sh')
        ModulestoreImporter(jsonModulestoreExcerpt)
        with open(pickleFile, 'r') as pickleFd:
            TestModuleStore.hashLookupDict = pickle.load(pickleFd)

    def setUp(self):
        super(TestModuleStore, self).setUp()
        self.hashLookupDict = TestModuleStore.hashLookupDict  

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testModulestoreImportExportInfo(self):
        
        testFilePath = os.path.join(os.path.dirname(__file__), 'data/modulestore_sample.json')
        importer = ModulestoreImporter(testFilePath)
        dest = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.csv')
        importer.exportHashInfo(dest, addHeader=True)
        truthFile = open(os.path.join(os.path.dirname(__file__),'data/modulestore_sampleTruth.csv'),'r')
        self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testModulestoreImportLookups(self):

        testFilePath = os.path.join(os.path.dirname(__file__), 'data/modulestore_sample.json')
        importer = ModulestoreImporter(testFilePath, testLookupDict=self.hashLookupDict)
        self.assertEqual(importer.getDisplayName("67b77215c10243f1a20d81350909084a"), 'Module 2')
        self.assertEqual(importer.getDisplayName("e9ef4bdae8874030b2321a7699f03a82"), 'Quiz')  
        self.assertEqual(importer.getDisplayName("109c60b8350a4a7aa8b7389c99fdf6ea"), 'Setting Norms')
        self.assertEqual(importer.getDisplayName("handouts"), '')

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testInfoExport(self):

        testFilePath = os.path.join(os.path.dirname(__file__), 'data/modulestore_sample.json')
        importer = ModulestoreImporter(testFilePath)
        dest = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.csv')
        importer.export(dest, addHeader=True)
        dest.close()
        truthFile = open(os.path.join(os.path.dirname(__file__),"data/modulestore_sampleTruth.csv"), 'r')
        if UPDATE_TRUTH:
            self.updateTruth(dest.name, truthFile.name)
        else:
            self.assertFileContentEquals(truthFile, dest.name)
    
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
        
        

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testImport']
    unittest.main()