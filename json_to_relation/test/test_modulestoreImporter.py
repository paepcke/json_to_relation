'''
Created on Nov 30, 2013

@author: paepcke
'''
import StringIO
import os
import tempfile
import unittest

from modulestoreImporter import ModulestoreImporter

TEST_ALL = False

class Test(unittest.TestCase):


    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testModulestoreImportExport(self):

        testFilePath = 'data/modulestoreImport.json'
        importer = ModulestoreImporter(testFilePath)
        dest = tempfile.NamedTemporaryFile(prefix='oolala', suffix='.csv')
        importer.export(dest)
        truthFile = open(os.path.join(os.path.dirname(__file__),'data/modulestoreImportTruth.csv'),'r')
        self.assertFileContentEquals(truthFile, dest.name)

    @unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testModulestoreImportLookups(self):

        testFilePath = 'data/modulestoreImport.json'
        importer = ModulestoreImporter(testFilePath)
        self.assertEqual(importer.getDisplayName("67b77215c10243f1a20d81350909084a"), 'Module 2')
        self.assertEqual(importer.getDisplayName("e9ef4bdae8874030b2321a7699f03a82"), 'Quiz')  
        self.assertEqual(importer.getDisplayName("109c60b8350a4a7aa8b7389c99fdf6ea"), 'Setting Norms')
        self.assertEqual(importer.getDisplayName("handouts"), '')

    #@unittest.skipIf(not TEST_ALL, "Temporarily disabled")
    def testFullModuleStore(self):

        testFilePath = '/home/paepcke/Project/VPOL/Data/FullDumps/modulestore_latest.json'
        importer = ModulestoreImporter(testFilePath)
        importer.export('/home/paepcke/Project/VPOL/Data/FullDumps/modulestore_latest.csv', addHeader=True)
        print str(importer.getDisplayName('f76abf408e84414aa9152c730fc9e95a'))
    
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