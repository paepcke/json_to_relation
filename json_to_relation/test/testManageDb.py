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
    jsonFName1 = 'tracking.log-20141007-1412648221.gz'
    jsonFName2 = 'tracking.log-20141008-1412767021.gz'

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
        TrackLogPuller.LOCAL_LOG_STORE_ROOT = '/tmp/unittest/tracking'
        
    def tearDown(self):
        shutil.rmtree(self.jsonDirApp2)
        shutil.rmtree(self.jsonDirApp1)

    def testTransformsStillToDoOneOfTwoDone(self):
        
        filesToTransform = self.puller.identifyNotTransformedLogFiles(localTrackingLogFilePaths=None, csvDestDir=self.csvDir)
        self.assertEqual(filesToTransform, ['/tmp/unittest/tracking/app1/tracking/tracking.log-20141007-1412648221.gz'])          

    def testTransformsStillToDoAllDone(self):
    
        self.touch(os.path.join(self.csvDir, TestManageDb.csvFName2))    
        filesToTransform = self.puller.identifyNotTransformedLogFiles(localTrackingLogFilePaths=None, csvDestDir=self.csvDir)
        self.assertEqual(filesToTransform, [])
        
    def testTransformsStillDoNoneDone(self):
    
        os.remove(os.path.join(self.csvDir, TestManageDb.csvFName1))    
        filesToTransform = self.puller.identifyNotTransformedLogFiles(localTrackingLogFilePaths=None, csvDestDir=self.csvDir)
        self.assertEqual(filesToTransform,
                         ['/tmp/unittest/tracking/app1/tracking/tracking.log-20141007-1412648221.gz',
                          '/tmp/unittest/tracking/tracking/app2/tracking/tracking.log-20141008-1412767021.gz'])
         

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()