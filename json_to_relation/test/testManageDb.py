'''
Created on Mar 31, 2015

@author: paepcke
'''
import os
import shutil
import unittest

from manageEdxDb import TrackLogPuller


class TestManageDb(unittest.TestCase):

    csvFName1  = 'tracking.app2.tracking.tracking.log-20141008-1412767021.gz.2015-03-07T20_18_53.273290_7501.sql'
    csvFName2  = 'app1.tracking.tracking.log-20141007-1412648221.gz.2014-12-20T12_45_23.610765_12632.sql'
    jsonFName1 = 'tracking.log-20141008-1412767021.gz'
    jsonFName2 = 'tracking.log-20141007-1412648221.gz'

    def touch(self, filePath):
        with open(filePath, 'a'):
            os.utime(filePath, None)

    def setUp(self):
        
        # Two json files...
        self.jsonDirApp1 = '/tmp/unittest/tracking/app1/tracking'
        self.jsonDirApp2 = '/tmp/unittest/tracking/tracking/app2/tracking'

        try:
            shutil.rmtree(self.jsonDirApp2)
        except:
            pass
        try:
            shutil.rmtree(self.jsonDirApp1)
        except:
            pass
        
        os.makedirs(self.jsonDirApp1)
        os.makedirs(self.jsonDirApp2)
        
        self.touch(os.path.join(self.jsonDirApp1, TestManageDb.jsonFName1))
        self.touch(os.path.join(self.jsonDirApp2, TestManageDb.jsonFName2))
        
        # Only 1 corresponding CSV file:
        self.csvDir = '/tmp/unittest/tracking/CSV'
        try:
            shutil.rmtree(self.csvDir)
        except:
            pass
        
        os.makedirs(self.csvDir)
        self.touch(os.path.join(self.csvDir, TestManageDb.csvFName1))
        
        self.puller = TrackLogPuller()
        TrackLogPuller.LOCAL_LOG_STORE_ROOT = '/tmp/unittest/'
        
    def tearDown(self):
        shutil.rmtree(self.jsonDirApp2)
        shutil.rmtree(self.jsonDirApp1)

    def testTransformsStillToDo(self):
        
        self.puller.identifyNotTransformedLogFiles(localTrackingLogFilePaths=None, csvDestDir=self.csvDir)          


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()