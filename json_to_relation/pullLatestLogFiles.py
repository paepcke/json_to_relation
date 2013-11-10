'''
Created on Nov 9, 2013

@author: paepcke
'''
import logging
import os
import re
import sys
import datetime

import boto


class TrackLogPuller(object):
    '''
    Logs into S3 service, and pulls JSON formatted OpenEdX track log files that have not
    been pulled and transformed yet. Maintains a file pullHistory.txt, which records
    the files that have been retrieved from S3. Initiates each log file's transformation
    to a relational model, generating .sql load files. Initiates loads of those files.
    Then deletes the local copies of log and sql files for security. They contain
    personally identifiable information.
    
    Technique for pulling files from S3 based on draft by Sef Kloninger. 
    '''

    LOCAL_LOG_STORE = "/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/"
    #LOCAL_LOG_STORE = "/home/dataman/Data/EdX/tracking/"
    LOG_BUCKETNAME = "stanford-edx-logs"
    
    FILE_DATE_PATTERN = re.compile(r'[^-]*-([0-9]*)[^.]*\.gz')

    def __init__(self, loggingLevel=logging.INFO, logFile=None, dryRun=False):
        '''
        Create an object that can retrieve log files from S3, avoiding  
        @param loggingLevel:
        @type loggingLevel:
        @param logFile:
        @type logFile:
        @param dryRun:
        @type dryRun:
        '''

        
        try:
            self.logger = None
            self.setupLogging(loggingLevel, logFile)
            conn = boto.connect_s3()
            self.log_bucket = conn.get_bucket(TrackLogPuller.LOG_BUCKETNAME)
            # Dict representing log pull history: maps file name to (size, processedDate)
            self.pullHistory = {}            
        except boto.exception.NoAuthHandlerFound as e:
            # TODO: more error cases to watch here to be sure (bucket not found?)
            self.logErr("boto authentication error: %s\n%s" % 
                        (str(e), "   Suggestion: put your credentials in AWS_ACCESS_KEY and AWS_SECRET_KEY environment variables, or a ~/.boto file"))
            sys.exit(1)
        
    def identifyNewLogFiles(self, historyFileDir):
        '''
        Logs into S3, and retrieves list of all log files there.
        Pulls list of previously examined log files from
        localLogFileDir/pullHistory.txt. It is structured like
        this::
            logFileName,size,processedDate
        @param historyFileDir: directory where the tack log load history file pullHistory.txt is stored.
        @type historyFileDir: String
        @return: array of Amazon log files that have not been downloaded yet. Array may be empty. 
                 locations include the application server directory above each file. Ex.: 'app10/tracking.log-20130623.gz'
        @rtype: [String]
        '''
        if historyFileDir is None:
            raise ValueError('historyFileDir must be a string denoting directory where track log load history file pullHistory.txt lives.')
        
        fileNamesToGet = []
        today = datetime.date.today()
        
        # Get remote track log file names:
        rLogFileNameObjs = self.log_bucket.list()
        if rLogFileNameObjs is None:
            return []
        try:
            with open(os.path.join(historyFileDir, 'pullHistory.txt'), 'r') as fd:
                historyLines = fd.readlines()
        except IOError:
            raise ValueError('At least one directory along the path %s does not exist, or is not searchable.' % historyFileDir)
        for histLine in historyLines: 
            try:
                (logFile, size, processedDate) = histLine.split(',')
                self.pullHistory[logFile] = (size, processedDate)
            except ValueError:
                continue
            
        for rlogNameObj in rLogFileNameObjs:
            rLogPath = str(rlogNameObj.name)
            if rLogPath[-1] == "/":
                # Ignore subdir names like 'app10/'
                continue
            rLogFileName = os.path.basename(rLogPath)
            localEquiv = self.pullHistory.get(rLogFileName, None)
            if localEquiv is not None:
                # ALreay downloaded and processed this log file earlier. 
                continue
            # Get date from log file name; format: tracking.log-20130623.gz
            dateMatch = TrackLogPuller.FILE_DATE_PATTERN.search(rLogFileName)
            if dateMatch is None:
                self.logWarn('Remote track log file name has non-standard format (expecting name like tracking.log-20130609.gz): %s' % rLogFileName)
                continue
            dateStr = dateMatch.groups(1)[0]
            # Make a date obj from yyyy, mm, and dd:
            logCreateDate = datetime.date(int(dateStr[:4]), int(dateStr[4:6]), int(dateStr[6:8]))  
            #print today - logCreateDate
            if (today - logCreateDate).days >= 1:
                fileNamesToGet.append(rLogPath)
        return fileNamesToGet

    def pullNewFiles(self, destDir):
        '''
        Given a root directory, copy track log files from S3 into subdirectories
        app10, app11, app20, etc. Only files that have not been processed yet
        are loaded. The load history file is consulted to ensure this selection.
        A list of full path for the newly downloaded files is returned.  
        @param destDir: directory from which app10/filename, etc. descend.
        @type destDir: String
        @return: list of full-path file names that have been downloaded. They have not been transformed and loaded yet.
        @rtype: [String]
        '''
        # Identify log files at S3 that we have not pulled yet.
        # Let location of pullHistory.txt file default:
        filesToPull = self.identifyNewLogFiles(TrackLogPuller.LOCAL_LOG_STORE)
        
        with open(os.path.join(destDir, 'pullHistory.txt')) as histFd: 
            for fileToPull in filesToPull:
                localDest = os.path.join(TrackLogPuller.LOCAL_LOG_STORE, fileToPull)
                self.log_bucket.get_contents_to_filename(localDest)
                # Update the history file (int, datetime):
                (fileSize, createTime) = self.getHistoryFacts(localDest)
                histFd.write('%s,%d,%s\n' % (localDest, fileSize, str(createTime)))

        return filesToPull

    def runTransforms(self, logFilePaths, sqlDestDir, transformLogDestDir):
        '''
        Given a list of full-path log files, initiate their transform.
        Uses gnu parallel to use multiple cores if available.        
        @param logFilePaths: list of full paths for log files to be transformed.
        @type logFilePaths: [String]
        @param sqlDestDir: full path to dir where sql files will be deposited.
        @type sqlDestDir: String
        @param: transformLogDestDir: full path to where the log files generated by the
                          transform process will be deposited. One log per transformed log file 
        @type: transformLogDestDir: String
        '''
        
    
    
    def createHistory(self, dirPath, histFileDestDir=None):
        '''
        Given a directory that contains track log files, create a
        history file for them (pullHistory.txt). Used only to repair
        broken history files, or build the history file when
        log files have been downloaded from S3, and transformed/loaded
        manually. Normally, downloaded files are added to the history
        file automatically.
        
        @param dirPath: path to directory that contains previously downloaded track logfiles
        @type dirPath: String
        '''
        if histFileDestDir is None:
            histFileDestDir = dirPath
        try:
            fileNames = os.listdir(dirPath)
        except IOError:
            self.logWarn("Directory path %s is not found." % dirPath)
            
        with open(os.path.join(histFileDestDir, 'pullHistory.txt'), 'a') as histFd:
            for maybeLogFile in fileNames:
                # Do a sanity check on the file name: it must be parsed successfully
                # the the   pattern: FILE_DATE_PATTERN
                dateMatch = TrackLogPuller.FILE_DATE_PATTERN.search(maybeLogFile)
                if dateMatch is None:
                    # not a log file:
                    continue
                fullPath  = os.path.join(dirPath, maybeLogFile)
                (fileSize, createTime) = self.getHistoryFacts(fullPath)
                histFd.write('%s,%d,%s\n' % (fullPath, fileSize, str(createTime)))
            

    def getHistoryFacts(self, logFilePath):
        '''
        Given the full path of a log file, return a tuple
        that includes the file's size in bytes, and the 
        file's creation time as a datetime object.
        @param logFilePath: absolute path to the log file in question
        @type logFilePath: String
        @return: a two-tuple that includes the file size in bytes, and a datetime object
                 that corresponds to the creation time.
        @rtype: (int, datetime.datetime)
        '''
        fileStats = os.stat(logFilePath)
        return (fileStats.st_size, datetime.datetime.fromtimestamp(fileStats.st_ctime))

    def setupLogging(self, loggingLevel, logFile):
        '''
        Set up the standard Python logger. 
        TODO: have the logger add the script name as Sef's original
        @param loggingLevel:
        @type loggingLevel:
        @param logFile:
        @type logFile:
        '''
        # Set up logging:
        self.logger = logging.getLogger('pullTackLogs')
        self.logger.setLevel(loggingLevel)
        # Create file handler if requested:
        if logFile is not None:
            handler = logging.FileHandler(logFile)
        else:
            # Create console handler:
            handler = logging.StreamHandler()
        handler.setLevel(loggingLevel)
