#!/usr/bin/env python
# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
                            default LOCAL_LOG_STORE_ROOT/CSV.
  --sqlSrc SQLSRC       For load: directory of .sql/.csv files to be loaded, or list of .sql files;
                            default LOCAL_LOG_STORE_ROOT/CSV.
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
                    is thus: /home/dataman/Data/EdX/app10/tracking.log-20130610.gz
@author: paepcke

Modifications:
    Jan 4, 20914: stopped using MD5 for comparing remote and local files, b/c
                  S3 uses a non-standard MD5 computation for files > 5GB

'''

import argparse
import boto
import copy
import datetime
import getpass
import glob
import logging
import os
import re
import socket
import string
import subprocess
import sys
import tempfile
import shutil

from pymysql_utils.pymysql_utils import MySQLDB
from listChunkFeeder import ListChunkFeeder
from fileCollection import collectFiles

#import boto.connection
# Add json_to_relation source dir to $PATH
# for duration of this execution:
source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir


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
    LOCAL_LOG_STORE_ROOT = None
    if hostname == 'duo':
        LOCAL_LOG_STORE_ROOT = "/home/paepcke/Project/VPOL/Data/EdX/tracking/"
    elif hostname == 'mono':
        LOCAL_LOG_STORE_ROOT = "/home/dataman/Data/EdX/tracking"
    elif hostname == 'taffy':
        LOCAL_LOG_STORE_ROOT = "/Users/dataman/Data/EdX/tracking"      
    elif hostname == 'datastage':
        LOCAL_LOG_STORE_ROOT = "/home/dataman/Data/EdX/tracking"
    elif hostname == 'datastage2':
        LOCAL_LOG_STORE_ROOT = "/home/dataman/Data/EdX/tracking"
    elif hostname == 'datastage2go':
        LOCAL_LOG_STORE_ROOT = "/home/dataman/Data/EdX/tracking"
    else:
        LOCAL_LOG_STORE_ROOT = None
    LOG_BUCKETNAME = "stanford-edx-logs"

    # File where lists of already transformed files
    # are stored. This file is removed after a full
    # the transformed files have been loaded:
    TRANSFORMED_LOG_NAME_LIST_FILE = 'transformedFileList.txt'

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

        if TrackLogPuller.LOCAL_LOG_STORE_ROOT is None:
            TrackLogPuller.LOAD_LOG_DIR = os.path.join('/tmp/', 'Logs')
        else:
            TrackLogPuller.LOAD_LOG_DIR = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'Logs')
        self.logger = None
        self.setupLogging(loggingLevel, logFile)
        
        # No connection yet to S3. That only
        # gets established when needed:
        self.tracking_log_bucket = None
        
        # Set of already loaded .gz JSON files not
        # yet retrieved from the database:
        self.loaded_file_set = None

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
                    # sys.last_value is only defined when errors occur
                    # To get Eclipse to shut up about var undefined, use
                    # decorator:
                    self.logErr("Could not connect to Amazon 3S: %s" % sys.last_value) #@UndefinedVariable
                except AttributeError:
                    # The last_value wasn't initialized yet:
                    sys.last_value = ""
                raise IOError("Could not connect to Amazon S3 to examine existing tracking log file list.")
        rLogFileKeyObjs = self.tracking_log_bucket.list()
        if rLogFileKeyObjs is None:
            return rfileObjsToGet

        done_files_set = self.getExistingLogFileNames(localTrackingLogFileRoot)
        
        # Add files loaded into the db some time ago, whose .gz files
        # are no longer in the file system. Save those names in instance 
        # var in case they are needed by other methods in the workflow:
        
        if self.loaded_file_set is None:
            self.loaded_file_set = self.getAllLoadedFilenames()
        done_files_set  = done_files_set.union(self.loaded_file_set)

        # This logInfo call would run the same loop
        # as the subsequent 'for' loop, just to
        # get the number of files to examine. This 
        # is true even with logDebug() when log level 
        # is above 'debug'. Too expensive for routine logInfo:
        # self.logDebug("Examining %d remote tracking log files." % self.getNumOfRemoteTrackingLogFiles())
        
        # Get all names of all available log files on Amazon: 
        for rlogFileKeyObj in rLogFileKeyObjs:
            # Get paths like:
            #   tracking/app10/tracking.log-20130609.gzq
            #   tracking/app10/tracking.log-20130610-errors
            rLogPath = str(rlogFileKeyObj.name)
            # If this isn't a tracking log file, skip:
            if TrackLogPuller.TRACKING_LOG_FILE_NAME_PATTERN.search(rLogPath) is None:
                continue
            self.logDebug('Looking at remote track log file %s' % rLogPath)
            if rLogPath in done_files_set:
                # Already downloaded this file during an earlier download:
                continue

            rfileObjsToGet.append(rLogPath)
            if pullLimit is not None and len(rfileObjsToGet) >= pullLimit:
                break

        return frozenset(rfileObjsToGet)
      
    def getExistingLogFileNames(self, localTrackingLogFileRoot):
        '''
        Return a list of .gz json file names that have been
        pulled from Amazon. The paths will be relative to 
        the given root. Example:
           tracking/app2/foo.gz
        
        Returns a frozenset of the file names.
        
        @param localTrackingLogFileRoot: directory below which all .gz json 
            files are stored.
        @type localTrackingLogFileRoot: str
        @param include_loaded_files: if true, then files aready in the database
            are included. Those may have been pulled, transformed, and loaded
            a long time ago, and local .gz files deleted.
        @rtype: frozenset 
        '''
        # Ensure trailing slash in tracking logs root dir:
        localTrackingLogFileRoot = os.path.join(localTrackingLogFileRoot,'')
        
        # Find all .gz files below the root. They are 
        # all in tracking/app<n>... The old app[1-20] directories
        # have been removed. The sed removes the root: all
        # up to the tracking/app<n>.
        # The slash before || is to chop off the leading
        # slash from the result: we want tracking/app1/tracking/foo.gz,
        # not /tracking/app1/tracking/foo.gz:
        
        # Make sure the log root directory has no trailing slash. We
        # do this by first ensuring that a slash is present, and then
        # taking it away:
        log_root = os.path.join(localTrackingLogFileRoot, '')[:-1]
        
        # Get from full paths to paths relative to the log root:
        #   From /home/dataman/EdX/tracking/tracking/app1/...
        #     to tracking/tracking/app1/...
        cmd = "find %s -name '*.gz' | sed -n 's|%s/\(.*\)$|\\1|p'" %\
                (log_root,log_root)
                
        # The split('\n') is needed b/c check_output returns
        # letter by letter:
                
        file_list = subprocess.check_output(cmd, shell=True).split('\n')                
        
        # Turn list of file names into an immutable
        # set to speed up lookups:
        return frozenset([done_file for done_file in file_list if done_file != None and done_file != ''])

    def identifyNotTransformedLogFiles(self, 
                                       localTrackingLogFilePaths=None, 
                                       csvDestDir=None,
                                       count_loaded_files=True):
        '''
        Messy method: determines which of a set of OpenEdX .json files have not already
        gone through the transform process to relations. Two ways to find out
        whether a given JSON .gz file has been transformed: If a corresponding 
        .sql file is in the CSV directory, and whether a file of that name shows
        in the LoadInfo table. The first method is always used. Whether the second 
        method is used is controlled by the count_loaded_files parameter.   
        
        Looking for .sql files is done by looking at the
        file names in the transform output directory, and matching them to the candidate
        .json files. This process works, because the transform process uses a file name
        convention: given a .json file like <root>/tracking/app10/foo.gz, the .sql file
        that the transform file generates will be named tracking.app10.foo.gz.<more pieces>.sql.
        Like this: tracking.app10.tracking.log-20131128.gz.2013-12-05T00_33_29.900465_5064.sql
        
        @param localTrackingLogFilePaths: list of all .json files to consider for transform.
               If None, uses LOCAL_LOG_STORE_ROOT + '/app*/.../*.gz (equivalent to bash 'find')
        @type localTrackingLogFilePaths: {[String] | None}
        @param csvDestDir: directory where previous transforms have deposited their output files.
        `     If None, uses LOCAL_LOG_STORE_ROOT/CSV
        @type csvDestDir: String
        @param count_loaded_files: look in LoadInfo table and consider files there
            as tranformed?
        @type count_loaded_files: bool
        @returns: array of absolute paths to OpenEdX tracking log files that need to be
                  transformed
        @rtype: [String]
        '''

        self.logDebug("Method identifyNotTransformedLogFiles()  called with localTrackingLogFilePaths='%s'; csvDestDir='%s'" % (localTrackingLogFilePaths,csvDestDir))

        if localTrackingLogFilePaths is None:
            if TrackLogPuller.LOCAL_LOG_STORE_ROOT is None:
                # Note: we check for this condition in main;
                # nonetheless...
                raise ValueError("If localTrackingLogFilePaths is None, then TrackLogPuller.LOCAL_LOG_STORE_ROOT must be set in manageEdxDb.py")
            # Find a list of all .gz JSON files on this machine;
            # those are candidates for having to be transformed:
            localTrackingLogFilePaths = self.getExistingLogFileNames(TrackLogPuller.LOCAL_LOG_STORE_ROOT)
        elif type(localTrackingLogFilePaths) == str:   
            # If tracking file list is a string entered on the command
            # line, then it might include shell wildcards. Expand 
            # that string into a file list:
            try:
                # After expansion, returns a list of files *that exist*:
                localTrackingLogFilePaths = glob.glob(localTrackingLogFilePaths)
            except TypeError:
                # File paths were already a list; keep only ones that exist:
                localTrackingLogFilePaths = filter(os.path.exists, localTrackingLogFilePaths)
            except AttributeError:
                # An empty list makes glob.glob throw
                #    AttributeError: 'list' object has no attribute 'rfind'
                pass

        self.logDebug("number of localTrackingLogFilePaths: '%d'" % len(localTrackingLogFilePaths))
        # If no log files exist at all, don't need to transform anything
        if len(localTrackingLogFilePaths) == 0:
            return []

        # The following takes too long for many files:
#         if len(localTrackingLogFilePaths) > 3:
#             self.logDebug("three examples from localTrackingLogFilePaths: '%s,%s,%s'" % (localTrackingLogFilePaths[0],
#                                                                                    localTrackingLogFilePaths[1],
#                                                                                    localTrackingLogFilePaths[2]))
#         else:
#             self.logDebug("all of localTrackingLogFilePaths: '%s'" % localTrackingLogFilePaths)

        # The following line is commented, b/c it can be a lot of output:
        # self.logDebug("localTrackingLogFilePaths: '%s'" % localTrackingLogFilePaths)

        # Next, gather names of files that have already 
        # been transformed but not been loaded yet:
        # files in the directory for transformed files 
        # (where there are both .sql and .csv files):
        if csvDestDir is None:
            if TrackLogPuller.LOCAL_LOG_STORE_ROOT is None:
                # Note: we check for this condition in main;
                # nonetheless...
                raise ValueError("If csvDestDir is None, then TrackLogPuller.LOCAL_LOG_STORE_ROOT must be set in manageEdxDb.py")
            csvDestDir = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'CSV')

        # Next: find all .sql files among the existing .csv/.sql
        # files from already accomplished transforms:
        allTransformResultFiles = self.getAllFilesByExtension(csvDestDir, 'sql')
        if count_loaded_files:
            if self.loaded_file_set is None:
                self.loaded_file_set = self.getAllLoadedFilenames()
            allTransformResultFiles.union(self.loaded_file_set)
        
        # Now we need to figure out to which .gz file each .sql file
        # corresponds. We do that via the .sql file name convention:
        # The transform module that generates the .sql files prepends
        # the dot-separated components of the source .gz file that
        # lie between the log file root and the file. The module then 
        # appends filename elements to the original tracking log file
        # name.
        # Example: for a tracking log file
        #
        #   /home/dataman/.../tracking/app10/tracking.log-20130609.gz
        #
        # the.sql file from a prior transform would look like this:
        #
        #    tracking.app10.tracking.log-20130609.gz.2013-12-23T13_07_05.081102_11121.sql
        #
        # To determine whether a given tracking log file has already
        # been transformed, we thus find all tracking log files that do not have
        # a .sql file that contains the distinguishing part of the
        # tracking log filename. For the example, we look for a .sql
        # file name that contains 
        #
        #    app10.tracking.-201log30609.gz'
        #
        # If none is found the respective tracking file is yet to be
        # transformed:

        self.logDebug("number of allTransformSQLFiles: '%d'" % len(allTransformResultFiles))
        if len(allTransformResultFiles) > 3:
            self.logDebug("three examples from allTransformSQLFiles: '%s,%s,%s'" % 
                          (tuple(allTransformResultFiles)[0],
                           tuple(allTransformResultFiles)[1],
                           tuple(allTransformResultFiles)[2]))
        else:
            self.logDebug("all of allTransformSQLFiles: '%s'" % allTransformResultFiles)

        # Need to compute set difference between the json files
        # and the .sql files from earlier transforms. Use a
        # hash table with keys of the form:
        #
        #     app2.tracking.log-20140626-1403785021.gz  : 1
        #
        # Then extract from each .json gz file name the
        # portion that makes up the form of those keys.
        # If that key is a hit in the hash table, the
        # respective json gz file was transformed earlier:

        normalizedSQLFiles = {}

        # Extract the pieces from the SQL file names that
        # will be used as keys to the hash table. Due to
        # file directory changes in the platform at some
        # point, we have to deal with two file name formats
        # for the .sql files from previous transforms:
        #   /home/dataman/Data/Edx/tracking/tracking.app2.tracking.tracking.log-20141008-1412767021.gz.2015-03-07T20_18_53.273290_7501.sql
        #   /home/dataman/Data/Edx/tracking/app1.tracking.tracking.log-20140608-1402247821.gz.2014-12-20T11_35_45.608695_10319.sql
        # Unify these to create keys for the table:

        for sqlFile in allTransformResultFiles:
            # Get something like
            #       'tracking.app2.tracking.tracking.log-20141008-1412767021'
            #   or  'app1.tracking.tracking.log-20140608-1402247821'
            gzFilePart = sqlFile.split('.gz')[0]
            # Get this: ['tracking', 'app2', 'tracking', 'tracking', 'log-20141008-1412767021']
            #       or: ['app1', 'tracking', 'tracking', 'log-20140608-1402247821']
            fileComponents = gzFilePart.split('.')

            # Normalize those two types of names into
            #    tracking/appX/log-20140608-1402247821
            # or appX/log-20140608-1402247821
            firstFileEl = fileComponents[0]
            if firstFileEl.startswith('app'):
                fileElementsToKeep = [el for el in fileComponents if el != 'tracking']
            else:
                fileElementsToKeep = ['tracking'] + [el for el in fileComponents if el != 'tracking']

            hashKey = '.'.join(fileElementsToKeep)
            #print(hashKey)
            normalizedSQLFiles[hashKey] = 1

        # If there are transformed files in csvDir, then
        # build the 'to-transform' list using hash table
        # misses to signal to-do files:
        
        if len(normalizedSQLFiles) == 0:
            # No transformed files sitting in the 
            # transform module results directory.
            # Files to transform are whatever we
            # found so far:
            toDo = localTrackingLogFilePaths
        else:
            toDo = []
            for logFile in localTrackingLogFilePaths:
                # logFile is a full path of a .gz tracking log file.
                # Get the normalized file name to see whether the file is
                # in the hash table:
    
                # Chop off the LOCAL_LOG_STORE_ROOT front-end;
                #    so: from '/home/dataman/Data/EdX/tracking/app1/tracking/tracking.log-20141008-1412767021.gz'
                #         get 'app1/tracking/tracking.log-20141008-1412767021.gz'
                # while  from '/home/dataman/Data/EdX/tracking/tracking/app2/tracking/tracking.log-20140408.gz
                #         get 'tracking/app2/tracking/tracking.log-20140408.gz'
                relPath = os.path.relpath(logFile, TrackLogPuller.LOCAL_LOG_STORE_ROOT)
    
                # Chop the '.gz', and replace slashes by dots:
                dottedFilename = relPath.replace('/', '.').split('.gz')[0]
                dottedFilenameComponents = dottedFilename.split('.')
                if dottedFilename.startswith('app'):
                    fileElementsToKeep = [el for el in dottedFilenameComponents if el != 'tracking']
                else:
                    fileElementsToKeep = ['tracking'] + [el for el in dottedFilenameComponents if el != 'tracking']
    
                hashKey = '.'.join(fileElementsToKeep)
                # If hash table contains that key, the transform
                # was done earlier:
                try:
                    normalizedSQLFiles[hashKey]
                except KeyError:
                    toDo.append(logFile)

        self.logDebug("toDo: '%s'" % toDo)
        self.logDebug("number of toDo: '%d'" % len(toDo))
        if len(toDo) > 3:
            self.logDebug("three examples from toDo: '%s,%s,%s'" %  tuple(toDo)[0:3])
        else:
            self.logDebug("all of : '%s'" % toDo)

        return list(toDo)

    def identifySQLToLoad(self, csvDir=None):
        '''
        Returns the absolute paths of .sql files in a given transform
        output directory that need to be loaded into the tracking log
        db. If file TrackLogPuller.TRANSFORMED_LOG_NAME_LIST_FILE
        exists, it is expected to contain a list of file names like these:
        
  				  app1.tracking.tracking.log-20140609-1402348621.gz        
				  tracking.app1.tracking.tracking.log-20150103-1420273021.gz
        
        Corresponding sql files in TrackLogPuller.LOCAL_LOG_STORE_ROOT
        look like these:
        
          app1.tracking.tracking.log-20140609-1402348621.gz.2017-06-12T11_16_47.734532_11850.sql
          tracking.app1.tracking.tracking.log-20150103-1420273021.gz.2017-06-12T11_16_47.734532_11850.sql
          
        I.e. all forward slashes are replaced with periods, and date/id
        tags are added.  
        
        If file TRANSFORMED_LOG_NAME_LIST_FILE does not exist, it is first
        created from the list of loaded files in LoadInfo.
        
        @param csvDir: directory where previous transform runs have deposited
               their .sql and .csv files. If None, LOCAL_LOG_STORE_ROOT/CSV'
               is assumed.
        @type csvDir: String
        @return: possibly empty list of absolute paths to .sql files that have
                 not yet been loaded into the OpenEdX tracking log relational
                 db.
        '''
        self.logDebug("Method identifySQLToLoad()  called with csvDir='%s'" % csvDir)

        if csvDir is None:
            # The following condition is checked in main,
            # ... still:
            if TrackLogPuller.LOCAL_LOG_STORE_ROOT is None:
                raise ValueError("Since TrackLogPuller.LOCAL_LOG_STORE_ROOT is not customized in manageEdxDb.py, you need to specify --csvDest.")
            csvDir = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'CSV')
            
        # If no .sql files are in the csvDir, then
        # nothing needs to/can be loaded:
        if not self.atLeastOneFile(csvDir, 'sql'):
            return frozenset([])
            
        # If file with list of just-transformed files exists,
        # use that:
        list_file = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 
                 TrackLogPuller.TRANSFORMED_LOG_NAME_LIST_FILE)
        if os.access(list_file, os.R_OK):
            with open(list_file, 'r') as fd:
                transformedJSONFiles = frozenset([file_name.strip() for file_name in fd if len(file_name) > 0]) 
        else:
            # Assume that all previously loaded files
            # have been transformed already and don't 
            # need to be redone: 

            # Get content of LoadInfo file names in MySQL db Edx
            # if that wasn't done in an ealier step:
            if self.loaded_file_set is None:
                self.loaded_file_set = self.getAllLoadedFilenames()
            
            transformedJSONFiles = self.loaded_file_set
            
        # All files in the CSV directory are results of
        # prior transforms: 
        all_sql_files = self.getAllFilesByExtension(csvDir, 'sql')
        
        # JSON .gz files to transform are ones that are
        # on this machine minus the ones that were already
        # transformed:
         
        sqlFilesToLoad = all_sql_files - transformedJSONFiles
        return(sqlFilesToLoad)

    def atLeastOneFile(self, the_dir, the_extension):
        '''
        Return True if given directory contains at least
        one file with extension the_extension.
        
        @param the_dir: directory to check
        @type the_dir: string
        @param the_extension: file extension to look for 
        @type the_extension: string
        @return: True if at least one file with given extension found, else False
        @rtype: boolean
        '''
        
        # Unix command: find . -name *.gz -print -quit
        # finds one match, then quits:
        find_cmd = ['find', '%s'%the_dir, '-name', '*.%s'%the_extension, '-print', '-quit']
        res = subprocess.check_output(find_cmd)
        if len(res) == 0:
            return False
        else:
            return True

    def getAllFilesByExtension(self, root_dir, extension):
        '''
        Given a root directory and file extension, return
        a frozenset of all files with that extension, relative
        to the given root.
        
        @param root_dir: directory relative to which to look for files.
        @type root_dir: str
        @param extension: file extension to find
        @type extension: str
        @return: set of file paths
        @rtype: frozenset(str)
        '''
        
        find_cmd = ['find', root_dir, '-name', '*.%s'%extension]
        # Subprocess call returns one big string 
        # with file paths separated by '\n':
        all_files_with_ext = set(subprocess.check_output(find_cmd).split('\n'))
        # There is sometimes an empty str at the end:
        try:
            all_files_with_ext.remove('')
        except KeyError:
            pass
        return(frozenset(all_files_with_ext))
        

    def getAllLoadedFilenames(self):
        '''
        Query the Edx.LoadInfo table for all loaded JSON .gz file
        names. Return a frozenset of the names. The returned names
        will be relative to the load root. For example, the file
        names in LoadInfo look like:
        
           file:///home/dataman/Data/EdX/tracking/tracking/app1/tracking/tracking.log-20150114-1421255821.g
        
        or file:///home/dataman/Data/EdX/tracking/app2/tracking/tracking.log-20140626-1403785021.gz
        
        We only want the part after our root:
        
           tracking/app1/tracking/tracking.log-20150114-1421255821.g
        or app2/tracking/tracking.log-20140626-1403785021.gz
        
        :returns set of file names that have been loaded
        :rtype frozenset
        '''
        # Get content of LoadInfo file names in MySQL db Edx.
        if self.pwd:
            mysqldb = MySQLDB(user=self.user, passwd=self.pwd, db='Edx')
        else:
            mysqldb = MySQLDB(user=self.user, db='Edx')
            
        loadedJSONFiles = []

        # Remove the junk before the load root
        # The '+ 1' chops off the leading '/':

        # Get just the trailing subpath below the root
        query = '''SELECT
                       SUBSTRING(load_file FROM POSITION('EdX/tracking' IN load_file) + LENGTH('EdX/tracking') + 1) AS file_name
                     FROM LoadInfo;
                 '''
        try:
            for jsonFileName in mysqldb.query(query):
                # jsonFileName is a one-tuple, like: ('/foo/bar.gz',); Get the str itself:
                loadedJSONFiles.append(jsonFileName)
        except Exception as e:
            self.logErr("Failed to inspect LoadInfo table for previously loaded materials: %s" % `e`)
            return []
        finally:
            mysqldb.close()

        return frozenset(loadedJSONFiles)      

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
        @return: frozenset of full-path file names that have been downloaded. They have not been transformed and loaded yet.
        @rtype: [String]
        @raise: IOError if connection to S3 cannot be established.
        '''

        self.logDebug("Method pullNewFiles()  called with localTrackingLogFileRoot='%s'; destDir='%s'" % (localTrackingLogFileRoot,destDir))

        if destDir is None:
            destDir=TrackLogPuller.LOCAL_LOG_STORE_ROOT

        if localTrackingLogFileRoot is None:
            localTrackingLogFileRoot = TrackLogPuller.LOCAL_LOG_STORE_ROOT

        # Identify log files at S3 that we have not pulled yet.
        # Returns a frozenset of names like: 'tracking/app<n>/foo.gz':
        rfileNamesToPull = self.identifyNewLogFiles(localTrackingLogFileRoot, pullLimit=pullLimit)
        if len(rfileNamesToPull) == 0:
            self.logInfo("No openEdx files to pull.")
        else:
            if pullLimit is not None and pullLimit > -1:
                #numToPull = len(rfileNamesToPull)
                # Need to convert frozenset to tuple for indexing:
                rfileNamesToPull = tuple(rfileNamesToPull)[0:pullLimit]
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
                            # sys.last_value is only defined when errors occur
                            # To get Eclipse to shut up about var undefined, use
                            # decorator:
                            self.logErr("Could not connect to Amazon 3S: %s" % sys.last_value) #@UndefinedVariable
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
                except OSError:
                    # Dir already exists; fine
                    pass
                fileKey.get_contents_to_filename(localDest)
        if dryRun:
            self.logInfo("Would have pulled %s OpenEdX tracking log files from S3 as per above listings." % str(len(rfileNamesToPull)))
        else:
            self.logInfo("Pulled %s OpenEdX tracking log files from S3" % str(len(rfileNamesToPull)))
        return rfileNamesToPull

    def transform(self, logFilePathsOrDir=None, csvDestDir=None, processOnCluster=False, dryRun=False):
        '''
        Given a list of full-path log files, initiate their transform.
        Uses gnu parallel to use multiple cores if available. One error log file
        is written for each transformed track log file. These error log files
        are written to directory TransformLogs that is a sibling of the given
        csvDestDir. Assumes that script transformGivenLogfiles.sh found by
        subprocess. Just have it in the same dir as this file.
        @param logFilePathsOrDir: list of full-path track log files that are to be transformed,
            or a directory with subdirectories named app<int>, where <int> is some
            integer. All files below the app<int> will be pulled in this case.
            NOTE: this directory option is only available when processOnCluster is True.
            (just laziness).
        @type logFilePathsOrDir: [String]
        @param csvDestDir: full path to dir where sql files will be deposited. If None,
                           SQL files will to into TrackLogPuller.LOCAL_LOG_STORE_ROOT/SQL
        @type csvDestDir: String
        @param: processOnCluster should be set to True if the transforms are to
              use a compute cluster. In that case, logFilePathsOrDir should be
              a directory. If False, transforms will be distributed
              among cores on the local machine via Gnu Parallel, and logFilePathsOrDir
              should be an array of file paths.
        @type: bool
        @param dryRun: if True, only log what *would* be done. Cause no actual changes.
        @type dryRun: Bool
        '''

        self.logDebug("Method transform() called with logFilePathsOrDir='%s'; csvDestDir='%s'" % (logFilePathsOrDir,csvDestDir))

        if TrackLogPuller.LOCAL_LOG_STORE_ROOT is None:
            # Note: we check for this condition in main;
            # nonetheless...
            raise ValueError("If localTrackingLogFilePaths is None, then TrackLogPuller.LOCAL_LOG_STORE_ROOT must be set in manageEdxDb.py")

        if csvDestDir is None:
            if TrackLogPuller.LOCAL_LOG_STORE_ROOT is None:
                # Note: we check for this condition in main;
                # nonetheless...
                raise ValueError("If localTrackingLogFilePaths is None, then TrackLogPuller.LOCAL_LOG_STORE_ROOT must be set in manageEdxDb.py")
            csvDestDir = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'CSV')

        if logFilePathsOrDir is None:
            logFilePathsOrDir = self.identifyNotTransformedLogFiles(csvDestDir=csvDestDir)
        else:
            # We were passed a list of files to transform. Check whether
            # any have been transformed before:
            logFilePathsOrDir = self.identifyNotTransformedLogFiles(localTrackingLogFilePaths=logFilePathsOrDir, csvDestDir=csvDestDir)

        if type(logFilePathsOrDir) == list and len(logFilePathsOrDir) == 0:
            self.logInfo("In transform(): all files were already transformed to %s; or logFilePathsOrDir was passed as an empty list." %
                          csvDestDir)
            return
        # Ensure that the target directory exists:
        try:
            os.makedirs(csvDestDir)
        except OSError:
            # If call failed, all dirs already exist:
            pass

        thisScriptsDir = os.path.dirname(__file__)
        if processOnCluster:
            if not os.path.isdir(logFilePathsOrDir):
                raise ValueError("For use on compute cluster, the logFilePathsOrDir parameter must be a directory with subdirs of the form 'app<int>'")
            shellCommand = [os.path.join(thisScriptsDir, 'transformGivenLogfilesOnCluster.sh'), logFilePathsOrDir, csvDestDir]
        else:
            shellCommand = [os.path.join(thisScriptsDir, 'transformGivenLogfiles.sh'), csvDestDir]
        # Add the logfiles as arguments; if that's a wildcard expression,
        # i.e. string, just append. Else it's assumed to an array of
        # strings that need to be concatted:
        fileList = []
        if not processOnCluster:
            
            # If file list is a shell glob, expand into a file list
            # to show the file names in logs and dryRun output below;
            # the actual command is executed in a shell and does its
            # own glob resolution:
            if isinstance(logFilePathsOrDir, basestring):
                fileList = glob.glob(logFilePathsOrDir)
            else:
                fileList = logFilePathsOrDir

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
#             logFilePathsForPrint = str(fileList).strip('[]')
#             logFilePathsForPrint = string.replace(fileList, ',', ' ')
#             logFilePathsForPrint = string.replace(fileList, "'", "")
            if processOnCluster:
                self.logInfo("Would call shell script transformGivenLogfilesOnCluster.sh %s %s" %
                             (fileList, csvDestDir))
            else:
                self.logInfo("Would call shell script transformGivenLogfiles.sh %s %s..." %
                             (csvDestDir,fileList[0:10]))
                            #(csvDestDir, map(os.path.basename, logFilePathsOrDir)))
            self.logInfo('Would be done transforming %d newly downloaded tracklog file(s)...' % len(fileList))
        else:
            if processOnCluster:
                self.logInfo('Starting to transform tracklog files below directories app<int> in [%s]... ' % fileList[0:10])
            else:
                self.logInfo('Starting to transform %d tracklog files...' % len(fileList))
            # self.logDebug('Calling Bash with %s' % shellCommand)
            # There could be thousands of files to transform.
            # The underlying shell script would complain about
            # too many arguments. So transform 50 at a time
            # First save the shell cmd stub (currently [<scriptName>, csvDir]
            # for re-use during each iteration. The list(<list>)
            # idiom clones:
            
            savedShellCommand = list(shellCommand)
            # Ask the transform shell script to transform
            # chunk_size json files at once (else may get 
            # arglist-to-long error:
            chunk_size = 50
            num_chunks_done = 0
            for files in ListChunkFeeder(fileList, chunk_size):
                self.logInfo('About to transform %s to %s of %s log files...' %\
                             (num_chunks_done*chunk_size,
                              min(num_chunks_done*chunk_size + chunk_size, len(fileList)),
                              len(fileList)
                              )
                             )
                # Get a fresh *copy* of the shell cmd 
                # stub (i.e. of <scriptPath> csvDir):
                shellCommand = list(savedShellCommand)
                # Turn each partial path to a .gz file
                # into a full path:
                files = [os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, oneLogFile) for oneLogFile in files]
                shellCommand.extend(files)
                
                #*************************
                # Production code is the following subprocess
                # call. It uses a shell script to launch multiple
                # .gz transforms at once, using multiple cores.
                # To debug while staying with this process (e.g.
                # in Eclipse), comment the subprocess line,
                # and uncomment up to the "#******"
                #***********
                subprocess.call(shellCommand)
                
#                 from input_source import InURI                
#                 from json_to_relation import JSONToRelation
#                 from edxTrackLogJSONParser import EdXTrackLogJSONParser
#                 from output_disposition import OutputDisposition, OutputFile
#                 
#                 jsonConverter = JSONToRelation(InURI(files[0]),
#                                OutputFile('testTablePrefix', OutputDisposition.OutputFormat.CSV),  #outSQLFile,
#                                mainTableName='EdxTrackEvent',
#     			               logFile='/tmp/logTmp.txt' # logFile
#                         )
#                 jsonConverter.setParser(EdXTrackLogJSONParser(jsonConverter,
#         								  'EdxTrackEvent',
#         			 						  replaceTables=False,
#          			 						  dbName='Edx',
#         			               useDisplayNameCache=True
#         						  ))
#                 
#                 jsonConverter.convert()
                #*************************
                num_chunks_done += 1
            if processOnCluster:
                self.logInfo('Done transforming newly downloaded tracklog file(s) below directories app<int> in [%s]' % logFilePathsOrDir[0:10])
            else:
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
                       If None, assumes LOCAL_LOG_STORE_ROOT/'/CSV'. Not used if
                       sqlFilesToLoad are specified explicitly.
        @type csvDir: String
        @param dryRun: if True, only log what *would* be done. Cause no actual changes.
        @type dryRun: Bool
        '''

        self.logDebug("Method load() called with sqlFilesToLoad='%s'; logDir=%s, csvDir='%s'" % (sqlFilesToLoad, logDir,csvDir))

        if csvDir is None:
            # The following condition is checked in main,
            # ... still:
            if TrackLogPuller.LOCAL_LOG_STORE_ROOT is None:
                raise ValueError("Since TrackLogPuller.LOCAL_LOG_STORE_ROOT is not customized in manageEdxDb.py, you need to specify --csvDest.")
            csvDir = os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'CSV')
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
        loadScriptPath = os.path.join(currDir, 'executeCSVBulkLoad.sh')

        # Now SQL files are guaranteed to be a list of
        # absolute paths to all .sql files to load. We
        # now call a script that extracts all LOAD DATA INFILE
        # statements, and combines them into one operation. If
        # we instead imported all the .sql files separately,
        # indexes would be rebuilt after each one.

        timestamp = datetime.datetime.now().isoformat().replace(':','_')
        tmpFilePrefix = 'batchLoad' + timestamp + '_'
        batchLoadFile = tempfile.NamedTemporaryFile(prefix=tmpFilePrefix, suffix='.sql', delete=False)
        batchMakerScriptPath = os.path.join(currDir, 'createBatchLoadFileForMyISAM.sh')
        scriptCmd = [batchMakerScriptPath] + list(sqlFilesToLoad)
        try:
            subprocess.call(scriptCmd, stdout=batchLoadFile)
        finally:
            batchLoadFileName = batchLoadFile.name
            batchLoadFile.close()
        # Input the single batchLoadFile into MySQL:

        # Build the Bash command for calling executeCSVBulkLoad.sh;
        # build a 'shadow' command for reporting to the log, such
        # that pwd does not show up in the log:
        if mysqlPWD is None:
            shellCommand = [loadScriptPath, logDir]
            shadowCmd = copy.copy(shellCommand)
        else:
            shellCommand = [loadScriptPath, '-w', mysqlPWD, logDir]
            shadowCmd = [loadScriptPath, '-w', '*******', logDir]
        shellCommand.append(batchLoadFileName)
        shadowCmd.append(batchLoadFileName)
        if dryRun:
            self.logInfo("Would now invoke bash command %s" % shadowCmd)
        else:
            self.logInfo('Starting to load %d transformed files' % len(sqlFilesToLoad))
            self.logDebug('Calling Bash with %s' % shadowCmd)
            ret_code = subprocess.call(shellCommand)
            if ret_code == 0:
                # Loaded the files, so remove the record of
                # just-transformed files, and empty the
                # CSV directory:
                try:
                    os.remove(os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT,
                                           TrackLogPuller.TRANSFORMED_LOG_NAME_LIST_FILE))
                except OSError:
                    pass
                if os.path.exists(csvDir):
                    shutil.rmtree(csvDir)
                    os.makedirs(csvDir)

        # Finally, update the pre-computed table that stores
        # all of the course_display_names from EventXtract, and
        # ActivityGrade, into AllCourseDisplayNames
        # NOTE: this is commented b/c we don't need this table any more.
        # The course name filters have taken its place. The makeCourseNamelistTable.sh
        # file was moved to json_to_relation/scripts/Old.
        #makeCourseNameListScriptName = os.path.join(currDir, 'makeCourseNameListTable.sh')
        #try:
        #    subprocess.call([makeCourseNameListScriptName])
        #except Exception as e:
        #    self.logErr('Could not create table of all course_display_list: %s' % `e`)

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
        if not os.path.isfile(filename):
            return False
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
    parser.add_argument('-c', '--onCluster',
                        help='transforms are to be processed on a compute cluster, rather than via Gnu Parallel.',
                        dest='onCluster',
                        action='store_true',
                        default=False);
    parser.add_argument('--logsDest',
                        action='store',
                        help='For pull: root destination of downloaded OpenEdX tracking log .json files;\n' +\
                             '    default LOCAL_LOG_STORE_ROOT (on this machine:\n' +\
                             '    %s' % str(TrackLogPuller.LOCAL_LOG_STORE_ROOT) +\
                             ').\n')
    parser.add_argument('--logsSrc',
                        action='store',
                        help='For transform: quoted string of comma or space separated \n'+\
                             '    individual OpenEdX tracking log files to be tranformed, \n' +\
                             '    and/or directories that contain such tracking log files; \n' +\
                             '    default: all files LOCAL_LOG_STORE_ROOT/app*/*.gz that have \n' +\
                             '    not yet been transformed (on this machine:\n' + \
                             '    %s).' % ('not set' if TrackLogPuller.LOCAL_LOG_STORE_ROOT is None else os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, 'app*/*.gz'))
                             )
    parser.add_argument('--sqlDest',
                        action='store',
                        help='For transform: destination directory of where the .sql and \n' +\
                             '    .csv files of the transformed OpenEdX tracking files go;\n' +\
                             '    default LOCAL_LOG_STORE_ROOT/CSV (on this machine: \n' +\
                             '    %s' % ('not set' if TrackLogPuller.LOCAL_LOG_STORE_ROOT is None else os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, '/CSV'))  +\
                             ').\n')
    parser.add_argument('--sqlSrc',
                        action='store',
                        help='For load: a string containing a space separated list with full paths to the .sql files to load;\n' +\
                             '    one directory instead of files is acceptable. default LOCAL_LOG_STORE_ROOT/CSV (on this machine:\n' +\
                             '    %s.' % ('not set' if TrackLogPuller.LOCAL_LOG_STORE_ROOT is None else os.path.join(TrackLogPuller.LOCAL_LOG_STORE_ROOT, '/CSV')) +\
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
        # (the transform logs go into LOCAL_LOG_STORE_ROOT/TransformLogs):
        if TrackLogPuller.LOCAL_LOG_STORE_ROOT is None:
            args.errLogFile = os.path.join('/tmp/', 'NonTransformLogs/manageDb_%s_%s.log' %
                                           (args.toDo, str(datetime.datetime.now()).replace(' ', 'T',).replace(':','_')))
        else:
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
#    print('onCluster: %s' % args.onCluster)
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

        # If TrackLogPuller.LOCAL_LOG_STORE_ROOT is not set, try
        # to rescue the situation:
        if TrackLogPuller.LOCAL_LOG_STORE_ROOT is None:
            if args.logsSrc is not None:
                TrackLogPuller.LOCAL_LOG_STORE_ROOT = args.logsDest

        receivedFiles = tblCreator.pullNewFiles(destDir=args.logsDest, pullLimit=args.pullLimit, dryRun=args.dryRun)

    # Check whether tracking logs are properly provided, unless
    # computation will happen on a compute cluster. In that case,
    # args.logsSrc must be a directory:
    if args.toDo == 'transform' or args.toDo == 'pullTransform' or args.toDo == 'transformLoad' or args.toDo == 'pullTransformLoad':
        if args.onCluster:
            if not os.path.isdir(args.logsSrc) or not os.access(args.logsSrc, os.R_OK):
                tblCreator.logErr("Tracking log directory '%s' not readable or non-existent" % args.logsSrc)
                sys.exit(1)
            allLogFiles = args.logsSrc
        else:
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
                    if not os.access(fileOrDir, os.R_OK):
                        raise ValueError('Given .gz JSON file %s does not exist or is not readable' % fileOrDir)
                    allLogFiles.extend(collectFiles(fileOrDir, 'gz', skip_non_readable=True))
            else:
                allLogFiles = None

        # args.sqlDest must be a singleton directory:
        # sanity checks:
        if ((args.sqlDest is not None and not os.path.isdir(args.sqlDest)) or \
            (args.sqlDest is not None and not os.access(args.sqlDest, os.W_OK))):
            tblCreator.logErr("For transform command the 'sqlDest' parameter must be a single directory where result .sql files are written.")
            sys.exit(1)

        # If TrackLogPuller.LOCAL_LOG_STORE_ROOT is not set, then
        # make sure that sqlDest was provided by the caller:
        if TrackLogPuller.LOCAL_LOG_STORE_ROOT is None and args.sqlDest is None:
            tblCreator.logErr("You need to provide sqlDest, since TrackLogPuller.LOCAL_LOG_STORE_ROOT in manageEdxDb.py was not customized.")
            sys.exit(1)

        tblCreator.transform(logFilePathsOrDir=allLogFiles, csvDestDir=args.sqlDest, dryRun=args.dryRun, processOnCluster=args.onCluster)

    if args.toDo == 'load' or args.toDo == 'transformLoad' or args.toDo == 'pullTransformLoad':
        # For loading, args.sqlSrc must be None, or a readable directory, or a sequence of readable .sql files.
        sqlFilesToLoad = []
        if args.sqlSrc is not None:
            sqlLocs = args.sqlSrc
            # On the commandline the --sqlSrc option will have a string
            # of either comma- or space-separated directories and/or files.
            # Get a Python list from that:
            sqlFilesOrDirs = re.split('[\s,]', sqlLocs)
            # Remove empty strings that come from use of commas *and* spaces in
            # the cmd line option:
            sqlFilesOrDirs = [sqlLoc for sqlLoc in sqlFilesOrDirs if len(sqlLoc) > 0]

            # If some of the srcFiles arguments are directories, replace those with arrays
            # of .sql files in those directories; for files in the argument, ensure they
            # exist:
            allSqlFiles = []
            for fileOrDir in sqlFilesOrDirs:
                if not os.access(fileOrDir, os.R_OK):
                    raise ValueError('Given sql file %s does not exist or is not readable' % fileOrDir)
                allSqlFiles.extend(collectFiles(fileOrDir, 'sql', skip_non_readable=True))
        else:
            allSqlFiles = None

        # For DB ops need DB root pwd, which was
        # put into tblCreator.pwd above by various means:
        tblCreator.load(mysqlPWD=tblCreator.pwd, sqlFilesToLoad=allSqlFiles, logDir=os.path.dirname(args.errLogFile), dryRun=args.dryRun)

    tblCreator.logInfo('Processing %s done.' % args.toDo)
    sys.exit(0)
    #tblCreator.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app10', tracklogRoot)
    #tblCreator.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app11', tracklogRoot)
    #tblCreator.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app20', tracklogRoot)
    #tblCreator.createHistory('/home/paepcke/Project/VPOL/Data/EdX/EdXTrackingLogsSep20_2013/tracking/app21', tracklogRoot)

    #tblCreator.runTransforms(newLogs, '~/tmp', dryRun=True)
