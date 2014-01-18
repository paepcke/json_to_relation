#!/usr/bin/python
#!/usr/bin/env python
'''
Created on Jan 14, 2014

@author: paepcke
'''

import cgi
import cgitb
import os
import socket
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
        self.csvFilePaths = []
        
        # A tempfile passed to the makeCourseCSVs.sh script.
        # That script will place file paths to all created 
        # tables into that file:
        self.infoTmpFile = tempfile.NamedTemporaryFile()
    
    def exportClass(self):
        theCourseID = self.parms.getvalue('courseID', '')
        if len(theCourseID) == 0:
            sys.stdout.write("Please fill in the course ID field.")
            return False
        # Check whether we are to delete any already existing
        # csv files for this class:
        xpungeExisting = self.parms.getvalue("fileAction", None)
        if xpungeExisting == 'xpunge':
            subprocess.call([self.exportTSVScript, '-u', 'www-data', '-x', '-i', self.infoTmpFile.name, theCourseID],
                            stdout=sys.stdout, stderr=sys.stdout)
        else:
            subprocess.call([self.exportTSVScript, '-u', 'www-data', '-i', self.infoTmpFile.name, theCourseID],
                            stdout=sys.stdout, stderr=sys.stdout)
        # Make an array of csv file paths:
        self.csvFilePaths = []
        for csvFilePath in server.infoTmpFile:
            self.csvFilePaths.append(csvFilePath.strip())        
        return True
    
    def printClassTableInfo(self):
        for csvFilePath in self.csvFilePaths:
            tblFileSize = os.path.getsize(csvFilePath)
            sys.stdout.write("<br><b>Table file</b> %s size: %d byes<br><b>Sample rows:</b><br>" % (csvFilePath, tblFileSize))
            if tblFileSize > 0:
                lineCounter = 0
                with open(csvFilePath) as infoFd:
                    while lineCounter < CourseTSVServer.NUM_OF_TABLE_SAMPLE_LINES:
                        tableRow = infoFd.readline()
                        if len(tableRow) > 0:
                            sys.stdout.write(tableRow + '<br>')
                        lineCounter += 1
                sys.stdout.write('<br>')
            sys.stdout.flush()
     
    def addClientInstructions(self):
        # Get just the first table path, we just
        # need its subdirectory name to build the
        # URL:
        if len(self.csvFilePaths) == 0:
            sys.stdout.write("Cannot create client instructions: file %s did not contain table paths.<br>" % self.infoTmpFile.name)
            return
        # Get the last part of the directory,
        # which is the 'CourseSubdir' in
        # /home/dataman/Data/CustomExcerpts/CourseSubdir/<tables>.csv:
        tableDir = os.path.basename(os.path.dirname(self.csvFilePaths[0]))
        thisFullyQualDomainName = socket.getfqdn()
        url = "http://%s/instructor/%s" % (thisFullyQualDomainName, tableDir)
        sys.stdout.write("<b>Email draft for client; copy-paste into email program:</b><br>")
        msgStart = 'Hi,<br>your data is ready for pickup. Please visit our <a href="%s">pickup page</a>, <br>' % url
        sys.stdout.write(msgStart)
        # The rest of the msg is in a file:
        with open('clientInstructions.html', 'r') as txtFd:
            for line in txtFd:
                sys.stdout.write(line)
        sys.stdout.flush()
                
    def echoParms(self):
        for parmName in self.parms.keys():
            print("Parm: '%s': '%s'" % (self.parms.getvalue(parmName, '')))


if __name__ == '__main__':
    
    TESTING = False
    #TESTING = True
    
    #sys.stdout.write("Content-type: text/html\n\n")
    sys.stdout.write("Content-type: text/event-stream\n")
    sys.stdout.write("Cache-Control: no-cache\n\n")
    sys.stdout.flush()

#     sys.stdout.write("<html>\n")
#     sys.stdout.write("<head></head>\n")
#     sys.stdout.write('<body bgcolor="#FFF8E8" link="#0000FF" vlink="#007090" alink="#00A0FF">\n')
    sys.stdout.write('data: <center><h1>Data Export Process</h1></center>\n\n')
    sys.stdout.flush()
    server = CourseTSVServer(testing=TESTING)
    if TESTING:
        server.addClientInstructions()
    else:
        exportSuccess = server.exportClass()
        if exportSuccess:
            server.printClassTableInfo()
            server.addClientInstructions()
        
    sys.stdout.write("</body>")
    sys.stdout.flush()
