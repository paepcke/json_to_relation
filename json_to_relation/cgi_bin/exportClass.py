#!/usr/bin/python
#!/usr/bin/env python
'''
Created on Jan 14, 2014

@author: paepcke
'''

import cgi
import cgitb
import datetime
import os
import socket
import string
from subprocess import CalledProcessError
import subprocess
import sys
import tempfile
from threading import Timer
import time


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
    
    # Time interval after which a 'dot' or other progress
    # indicator is sent to the calling browser:
    PROGRESS_INTERVAL = 3 # seconds
    
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
        
        self.currTimer = None
    
    def exportClass(self):
        theCourseID = self.parms.getvalue('courseID', '')
        if len(theCourseID) == 0:
            self.send("Please fill in the course ID field.")
            return False
        # Check whether we are to delete any already existing
        # csv files for this class:
        xpungeExisting = self.parms.getvalue("fileAction", None)
        try:
            if xpungeExisting == 'true':
                subprocess.call([self.exportTSVScript, '-u', 'www-data', '-x', '-i', self.infoTmpFile.name, theCourseID],
                                stdout=sys.stdout, stderr=sys.stdout)
            else:
                subprocess.call([self.exportTSVScript, '-u', 'www-data', '-i', self.infoTmpFile.name, theCourseID],
                                stdout=sys.stdout, stderr=sys.stdout)
        except Exception as e:
            self.send(`e`)
        #***************
        time.sleep(10)   
        #***************           
        # The following commented region was one of many attempts at
        # sending progress realitime. No luck:
#         try:
#             if xpungeExisting == 'true':
#                 for line in subprocess.Popen([self.exportTSVScript, '-u', 'www-data', '-x', '-i', self.infoTmpFile.name, theCourseID],
#                                              stdout=subprocess.PIPE, stderr=subprocess.PIPE, bufsize=0).communicate():
#                     self.send(line)
#             else:
#                 for line in subprocess.Popen([self.exportTSVScript, '-u', 'www-data', '-i', self.infoTmpFile.name, theCourseID],
#                                              stdout=sys.stdout, stderr=sys.stdout, bufsize=0).communicate():
#                     self.send(line)
#         except Exception as e:
#             self.send(`e`)


        # Make an array of csv file paths:
        self.csvFilePaths = []
        for csvFilePath in server.infoTmpFile:
            self.csvFilePaths.append(csvFilePath.strip())        
        return True
    
    def printClassTableInfo(self):
        for csvFilePath in self.csvFilePaths:
            tblFileSize = os.path.getsize(csvFilePath)
            # Get the line count:
            lineCnt = 'unknown'
            try:
                # Get a string: '23 fileName\n', where 23 is an ex. for the line count:
                lineCntAndFilename = subprocess.check_output(['wc', '-l', csvFilePath])
                # Isolate the line count:
                lineCnt = lineCntAndFilename.split(' ')[0]
            except (CalledProcessError, IndexError):
                pass
            self.send("<br><b>Table file</b> %s size: %d bytes, %s line(s)<br><b>Sample rows:</b><br>" % (csvFilePath, tblFileSize, lineCnt))
            if tblFileSize > 0:
                lineCounter = 0
                with open(csvFilePath) as infoFd:
                    while lineCounter < CourseTSVServer.NUM_OF_TABLE_SAMPLE_LINES:
                        tableRow = infoFd.readline()
                        if len(tableRow) > 0:
                            self.send(tableRow + '<br>')
                        lineCounter += 1
        self.send('<br>')
     
    def addClientInstructions(self):
        # Get just the first table path, we just
        # need its subdirectory name to build the
        # URL:
        if len(self.csvFilePaths) == 0:
            #self.send("Cannot create client instructions: file %s did not contain table paths.<br>" % self.infoTmpFile.name)
            return
        # Get the last part of the directory,
        # which is the 'CourseSubdir' in
        # /home/dataman/Data/CustomExcerpts/CourseSubdir/<tables>.csv:
        tableDir = os.path.basename(os.path.dirname(self.csvFilePaths[0]))
        thisFullyQualDomainName = socket.getfqdn()
        url = "http://%s/instructor/%s" % (thisFullyQualDomainName, tableDir)
        self.send("<b>Email draft for client; copy-paste into email program:</b><br>")
        msgStart = 'Hi,<br>your data is ready for pickup. Please visit our <a href="%s">pickup page</a>.<br>' % url
        self.send(msgStart)
        # The rest of the msg is in a file:
        with open('clientInstructions.html', 'r') as txtFd:
            lines = txtFd.readlines()
        txt = '<br>'.join(lines)
        # Remove \n everywhere:
        txt = string.replace(txt, '\n', '')
        self.send(txt)
                
    def reportProgress(self):
        self.send('.')
        self.setTimer(CourseTSVServer.PROGRESS_INTERVAL)
                
    def setTimer(self, time=None):
        if time is None:
            time = CourseTSVServer.PROGRESS_INTERVAL
        self.currTimer = Timer(time, self.reportProgress).start()

    def cancelTimer(self):
        if self.currTimer is not None:
            self.currTimer.cancel()
            
    def send(self, msg):
        if msg is not None:
            sys.stdout.write('data: %s\n\n' % msg.strip())
            sys.stdout.flush()

    # -------------------------------------------  Testing  ------------------
                
    def echoParms(self):
        for parmName in self.parms.keys():
            print("Parm: '%s': '%s'" % (self.parms.getvalue(parmName, '')))


if __name__ == '__main__':
    
    TESTING = False
    #TESTING = True
    
    startTime = datetime.datetime.now()
    
    #sys.stdout.write("Content-type: text/html\n\n")
    sys.stdout.write("Content-type: text/event-stream\n")
    sys.stdout.write("Cache-Control: no-cache\n\n")
    sys.stdout.flush()

    # JavaScript exportClass.js writes the following
    # now; --> commented out:
    #sys.stdout.write('data: <h2>Data Export Progress</h2>\n\n')
    #sys.stdout.flush()
    server = CourseTSVServer(testing=TESTING)
    if TESTING:
        server.addClientInstructions()
    else:
        # Timer sending dots for progress not working b/c of
        # buffering:
        #*****server.setTimer()
        exportSuccess = server.exportClass()
        #*****server.cancelTimer()
        endTime = datetime.datetime.now() - startTime
        # Get a timedelta object with the microsecond
        # component subtracted to be 0, so that the
        # microseconds won't get printed:        
        duration = endTime - datetime.timedelta(microseconds=endTime.microseconds)
        server.send("Runtime: %s" % str(duration))
        if exportSuccess:
            server.printClassTableInfo()
            server.addClientInstructions()
         
    
    sys.stdout.write("event: allDone\n")
    sys.stdout.write("data: Done in %s.\n\n" % str(duration))
    sys.stdout.flush()
