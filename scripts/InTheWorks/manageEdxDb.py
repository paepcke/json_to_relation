#!/usr/bin/env python

'''
Created on Nov 9, 2013

@author: paepcke
'''
import argparse
import datetime
import getpass
import glob
import logging
import os
import re
import socket
import subprocess
import sys

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
    
    hostname = socket.gethostname()
    if hostname == 'duo':
        LOCAL_LOG_STORE = "/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/"
    elif hostname == 'mono':
        LOCAL_LOG_STORE = "/home/paepcke/Project/VPOL/Data/EdXTrackingOct22_2013/"
    elif hostname == 'datastage':
        LOCAL_LOG_STORE = "/home/dataman/Data/EdX/tracking/"
    LOG_BUCKETNAME = "stanford-edx-logs"
    
    FILE_DATE_PATTERN = re.compile(r'[^-]*-([0-9]*)[^.]*\.gz')

# ----------------------------------------  Public Methods ----------------------

    def __init__(self, loggingLevel=logging.INFO, logFile=None):
        '''
        Create an object that can retrieve log files from S3, avoiding  
        @param loggingLevel:
        @type loggingLevel:
        @param logFile:
        @type logFile:
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
        localLogFileDir/pullHistory.txt. This file is structured like
        this::
            logFileName,size,processedDate
            
        The historyFileDir is where the history file is stored, but
        it is also the root of the track log file subtree: historyFileDir/app10, historyFileDir/app11, etc.
        @param historyFileDir: directory where the tack log load history file pullHistory.txt is stored. Also the root of the track log file subtree.
        @type historyFileDir: String
        @return: array of Amazon log files that have not been downloaded yet. Array may be empty. 
                 locations include the application server directory above each file. Ex.: 'app10/tracking.log-20130623.gz'
        @rtype: [String]
        '''
        if historyFileDir is None:
            raise ValueError('historyFileDir must be a string denoting directory where track log load history file pullHistory.txt lives.')
        
        rfileObjsToGet = []
        today = datetime.date.today()
        
        # Get remote track log file names:
        rLogFileObjs = self.log_bucket.list()
        if rLogFileObjs is None:
            return []
        try:
            historyFilePath = os.path.join(historyFileDir, 'pullHistory.txt')
            with open(historyFilePath, 'r') as fd:
                historyLines = fd.readlines()
        except IOError:
            if os.path.exists(historyFileDir):
                advice = "   Create an empty one there, or use method createHistory() if you have manually downloaded track log files."
                raise ValueError('No pullHistory.txt file at %s.\n%s' % (historyFileDir, advice))
            else:
                raise ValueError('At least one directory along the path %s does not exist, or is not searchable.' % historyFileDir)
        for histLine in historyLines: 
            try:
                (logFile, size, processedDate) = histLine.split(',')
                self.pullHistory[logFile] = (size, processedDate)
            except ValueError:
                continue
            
        for rlogFileObj in rLogFileObjs:
            
            rLogPath = str(rlogFileObj.name)
            self.logDebug('Looking at remote track log file %s' % rLogPath)            
            if rLogPath[-1] == "/":
                # Ignore subdir names like 'app10/'
                continue
            rLogFileName = os.path.basename(rLogPath)
            localEquiv = self.pullHistory.get(os.path.join(historyFileDir, rLogPath), None)
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
                rfileObjsToGet.append(rlogFileObj)
        return rfileObjsToGet

    def pullNewFiles(self, destDir=None, dryRun=False):
        '''
        Given a root directory, copy track log files from S3 into subdirectories
        app10, app11, app20, etc. Only files that have not been processed yet
        are loaded. The load history file is consulted to ensure this selection.
        A list of full paths for the newly downloaded files is returned.  The
        history file is by default in TrackLogPuller.LOCAL_LOG_STORE
        @param destDir: directory from which app10/filename, etc. descend.
        @type destDir: String
        @param dryRun: if True, only log what *would* be done. Cause no actual changes.
        @type dryRun: Bool
        @return: list of full-path file names that have been downloaded. They have not been transformed and loaded yet.
        @rtype: [String]
        '''
        
        if destDir is None:
            destDir=TrackLogPuller.LOCAL_LOG_STORE
        
        # Identify log files at S3 that we have not pulled yet.
        # Let location of pullHistory.txt file default:
        rfileObjsToPull = self.identifyNewLogFiles(TrackLogPuller.LOCAL_LOG_STORE)
        
        with open(os.path.join(destDir, 'pullHistory.txt'), 'a') as histFd: 
            for rfileObjToPull in rfileObjsToPull:
                localDest = os.path.join(TrackLogPuller.LOCAL_LOG_STORE, rfileObjToPull.name)
                if dryRun:
                    self.logInfo("Would download file %s from S3" % localDest)
                    self.logInfo("Would update pullHistory.txt with stats of .../%s" % os.path.basename(localDest))
                else:
                    self.logInfo("Downloading file %s from S3..." % localDest)
                    rfileObjToPull.get_contents_to_filename(localDest)

                    # Update the history file (int, datetime):
                    (fileSize, createTime) = self.getHistoryFacts(localDest)
                    self.logInfo("Updating pullHistory.txt with .../%s,%d,%s" % (os.path.basename(localDest), fileSize, str(createTime)))
                    histFd.write('%s,%d,%s\n' % (localDest, fileSize, str(createTime)))
        if dryRun:
            self.logInfo("Would have pulled files from S3 that are at least one day old, and are not present locally.")                    
        else:
            self.logInfo("Pulled all track log files that are new on S3, are at least one day old, and are not present locally.")                    
        return rfileObjsToPull

    def transform(self, logFilePaths, sqlDestDir=None, dryRun=False):
        '''
        Given a list of full-path log files, initiate their transform.
        Uses gnu parallel to use multiple cores if available. One error log file
        is written for each transformed track log file. These error log files
        are written to directory TransformLogs that is a sibling of the given
        sqlDestDir. Assumes that script transformGivenLogfiles.sh found by
        subprocess. Just have it in the same dir as this file.
        @param logFilePaths: list of full0path track log files that are to be transformed.
        @type logFilePaths: [String]
        @param sqlDestDir: full path to dir where sql files will be deposited. If None,
                           SQL files will to into TrackLogPuller.LOCAL_LOG_STORE/SQL
        @type sqlDestDir: String
        @param dryRun: if True, only log what *would* be done. Cause no actual changes.
        @type dryRun: Bool
        '''
        if logFilePaths is None:
            logFilePaths = TrackLogPuller.LOCAL_LOG_STORE + '/app*/*.gz'
        if sqlDestDir is None:
            sqlDestDir = os.path.join(TrackLogPuller.LOCAL_LOG_STORE, 'SQL')
        shellCommand = ['transformGivenLogfiles.sh', sqlDestDir]
        # Add the logfiles as arguments; if that's a wildcard expression,
        # i.e. string, just append. Else it's assumed to an array of
        # strings that need to be concatted:
        if isinstance(logFilePaths, basestring):
            shellCommand.append(logFilePaths)
        else:
            shellCommand.extend(logFilePaths)

        # If file list is a shell glob, expand into a file list:
        # for logging:
        if isinstance(logFilePaths, basestring):
            fileList = glob.glob(logFilePaths)

        if dryRun:
            self.logInfo('Would start to transform %d tracklog files...' % len(fileList))            
            # List just the basenames of the log files.
            self.logInfo("Would call shell script transformGivenLogfiles.sh %s %s" %
                         (sqlDestDir, str(logFilePaths)))
                        #(sqlDestDir, map(os.path.basename, logFilePaths)))
            self.logInfo('Would be done transforming %d newly downloaded tracklog files...' % len(fileList))
        else:
            self.logInfo('Starting to transform %d tracklog files...' % len(fileList))
            self.logDebug('Calling Bash with %s' % shellCommand)
            subprocess.call(shellCommand)
            self.logInfo('Done transforming %d newly downloaded tracklog files...' % len(fileList))

    def load(self, pwd, sqlFileSrc=None, dryRun=False):
        '''
        Given a directory that contains .sql files, or an array of full-path .sql
        files, load them into mysql.
        @param pwd: Root password for MySQL db
        @type pwd: String
        @param sqlFileSrc: 
        @type sqlFileSrc:
        @param dryRun:
        @type dryRun:
        '''
        if sqlFileSrc is None:
            sqlFileSrc = os.listdir(TrackLogPuller.LOCAL_LOG_STORE + '/SQL')
        # Now SQL files are guaranteed to be a list. Load them all using
        # a bash script, which will also run the index: 
        shellCommand = ['load.sh', pwd]
        shellCommand.extend(sqlFileSrc)
        if dryRun:
            self.logInfo("Would now invoke bash command %s" % shellCommand)
        else:
            subprocess.call(shellCommand)
    
    def createHistory(self, dirPath, histFileDestDir=None, dryRun=None):
        '''
        Given a directory that contains track log files, create a
        history file for them (pullHistory.txt). The file will look
        as if the log files had been pulled from S3 by this script
        automatically.
        Used only to repair broken history files, or build the history file when
        log files have been downloaded from S3, and transformed/loaded
        manually. Normally, downloaded files are added to the history
        file automatically.
        
        @param dirPath: path to directory that contains previously downloaded track logfiles
        @type dirPath: String
        @param histFileDestDir: directory where history file is to be placed. Default: TrackLogPuller.LOCAL_LOG_STORE
        @type histFileDestDir: String
        @param dryRun: if True, only log what *would* be done. Cause no actual changes.
        @type dryRun: Bool
        '''
        if histFileDestDir is None:
            histFileDestDir = TrackLogPuller.LOCAL_LOG_STORE
        try:
            os.makedirs(dirPath)
        except OSError:
            # dir and all intermediate dirs already exit; fine.
            pass
        try:
            # Get all files in the dir where the track logs are stored:
            fileNames = os.listdir(dirPath)
        except IOError:
            # Shouldn't happen.
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
                if dryRun:
                    self.logInfo('Would add to history file: "%s,%d,%s"' % (fullPath, fileSize, str(createTime)))
                else:
                    histFd.write('%s,%d,%s\n' % (fullPath, fileSize, str(createTime)))
            
    # ----------------------------------------  Private Methods ----------------------
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
        #self.logger = logging.getLogger('pullTackLogs')
        self.logger = logging.getLogger(os.path.basename(__file__))

        # Create file handler if requested:
        if logFile is not None:
            handler = logging.FileHandler(logFile)
        else:
            # Create console handler:
            handler = logging.StreamHandler()
        handler.setLevel(loggingLevel)

        # Create formatter
        formatter = logging.Formatter("%(name)s: %(asctime)s;%(levelname)s: %(message)s")       
        handler.setFormatter(formatter)
        
        # Add the handler to the logger
        self.logger.addHandler(handler)
        self.logger.setLevel(loggingLevel)
         
    def logDebug(self, msg):
        self.logger.debug(msg)

    def logWarn(self, msg):
        self.logger.warn(msg)

    def logInfo(self, msg):
        self.logger.info(msg)

    def logErr(self, msg):
        self.logger.error(msg)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog=os.path.basename(sys.argv[0]))
    parser.add_argument('-l', '--errLogFile', 
                        help='fully qualified log file name to which info and error are directed. Default: log to stdout.',
                        dest='errLogFile',
                        default=None);
    parser.add_argument('-d', '--dryRun', 
                        help='show what script would do if run normally; no actual downloads or other changes are performed.', 
                        action='store_true');
    parser.add_argument('-v', '--verbose', 
                        help='print operational info to console.', 
                        dest='verbose',
                        action='store_true');
    parser.add_argument('--logs',
                        action='append',
                        help='For pull: root destination of downloaded track log files; default: ' + TrackLogPuller.LOCAL_LOG_STORE +\
                             '. For transform: root location of log files to be tranformed; default: %s.' %
                             TrackLogPuller.LOCAL_LOG_STORE)
    parser.add_argument('--sql',
                        action='append',
                        help='For transform: destination directory of where transformed track log files go (.sql files); default: ' + os.path.join(TrackLogPuller.LOCAL_LOG_STORE, 'SQL') +\
                             '. For load: directory of .sql files to be loaded, or list of .sql files; default: %s.' %
                             os.path.join(TrackLogPuller.LOCAL_LOG_STORE, 'SQL'))
    parser.add_argument('toDo',
                        help='What to do: {pull | transform | load | pullTransform | pullTransformLoad'
                        ) 
    
    args = parser.parse_args();

    if args.toDo != 'pull' and\
       args.toDo != 'transform' and\
       args.toDo != 'load' and\
       args.toDo != 'pullTransform' and\
       args.toDo != 'pullTransformLoad' and\
       args.toDo != 'createHistory':
        print("Main argument must be one of pull, transform load, pullTransform, pullTransformAndLoad, and createHistory")
        sys.exit(1)


    # Log file:
    if args.errLogFile is not None:
        os.makedirs(args.errLogFile)

    print('dryRun: %s' % args.dryRun)
    print('errLogFile: %s' % args.errLogFile)
    print('verbose: %s' % args.verbose)
    print('logs: %s' % args.logs)
    print('sql: %s' % args.sql)
    print('toDo: %s' % args.toDo)

    #sys.exit(0)
    
    if args.verbose:
        puller = TrackLogPuller(logFile=args.errLogFile, loggingLevel=logging.DEBUG)
    else:
        puller = TrackLogPuller(logFile=args.errLogFile)
    
    #**********************
    print(puller.identifyNewLogFiles("/lfs/datasource/0/home/dataman/Data/EdX/tracking/pullHistory.txt"))
    sys.exit()
    #**********************
    
    if args.toDo == 'pull' or args.toDo == 'pullTransform' or args.toDo == 'pullTransformLoad':
        # For pull cmd, 'logs' must be a writable directory (to which the track logs will be written). 
        # It will come in as a singleton array:
        if (args.logs is not None and not os.access(args.logs[0], os.W_OK)) or len(args.logs) > 1: 
            puller.logErr("For pulling track log files from S3, the 'logs' parameter must either not be present, or it must be one *writable* directory (where files will be deposited).")
            sys.exit(1)
        receivedFiles = puller.pullNewFiles(args.logs, args.dryRun)
    
    if args.toDo == 'transform' or args.toDo == 'pullTransform' or args.toDo == 'pullTransformLoad':
        # For transform cmd, logs will defaulted, or be a list of log files, or a singleton
        # list of which the first might be a directory:
        # Check for, and point out all errors, rather than quitting after one:
        if args.logs is not None:
            if os.path.isdir(args.logs[0]) and len(args.logs) > 1: 
                puller.logErr("For transform the 'logs' parameter must either be a single directory, or a list of files.")
                sys.exit(1)
            # All files must exist:
            trueFalseList = map(os.path.exists, args.logs)
            ok = True
            for i in range(len(trueFalseList)):
                if not trueFalseList[i]:
                    puller.logErr("File % does not exist." % args.logs[i])
                    ok = False
                if not os.access(args.logs[i], os.R_OK):
                    puller.logErr("File % exists, but is not readable." % args.logs[i])
                    ok = False
            if not ok:
                puller.logErr("Command aborted, no action was taken.")
                sys.exit(1)
                              
        # args.sql must be a singleton directory:
        if (args.sql is not None and len(args.sql) > 1) or not os.path.isdir(args.sql[0]) or not os.access(args.sql[0], os.W_OK):
            puller.logErr("For transform command the 'sql' parameter must be a single directory where result .sql files are written.")
            sys.exit(1)
        puller.transform(args.logs, args.sql, args.dryRun)
    
    if args.toDo == 'load' or args.toDo == 'pullTransformLoad':
        # For loading, args.sql must be None, or a readable directory, or a sequence of readable .sql files.
        if args.sql is not None:
            if os.path.isdir(args.sql[0]) and len(args.sql) > 1: 
                puller.logErr("For load the 'sql' parameter must either be a single directory, or a list of files.")
                sys.exit(1)
            # All files must exist:
            trueFalseList = map(os.path.exists, args.sql)
            ok = True
            for i in range(len(trueFalseList)):
                if not trueFalseList[i]:
                    puller.logErr("File % does not exist." % args.sql[i])
                    ok = False
                if not os.access(args.sql[i], os.R_OK):
                    puller.logErr("File % exists, but is not readable." % args.sql[i])
                    ok = False
            if not ok:
                puller.logErr("Command aborted, no action was taken.")
                sys.exit(1)
        
        # For DB ops need DB root pwd:
        pwd = getpass.getpass("Root's mysql pwd: ")
        puller.load(pwd, args.sql, args.dryRun)
    
    
    sys.exit(0)
    #puller.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app10', tracklogRoot)
    #puller.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app11', tracklogRoot)
    #puller.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app20', tracklogRoot)
    #puller.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app21', tracklogRoot)

    #puller.runTransforms(newLogs, '~/tmp', dryRun=True)
    
    
    