#!/usr/bin/env python
'''
Created on Jan 14, 2014

@author: paepcke
'''

import os
import socket
import string
from subprocess import CalledProcessError
import subprocess
import sys
import tempfile
from threading import Timer
import time # @UnusedImport
import getpass
import json

# Add json_to_relation source dir to $PATH
# for duration of this execution:
source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")]
source_dir.extend(sys.path)
sys.path = source_dir

from mysqldb import MySQLDB

import tornado;
from tornado.ioloop import IOLoop;
from tornado.websocket import WebSocketHandler;
from tornado.httpserver import HTTPServer;

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
        self.exportCSVScript = os.path.join(thisScriptDir, '../../scripts/makeCourseCSVs.sh')
        self.csvFilePaths = []
        
        # A tempfile passed to the makeCourseCSVs.sh script.
        # That script will place file paths to all created 
        # tables into that file:
        self.infoTmpFile = tempfile.NamedTemporaryFile()
        self.dbError = 'no error'
        currUser = getpass.getuser()
        try:
            with open('/home/%s/.ssh/mysql' % currUser, 'r') as fd:
                pwd = fd.readline()
                self.mysqlDb = MySQLDB(user=currUser, passwd=pwd, db='Edx')
        except Exception:
            try:
                # Try w/o a pwd:
                self.mysqlDb = MySQLDB(user=currUser, db='Edx')
            except Exception as e:
                # Remember the error msg for later:
                self.dbError = `e`;
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
        #print("Open called")
    
    def on_message(self, message):
        '''
        Connected browser requests action: "<actionType>:<actionArg(s)>,
        where actionArgs is a single string or an array of items.
        @param message: message arriving from the browser
        @type message: string
        '''
        #print message
        try:
            requestDict = json.loads(message)
        except Exception as e:
            self.writeError("Bad JSON in request received at server: %s" % `e`)

        # Get the request name:
        try:
            requestName = requestDict['req']
            args        = requestDict['args']
            if requestName == 'reqCourseNames':
                self.handleCourseNamesReq(requestName, args)
            elif requestName == 'getData':
                self.exportClass(args)
            else:
                self.writeError("Unknown request name: %s" % requestName)
        except Exception as e:
            self.writeError("Server could not extract request name/args from (%s): %s" % (message, `e`))
            
    def handleCourseNamesReq(self, requestName, args):
        try:
            courseRegex = args
            matchingCourseNames = self.queryCourseNameList(courseRegex)
            # Check whether __init__() method was unable to log into 
            # the db:
            if matchingCourseNames is None:
                self.writeError('Server could not log into database: %s' % self.dbError)
                return
        except Exception as e:
            self.writeError(`e`)
            return
        self.writeResult('courseList', matchingCourseNames)
        
    def writeError(self, msg):
        '''
        Writes a response to the JS running in the browser
        that indicates an error. Result action is "error",
        and "args" is the error message string:
        @param msg: error message to send to browser
        @type msg: String
        '''
        self.writeError(msg)

    def writeResult(self, responseName, args):
        '''
        Write a JSON formatted result back to the browser.
        Format will be {"resp" : "<respName>", "args" : "<jsonizedArgs>"},
        That is, the args will be turned into JSON that is the
        in the response's "args" value:
        @param responseName: name of result that is recognized by the JS in the browser
        @type responseName: String
        @param args: any Python datastructure that can be turned into JSON
        @type args: {int | String | [String] | ...}
        '''
        jsonArgs = json.dumps(args)
        msg = '{"resp" : "%s", "args" : %s}' % (responseName, jsonArgs)
        self.write_message(msg)
        
    def exportClass(self, detailDict):
        '''
        {courseId : <the courseID>, wipeExisting : <true/false wipe existing class tables files>}
        @param detailDict:
        @type detailDict:
        '''
        theCourseID = detailDict.get('courseId', '')
        if len(theCourseID) == 0:           

            self.writeError('Please fill in the course ID field.')
            return False
        # Check whether we are to delete any already existing
        # csv files for this class:
        xpungeExisting = detailDict.get("wipeExisting", False)