#       # Add the handler to the logger
        self.logger.addHandler(handler)
 
    def logWarn(self, msg):
        self.logger.warn(msg)

    def logInfo(self, msg):
        self.logger.info(msg)

    def logErr(self, msg):
        self.logger.error(msg)

#         
#         
# 
# import sys
# import os
# import boto
# 
# 
# 
# 
# myname = sys.argv[0]
# 
# 
# try:
#     conn = boto.connect_s3()
# 
#     log_bucket = conn.get_bucket(LOG_BUCKETNAME)
# 
# except boto.exception.NoAuthHandlerFound as e:
# 
#     # TODO: more error cases to watch here to be sure (bucket not found?)
#     sys.stderr.write("%s: boto authentication error: %s\n" % (myname, str(e)))
# 
#     sys.stderr.write("suggestion: put your credentials in AWS_ACCESS_KEY and AWS_SECRET_KEY environment variables, or a ~/.boto file\n")
# 
#     sys.exit(1)
# 
# logs = log_bucket.list()
# for log in logs:
# 
#     logstr = str(log.name)
# 
#     if logstr[-1] == "/":
# 
#         continue
# 
#     dest = LOCAL_LOG_STORE+logstr
# 
#     if os.path.exists(dest):
# 
#         if os.stat(dest).st_size == log.size:
# 
#             print myname, "skipping:", logstr
#             continue
#         else:
#             print myname, "removing partial:", logstr
# 
#             os.remove(dest)
# 
# 
#     print myname, "downloading:", logstr
#     dest_path = "/".join(dest.split("/")[0:-1])
# 
#     if not os.path.exists(dest_path):
# 
#         os.makedirs(dest_path)
#     log.get_contents_to_filename(dest)     

if __name__ == '__main__':
    # For testing:
    puller = TrackLogPuller()
    print puller.identifyNewLogFiles('/tmp')
    #print puller.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app10', '/tmp')
    
    
    