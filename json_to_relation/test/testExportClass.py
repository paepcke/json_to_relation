'''
Created on Jan 21, 2014

@author: paepcke
'''
import unittest

from cgi_bin.exportClass import CourseTSVServer


class ExportClassTest(unittest.TestCase):


    def testMakePickupURL(self):
        server = CourseTSVServer()
        dirLeaf = '_ALLEE222_ALL'
        self.writeTablePaths(dirLeaf, server)
        server.addClientInstructions()

    def writeTablePaths(self, dirLeaf, server):
        eventXtractFname = '/foo/bar/%s_EventXtract.csv' % dirLeaf
        activityGradeFname = '/foo/bar/%s_ActivityGrade.csv' % dirLeaf
        videoFname = '/foo/bar/%s_VideoInteraction.csv' % dirLeaf
        server.csvFilePaths = [eventXtractFname, activityGradeFname, videoFname]
#         targetFile = server.infoTmpFile
#         targetFile.truncate()
#         targetFile.write(eventXtractFname + '\n')
#         targetFile.write(activityGradeFname + '\n')
#         targetFile.write(videoFname + '\n')
# 
#         server.csvFilePaths = []
#         for csvFilePath in server.infoTmpFile:
#             self.csvFilePaths.append(csvFilePath.strip())        



if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()