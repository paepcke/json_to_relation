#!/usr/bin/env python

'''
Created on Nov 9, 2013

Modifications:
  - Dec 27, 2013: Added pullLimit to the pull command.
  - Dec 28, 2013: Removed requirement to run load as Linux root.
  - Dec 28, 2013: Changed argparse 'append' to 'store', simplifying
                  subsequent code.
-   Dec 28, 2013: Fixed parsing of sqlSrc option

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
  toDo                  What to do: {pull | transform | load | pullTransform | transformLoad | pullTransformLoad}

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
  --pullLimit PULLLIMIT
                        For load: maximum number of new OpenEdx tracking log files to pull from AmazonS3
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
@author: paepcke

Modifications:
    Jan 4, 20914: stopped using MD5 for comparing remote and local files, b/c 
                  S3 uses a non-standard MD5 computation for files > 5GB

'''

import argparse
import copy
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
#import boto.connection 

# Add json_to_relation source dir to $PATH
# for duration of this execution:
source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir

from pymysql_utils.pymysql_utils import MySQLDB

# Error info only available after 
# exceptions. Else undefined. Set
# to None to make Eclipse happy:
sys.last_value = None

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
    
    # Directory into which the executeCSVLoad.sh script that is invoked
    # from the load() method will put its log entries.
    LOAD_LOG_DIR = ''
    
    # The following commented pattern only covered 
    # log file names from before someone suddenly 
    # changed the file name format. The pattern below
    # covers both:
    # TRACKING_LOG_FILE_NAME_PATTERN = re.compile(r'tracking.log-[0-9]{8}.gz$')
    TRACKING_LOG_FILE_NAME_PATTERN = re.compile(r'tracking.log-[0-9]{8}[-0-9]*.gz$')
    
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
        
    def identifyNewLogFiles(self, localTrackingLogFileRoot=None, pullLimit=None):
        '''
        Logs into S3, and retrieves list of all OpenEdx tracking log files there.
        Identifies the remote files that do not exist on the local file system,
        and returns an array of remote S3 key names for those new log files.
        
        Example return:
          ['tracking/app10/tracking.log-20130609.gz', 'tracking/app10/tracking.log-20130610.gz']
        
        When a local file of the same name as the a remote file is found, the
        remote and local sizes are compared to ensure that they are indeed
        the same files.
        
        @param localTrackingLogFileRoot: root of subtree that matches the subtree received from
               S3. Two examples for S3 subtrees in Stanford's installation are: 
               tracking/app10/foo.gz and tracking/app21/bar.gz. The localTrackingLogFileRoot
               must in that case contain the subtree 'tracking/appNN/yyy.gz'. If None, then
               class variable TrackLogPuller.LOCAL_LOG_STORE_ROOT is used.
        @type localTrackingLogFileRoot: String
        @param pullLimit: maximum number of tracking log files returned by 
               this method that the caller wishes to download. If None then
               caller wants to know about all tracking log files that are on
               S3, but not local. The caller specifying this limit saves this
               method some MD5 checking, though that operation is fast.
        @type pullLimit: int
        @return: array of Amazon S3 log file key names that have not been downloaded yet. Array may be empty. 
                 locations include the application server directory above each file. Ex.: 'app10/tracking.log-20130623.gz'
        @rtype: [String]
        @raise: IOError if connection to S3 cannot be established.
        '''

        self.logDebug("Method identifyNewLogFiles() called with localTrackingLogFileRoot='%s' and pullLimit=%s" % 
                      (localTrackingLogFileRoot, str(pullLimit)))
        
        rfileObjsToGet = []
        if localTrackingLogFileRoot is None:
            localTrackingLogFileRoot = TrackLogPuller.LOCAL_LOG_STORE_ROOT
        
        # Get remote track log file key objects:
        if self.tracking_log_bucket is None:            
            # No connection has been established yet to S3:
            self.logInfo("Establishing connection to Amazon S3")
            if not self.openS3Connection():
                try:
                    self.logErr("Could not connect to Amazon 3S: %s" % sys.last_value)
                except AttributeError:
                    # The last_value wasn't initialized yet:
                    sys.last_value = ""
                raise IOError("Could not connect to Amazon S3 to examine existing tracking log file list.")
        rLogFileKeyObjs = self.tracking_log_bucket.list()
        if rLogFileKeyObjs is None:
            return rfileObjsToGet
        
        # This logInfo call runs the same loop
        # as the subsequent 'for' loop, just to
        # get the number of files to examine. But
        # who cares:
        self.logInfo("Examining %d remote tracking log files." % self.getNumOfRemoteTrackingLogFiles())
        for rlogFileKeyObj in rLogFileKeyObjs:
            # Get paths like:
            #   tracking/app10/tracking.log-20130609.gzq
            #   tracking/app10/tracking.log-20130610-errors
            rLogPath = str(rlogFileKeyObj.name)
            # If this isn't a tracking log file, skip:
            if TrackLogPuller.TRACKING_LOG_FILE_NAME_PATTERN.search(rLogPath) is None:
                continue
            self.logDebug('Looking at remote track log file %s' % rLogPath)
            localEquivPath = os.path.join(localTrackingLogFileRoot, rLogPath)
            self.logDebug("Check against local path: %s" % localEquivPath)
            if os.path.exists(localEquivPath):
                self.logDebug("Local path: %s does exist; compare lengths of remote & local." % localEquivPath)
                # Ensure that the local file is the same as the remote one, 
                # i.e. that we already copied it over.
                if self.checkFilesEqualSize(rlogFileKeyObj, localEquivPath):
                    self.logDebug("File lengths match; will not pull remote file.")
                    continue
                else:
                    self.logDebug("File MD5s do not match; pull remote file.")
            else:
                self.logDebug("Local path: %s does not exist." % localEquivPath)
            
            rfileObjsToGet.append(rLogPath)
            if pullLimit is not None and len(rfileObjsToGet) >= pullLimit:
                break
            
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
        # name. 
        # Example: for a tracking log file
        #   /home/dataman/.../tracking/app10/tracking.log-20130609.gz
        # the.sql file from a prior transform would look like this: 
        #    tracking.app10.tracking.log-20130609.gz.2013-12-23T13_07_05.081102_11121.sql
        # To determine whether a given tracking log file has already
        # been transformed, we thus find all tracking log files that do not have
        # a .sql file that contains the distinguishing part of the
        # tracking log filename. For the example, we look for a .sql
        # file name that contains 'app10.tracking.log-20130609.gz'. If
        # none is found the respective tracking file is yet to be
        # transformed:
        #
        # The ugly conditional below works like this:logFilePath.split('/')
        # turns /home/dataman/.../tracking/app10/tracking.log-20130609.gz
        # into .home.dataman....tracking.app10.tracking.log-20130609.gz
        # The [-1] and [-2] pick out 'app10' and 'tracking.log-20130609.gz'
        # from the resulting list.
        # These two are combined into app10.tracking.log-20130609.gz. 
        # The find() looks for 'app10.tracking.log-20130609.gz' in 
        # each sqlFilePath. If none is found, the respective tracking
        # log file is yet to be transformed. This ugly expression
        # can surely be prettified, but I need to move on.
        # 
        # I'm trying out the pythonic use of list comprehensions.
        # I'm not convinced that this syntax is more clear than
        # using a more verbose, standard approach. You be the judge: 
        
        alreadyTransformedList = [logFilePath 
                                  for sqlFilePath in allTransformSQLFiles  # go through all transform output file names 
                                  for logFilePath in localTrackingLogFilePaths # go through each .json file path
                                  if sqlFilePath.find( logFilePath.split('/')[-2] + '.' + logFilePath.split('/')[-1] ) > -1
                                  ]
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
            mysqldb = MySQLDB(user=self.user, passwd=self.pwd, db='Edx')
        else:
            mysqldb = MySQLDB(user=self.user, db='Edx')
        loadedJSONFiles = []
        try:
            for jsonFileName in mysqldb.query("SELECT load_file FROM LoadInfo"):
                # jsonFileName is a one-tuple, like: ('/foo/bar.gz',); Get the str itself:
                loadedJSONFiles.append(jsonFileName[0])
        except Exception as e:
            self.logErr("Failed to inspect LoadInfo table for previously loaded materials: %s" % `e`)
            return []
        finally: 
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
            # Make each file name into an absolute path, using that pythonic,
            # but kind of hard to read list comprehension mechanism:
            allTransformSQLFiles = [os.path.join(csvDir,sqlBaseName) for sqlBaseName in allTransformSQLFiles]
            return allTransformSQLFiles 
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
         

    def pullNewFiles(self, localTrackingLogFileRoot=None, destDir=None, pullLimit=None, dryRun=False):
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
        @param pullLimit: a positive integer N; only a maximum of N new OpenEdX tracking log files will
                      be pulled from Amazon S3. None: all new files are pulled.
        @type pullLimit: int
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
        rfileNamesToPull = self.identifyNewLogFiles(localTrackingLogFileRoot, pullLimit=pullLimit)
        if len(rfileNamesToPull) == 0:
            self.logInfo("No openEdx files to pull.")
        else:
            if pullLimit is not None and pullLimit > -1:
                #numToPull = len(rfileNamesToPull)
                rfileNamesToPull = rfileNamesToPull[0:pullLimit]
                #self.logDebug('Limiting tracking logs to pull from %d to %d' % (numToPull, len(rfileNamesToPull)))
            else:
                self.logDebug('No pullLimit specified; will pull all %d new tracking log files.' % len(rfileNamesToPull))
            
        for rfileNameToPull in rfileNamesToPull:
            localDest = os.path.join(destDir, rfileNameToPull)
            if dryRun:
                self.logInfo("Would download file %s from S3" % rfileNameToPull)
            else:
                if self.tracking_log_bucket is None:
                    self.logInfo("Establishing connection to Amazon S3")
                    # No connection has been established yet to S3:
                    if not self.openS3Connection():
                        try:
                            self.logErr("Could not connect to Amazon 3S: %s" % sys.last_value)
                        except AttributeError:
                            # The last_value wasn't initialized yet:
                            sys.last_value = ""
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
                except OSError as e:
                    #self.logErr('Error while trying to write track log file to local (%s): %s' % (localDest, `e`))
                    # Dir already exists; fine
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
        
        self.logDebug("Method transform() called with logFilePaths='%s'; csvDestDir='%s'" % (logFilePaths,csvDestDir))

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

        # Place where each invocation of the underlying json2sql.py
        # will write a log file for its transform process (json2sql.py
        # is called by transformGivenLogfiles.sh, which we invoked
        # below. This level of abstraction shouldn't know what those
        # underlying scripts do, but we need to tell user of 
        # manageEdxDb where the logs are, and json2sql.py is called
        # many times in parallel; so we compromise:
        logDir = os.path.join(csvDestDir, '..') + '/TransformLogs'
        print('Transform logs will be in %s' % logDir)
        
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

    def load(self, mysqlPWD=None, sqlFilesToLoad=None, logDir=None, csvDir=None, dryRun=False):
        '''
        Given a directory that contains .sql files, or an array of full-path .sql
        files, load them into mysql. The main work is done by the shell script
        executeCSVLoad.sh. See comments in that script for more information.  
        This executeCSVLoad.sh script needs to use the MySQL db as
        root. As documented in executeCSVLoad.sh, there are multiple ways
        to accomplish this. In this method we use one of two such methods.
        If mysqlPWD is provided, it must be the MySQL localhost root pwd.
        It is passed to executeCSVLoad.sh via the -w switch.
        
        If mysqlPWD is not provided, then the executeCSVLoad.sh script, which
        this method invokes examines the current user's HOME/.ssh directory 
        to find a file mysql_root. That file, if found is expected to contain 
        the MySQL root pwd. If that file is not found, executeCSVLoad.sh will 
        attempt to access MySQL as root without a password.
        
        @param mysqlPWD: Root password for MySQL db. (See usage info in file header for how pwd can be provided)
        @type mysqlPWD: String
        @param sqlFilesToLoad: list of .sql files that were created by transforms to load
                        If None, calls identifySQLToLoad() to select files that have
                        not previously been loaded. Keeping this to None is recommended
                        to ensure that log files don't get loaded multiple times.
        @type sqlFilesToLoad: String
        @param logDir: directory for file loadLog.log where this method directs logging.
        @type logDir: String
        @param csvDir: directory where transforms have deposited their .sql and associated .csv files.
                       If None, assumes LOCAL_LOG_STORE_ROOT/'tracking/CSV'. Not used if
                       sqlFilesToLoad are specified explicitly.
        @type csvDir: String
        @param dryRun: if True, only log what *would* be done. Cause no actual changes.
        @type dryRun: Bool
        '''
        
        self.logDebug("Method load() called with sqlFilesToLoad='%s'; logDir=%s, csvDir='%s'" % (sqlFilesToLoad, logDir,csvDir))
        
        if csvDir is None:
            csvDir = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'tracking/CSV')
        if sqlFilesToLoad is None:
            sqlFilesToLoad = self.identifySQLToLoad(csvDir=csvDir)
        if len(sqlFilesToLoad) == 0:
            self.logInfo('Load process: all transformed files were already loaded earlier') 
            return
        if logDir is None:
            logDir = TrackLogPuller.LOAD_LOG_DIR
        # Ensure that the log directory exists:
        try:
            os.makedirs(logDir)
        except OSError:
            pass
        
        # Directory of this script:
        currDir = os.path.dirname(__file__)
        loadScriptPath = os.path.join(currDir, 'executeCSVLoad.sh')
        
        # Now SQL files are guaranteed to be a list. Load them all using
        # a bash script, which will also run the index:
        
        # Build the Bash command for calling executeCSVLoad.sh;
        # build a 'shadow' command for reporting to the log, such
        # that pwd does not show up in the log:
        if mysqlPWD is None:
            shellCommand = [loadScriptPath, logDir]
            shadowCmd = copy.copy(shellCommand)
        else:
            shellCommand = [loadScriptPath, '-w', mysqlPWD, logDir]
            shadowCmd = [loadScriptPath, '-w', '*******', logDir]
        shellCommand.extend(sqlFilesToLoad)
        shadowCmd.extend(sqlFilesToLoad)
        if dryRun:
            self.logInfo("Would now invoke bash command %s" % shadowCmd)
        else:
            self.logInfo('Starting to load %d transformed files' % len(sqlFilesToLoad))
            self.logDebug('Calling Bash with %s' % shadowCmd)
            subprocess.call(shellCommand)
        
        # Finally, update the pre-computed table that stores
        # all of the course_display_names from EventXtract, and 
        # ActivityGrade, into AllCourseDisplayNames
        makeCourseNameListScriptName = os.path.join(currDir, 'makeCourseNameListTable.sh')
        try:
            subprocess.call([makeCourseNameListScriptName])
        except Exception as e:
            self.logErr('Could not create table of all course_display_list: %s' % `e`)
        
    # ----------------------------------------  Private Methods ----------------------

    def getNumOfRemoteTrackingLogFiles(self):
        '''
        Return current number of tracking log files on S3
        in bucket LOG_BUCKETNAME. Using an s3 command as
        shown in the working method getNumOfRemoteTrackingLogFilesUsingS3Cmd()
        below would be great. But then we'd require S3cmd as a
        dependency. Boto only seems to offer an iterator through
        all of a bucket's keys, without a len() method. So this
        method runs through that iterator, counting. Yikes, but
        not a big deal with the number of files we are working
        with here.
        @return: number of OpenEdX tracking log files in remote S3 bucket.
        @rtype: int
        '''
        count = 0
        rLogFileKeyObjs = self.tracking_log_bucket.list()
        if rLogFileKeyObjs is None:
            return 0
        for rlogFileKeyObj in rLogFileKeyObjs:  # @UnusedVariable
            rLogPath = str(rlogFileKeyObj.name)
            # If this isn't a tracking log file, skip:
            if TrackLogPuller.TRACKING_LOG_FILE_NAME_PATTERN.search(rLogPath) is None:
                continue
            count += 1
        return count
    
    def getNumOfRemoteTrackingLogFilesUsingS3Cmd(self):
        '''
        Return current number of tracking log files on S3
        in bucket LOG_BUCKETNAME. Uses s3cmd's 'ls' commnad::
          s3cmd ls -r s3://<bucketName> | grep .*tracking.*\.gz | wc -l'
        @return: number of OpenEdX tracking log files in remote S3 bucket.
        @rtype: int
        '''
        # Splice multiple pipes together:
        pipe_bucket_ls = subprocess.Popen(['s3cmd','ls','-r','s3://%s'%TrackLogPuller.LOG_BUCKETNAME] , stdout=subprocess.PIPE)
        pipe_grep = subprocess.Popen(['grep', '.*tracking.*\.gz'], stdin=pipe_bucket_ls.stdout, stdout=subprocess.PIPE)
        pipe_wc = subprocess.Popen(['wc', '-l'], stdin=pipe_grep.stdout, stdout=subprocess.PIPE)
        # Get something like: ('414\n', None)
        stdoutAndstderr = pipe_wc.communicate()
        try:
            return int(stdoutAndstderr[0])
        except (ValueError, IndexError):
            self.logErr("In method getNumOfRemoteTrackingLogFiles(): S3 call returned unexpected result: %s", str(stdoutAndstderr))

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
            print('Logging of control flow will go to %s' % logFile)            
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
    
    def checkFilesIdentical(self, s3FileKeyObj, localFilePath):
        '''
        DON'T USE.
        Compares the MD5 of a local file with that of an S3-resident
        remote file for which a Boto file key object is being passed in.
        Unfortunately, this method only works up to files of 5GB.
        Beyond that S3 computes MD5s from file fragments, and then
        combines those MD5s into a new one. So it's useless. Method
        is retained here in case S3 changes.
        @param s3FileKeyObj:
        @type s3FileKeyObj:
        @param localFilePath:
        @type localFilePath:
        '''
        try:
            # Ensure that the local file is the same as the remote one, 
            # i.e. that we already copied it over. The following call
            # returns '<md5> <filename>':
            md5PlusFileName = subprocess.check_output(['md5sum',localFilePath])
            localMD5 = md5PlusFileName.split()[0]
            # The etag property of an S3 key obj contains
            # the remote file's MD5, surrounded by double-quotes:
            remoteMD5 = string.strip(s3FileKeyObj.etag, '"')
            return localMD5 == remoteMD5
        except Exception as e:
            self.logErr("Could not compare remote file %s's MD5 with that of the local equivalent %s: %s" % (s3FileKeyObj.name, localFilePath, `e`))
            return False


    def checkFilesEqualSize(self, s3FileKeyObj, localFilePath):
        '''
        Compares the length of a local file with that of an S3-resident
        remote file for which a Boto file key object is being passed in.
        The remote file size is obtained from the key object's metadata.
        The file is not downloaded.
        @param s3FileKeyObj: Boto file key object that represents the remote file
        @type s3FileKeyObj: Boto Key instance
        @param localFilePath: absolute path to local file whose length is to be compared.
        @type localFilePath: String
        @return: True/False depending on whether file lengths are equal.
        @rtype: Bool
        '''
        try:
            localFileSize = os.path.getsize(localFilePath)
            return localFileSize == s3FileKeyObj.size
        except Exception as e:
            self.logErr("Could not compare sizes of remote file %s and local file %s: %s" % (s3FileKeyObj.name, localFilePath, `e`))
            return False



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
                        action='store',
                        help='For pull: root destination of downloaded OpenEdX tracking log .json files;\n' +\
                             '    default LOCAL_LOG_STORE_ROOT (on this machine:\n' +\
                             '    %s' % TrackLogPuller.LOCAL_LOG_STORE_ROOT +\
                             ').\n')
    parser.add_argument('--logsSrc',
                        action='store',
                        help='For transform: quoted string of comma or space separated \n'+\
                             '    individual OpenEdX tracking log files to be tranformed, \n' +\
                             '    and/or directories that contain such tracking log files; \n' +\
                             '    default: all files LOCAL_LOG_STORE_ROOT/app*/*.gz that have \n' +\
                             '    not yet been transformed (on this machine:\n' + \
                             '    %s).' % os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'tracking/app*/*.gz')
                             )
    parser.add_argument('--sqlDest',
                        action='store',
                        help='For transform: destination directory of where the .sql and \n' +\
                             '    .csv files of the transformed OpenEdX tracking files go;\n' +\
                             '    default LOCAL_LOG_STORE_ROOT/tracking/CSV (on this machine: \n' +\
                             '    %s' % os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'tracking/CSV')  +\
                             ').\n')
    parser.add_argument('--sqlSrc',
                        action='store',
                        help='For load: a string containing a space separated list with full paths to the .sql files to load;\n' +\
                             '    default LOCAL_LOG_STORE_ROOT/tracking/CSV (on this machine:\n' +\
                             '    %s.' % os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'tracking/CSV') +\
                             ')'
                             )
    parser.add_argument('--pullLimit',
                        action='store',
                        help='For load: maximum number of new OpenEdx tracking log files to pull from AmazonS3',
                        type=int
                        )
    parser.add_argument('-u', '--user',
                        action='store',
                        help='For load: User ID that is to log into MySQL. Default: the user who is invoking this script.')
    parser.add_argument('-p', '--password',
                        action='store_true',
                        help='For load: request to be asked for pwd for operating MySQL;\n' +\
                             '    default: content of scriptInvokingUser$Home/.ssh/mysql if --user is unspecified,\n' +\
                             '    or, if specified user is root, then the content of scriptInvokingUser$Home/.ssh/mysql_root.'
                             )
    parser.add_argument('toDo',
                        help='What to do: {pull | transform | load | pullTransform | transformLoad | pullTransformLoad}'
                        ) 
    
    args = parser.parse_args();

    if args.toDo != 'pull' and\
       args.toDo != 'transform' and\
       args.toDo != 'load' and\
       args.toDo != 'pullTransform' and\
       args.toDo != 'transformLoad' and\
       args.toDo != 'pullTransformLoad':
        print("Main argument must be one of pull, transform load, pullTransform, transformLoad, and pullTransformAndLoad")
        sys.exit(1)

    # Log file:
    if args.errLogFile is None:
        # Default error logs go to LOCAL_LOG_STORE_ROOT/NonTransformLogs.
        # (the transform logs go into LOCAL_LOG_STORE_ROOT/tracking/TransformLogs):
        args.errLogFile = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'NonTransformLogs/manageDb_%s_%s.log' % 
                                       (args.toDo, str(datetime.datetime.now()).replace(' ', 'T',).replace(':','_')))

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
#    print('MySQL pullLimit: %s' % args.pullLimit)
#    print('toDo: %s' % args.toDo)
#************
#    sys.exit(0)
    
    if args.verbose:
        tblCreator = TrackLogPuller(logFile=args.errLogFile, loggingLevel=logging.DEBUG)
    else:
        tblCreator = TrackLogPuller(logFile=args.errLogFile)

    # For certain operations, either LOCAL_LOG_STORE_ROOT or
    # relevant options must be defined. Check for that to 
    # prevent grief later:
    if (TrackLogPuller.LOCAL_LOG_STORE_ROOT is None) and \
        ((args.toDo == 'pull') or (args.toDo == 'pullTransform') or (args.toDo == 'pullTransformLoad')) and \
         (args.sqlDest is None):
        tblCreator.logErr("For 'pull' operation must either define LOCAL_LOG_STORE_ROOT or use command line option '--sqlDest")             
        sys.exit(1)
    if (TrackLogPuller.LOCAL_LOG_STORE_ROOT is None) and \
        ((args.toDo == 'transform') or (args.toDo == 'pullTransform') or (args.toDo == 'transformLoad') or (args.toDo == 'pullTransformLoad')) and \
        (args.logsSrc is None):
        tblCreator.logErr("For 'transform' operation must either define LOCAL_LOG_STORE_ROOT or use command line option '--logsSrc")             
        sys.exit(1)
    if (TrackLogPuller.LOCAL_LOG_STORE_ROOT is None) and \
        ((args.toDo == 'load') or (args.toDo == 'transformLoad') or (args.toDo == 'pullTransformLoad')) and \
        (args.sqlSrc is None):
        tblCreator.logErr("For 'load' operation must either define LOCAL_LOG_STORE_ROOT or use command line option '--sqlSrc")             
        sys.exit(1)
    
    if args.user is None:
        tblCreator.user = getpass.getuser()
    else:
        tblCreator.user = args.user
        
    if args.password:
        tblCreator.pwd = getpass.getpass("Enter %s's MySQL password on localhost: " % tblCreator.user)
    else:
        # Try to find pwd in specified user's $HOME/.ssh/mysql
        currUserHomeDir = os.getenv('HOME')
        if currUserHomeDir is None:
            tblCreator.pwd = None
        else:
            # Don't really want the *current* user's homedir,
            # but the one specified in the -u cli arg:
            userHomeDir = os.path.join(os.path.dirname(currUserHomeDir), tblCreator.user)
            try:
                # Need to access MySQL db as its 'root':
                with open(os.path.join(currUserHomeDir, '.ssh/mysql_root')) as fd:
                    tblCreator.pwd = fd.readline().strip()
                # Switch user to 'root' b/c from now on it will need to be root:
                tblCreator.user = 'root'
                
            except IOError:
                # No .ssh subdir of user's home, or no mysql inside .ssh:
                tblCreator.pwd = None

    if args.pullLimit is not None:
        # Make sure that the load limit is
        # a positive int argparse already
        # ensured that it's an int:
        if args.pullLimit < 0:
            args.pullLimit = 0;
        
        
    #**********************
    # For testing different sections:
    #print('User: ' + str(tblCreator.user))
    #print('PWD: ' + str(tblCreator.pwd))
    #sys.exit()
    #
    #print(tblCreator.identifyNewLogFiles("/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingSep20_To_Dec5_2013"))
    #print(tblCreator.identifyNewLogFiles("/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingSep20_To_Dec5_2013"))
    #print(tblCreator.identifyNewLogFiles())
    #sys.exit()
    #
    #tblCreator.identifySQLToLoad()
    #sys.exit()
    #
    #print(tblCreator.pullNewFiles(dryRun=True))
    #sys.exit()
    #
    #print(tblCreator.identifyNotTransformedLogFiles(csvDestDir='/home/paepcke/tmp/CSV'))
    #print(tblCreator.identifyNotTransformedLogFiles('/foo.log')) # should be empty list
    #sys.exit()
    #
    #tblCreator.transform(dryRun=True)
    #tblCreator.transform(csvDestDir='/home/paepcke/tmp/CSV')
    #sys.exit()
    #
    #tblCreator.load()
    #sys.exit()
    #**********************
    
    if args.toDo == 'pull' or args.toDo == 'pullTransform' or args.toDo == 'pullTransformLoad':
        # For pull cmd, 'logs' must be a writable directory (to which the track logs will be written). 
        # It will come in as a singleton array:
        if (args.logsDest is not None and not os.access(args.logsDest, os.W_OK)):
            tblCreator.logErr("For pulling track log files from S3, the 'logs' parameter must either not be present, or it must be one *writable* directory (where files will be deposited).")
            sys.exit(1)
        receivedFiles = tblCreator.pullNewFiles(destDir=args.logsDest, pullLimit=args.pullLimit, dryRun=args.dryRun)
    
    if args.toDo == 'transform' or args.toDo == 'pullTransform' or args.toDo == 'transformLoad' or args.toDo == 'pullTransformLoad':
        # For transform cmd, logs will be defaulted, or be a space-or-comma-separated string of log files/directories:
        # Check for, and point out all errors, rather than quitting after one:
        if args.logsSrc is not None:
            logsLocs = args.logsSrc
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
                    tblCreator.logErr("Tracking log file or directory '%s' not readable or non-existent; ignored." % fileOrDir)
                    continue
                if os.path.isdir(fileOrDir):
                    # For directories in the args, ensure that
                    # each gzipped file within is readable:
                    dirFiles = filter(tblCreator.isGzippedFile, os.listdir(fileOrDir))
                    for dirFile in dirFiles:
                        if not os.access(os.path.join(fileOrDir,dirFile), os.R_OK):
                            tblCreator.logErr("Tracking log file '%s' not readable or non-existent; ignored." % os.path.join(fileOrDir, dirFile))
                            continue
                        allLogFiles.append(os.path.join(fileOrDir,dirFile))
                else: # arg not a directory:
                    if tblCreator.isGzippedFile(fileOrDir):
                        allLogFiles.append(fileOrDir)
        else:
            allLogFiles = None
                        
        # args.sqlDest must be a singleton directory:
        # sanity checks:
        if ((args.sqlDest is not None and not os.path.isdir(args.sqlDest)) or \
            (args.sqlDest is not None and not os.access(args.sqlDest, os.W_OK))):
            tblCreator.logErr("For transform command the 'sqlDest' parameter must be a single directory where result .sql files are written.")
            sys.exit(1)
        tblCreator.transform(logFilePaths=allLogFiles, csvDestDir=args.sqlDest, dryRun=args.dryRun)
    
    if args.toDo == 'load' or args.toDo == 'transformLoad' or args.toDo == 'pullTransformLoad':
        # For loading, args.sqlSrc must be None, or a readable directory, or a sequence of readable .sql files.
        sqlFilesToLoad = None
        if args.sqlSrc is not None:
            # args.sqlSrc must be a string containing
            # one or more .sql file paths: 
            try:
                sqlFilesToLoad = args.sqlSrc.split(' ')
                # Remove any empty strings that result from
                # file names being separated by more than one
                # space:
                sqlFilesToLoad = [oneFile for oneFile in sqlFilesToLoad if len(oneFile) > 0]
            except AttributeError:
                tblCreator.logErr("For load the '--sqlSrc' option value  must be string listing full paths of .sql files to load, separated by spaces.")
                sys.exit(1)
            # All files must exist:
            trueFalseList = map(os.path.exists, sqlFilesToLoad)
            ok = True
            for i in range(len(trueFalseList)):
                if not trueFalseList[i]:
                    tblCreator.logErr("File % does not exist." %  sqlFilesToLoad[i])
                    ok = False
                if not os.access(sqlFilesToLoad[i], os.R_OK):
                    tblCreator.logErr("File % exists, but is not readable." % sqlFilesToLoad[i])
                    ok = False
            if not ok:
                tblCreator.logErr("Command aborted, no action was taken.")
                sys.exit(1)
        # For DB ops need DB root pwd, which was 
        # put into tblCreator.pwd above by various means:
        tblCreator.load(mysqlPWD=tblCreator.pwd, sqlFilesToLoad=sqlFilesToLoad, logDir=os.path.dirname(args.errLogFile), dryRun=args.dryRun)
    
    tblCreator.logInfo('Processing %s done.' % args.toDo)
    sys.exit(0)
    #tblCreator.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app10', tracklogRoot)
    #tblCreator.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app11', tracklogRoot)
    #tblCreator.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app20', tracklogRoot)
    #tblCreator.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app21', tracklogRoot)

    #tblCreator.runTransforms(newLogs, '~/tmp', dryRun=True)
