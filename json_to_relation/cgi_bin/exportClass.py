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
import time  # @UnusedImport
from mysqldb import MySQLDB 

import tornado;
from tornado.ioloop import IOLoop;
from tornado.websocket import WebSocketHandler;
from tornado.httpserver import HTTPServer;

cgitb.enable()

class CourseCSVServer(WebSocketHandler):
    
    # Time interval after which a 'dot' or other progress
    # indicator is sent to the calling browser:
    PROGRESS_INTERVAL = 3 # seconds
    
    # Max number of lines from each csv table to output
    # as samples to the calling browser for human sanity 
    # checking:
    NUM_OF_TABLE_SAMPLE_LINES = 5
    
    def __init__(self, application, request, **kwargs ):
        '''
        Invoked when browser accesses this server via ws://...
        Register this handler instance in the handler list.
        @param application: Application object that defines the collection of handlers.
        @type application: tornado.web.Application
        @param request: a request object holding details of the incoming request
        @type request:HTTPRequest.HTTPRequest
        @param kwargs: dict of additional parameters for operating this service.
        @type kwargs: dict
        '''
        super(CourseCSVServer, self).__init__(application, request, **kwargs);
        self.request = request;        

        # Locate the makeCourseCSV.sh script:
        thisScriptDir = os.path.dirname(__file__)
        self.exportTSVScript = os.path.join(thisScriptDir, '../../scripts/makeCourseCSVs.sh')
        self.csvFilePaths = []
        
        # A tempfile passed to the makeCourseCSVs.sh script.
        # That script will place file paths to all created 
        # tables into that file:
        self.infoTmpFile = tempfile.NamedTemporaryFile()

        try:
            with open('/home/dbadmin/.ssh/mysql', 'r') as fd:
                dbadminPwd = fd.readline()
                self.mysqlDb = MySQLDB(user='dbadmin', passwd=dbadminPwd, db='Edx')
        except Exception:
            self.mysqlDb = None
            
        self.currTimer = None
    
    def allow_draft76(self):
        '''
        Allow WebSocket connections via the old Draft-76 protocol. It has some
        security issues, and was replaced. However, Safari (i.e. e.g. iPad)
        don't implement the new protocols yet. Overriding this method, and
        returning True will allow those connections.
        '''
        return True    
    
    def open(self): #@ReservedAssignment
        '''
        Called by WebSocket/tornado when a client connects. Method must
        be named 'open'
        '''
        print("Open called")
    
    def on_message(self, message):
        '''
        Connected browser requests action: "<actionType>:<actionArg(s)>,
        where actionArgs is a single string or an array of items.
        @param message: message arriving from the browser
        @type message: string
        '''
        print message
        try:
            (action, args) = string.split(message, ':')
        except Exception as e:
            pass
        if action == 'courseNameQ':
            try:
                courseName = args
                matchingCourseNames = self.queryCourseNameList(courseName)
            except Exception as e:
                self.write_message("error:%s" % `e`)
            #************self.write_message('courseList:' + str(matchingCourseNames))
            self.write_message('courseList:' + str(['foo','bar']))
        
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

        # Make an array of csv file paths:
        self.csvFilePaths = []
        for csvFilePath in self.infoTmpFile:
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
                    while lineCounter < CourseCSVServer.NUM_OF_TABLE_SAMPLE_LINES:
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
      
    def queryCourseNameList(self, courseID):
        courseNames = []
        if self.mysqlDb is not None:
            for courseName in self.mysqlDb.query('SELECT DISTINCT course_display_name FROM EdxXtract WHERE course_display_name LIKE "%s";'):
                courseNames.append(courseName)
        return courseNames
      
    def sendCourseCheckboxes(self, courseNmList):
        self.send("<form action=''>");
        for name in courseNmList:
            self.send('<input type="radio" name="crsChoice" value="%s">%s<br>' % (name,name))
        self.send("</form>")
                
    def reportProgress(self):
        self.send('.')
        self.setTimer(CourseCSVServer.PROGRESS_INTERVAL)
                
    def setTimer(self, time=None):
        if time is None:
            time = CourseCSVServer.PROGRESS_INTERVAL
        self.currTimer = Timer(time, self.reportProgress).start()

    def cancelTimer(self):
        if self.currTimer is not None:
            self.currTimer.cancel()
            
    # -------------------------------------------  Testing  ------------------
                
    def echoParms(self):
        for parmName in self.parms.keys():
            print("Parm: '%s': '%s'" % (self.parms.getvalue(parmName, '')))


if __name__ == '__main__':
    
    application = tornado.web.Application([(r"/exportClass", CourseCSVServer),])
    application.listen(8080)
    tornado.ioloop.IOLoop.instance().start()
    
#          Timer sending dots for progress not working b/c of
#          buffering:
#         *****server.setTimer()
#         exportSuccess = server.exportClass()
#         *****server.cancelTimer()
#         endTime = datetime.datetime.now() - startTime
#          Get a timedelta object with the microsecond
#          component subtracted to be 0, so that the
#          microseconds won't get printed:        
#         duration = endTime - datetime.timedelta(microseconds=endTime.microseconds)
#         server.send("Runtime: %s" % str(duration))
#         if exportSuccess:
#             server.printClassTableInfo()
#             server.addClientInstructions()
#          
#     
#     sys.stdout.write("event: allDone\n")
#     sys.stdout.write("data: Done in %s.\n\n" % str(duration))
#     sys.stdout.flush()