#         try:
#             if xpungeExisting == 'true':
#                 subprocess.call([self.exportCSVScript, '-u', 'www-data', '-x', '-i', self.infoTmpFile.name, theCourseID],
#                                 stdout=sys.stdout, stderr=sys.stdout)
#             else:
#                 subprocess.call([self.exportCSVScript, '-u', 'www-data', '-i', self.infoTmpFile.name, theCourseID],
#                                 stdout=sys.stdout, stderr=sys.stdout)
#         except Exception as e:
#             self.writeError(`e`)

        try:
            if xpungeExisting:
                pipeFromScript = subprocess.Popen([self.exportCSVScript, '-u', 'www-data', '-x', '-i', self.infoTmpFile.name, theCourseID],
                                                  stdout=subprocess.PIPE).stdout
            else:
                pipeFromScript = subprocess.Popen([self.exportCSVScript, '-u', 'www-data', '-i', self.infoTmpFile.name, theCourseID],
                                                  stdout=subprocess.PIPE).stdout
            for msgFromScript in pipeFromScript:
                self.writeResult('progress', msgFromScript)
                                                  
        except Exception as e:
            self.writeError(`e`)


        # Make an array of csv file paths:
        self.csvFilePaths = []
        self.infoTmpFile.seek(0)
        for csvFilePath in self.infoTmpFile:
            self.csvFilePaths.append(csvFilePath.strip())        
            
        # Send table row samples to browser:
        self.printClassTableInfo()
        
        # Add an example client letter:
        self.addClientInstructions()
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
            self.writeResult('printTblInfo', 
                             "<br><b>Table file</b> %s size: %d bytes, %s line(s)<br><b>Sample rows:</b><br>" % 
                             (csvFilePath, tblFileSize, lineCnt))
            if tblFileSize > 0:
                lineCounter = 0
                with open(csvFilePath) as infoFd:
                    while lineCounter < CourseCSVServer.NUM_OF_TABLE_SAMPLE_LINES:
                        tableRow = infoFd.readline()
                        if len(tableRow) > 0:
                            self.writeResult('printTblInfo', tableRow + '<br>')
                        lineCounter += 1
        #****self.writeResult('<br>')
     
    def addClientInstructions(self):
        # Get just the first table path, we just
        # need its subdirectory name to build the
        # URL:
        if len(self.csvFilePaths) == 0:
            #self.writeError("Cannot create client instructions: file %s did not contain table paths.<br>" % self.infoTmpFile.name)
            return
        # Get the last part of the directory,
        # which is the 'CourseSubdir' in
        # /home/dataman/Data/CustomExcerpts/CourseSubdir/<tables>.csv:
        tableDir = os.path.basename(os.path.dirname(self.csvFilePaths[0]))
        thisFullyQualDomainName = socket.getfqdn()
        url = "http://%s/instructor/%s" % (thisFullyQualDomainName, tableDir)
        self.writeResult('progress', "<b>Email draft for client; copy-paste into email program:</b><br>")
        msgStart = 'Hi,<br>your data is ready for pickup. Please visit our <a href="%s">pickup page</a>.<br>' % url
        self.writeResult('progress', msgStart)
        # The rest of the msg is in a file:
        with open('clientInstructions.html', 'r') as txtFd:
            lines = txtFd.readlines()
        txt = '<br>'.join(lines)
        # Remove \n everywhere:
        txt = string.replace(txt, '\n', '')
        self.writeResult('progress', txt)
      
    def queryCourseNameList(self, courseID):
        '''
        Given a MySQL regexp courseID string, return a list
        of matchine course_display_name in the db. If self.mysql
        is None, indicating that the __init__() method was unable
        to log into the db, then return None.
        @param courseID: Course name regular expression in MySQL syntax.
        @type courseID: String
        @return: An array of matching course_display_name, which may
                 be empty. None if _init__() was unable to log into db.
        @rtype: {[String] | None}
        '''
        courseNames = []
        if self.mysqlDb is not None:
            for courseName in self.mysqlDb.query('SELECT DISTINCT course_display_name ' +\
                                                 'FROM Edx.EventXtract ' +\
                                                 'WHERE course_display_name LIKE "%s";' % courseID):
                if courseName is not None:
                    # Results are singleton tuples, so
                    # need to get 0th element:
                    courseNames.append('"%s"' % courseName[0])
        else:
            return None
        return courseNames
      
    def reportProgress(self):
        self.writeResult('progress', '.')
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
#         server.writeResult('progress', "Runtime: %s" % str(duration))
#         if exportSuccess:
#             server.printClassTableInfo()
#             server.addClientInstructions()
#          
#     
#     sys.stdout.write("event: allDone\n")
#     sys.stdout.write("data: Done in %s.\n\n" % str(duration))
#     sys.stdout.flush()
