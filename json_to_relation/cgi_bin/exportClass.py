#!/usr/bin/python
#!/usr/bin/env python
'''
Created on Jan 14, 2014

@author: paepcke
'''

import cgi
import cgitb
import os
import subprocess
import sys
import tempfile


cgitb.enable()

class MockCGI:
    
    def __init__(self):
        self.parms = {'courseID' : "Engineering/CS106A/Fall2013"}
        
    def getvalue(self, parmName, default=None):
        try:
            return self.parms[parmName]
        except KeyError:
            return default

class CourseTSVServer:
    
    # Max number of lines from each csv table to output
    # as samples to the calling browser for human sanity 
    # checking:
    NUM_OF_TABLE_SAMPLE_LINES = 5
    
    def __init__(self, testing=False):
        if testing:
            self.parms = MockCGI()
        else:
            self.parms = cgi.FieldStorage()
        # Locate the makeCourseTSV.sh script:
        thisScriptDir = os.path.dirname(__file__)
        self.exportTSVScript = os.path.join(thisScriptDir, '../../scripts/makeCourseCSVs.sh')
        
        # A tempfile passed to the makeCourseCSVs.sh script.
        # That script will place file paths to all created 
        # tables into that file:
        self.infoTmpFile = tempfile.NamedTemporaryFile()
    
    def exportClass(self):
        theCourseID = self.parms.getvalue('courseID', '')
        subprocess.call([self.exportTSVScript, '-u', 'www-data', '-i', self.infoTmpFile.name, theCourseID],
                        stdout=sys.stdout, stderr=sys.stdout)
    
    def printClassTableInfo(self):
        for csvFilePath in self.infoTmpFile:
            csvFilePath = csvFilePath.strip()
            tblFileSize = os.path.getsize(csvFilePath)
            sys.stdout.write("<br>Table file %s size: %d<br>" % (csvFilePath, tblFileSize))
            if tblFileSize > 0:
                lineCounter = 0
                with open(csvFilePath) as infoFd:
                    while lineCounter < CourseTSVServer.NUM_OF_TABLE_SAMPLE_LINES:
                        sys.stdout.write(infoFd.readline() + '<br>')
                        lineCounter += 1
                sys.stdout.write('<br>')
            sys.stdout.flush()
                
    def echoParms(self):
        for parmName in self.parms.keys():
            print("Parm: '%s': '%s'" % (self.parms.getvalue(parmName, '')))


if __name__ == '__main__':
    sys.stdout.write("Content-type: text/html\n\n")
    sys.stdout.flush()

    sys.stdout.write("<html>\n")
    sys.stdout.write("<head></head>\n")
    sys.stdout.write("<body>\n")
    sys.stdout.flush()
    
    #server = CourseTSVServer(testing=True)
    server = CourseTSVServer(testing=False)
    server.exportClass()
    server.printClassTableInfo()

    sys.stdout.write("</body>")
    sys.stdout.flush()
