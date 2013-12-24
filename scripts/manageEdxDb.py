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
import sets
import socket
import string
import subprocess
import sys

import boto

# Add json_to_relation source dir to $PATH
# for duration of this execution:
source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir

from mysqldb import MySQLDB

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
        LOCAL_LOG_STORE_ROOT = "/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsTests/"
    elif hostname == 'mono':
        LOCAL_LOG_STORE_ROOT = "/home/paepcke/Project/VPOL/Data/EdXTrackingOct22_2013/"
    elif hostname == 'datastage':
        LOCAL_LOG_STORE_ROOT = "/home/dataman/Data/EdX"
    LOG_BUCKETNAME = "stanford-edx-logs"
    
    TRACKING_LOG_FILE_NAME_PATTERN = re.compile(r'tracking.log-[0-9]{8}.gz$')
    SQL_FILE_NAME_PATTERN = re.compile(r'.sql$')
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
        except boto.exception.NoAuthHandlerFound as e:
            # TODO: more error cases to watch here to be sure (bucket not found?)
            self.logErr("boto authentication error: %s\n%s" % 
                        (str(e), "   Suggestion: put your credentials in AWS_ACCESS_KEY and AWS_SECRET_KEY environment variables, or a ~/.boto file"))
            sys.exit(1)
        
    def identifyNewLogFiles(self, localTrackingLogFileRoot=None):
        '''
        Logs into S3, and retrieves list of all OpenEdx tracking log files there.
        Identifies the remote files that do not exist on the local file system,
        and returns an array of remote S3 key names for those new log files.
        
        Example return:
          ['tracking/app10/tracking.log-20130609.gz', 'tracking/app10/tracking.log-20130610.gz']
        
        When a local file of the same name as the a remote file is found, the
        remote and local MD5 hashes are compared to ensure that they are indeed
        the same files.
        
        @param localTrackingLogFileRoot: root of subtree that matches the subtree received from
               S3. Two examples for S3 subtrees in Stanford's installation are: 
               tracking/app10/foo.gz and tracking/app21/bar.gz. The localTrackingLogFileRoot
               must in that case contain the subtree 'tracking/appNN/yyy.gz'. If None, then
               class variable TrackLogPuller.LOCAL_LOG_STORE_ROOT is used.
        @type localTrackingLogFileRoot: String
        @return: array of Amazon S3 log file key names that have not been downloaded yet. Array may be empty. 
                 locations include the application server directory above each file. Ex.: 'app10/tracking.log-20130623.gz'
        @rtype: [String]
        '''
        rfileObjsToGet = []
        if localTrackingLogFileRoot is None:
            localTrackingLogFileRoot = TrackLogPuller.LOCAL_LOG_STORE_ROOT
        
        # Get remote track log file key objects:
        rLogFileKeyObjs = self.log_bucket.list()
        if rLogFileKeyObjs is None:
            return rfileObjsToGet
        
        for rlogFileKeyObj in rLogFileKeyObjs:
            # Get paths like:
            #   tracking/app10/tracking.log-20130609.gz
            #   tracking/app10/tracking.log-20130610-errors
            rLogPath = str(rlogFileKeyObj.name)
            # If this isn't a tracking log file, skip:
            if TrackLogPuller.TRACKING_LOG_FILE_NAME_PATTERN.search(rLogPath) is None:
                continue
            self.logDebug('Looking at remote track log file %s' % rLogPath)
            localEquivPath = os.path.join(localTrackingLogFileRoot, rLogPath)
            if os.path.exists(localEquivPath):
                try:
                    # Ensure that the local file is the same as the remote one, 
                    # i.e. that we already copied it over. The following call
                    # returns '<md5> <filename>':
                    md5PlusFileName = subprocess.check_output(['md5sum',localEquivPath])
                    localMD5 = md5PlusFileName.split()[0]
                    # The etag property of an S3 key obj contains
                    # the remote file's MD5, surrounded by double-quotes:
                    remoteMD5 = string.strip(rlogFileKeyObj.etag, '"')
                    if localMD5 == remoteMD5:
                        continue
                except Exception as e:
                    self.logErr("Could not compare remote file %s's MD5 with that of the local equivalent %s: %s" % (rLogPath, localEquivPath, `e`))
                    continue
            
            rfileObjsToGet.append(rLogPath)
            
        return rfileObjsToGet

    def identifyNotTransformedLogFiles(self, localTrackingLogFilePaths=None, csvDestDir=None):
        '''
        Messy method: determines which of a set of OpenEdX .json files have not already
        gone through the transform process to relations. This is done by looking at the
        file names in the transform output directory, and matching them to the candidate
        .json files. This process works, because the transform process uses a file name
        convention: given a .json file like <root>/tracking/app10/foo.gz, the .sql file
        that the transform file generates will be named tracking.app10.foo.gz.<more pieces>.sql.  
        Like this: tracking.app10.tracking.log-20131128.gz.2013-12-05T00_33_29.900465_5064.sql
        @param localTrackingLogFilePaths: list of all .json files to consider for transform.
               If None, uses LOCAL_LOG_STORE_ROOT + '/tracking/app*/*.gz'
        @type localTrackingLogFilePaths: {[String] | None}
        @param csvDestDir: directory where previous transforms have deposited their output files.
        `     If None, uses LOCAL_LOG_STORE_ROOT/tracking/CSV
        @type csvDestDir: String
        @returns: array of absolute paths to OpenEdX tracking log files that need to be
                  transformed
        @rtype: [String]
        '''
        
        if localTrackingLogFilePaths is None:
            localTrackingLogFilePaths = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'tracking/app*/*.gz')
            
        if csvDestDir is None:
            csvDestDir = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'tracking/CSV')
            
        # If tracking file list is a string (that might include shell
        # wildcards), expand into a file list:
        try:
            # After expansion, returns a list of files *that exist*:
            localTrackingLogFilePaths = glob.glob(localTrackingLogFilePaths)
        except TypeError:
            # File paths were already a list; keep only ones that exist:
            localTrackingLogFilePaths = filter(os.path.exists, localTrackingLogFilePaths)
        
        # If no log files exist at all, don't need to transform anything
        if len(localTrackingLogFilePaths) == 0:
            return []
         
        # Do have at least one tracking log file that might need
        # to be transformed. Example list:
        #   ['/home/johndoe/tracking/app10/tracking.log-20130610.gz', 
        #    '/home/johndoe/tracking/app10/tracking.log-20130609.gz'] 
        # Given LOCAL_LOG_STORE_ROOT (e.g. == '/home/johndoe/') 
        # find the path components between the end of the log files
        # root and the beginning of the log file name:
        try:
            subtree = localTrackingLogFilePaths[0][len(TrackLogPuller.LOCAL_LOG_STORE_ROOT):]
            # Chop off the file name to get, e.g. 'tracking/app10':
            subtree = os.path.dirname(subtree)
        except IndexError:
            subtree = ''
        # The transform process converts the subtree's slashes to dots,
        # and prepends the result to tracking log files when it creates
        # the output .sql files. Ex: the transform's .sql file for
        # an input file '/home/johndoe/tracking/app10/tracking.log-20130610.gz'
        # will be something like:
        # 'tracking.app10.tracking.log-20130610.gz.2013-12-23T13_07_05.082546_11122.sql
        # We need that prepended part (e.g. 'tracking.app10.'):
        outputFilePrepend = re.sub('/', '.', subtree).strip('.') + '.'
        
        # Next: find all .sql files among the existing .csv/.sql
        # files from already accomplished transforms:
        try:
            allTransformResultFiles = os.listdir(csvDestDir)
        except OSError:
            # Destination dir doesn't even exist: All tracking log files 
            # need to be transformed:
            return localTrackingLogFilePaths
        # Each transformed tracking log file has generated several .csv
        # files, but only one .sql file, so keep only the latter in
        # a list: 
        allTransformSQLFiles = filter(TrackLogPuller.SQL_FILE_NAME_PATTERN.search, allTransformResultFiles)
        
        # The .sql files created by the transform module prepend
        # the dot-separated components of the source .json file that
        # lie between the log file root and the file, and then append
        # filename elements to the original tracking log file
        # name. Example .sql file from a prior transform: 
        #    tracking.app10.tracking.log-20130609.gz.2013-12-23T13_07_05.081102_11121.sql
        # We thus find all tracking log files that do not have
        # a .sql file that starts with the prepended components (tracking.app10.
        # in the above example), followed by the json file name (tracking.log-20130609.gz
        # in the above example).
        # I'm trying out the pythonic use of list comprehensions.
        # I'm not convinced that this syntax is more clear than
        # using a more verbose, standard approach. You be the judge: 
        
        alreadyTransformedList = [logFilePath 
                                  for sqlFilePath in allTransformSQLFiles  # go through all transform output file names 
                                  for logFilePath in localTrackingLogFilePaths # go through each .json file path
                                  if os.path.basename(sqlFilePath).find(outputFilePrepend + os.path.basename(logFilePath)) > -1] # keep only the matches
        # Finally: the .json files that need to be transformed
        # are the ones that are in the .json file list, but not
        # in the .sql file list: use set difference:
        toDo = sets.Set(localTrackingLogFilePaths).difference(sets.Set(alreadyTransformedList))
        # Return an array, rather than the set,
        # b/c that's more common:
        return list(toDo)
       
       
    def identifySQLToLoad(self, csvDir=None):
        '''
        Returns the absolute paths of .sql files in a given transform
        output directory that need to be loaded into the tracking log
        db. Uses the Edx.LoadInfo to see which .sql files have already
        been loaded.
        @param csvDir: directory where previous transform runs have deposited
               their .sql and .csv files. If None, LOCAL_LOG_STORE_ROOT/tracking/CSV'
               is assumed.
        @type csvDir: String
        @return: possibly empty list of absolute paths to .sql files that have
                 not yet been loaded into the OpenEdX tracking log relational
                 db.
        '''

        if csvDir is None:
            csvDir = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'tracking/CSV')
        # Get content of LoadInfo file names in MySQL db Edx:
        if self.pwd:
            mysqldb = MySQLDB(user=self.user, passwd=self.password, db='Edx')
        else:
            mysqldb = MySQLDB(user=self.user, db='Edx')
        loadedJSONFiles = []
        for jsonFileName in mysqldb.query("SELECT load_file FROM LoadInfo"):
            # jsonFileName is a one-tuple, like: ('/foo/bar.gz',); Get the str itself:
            loadedJSONFiles.append(jsonFileName[0])
        mysqldb.close()
        # Get all the .sql file names from the CSV directory:
        try:
            allTransformResultFiles = os.listdir(csvDir)
        except OSError:
            # The csvDir doesn't exist:
            self.logWarn('Method identifySQLToLoad called with csvDir=%s, but that dir does not exist.' % csvDir)
            return []
                # Each transformed tracking log file has generated several .csv
        # files, but only one .sql file, so keep only the latter in
        # a list: 
        allTransformSQLFiles = filter(TrackLogPuller.SQL_FILE_NAME_PATTERN.search, allTransformResultFiles)
        # If no files have been loaded into the db yet, easy: 
        if len(loadedJSONFiles) == 0:
            return allTransformResultFiles 
        # Now need to compare the list of loaded files from the LoadInfo
        # table with the list of .sql file names in the directory of transform
        # results.
        
        # Elements in allTransformSQLFiles are of the 
        # form 'tracking.app10.tracking.log-20130609.gz.2013-12-23T16_14_02.335147_17587.sql'
        # So, they start with a subtree from LOCAL_LOG_STORE_ROOT, with
        # slashes replaced by dots, followed by the .json file name for
        # which the .sql file is a transform result. 
        #
        # To compare the list of already loaded files with the list of .sql files,
        # given this file name convention: we first replace
        # the slashes in the json file names from the LoadInfo
        # table with dots, turning something like 
        # 'file:///home/dataman/Data/EdX/tracking/app11/tracking.log-20131128.gz'
        # into: 'file:...home.dataman.Data.EdX.tracking.app10.tracking.log-20130609.gz'
        #
        # Then we drop everything after the json file name in each allTransformSQLFiles
        # to go from:
        # 'tracking.app10.tracking.log-20130609.gz.2013-12-23T16_14_02.335147_17587.sql' to
        # 'tracking.app10.tracking.log-20130609.gz'.
        # Finally we can check whether any of the names of already loaded files ends
        # with that json file name. 
        
        sqlFilesToSkip = []
        for sqlFileName in allTransformSQLFiles:
            # Keep only the part up to .gz from the sqlFileName:
            gzPos = sqlFileName.find('.gz')
            if gzPos < 0:
                self.logErr("One of the .sql file names in %s is non-standard: %s" % (csvDir, sqlFileName))
                continue
            sqlFileNameJSONFilePartOnly = sqlFileName[0:gzPos + len('.gz')]
            # Have 'tracking.app10.tracking.log-20130609.gz' from the CSV directory's .sql file name
            for loadedFileName in loadedJSONFiles:
                # Replace '/' with '.' in the already-loaded file name:
                loadedFileName = re.sub('/', '.', loadedFileName)
                # have '...home.dataman.Data.EdX.tracking.app10.tracking.log-20130609.gz'
                if loadedFileName.endswith(sqlFileNameJSONFilePartOnly):
                    sqlFilesToSkip.append(sqlFileName)
        # We now know which .sql to *skip*, but need the ones we do need to load.
        # Use set difference for that:
        sqlFilesToLoadSet = sets.Set(allTransformSQLFiles).difference(sets.Set(sqlFilesToSkip))
        # Make each file name into an absolute path, using that pythonic,
        # but kind of hard to read list comprehension mechanism:
        sqlFilesToLoad = [os.path.join(csvDir,sqlBaseName) for sqlBaseName in sqlFilesToLoadSet]
        return sqlFilesToLoad
         

    def pullNewFiles(self, localTrackingLogFileRoot=None, destDir=None, dryRun=False):
        '''
        Copy track log files from S3 to the local machine, if they do not
        already exist there.
        A list of full paths for the newly downloaded files is returned.
        
        @param localTrackingLogFileRoot: root of subtree that matches the subtree received from
               S3. Two examples for S3 subtrees in Stanford's installation are: 
               tracking/app10/foo.gz and tracking/app21/bar.gz. The localTrackingLogFileRoot
               must in that case contain the subtree 'tracking/appNN/yyy.gz'. If None, then
               class variable TrackLogPuller.LOCAL_LOG_STORE_ROOT is used. 
        @type localTrackingLogFileRoot: String
        @param destDir: directory from which subtree tracking/appNN/filename, etc. descend.
        @type destDir: String
        @param dryRun: if True, only log what *would* be done. Cause no actual changes.
        @type dryRun: Bool
        @return: list of full-path file names that have been downloaded. They have not been transformed and loaded yet.
        @rtype: [String]
        '''
        
        if destDir is None:
            destDir=TrackLogPuller.LOCAL_LOG_STORE_ROOT
        
        if localTrackingLogFileRoot is None:
            localTrackingLogFileRoot = TrackLogPuller.LOCAL_LOG_STORE_ROOT
        
        # Identify log files at S3 that we have not pulled yet.
        rfileNamesToPull = self.identifyNewLogFiles(localTrackingLogFileRoot)
        if len(rfileNamesToPull) == 0:
            self.logInfo("No openEdx files to pull.")
            
        for rfileNameToPull in rfileNamesToPull:
            localDest = os.path.join(destDir, rfileNameToPull)
            if dryRun:
                self.logInfo("Would download file %s from S3" % rfileNameToPull)
            else:
                self.logInfo("Downloading file %s from S3 to %s..." % (rfileNameToPull, localDest))
                fileKey = self.log_bucket.get_key(rfileNameToPull)
                if fileKey is None:
                    self.logErr("Remote OpenEdX log file %s was detected earlier, but cannot retrieve associated key object now." % rfileNameToPull)
                    continue
                # Ensure that the directory path to the local
                # dest exists:
                try:
                    os.makedirs(os.path.dirname(localDest))
                except OSError:
                    pass
                fileKey.get_contents_to_filename(localDest)
        if dryRun:
            self.logInfo("Would have pulled OpenEdX tracking log files from S3: %s" % str(rfileNamesToPull))
        else:
            self.logInfo("Pulled OpenEdX tracking log files from S3: %s" % str(rfileNamesToPull))
        return rfileNamesToPull

    def transform(self, logFilePaths=None, csvDestDir=None, dryRun=False):
        '''
        Given a list of full-path log files, initiate their transform.
        Uses gnu parallel to use multiple cores if available. One error log file
        is written for each transformed track log file. These error log files
        are written to directory TransformLogs that is a sibling of the given
        csvDestDir. Assumes that script transformGivenLogfiles.sh found by
        subprocess. Just have it in the same dir as this file.
        @param logFilePaths: list of full0path track log files that are to be transformed.
        @type logFilePaths: [String]
        @param csvDestDir: full path to dir where sql files will be deposited. If None,
                           SQL files will to into TrackLogPuller.LOCAL_LOG_STORE_ROOT/SQL
        @type csvDestDir: String
        @param dryRun: if True, only log what *would* be done. Cause no actual changes.
        @type dryRun: Bool
        '''
        if logFilePaths is None:
            logFilePaths = self.identifyNotTransformedLogFiles(csvDestDir=csvDestDir)
        if csvDestDir is None:
            csvDestDir = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'tracking/CSV')
        # Ensure that the target directory exists:
        try:
            os.makedirs(csvDestDir)
        except OSError:
            pass
        
        thisScriptsDir = os.path.dirname(__file__)
        shellCommand = [os.path.join(thisScriptsDir, 'transformGivenLogfiles.sh'), csvDestDir]
        # Add the logfiles as arguments; if that's a wildcard expression,
        # i.e. string, just append. Else it's assumed to an array of
        # strings that need to be concatted:
        if isinstance(logFilePaths, basestring):
            shellCommand.append(logFilePaths)
        else:
            shellCommand.extend(logFilePaths)

        # If file list is a shell glob, expand into a file list
        # to show the file names in logs and dryRun output below;
        # the actual command is executed in a shell and does its
        # own glob resolution:
        if isinstance(logFilePaths, basestring):
            fileList = glob.glob(logFilePaths)
        else:
            fileList = logFilePaths

        if dryRun:
            self.logInfo('Would start to transform %d tracklog files...' % len(fileList))            
            # List just the basenames of the log files.
            self.logInfo("Would call shell script transformGivenLogfiles.sh %s %s" %
                         (csvDestDir, str(logFilePaths).strip('[]')))
                        #(csvDestDir, map(os.path.basename, logFilePaths)))
            self.logInfo('Would be done transforming %d newly downloaded tracklog files...' % len(fileList))
        else:
            self.logInfo('Starting to transform %d tracklog files...' % len(fileList))
            self.logDebug('Calling Bash with %s' % shellCommand)
            subprocess.call(shellCommand)
            self.logInfo('Done transforming %d newly downloaded tracklog files...' % len(fileList))

    def load(self, mysqlPWD=None, sqlFilesToLoad=None, csvDir=None, dryRun=False):
        '''
        Given a directory that contains .sql files, or an array of full-path .sql
        files, load them into mysql. This script needs to use the MySQL db as
        root, so the mysqlPWD must be the root pwd. 
        @param mysqlPWD: Root password for MySQL db. See main section for how that pwd is obtained.
        @type mysqlPWD: String
        @param sqlFilesToLoad: list of .sql files that were created by transforms to load
                        If None, calls identifySQLToLoad() to select files that have
                        not previously been loaded. Keeping this to None is recommended
                        to ensure that log files don't get loaded multiple times.
        @type sqlFilesToLoad: String
        @param csvDir: directory where transforms have deposited their .sql and associated .csv files.
                       If None, assumes LOCAL_LOG_STORE_ROOT/'tracking/CSV'. Not used if
                       sqlFilesToLoad are specified explicitly.
        @type csvDir: String
        @param dryRun: if True, only log what *would* be done. Cause no actual changes.
        @type dryRun: Bool
        '''
        if csvDir is None:
            csvDir = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'tracking/CSV')
        if sqlFilesToLoad is None:
            sqlFilesToLoad = self.identifySQLToLoad(csvDir=csvDir)
        if len(sqlFilesToLoad) == 0:
            return
        
        # Now SQL files are guaranteed to be a list. Load them all using
        # a bash script, which will also run the index: 
        shellCommand = ['load.sh', pwd]
        shellCommand.extend(sqlFileSrc)
        if dryRun:
            self.logInfo("Would now invoke bash command %s" % shellCommand)
        else:
            subprocess.call(shellCommand)
    
            
    # ----------------------------------------  Private Methods ----------------------

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
                        help='For pull: root destination of downloaded track log files; default: ' + TrackLogPuller.LOCAL_LOG_STORE_ROOT +\
                             '. For transform: root location of log files to be tranformed; default: %s.' %
                             TrackLogPuller.LOCAL_LOG_STORE_ROOT)
    parser.add_argument('--sql',
                        action='append',
                        help='For transform: destination directory of where transformed track log files go (.sql files); default: ' + os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'SQL') +\
                             '. For load: directory of .sql files to be loaded, or list of .sql files; default: %s.' %
                             os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'SQL'))
    parser.add_argument('-u', '--user',
                        action='append',
                        help='For load: user ID for operating MySQL.')
    parser.add_argument('-p', '--password',
                        action='store_true',
                        help='For load: request to be asked for pwd for operating MySQL; if omitted, script looks for $HOME/.ssh/mysql, and assumes its content is the pwd.')
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
    print('MySQL uid: %s' % args.user)
    print('MySQL pwd: %s' % args.password)
    print('toDo: %s' % args.toDo)

    #sys.exit(0)
    
    if args.verbose:
        puller = TrackLogPuller(logFile=args.errLogFile, loggingLevel=logging.DEBUG)
    else:
        puller = TrackLogPuller(logFile=args.errLogFile)

    if args.user is None:
        puller.user = getpass.getuser()
    else:
        puller.user = args.user[0]
        
    if args.password:
        puller.pwd = getpass.getpass("Enter %s's MySQL password on localhost: " % puller.user)
    else:
        # Try to find pwd in specified user's $HOME/.ssh/mysql
        currUserHomeDir = os.getenv('HOME')
        if currUserHomeDir is None:
            puller.pwd = None
        else:
            # Don't really want the *current* user's homedir,
            # but the one specified in the -u cli arg:
            userHomeDir = os.path.join(os.path.dirname(currUserHomeDir), puller.user)
            try:
                with open(os.path.join(userHomeDir, '.ssh/mysql')) as fd:
                    puller.pwd = fd.readline().strip()
            except IOError:
                # No .ssh subdir of user's home, or no mysql inside .ssh:
                puller.pwd = None
    #**********************
    #print('User: ' + str(puller.user))
    #print('PWD: ' + str(puller.pwd))
    #sys.exit()
    #
    #print(puller.identifyNewLogFiles("/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingSep20_To_Dec5_2013"))
    #print(puller.identifyNewLogFiles("/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingSep20_To_Dec5_2013"))
    #print(puller.identifyNewLogFiles())
    #sys.exit()
    #
    puller.identifySQLToLoad()
    sys.exit()
    #
    #print(puller.pullNewFiles(dryRun=True))
    #sys.exit()
    #
    #print(puller.identifyNotTransformedLogFiles(csvDestDir='/home/paepcke/tmp/CSV'))
    #print(puller.identifyNotTransformedLogFiles('/foo.log')) # should be empty list
    #sys.exit()
    #
    #puller.transform(dryRun=True)
    #puller.transform(csvDestDir='/home/paepcke/tmp/CSV')
    #sys.exit()
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
    
    
    