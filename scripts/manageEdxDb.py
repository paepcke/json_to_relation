#!/usr/bin/env python

'''
Created on Nov 9, 2013

Script that depending on CLI options will
  - Retrieve any new OpenEdx tracking log files from S3
  - Transform the new files
  - Load the resulting .csv files into the OpenEdX relational db

Three variables can be set to account for installations other
than Stanford's. See below. 

usage: manageEdxDb.py [-h] [-l ERRLOGFILE] [-d] [-v] [--logsDest LOGSDEST]
                      [--logsSrc LOGSSRC] [--sqlDest SQLDEST]
                      [--sqlSrc SQLSRC] [-u USER] [-p]
                      toDo

positional arguments:
  toDo                  What to do: {pull | transform | load | pullTransform | pullTransformLoad}

optional arguments:
  -h, --help            show this help message and exit
  -l ERRLOGFILE, --errLogFile ERRLOGFILE
                        fully qualified log file name to which info and error messages 
                        are directed. Default: stdout.
  -d, --dryRun          show what script would do if run normally; no actual downloads 
                        or other changes are performed.
  -v, --verbose         print operational info to log.
  --logsDest LOGSDEST   For pull: root destination of downloaded OpenEdX tracking log .json files;
                            default LOCAL_LOG_STORE_ROOT.
  --logsSrc LOGSSRC     For transform: quoted string of comma or space separated 
                            individual OpenEdX tracking log files to be tranformed, 
                            and/or directories that contain such tracking log files; 
                            default: all files LOCAL_LOG_STORE_ROOT/app*/*.gz that have 
                            not yet been transformed.
  --sqlDest SQLDEST     For transform: destination directory of where the .sql and 
                            .csv files of the transformed OpenEdX tracking files go;
                            default LOCAL_LOG_STORE_ROOT/tracking/CSV.
  --sqlSrc SQLSRC       For load: directory of .sql/.csv files to be loaded, or list of .sql files;
                            default LOCAL_LOG_STORE_ROOT/tracking/CSV.
  -u USER, --user USER  For load: user ID whose HOME/.ssh/mysql_root contains the localhost MySQL root password.
  -p, --password        For load: request to be asked for pwd for operating MySQL;
                            default: content of /home/paepcke/.ssh/mysql_root if --user is unspecified,
                            or content of <homeOfUser>/.ssh/mysql_root where
                            <homeOfUser> is the home directory of the user specified in the --user option.

At Stanford's datastage.stanford.edu machine the script will do 'the right thing'
with just a single argument: {pull | transform | load | pullTransform | pullTransformLoad'}. 
To use the script in other installations, modify the following constants:

  - LOG_BUCKETNAME: the S3 bucket where OpenEdX tracking log files are stored as they 
                    become available.
  - LOCAL_LOG_STORE_ROOT: The root directory on the local machine (where this script is run),
                    from which subtrees of loaded tracking files grow. At stanford the
                    subtree is tracking/{app10/app11/app20/app21}. The root of that 
                    subtree is /home/dataman/Data/EdX. An example tracking log file path
                    is thus: /home/dataman/Data/EdX/tracking/app10/tracking.log-20130610.gz
  - MYSQL_ROOT_USER a user name in whose HOME/.ssh the script will find the localhost MySQL
                    root user's password in file mysql_root. If such a user is unavailable or undesired,
                    make this constant blank, and use the -p option when calling 
                    the script, and it will prompt for the pwd. 
                    Or, if it is undesired to hard code that user, make sure
                    to provide the --user option in calls that effect loading. 
                    The .ssh/mysql_root mechanism is available to run this script in 
                    unattended CRON jobs. 
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
    
    # If LOCAL_LOG_STORE_ROOT is not set in the following
    # statement, then options --logsDest , --logsSrc, --sqlDest,
    # and --sqlSrc must be provided for pull, transform, and load
    # commands, as appropriate. If LOCAL_LOG_STORE_ROOT
    # is provided here, then appropriate defaults will
    # be computed for these options:
    if hostname == 'duo':
        LOCAL_LOG_STORE_ROOT = "/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsTests/"
    elif hostname == 'mono':
        LOCAL_LOG_STORE_ROOT = "/home/paepcke/Project/VPOL/Data/EdXTrackingOct22_2013/"
    elif hostname == 'datastage':
        LOCAL_LOG_STORE_ROOT = "/home/dataman/Data/EdX"
    else:
        LOCAL_LOG_STORE_ROOT = None
    LOG_BUCKETNAME = "stanford-edx-logs"
    
    # UID of user in whose HOME/.ssh/ a mysql_root file contains
    # the MySQL root pwd for access from localhost. If set to None,
    # then invocation of this script needs to use the -p option,
    # or must provide this user in the -u option:
    #MYSQL_ROOT_USER = None
    MYSQL_ROOT_USER = 'paepcke'
    
    # Directory into which the executeCSVLoad.sh script that is invoked
    # from the load() method will put its log entries.
    LOAD_LOG_DIR = ''
    
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

        TrackLogPuller.LOAD_LOG_DIR = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'Logs')        
        self.logger = None
        self.setupLogging(loggingLevel, logFile)
        # No connection yet to S3. That only
        # gets established when needed:
        self.tracking_log_bucket = None

    def openS3Connection(self):
        '''
        Attempt to connect to Amazon S3. This connection depends on 
        Boto, and thereby on the home directory of the user who invoked
        manageExDb.py to have a .boto subdirectory with the requisite
        authentication information.
        '''
        try:
            conn = boto.connect_s3()
            self.tracking_log_bucket = conn.get_bucket(TrackLogPuller.LOG_BUCKETNAME)
        except boto.exception.NoAuthHandlerFound as e:
            # TODO: more error cases to watch here to be sure (bucket not found?)
            self.logErr("boto authentication error: %s\n%s" % 
                        (str(e), "   Suggestion: put your credentials in AWS_ACCESS_KEY and AWS_SECRET_KEY environment variables, or a ~/.boto file"))
            return False
        return True
        
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
        @raise: IOError if connection to S3 cannot be established.
        '''

        self.logDebug("Method identifyNewLogFiles() called with localTrackingLogFileRoot='%s'" % localTrackingLogFileRoot)
        
        rfileObjsToGet = []
        if localTrackingLogFileRoot is None:
            localTrackingLogFileRoot = TrackLogPuller.LOCAL_LOG_STORE_ROOT
        
        # Get remote track log file key objects:
        if self.tracking_log_bucket is None:            
            # No connection has been established yet to S3:
            self.logInfo("Establishing connection to Amazon S3")
            if not self.openS3Connection():
                self.logErr("Could not connect to Amazon 3S: %s" % sys.last_value)
                raise IOError("Could not connect to Amazon S3 to examine existing tracking log file list.")
        rLogFileKeyObjs = self.tracking_log_bucket.list()
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

        self.logDebug("Method identifyNotTransformedLogFiles()  called with localTrackingLogFilePaths='%s'; csvDestDir='%s'" % (localTrackingLogFilePaths,csvDestDir))
             
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

        self.logDebug("Method identifySQLToLoad()  called with csvDir='%s'" % csvDir)

        if csvDir is None:
            csvDir = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'tracking/CSV')
        # Get content of LoadInfo file names in MySQL db Edx:
        if self.pwd:
            mysqldb = MySQLDB(user='root', passwd=self.pwd, db='Edx')
        else:
            mysqldb = MySQLDB(user='root', db='Edx')
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
        @raise: IOError if connection to S3 cannot be established.        
        '''

        self.logDebug("Method pullNewFiles()  called with localTrackingLogFileRoot='%s'; destDir='%s'" % (localTrackingLogFileRoot,destDir))
        
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
                self.logInfo("Establishing connection to Amazon S3")
                if self.tracking_log_bucket is None:
                    # No connection has been established yet to S3:
                    if not self.openS3Connection():
                        self.logErr("Could not connect to Amazon 3S: %s" % sys.last_value)
                        raise IOError("Could not connect to Amazon S3 to examine existing tracking log file list.")
                
                self.logInfo("Downloading file %s from S3 to %s..." % (rfileNameToPull, localDest))
                fileKey = self.tracking_log_bucket.get_key(rfileNameToPull)
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
            self.logInfo("Would have pulled OpenEdX tracking log files from S3 as per above listings.")
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
        @param logFilePaths: list of full-path track log files that are to be transformed.
        @type logFilePaths: [String]
        @param csvDestDir: full path to dir where sql files will be deposited. If None,
                           SQL files will to into TrackLogPuller.LOCAL_LOG_STORE_ROOT/SQL
        @type csvDestDir: String
        @param dryRun: if True, only log what *would* be done. Cause no actual changes.
        @type dryRun: Bool
        '''
        
        self.logDebug("Method transform() method called with logFilePaths='%s'; csvDestDir='%s'" % (logFilePaths,csvDestDir))

        if logFilePaths is None:
            logFilePaths = self.identifyNotTransformedLogFiles(csvDestDir=csvDestDir)
        if csvDestDir is None:
            csvDestDir = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'tracking/CSV')
            
        if len(logFilePaths) == 0:
            self.logInfo("In transform(): all files in %s were already transformed to %s; or logFilePaths was passed as an empty list." %
                         (os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT,'tracking/app*/*.gz'),
                          csvDestDir))
            return
        # Ensure that the target directory exists:
        try:
            os.makedirs(csvDestDir)
        except OSError:
            # If call failed, all dirs already exist:
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
            # Make the array of log file paths look as if typed on a CL: Instead
            # of "scriptName ['foo.log', bar.log']" make it: "scriptName foo.log bar.log"
            # by removing the brackets, commas, and quotes normally produced by
            # str(someList):
            logFilePathsForPrint = str(logFilePaths).strip('[]')
            logFilePathsForPrint = string.replace(logFilePathsForPrint, ',', ' ')
            logFilePathsForPrint = string.replace(logFilePathsForPrint, "'", "")
            self.logInfo("Would call shell script transformGivenLogfiles.sh %s %s" %
                         (csvDestDir,logFilePathsForPrint))
                        #(csvDestDir, map(os.path.basename, logFilePaths)))
            self.logInfo('Would be done transforming %d newly downloaded tracklog file(s)...' % len(fileList))
        else:
            self.logInfo('Starting to transform %d tracklog files...' % len(fileList))
            self.logDebug('Calling Bash with %s' % shellCommand)
            subprocess.call(shellCommand)
            self.logInfo('Done transforming %d newly downloaded tracklog file(s)...' % len(fileList))

    def load(self, mysqlPWD=None, sqlFilesToLoad=None, csvDir=None, dryRun=False):
        '''
        Given a directory that contains .sql files, or an array of full-path .sql
        files, load them into mysql. The main work is done by the shell script
        executeCSVLoad.sh. See comments in that script for more information.  
        This executeCSVLoad.sh script needs to use the MySQL db as
        root. As documented in executeCSVLoad.sh, there are multiple ways
        to accomplish this. In this method we use one of two such methods.
        If mysqlPWD is provided, it must be the MySQL localhost root pwd.
        It is passed to executeCSVLoad.sh via the -w switch.
        
        If mysqlPWD is not provided, this method invokes executeCSVLoad.sh
        with the -u option, passing MYSQL_ROOT_USER as the uid. The executeCSVLoad.sh
        script examines that user's HOME/.ssh directory to find a file mysql_root.
        That file, if found is expected to contain the MySQL root pwd. If that file
        is not found, executeCSVLoad.sh will attempt to access MySQL as root without
        a password.
        
        In addition, the executeCSVLoad.sh must run as sudo, which means that
        this script must also run as sudo.
         
        @param mysqlPWD: Root password for MySQL db. (See usage info in file header for how pwd can be provided)
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
        
        self.logDebug("Method load() called with sqlFilesToLoad='%s'; csvDir='%s'" % (sqlFilesToLoad,csvDir))
        
        if getpass.getuser() != 'root':
            if dryRun:
                self.logInfo("Would reject call b/c caller is not sudo; continuing because this is a dry run.")
            else:
                self.logErr(("The load() method must run as root; instead it was run as %s." % getpass.getuser()))
                return None
        if csvDir is None:
            csvDir = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'tracking/CSV')
        if sqlFilesToLoad is None:
            sqlFilesToLoad = self.identifySQLToLoad(csvDir=csvDir)
        if len(sqlFilesToLoad) == 0:
            return
        logDestDir = TrackLogPuller.LOAD_LOG_DIR
        # Ensure that the log directory exists:
        try:
            os.makedirs(logDestDir)
        except OSError:
            pass
        
        # Directory of this script:
        currDir = os.path.dirname(__file__)
        loadScriptPath = os.path.join(currDir, 'executeCSVLoad.sh')
        
        # Now SQL files are guaranteed to be a list. Load them all using
        # a bash script, which will also run the index:
        if mysqlPWD is None:
            shellCommand = [loadScriptPath, '-u', TrackLogPuller.MYSQL_ROOT_USER, logDestDir]
        else:
            shellCommand = [loadScriptPath, '-w', mysqlPWD, logDestDir]
        shellCommand.extend(sqlFilesToLoad)
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

    def isGzippedFile(self, filename):
        return filename.endswith('.gz')
    

if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog=os.path.basename(sys.argv[0]), formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-l', '--errLogFile', 
                        help='fully qualified log file name to which info and error messages \n' +\
                             'are directed. Default: stdout.',
                        dest='errLogFile',
                        default=None);
    parser.add_argument('-d', '--dryRun', 
                        help='show what script would do if run normally; no actual downloads \nor other changes are performed.', 
                        action='store_true');
    parser.add_argument('-v', '--verbose', 
                        help='print operational info to log.', 
                        dest='verbose',
                        action='store_true');
    parser.add_argument('--logsDest',
                        action='append',
                        help='For pull: root destination of downloaded OpenEdX tracking log .json files;\n' +\
                             '    default LOCAL_LOG_STORE_ROOT (on this machine:\n' +\
                             '    %s' % TrackLogPuller.LOCAL_LOG_STORE_ROOT +\
                             ').\n')
    parser.add_argument('--logsSrc',
                        action='append',
                        help='For transform: quoted string of comma or space separated \n'+\
                             '    individual OpenEdX tracking log files to be tranformed, \n' +\
                             '    and/or directories that contain such tracking log files; \n' +\
                             '    default: all files LOCAL_LOG_STORE_ROOT/app*/*.gz that have \n' +\
                             '    not yet been transformed (on this machine:\n' + \
                             '    %s).' % os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'tracking/app*/*.gz')
                             )
    parser.add_argument('--sqlDest',
                        action='append',
                        help='For transform: destination directory of where the .sql and \n' +\
                             '    .csv files of the transformed OpenEdX tracking files go;\n' +\
                             '    default LOCAL_LOG_STORE_ROOT/tracking/CSV (on this machine: \n' +\
                             '    %s' % os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'tracking/CSV')  +\
                             ').\n')
    parser.add_argument('--sqlSrc',
                        action='append',
                        help='For load: directory of .sql/.csv files to be loaded, or list of .sql files;\n' +\
                             '    default LOCAL_LOG_STORE_ROOT/tracking/CSV (on this machine:\n' +\
                             '    %s.' % os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'tracking/CSV') +\
                             ')'
                             )
    parser.add_argument('-u', '--user',
                        action='append',
                        help='For load: user ID whose HOME/.ssh/mysql_root contains the localhost MySQL root password.')
    parser.add_argument('-p', '--password',
                        action='store_true',
                        help='For load: request to be asked for pwd for operating MySQL;\n' +\
                             '    default: content of %s/.ssh/mysql_root if --user is unspecified,\n' % os.getenv('HOME') +\
                             '    or content of <homeOfUser>/.ssh/mysql_root where\n' +\
                             '    <homeOfUser> is the home directory of the user specified in the --user option.' 
                             )
    parser.add_argument('toDo',
                        help='What to do: {pull | transform | load | pullTransform | pullTransformLoad}'
                        ) 
    
    args = parser.parse_args();

    if args.toDo != 'pull' and\
       args.toDo != 'transform' and\
       args.toDo != 'load' and\
       args.toDo != 'pullTransform' and\
       args.toDo != 'pullTransformLoad':
        print("Main argument must be one of pull, transform load, pullTransform, and pullTransformAndLoad")
        sys.exit(1)

    # Log file:
    if args.errLogFile is None:
        args.errLogFile = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'NonTransformLogs/manageDb_%s_%s.log' % (args.toDo, str(datetime.datetime.now()).replace(' ', 'T',).replace(':','_')))

    try:
        os.makedirs(os.path.dirname(args.errLogFile))
    except OSError:
        # File already in place:
        pass
    
#************
#    print('dryRun: %s' % args.dryRun)
#    print('errLogFile: %s' % args.errLogFile)
#    print('verbose: %s' % args.verbose)
#    print('logsDest: %s' % args.logsDest)
#    print('logsSrc: %s' % args.logsSrc)    
#    print('sqlDest: %s' % args.sqlDest)
#    print('sqlSrc: %s' % args.sqlSrc)
#    print('MySQL uid: %s' % args.user)
#    print('MySQL pwd: %s' % args.password)
#    print('toDo: %s' % args.toDo)
#************
#    sys.exit(0)
    
    if args.verbose:
        puller = TrackLogPuller(logFile=args.errLogFile, loggingLevel=logging.DEBUG)
    else:
        puller = TrackLogPuller(logFile=args.errLogFile)

    # For certain operations, either LOCAL_LOG_STORE_ROOT or
    # relevant options must be defined. Check for that to 
    # prevent grief later:
    if (TrackLogPuller.LOCAL_LOG_STORE_ROOT is None) and \
        ((args.toDo == 'pull') or (args.toDo == 'pullTransform') or (args.toDo == 'pullTransformLoad')) and \
         (args.sqlDest is None):
        puller.logErr("For 'pull' operation must either define LOCAL_LOG_STORE_ROOT or use command line option '--sqlDest")             
        sys.exit(1)
    if (TrackLogPuller.LOCAL_LOG_STORE_ROOT is None) and \
        ((args.toDo == 'transform') or (args.toDo == 'pullTransform') or (args.toDo == 'pullTransformLoad')) and \
        (args.logsSrc is None):
        puller.logErr("For 'transform' operation must either define LOCAL_LOG_STORE_ROOT or use command line option '--logsSrc")             
        sys.exit(1)
    if (TrackLogPuller.LOCAL_LOG_STORE_ROOT is None) and \
        ((args.toDo == 'load') or (args.toDo == 'pullTransformLoad')) and \
        (args.sqlSrc is None):
        puller.logErr("For 'load' operation must either define LOCAL_LOG_STORE_ROOT or use command line option '--sqlSrc")             
        sys.exit(1)
    
    if args.user is None:
        if TrackLogPuller.MYSQL_ROOT_USER is None: 
            puller.user = getpass.getuser()
        else:
            puller.user = TrackLogPuller.MYSQL_ROOT_USER
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
                with open(os.path.join(userHomeDir, '.ssh/mysql_root')) as fd:
                    puller.pwd = fd.readline().strip()
            except IOError:
                # No .ssh subdir of user's home, or no mysql inside .ssh:
                puller.pwd = None
    #**********************
    # For testing different sections:
    #print('User: ' + str(puller.user))
    #print('PWD: ' + str(puller.pwd))
    #sys.exit()
    #
    #print(puller.identifyNewLogFiles("/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingSep20_To_Dec5_2013"))
    #print(puller.identifyNewLogFiles("/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingSep20_To_Dec5_2013"))
    #print(puller.identifyNewLogFiles())
    #sys.exit()
    #
    #puller.identifySQLToLoad()
    #sys.exit()
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
    #
    #puller.load()
    #sys.exit()
    #**********************
    
    if args.toDo == 'pull' or args.toDo == 'pullTransform' or args.toDo == 'pullTransformLoad':
        # For pull cmd, 'logs' must be a writable directory (to which the track logs will be written). 
        # It will come in as a singleton array:
        if (args.logsDest is not None and not os.access(args.logsDest[0], os.W_OK)) or (args.logsDest is not None and len(args.logsDest)) > 1: 
            puller.logErr("For pulling track log files from S3, the 'logs' parameter must either not be present, or it must be one *writable* directory (where files will be deposited).")
            sys.exit(1)
        receivedFiles = puller.pullNewFiles(destDir=args.logsDest, dryRun=args.dryRun)
    
    if args.toDo == 'transform' or args.toDo == 'pullTransform' or args.toDo == 'pullTransformLoad':
        # For transform cmd, logs will be defaulted, or be a space-or-comma-separated string of log files/directories:
        # Check for, and point out all errors, rather than quitting after one:
        if args.logsSrc is not None:
            # args.logsSrc comes as a one-element list; pull that element out:
            logsLocs = args.logsSrc[0]
            # On the commandline the --logs option will have a string
            # of either comma- or space-separated directories and/or files.
            # Get a Python list from that:
            logFilesOrDirs = re.split('[\s,]', logsLocs)
            # Remove empty strings that come from use of commas *and* spaces in
            # the cmd line option:
            logFilesOrDirs = [logLoc for logLoc in logFilesOrDirs if len(logLoc) > 0]
            
            # If some of the srcFiles arguments are directories, replace those with arrays
            # of .gz files in those directories; for files in the argument, ensure they
            # exist: 
            allLogFiles = []
            for fileOrDir in logFilesOrDirs:
                # Whether file or directory: either must be readable:
                if not os.access(fileOrDir, os.R_OK):
                    puller.logErr("Tracking log file or directory '%s' not readable or non-existent; ignored." % fileOrDir)
                    continue
                if os.path.isdir(fileOrDir):
                    # For directories in the args, ensure that
                    # each gzipped file within is readable:
                    dirFiles = filter(puller.isGzippedFile, os.listdir(fileOrDir))
                    for dirFile in dirFiles:
                        if not os.access(os.path.join(fileOrDir,dirFile), os.R_OK):
                            puller.logErr("Tracking log file '%s' not readable or non-existent; ignored." % os.path.join(fileOrDir, dirFile))
                            continue
                        allLogFiles.append(os.path.join(fileOrDir,dirFile))
                else: # arg not a directory:
                    if puller.isGzippedFile(fileOrDir):
                        allLogFiles.append(fileOrDir)
        else:
            allLogFiles = None
                        
        # args.sqlDest must be a singleton directory:
        # sanity checks:
        if (args.sqlDest is not None and len(args.sqlDest) > 1) or \
            (args.sqlDest is not None and not os.path.isdir(args.sqlDest[0])) or \
            (args.sqlDest is not None and not os.access(args.sqlDest[0], os.W_OK)):
            puller.logErr("For transform command the 'sqlDest' parameter must be a single directory where result .sql files are written.")
            sys.exit(1)
        elif args.sqlDest is not None:
            args.sqlDest = args.sqlDest[0]
        puller.transform(logFilePaths=allLogFiles, csvDestDir=args.sqlDest, dryRun=args.dryRun)
    
    if args.toDo == 'load' or args.toDo == 'pullTransformLoad':
        # For loading, args.sqlSrc must be None, or a readable directory, or a sequence of readable .sql files.
        if args.sqlSrc is not None:
            if os.path.isdir(args.sqlSrc[0]) and len(args.sqlSrc) > 1: 
                puller.logErr("For load the 'sqlSrc' parameter must either be a single directory, or a list of files.")
                sys.exit(1)
            # All files must exist:
            trueFalseList = map(os.path.exists, args.sqlSrc)
            ok = True
            for i in range(len(trueFalseList)):
                if not trueFalseList[i]:
                    puller.logErr("File % does not exist." % args.sqlSrc[i])
                    ok = False
                if not os.access(args.sqlSrc[i], os.R_OK):
                    puller.logErr("File % exists, but is not readable." % args.sqlSrc[i])
                    ok = False
            if not ok:
                puller.logErr("Command aborted, no action was taken.")
                sys.exit(1)
        # For DB ops need DB root pwd, which was 
        # put into puller.pwd above by various means:
        puller.load(mysqlPWD=puller.pwd, sqlFilesToLoad=args.sqlSrc, dryRun=args.dryRun)
    
    
    sys.exit(0)
    #puller.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app10', tracklogRoot)
    #puller.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app11', tracklogRoot)
    #puller.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app20', tracklogRoot)
    #puller.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app21', tracklogRoot)

    #puller.runTransforms(newLogs, '~/tmp', dryRun=True)
