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
import datetime

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
    
    LOG_LEVEL_NONE  = 0
    LOG_LEVEL_ERR   = 1
    LOG_LEVEL_INFO  = 2
    LOG_LEVEL_DEBUG = 3
    
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

        self.loglevel = CourseCSVServer.LOG_LEVEL_DEBUG
        #self.loglevel = CourseCSVServer.LOG_LEVEL_NONE

        # Locate the makeCourseCSV.sh script:
        self.thisScriptDir = os.path.dirname(__file__)
        self.exportCSVScript = os.path.join(self.thisScriptDir, '../../scripts/makeCourseCSVs.sh')
        self.searchCourseNameScript = os.path.join(self.thisScriptDir, '../../scripts/searchCourseDisplayNames.sh')
        self.csvFilePaths = []
        
        # A tempfile passed to the makeCourseCSVs.sh script.
        # That script will place file paths to all created 
        # tables into that file:
        self.infoTmpFile = tempfile.NamedTemporaryFile()
        self.dbError = 'no error'
        self.currUser = getpass.getuser()
        try:
            with open('/home/%s/.ssh/mysql' % self.currUser, 'r') as fd:
                self.mySQLPwd = fd.readline().strip()
                self.mysqlDb = MySQLDB(user=self.currUser, passwd=self.mySQLPwd, db='Edx')
        except Exception:
            try:
                # Try w/o a pwd:
                self.mySQLPwd = None
                self.mysqlDb = MySQLDB(user=self.currUser, db='Edx')
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
        self.logDebug("Open called")
    
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
            self.logDebug("request received: %s" % str(message))
        except Exception as e:
            self.writeError("Bad JSON in request received at server: %s" % `e`)

        # Get the request name:
        try:
            requestName = requestDict['req']
            args        = requestDict['args']
            if requestName == 'reqCourseNames':
                self.handleCourseNamesReq(requestName, args)
            elif requestName == 'getData':
                startTime = datetime.datetime.now()
                self.setTimer()
                
                self.exportClass(args)
                
                self.cancelTimer()
                endTime = datetime.datetime.now() - startTime
                # Get a timedelta object with the microsecond
                # component subtracted to be 0, so that the
                # microseconds won't get printed:        
                duration = endTime - datetime.timedelta(microseconds=endTime.microseconds)
                self.writeResult('progress', "<br>Runtime: %s<br>" % str(duration))
                                
                # Add an example client letter:
                inclPII = args.get("inclPII", False)
                self.addClientInstructions(inclPII)

            else:
                self.writeError("Unknown request name: %s" % requestName)
        except Exception as e:
            # Stop sending progress indicators to browser:
            self.cancelTimer()
            self.logErr('Error while processing req: %s' % `e`)
            # Need to escape double-quotes so that the 
            # browser-side JSON parser for this response
            # doesn't get confused:
            #safeResp = json.dumps('(%s): %s)' % (requestDict['req']+str(requestDict['args']), `e`))
            #self.writeError("Server could not extract request name/args from %s" % safeResp)
            self.writeError("%s" % `e`)
            
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
        self.logDebug("Sending err to browser: %s" % msg)
        self.write_message('{"resp" : "error", "args" : "%s"}' % msg)

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
        self.logDebug("Prep to send result to browser: %s" % responseName + ':' +  str(args))
        jsonArgs = json.dumps(args)
        msg = '{"resp" : "%s", "args" : %s}' % (responseName, jsonArgs)
        self.logDebug("Sending result to browser: %s" % msg)
        self.write_message(msg)
        
    def exportClass(self, detailDict):
        '''
        {courseId : <the courseID>, wipeExisting : <true/false wipe existing class tables files>}
        @param detailDict:
        @type detailDict:
        '''
        theCourseID = detailDict.get('courseId', '').strip()
        if len(theCourseID) == 0:     
            self.writeError('Please fill in the course ID field.')
            return False
        # Check whether we are to delete any already existing
        # csv files for this class:
        xpungeExisting = detailDict.get("wipeExisting", False)
        inclPII = detailDict.get("inclPII", False)
        cryptoPWD = detailDict.get("cryptoPwd", '')
        if cryptoPWD is None:
            cryptoPWD = ''
            
        # Build the CL command for script makeCourseCSV.sh
        scriptCmd = [self.exportCSVScript,'-u',self.currUser]
        if self.mySQLPwd is not None:
            scriptCmd.extend(['-w',self.mySQLPwd])
        if xpungeExisting:
            scriptCmd.append('-x')
        scriptCmd.extend(['-i',self.infoTmpFile.name])
        if inclPII:
            scriptCmd.extend(['-n',cryptoPWD])
        scriptCmd.append(theCourseID)
        
        #************
        self.logDebug("Script cmd is: %s" % str(scriptCmd))
        #************
        
        # Call makeClassCSV.sh to export:
        try:
            #pipeFromScript = subprocess.Popen(scriptCmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE).stdout
            pipeFromScript = subprocess.Popen(scriptCmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
            while pipeFromScript.poll() is None:
                (msgFromScript,errmsg) = pipeFromScript.communicate()
                if len(errmsg) > 0:
                    self.writeResult('progress', errmsg)
                else:
                    self.writeResult('progress', msgFromScript)
                    
            #**********8            
            #for msgFromScript in pipeFromScript:
            #    self.writeResult('progress', msgFromScript)
            #**********8                            
        except Exception as e:
            self.writeError(`e`)
        
        # The bash script will have placed a list of
        # output files it has created into self.infoTmpFile.
        # If the script aborted b/c it did not wish to overwrite
        # existing files, then the script truncated 
        # the file to zero:
        
        if os.path.getsize(self.infoTmpFile.name) > 0:
            # Make an array of csv file paths:
            self.csvFilePaths = []
            self.infoTmpFile.seek(0)
            for csvFilePath in self.infoTmpFile:
                self.csvFilePaths.append(csvFilePath.strip())        
                
            # Send table row samples to browser:
            self.printClassTableInfo(inclPII)
            
        return True
    
    def printClassTableInfo(self, inclPII):
        '''
        Writes html to browser that shows result table
        file names and sizes. Also sends a few lines
        from each table as samples.
        In case of PII-including reports, only one file
        exists, and it is zipped and encrypted.
        @param inclPII: whether or not the report includes PII
        @type inclPII: Boolean 
        '''
        
        if inclPII:
            self.writeResult('printTblInfo', '<br><b>Tables are zipped and encrypted</b></br>')
            return
        
        self.logDebug('Getting table names from %s' % str(self.csvFilePaths))
        
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
            
            # Get the table name from the table file name:
            if csvFilePath.find('EventXtract') > -1:
                tblName = 'EventXtract'
            elif csvFilePath.find('VideoInteraction') > -1:
                tblName = 'VideoInteraction'
            elif csvFilePath.find('ActivityGrade') > -1:
                tblName = 'ActivityGrade'
            else:
                tblName = 'unknown table name'
            
            # Only output size and sample rows if table
            # wasn't empty. Line count of an empty
            # table will be 1, b/c the col header will
            # have been placed in it. So tblFileSize == 0
            # won't happen, unless we change that:
            if tblFileSize == 0 or lineCnt == '1':
                self.writeResult('printTblInfo', '<br><b>Table %s</b> is empty.' % tblName)
                continue
            
            self.writeResult('printTblInfo', 
                             '<br><b>Table %s</b></br>' % tblName +\
                             '(file %s size: %d bytes, %s line(s))<br>' % (csvFilePath, tblFileSize, lineCnt) +\
                             'Sample rows:<br>')
            if tblFileSize > 0:
                lineCounter = 0
                with open(csvFilePath) as infoFd:
                    while lineCounter < CourseCSVServer.NUM_OF_TABLE_SAMPLE_LINES:
                        tableRow = infoFd.readline()
                        if len(tableRow) > 0:
                            self.writeResult('printTblInfo', tableRow + '<br>')
                        lineCounter += 1
        #****self.writeResult('<br>')
     
    def addClientInstructions(self, inclPII):
        '''
        Send the draft of an email message for the client
        back to the browsser. The message will contain the
        URL to where the client can pick up the result. If
        personally identifiable information was requested,
        the draft will include instructions for opening the
        zip file.
        @param inclPII: whether or not PII was requested
        @type inclPII: Boolean
        '''
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
        url = "https://%s/instructor/%s" % (thisFullyQualDomainName, tableDir)
        self.writeResult('progress', "<p><b>Email draft for client; copy-paste into email program:</b><br>")
        msgStart = 'Hi,<br>your data is ready for pickup. Please visit our <a href="%s">pickup page</a>.<br>' % url
        self.writeResult('progress', msgStart)
        # The rest of the msg is in a file:
        try:
            if inclPII:
                with open(os.path.join(self.thisScriptDir, 'clientInstructionsSecure.html'), 'r') as txtFd:
                    lines = txtFd.readlines()
            else:
                with open(os.path.join(self.thisScriptDir, 'clientInstructions.html'), 'r') as txtFd:
                    lines = txtFd.readlines()
        except Exception as e:
            self.writeError('Could not read client instruction file: %s' % `e`)
            return
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
        mySqlCmd = [self.searchCourseNameScript,'-u',self.currUser]
        if self.mySQLPwd is not None:
            mySqlCmd.extend(['-w',self.mySQLPwd])
        mySqlCmd.extend([courseID])
        self.logDebug("About to query for course names on regexp: '%s'" % mySqlCmd)
        
        try:
            pipeFromMySQL = subprocess.Popen(mySqlCmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE).stdout
        except Exception as e:
            self.writeError('Error while searching for course names: %s' % `e`)
            return courseNames
        for courseName in pipeFromMySQL:
            courseNames.append(courseName)
        return courseNames
      
    def reportProgress(self):
        self.writeResult('progress', '.')
        self.setTimer(CourseCSVServer.PROGRESS_INTERVAL)
                
    def setTimer(self, time=None):
        if time is None:
            time = CourseCSVServer.PROGRESS_INTERVAL
        self.currTimer = Timer(time, self.reportProgress)
        self.currTimer.start()

    def cancelTimer(self):
        if self.currTimer is not None:
            self.currTimer.cancel()
            self.logDebug('Cancelling progress timer')
            
    def logInfo(self, msg):
        if self.loglevel >= CourseCSVServer.LOG_LEVEL_INFO:
            print(str(datetime.datetime.now()) + ' info: ' + msg) 

    def logErr(self, msg):
        if self.loglevel >= CourseCSVServer.LOG_LEVEL_ERR:
            print(str(datetime.datetime.now()) + ' error: ' + msg) 

    def logDebug(self, msg):
        if self.loglevel >= CourseCSVServer.LOG_LEVEL_DEBUG:
            print(str(datetime.datetime.now()) + ' debug: ' + msg) 

     
    # -------------------------------------------  Testing  ------------------
                
    def echoParms(self):
        for parmName in self.parms.keys():
            print("Parm: '%s': '%s'" % (self.parms.getvalue(parmName, '')))


if __name__ == '__main__':
    
    application = tornado.web.Application([(r"/exportClass", CourseCSVServer),])
    #application.listen(8080)
    
    # To find the SSL certificate location, we assume
    # that it is stored in dir '.ssl' in the current 
    # user's home dir. 
    # We'll build string up to, and excl. '.crt'/'.key' in:
    #     "/home/paepcke/.ssl/mono.stanford.edu.crt"
    # and "/home/paepcke/.ssl/mono.stanford.edu.key"
    # The home dir and fully qual. domain name
    # will vary by the machine this code runs on:    
    # We assume the cert and key files are called
    # <fqdn>.crt and <fqdn>.key:
    
    homeDir = os.path.expanduser("~")
    thisFQDN = socket.getfqdn()
    
    sslRoot = '%s/.ssl/%s' % (homeDir, thisFQDN)
    
    http_server = tornado.httpserver.HTTPServer(application,ssl_options={
       "certfile": sslRoot + '.crt',
       "keyfile":  sslRoot + '.key',
       })
    
    application.listen(8080, ssl_options={
                            "certfile": sslRoot + '.crt',
                            "keyfile":  sslRoot + '.key',
                            })    
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
