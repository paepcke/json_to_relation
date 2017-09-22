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


## Class: ModulestoreExtractor
## Author: Alex Kindel
## Date: 8 February 2016
## Converts modulestore mongo structure to SQL.
##
## On 25 January 2016, Lagunita (OpenEdX @ Stanford) switched from a single modulestore (one Mongo database)
##  to a split modulestore (three Mongo databases). This class provides an interface to explicitly handle
##  either modulestore case.


from collections import namedtuple
import datetime
import logging
import math
import os.path
import re
import sys

import pymongo as mng
from pymysql_utils1 import MySQLDB


#from collections import defaultdict, namedtuple
# Data type for AY_[quarter][year] date ranges
Quarter = namedtuple('Quarter', ['start_date', 'end_date', 'quarter'])

# Class variables for determining internal status of course
SU_ENROLLMENT_DOMAIN = "shib:https://idp.stanford.edu/"
INTERNAL_ORGS = ['ohsx', 'ohs']

TEST_COURSE_NAME_PATTERN = re.compile(r'[Ss]andbox|TESTTEST')
# When courses are created, OpenEdx gives them a run date
# of 2030. Only when they are finalized do they
# get a real run-date. So create a list with valid
# academic years: 2012 up to current year + 5:

VALID_AYS = [ay for ay in range(2012, datetime.datetime.today().year + 6)]

class ModulestoreExtractor(MySQLDB):

    # Max number of collection records 
    # to import before doing a bulk
    # import:
    BULK_INSERT_NUM_ROWS = 10000
    
    # For logging: print how many rows have 
    # been ingested every REPORT_EVERY_N_ROWS 
    # rows:
    REPORT_EVERY_N_ROWS  = 10000
    
    def __init__(self, split=True, old=True, edxproblem=True, courseinfo=True, edxvideo=True, verbose=False):
        '''
        Get interface to modulestore backup.
        Note: This class presumes modulestore was recently loaded to mongod.
        Class also presumes that mongod is running on localhost:27017.
        '''
        
        # FIXME: don't presume modulestore is recently loaded and running
        self.msdb = mng.MongoClient().modulestore

        if verbose:
            self.setupLogging(logging.INFO, logFile=None)
        else:        
            self.setupLogging(logging.WARN, logFile=None)        

        # Need to handle Split and Old modulestore cases
        self.split = split
        self.old = old

        # Switch for updating EdxProblem and CourseInfo separately (useful for testing)
        self.update_EP = edxproblem
        #*****self.update_CI = courseinfo
        self.update_CI = False
        #*****self.update_EV = edxvideo
        self.update_EV = False

        # Initialize MySQL connection from config file
        home = os.path.expanduser('~')
        dbFile = home + "/.ssh/mysql_user"
        if not os.path.isfile(dbFile):
            sys.exit("MySQL user credentials not found: " + dbFile)
        dbuser = None #@UnusedVariable
        dbpass = None #@UnusedVariable
        with open(dbFile, 'r') as f:
            dbuser = f.readline().rstrip()
            dbpass = f.readline().rstrip()
        MySQLDB.__init__(self, db="Edx", user=dbuser, passwd=dbpass)

    def __buildEmptyEdxProblemTable(self):
        '''
        Reset EdxProblem table and rebuild.
        '''
        # Build table drop and table create queries
        dropOldTableQuery = """DROP TABLE IF EXISTS `EdxProblem`;"""
        emptyEdxProblemTableQuery = """
            CREATE TABLE IF NOT EXISTS `EdxProblem` (
              `problem_id` VARCHAR(32) DEFAULT NULL,
              `problem_display_name` VARCHAR(100) DEFAULT NULL,
              `course_display_name` VARCHAR(100) DEFAULT NULL,
              `problem_text` LONGTEXT,
              `date` VARCHAR(50) DEFAULT NULL,
              `weight` DECIMAL DEFAULT NULL,
              `revision` VARCHAR(10) DEFAULT NULL,
              `max_attempts` INT DEFAULT NULL,
              `trackevent_hook` VARCHAR(200) DEFAULT NULL,
              `vertical_uri` VARCHAR(200) DEFAULT NULL,
              `problem_idx` INT DEFAULT NULL,
              `sequential_uri` VARCHAR(200) DEFAULT NULL,
              `vertical_idx` INT DEFAULT NULL,
              `chapter_uri` VARCHAR(200) DEFAULT NULL,
              `sequential_idx` INT DEFAULT NULL,
              `chapter_idx` INT DEFAULT NULL,
              `staff_only` tinyint(4) DEFAULT NULL
            ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
        """

        # Execute table definition queries
        self.execute(dropOldTableQuery)
        self.execute(emptyEdxProblemTableQuery)


    def __buildEmptyEdxVideoTable(self):
        '''
        '''
        dropOldTableQuery = """DROP TABLE IF EXISTS `EdxVideo`;"""
        emptyEdxVideoTableQuery = """
            CREATE TABLE IF NOT EXISTS `EdxVideo` (
                `video_id` VARCHAR(32) DEFAULT NULL,
                `video_display_name` VARCHAR(100) DEFAULT NULL,
                `course_display_name` VARCHAR(100) DEFAULT NULL,
                `video_uri` TEXT DEFAULT NULL,
                `video_code` TEXT DEFAULT NULL,
                `trackevent_hook` VARCHAR(200) DEFAULT NULL,
                `vertical_uri` VARCHAR(200) DEFAULT NULL,
                `video_idx` INT DEFAULT NULL,
                `sequential_uri` VARCHAR(200) DEFAULT NULL,
                `vertical_idx` INT DEFAULT NULL,
                `chapter_uri` VARCHAR(200) DEFAULT NULL,
                `sequential_idx` INT DEFAULT NULL,
                `chapter_idx` INT DEFAULT NULL
            ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
        """

        # Execute table definition queries
        self.execute(dropOldTableQuery)
        self.execute(emptyEdxVideoTableQuery)


    def __buildEmptyCourseInfoTable(self):
        '''
        Reset CourseInfo table and rebuild.
        '''
        # Build table drop and table definition queries
        dropOldTableQuery = """DROP TABLE IF EXISTS `CourseInfo`;"""
        emptyCourseInfoTableQuery = """
            CREATE TABLE IF NOT EXISTS `CourseInfo` (
                `course_display_name` varchar(255) DEFAULT NULL,
                `course_catalog_name` varchar(255) DEFAULT NULL,
                `academic_year` int(11) DEFAULT NULL,
                `quarter` varchar(7) DEFAULT NULL,
                # `num_quarters` int(11) DEFAULT NULL,  # NOTE: num_quarters field deprecated 5 May 2016
                `is_internal` tinyint(4) DEFAULT NULL,
                `enrollment_start` datetime DEFAULT NULL,
                `start_date` datetime DEFAULT NULL,
                `enrollment_end` datetime DEFAULT NULL,
                `end_date` datetime DEFAULT NULL,
                `grade_policy` text DEFAULT NULL,
                `certs_policy` text DEFAULT NULL
            ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
        """

        # Execute table definition queries
        self.execute(dropOldTableQuery)
        self.execute(emptyCourseInfoTableQuery)


    def export(self):
        '''
        Client method builds tables and loads various modulestore cases to MySQL.
        We reload both tables from scratch each time since the tables are relatively small.
        '''
        self.__buildEmptyEdxProblemTable() if self.update_EP else None
        self.__buildEmptyCourseInfoTable() if self.update_CI else None
        self.__buildEmptyEdxVideoTable() if self.update_EV else None

        if self.split and self.update_EP:
            self.logInfo("About to ingest problem defs from new-type modulestore...")
            self.__extractSplitEdxProblem()
            self.logInfo("Done ingesting problem defs from new-type modulestore...")

        if self.split and self.update_CI:
            self.logInfo("About to ingest course defs from new-type modulestore...")
            self.__extractSplitCourseInfo()
            self.logInfo("Done ingesting course defs from new-type modulestore...")

        if self.split and self.update_EV:
            self.logInfo("About to ingest video defs from new-type modulestore...")
            self.__extractSplitEdxVideo()
            self.logInfo("Done ingesting video defs from new-type modulestore...")

        if self.old and self.update_EP:
            self.logInfo("About to ingest problem defs from old-type modulestore...")
            self.__extractOldEdxProblem()
            self.logInfo("Done ingesting problem defs from old-type modulestore...")

        if self.old and self.update_CI:
            self.logInfo("About to ingest course defs from old-type modulestore...")            
            self.__extractOldCourseInfo()
            self.logInfo("Done ingesting course defs from old-type modulestore...")

        if self.old and self.update_EV:
            self.logInfo("About to ingest video defs from old-type modulestore...")
            self.__extractOldEdxVideo()
            self.logInfo("Done ingesting video defs from old-type modulestore...")

    @staticmethod
    def __resolveResourceURI(problem):
        '''
        Extract resource URI as identifier for EdxTrackEvent hook.
        '''
        tag = problem["_id"]["tag"]
        org = problem["_id"]["org"]
        course = problem["_id"]["course"]
        category = problem["_id"]["category"]
        name = problem["_id"]["name"]
        uri = "%s://%s/%s/%s/%s" % (tag, org, course, category, name)
        return uri


    @staticmethod
    def __resolveTimestamp(problem):
        '''
        Convert published_date array from modulestore to python datetime object.
        '''
        # FIXME: This function is 100% wrong, lol
        dtarr = problem['metadata'].get('published_date', False)
        if not dtarr:
            return None
        dtstr = '-'.join(map(str, dtarr[:6]))
        date = datetime.datetime.strptime(dtstr, "%Y-%m-%d-%H-%M-%S")
        return date


    def __resolveCDN(self, module):
        '''
        Extract course display name from old-style modulestore.
        '''
        org = module["_id"]["org"]
        course = module["_id"]["course"]
        definition = self.msdb.modulestore.find({"_id.category": "course",
                                                 "_id.org": org,
                                                 "_id.course": course})
        try:
            name = definition[0]["_id"]["name"]
        except IndexError:
            self.logError('********** Course display name for course %s not found.' % str(course))
            cdn = '<Not found in Modulestore>'
            return cdn

        cdn = "%s/%s/%s" % (org, course, name)
        return cdn


    def __locateModuleInParent(self, resource_uri):
        '''
        Given URI for a vertical, return the URI of the encapsulating sequential
        and an integer for what order in the sequence the vertical occurred.
        '''
        if not resource_uri:
            return None, -2
        try:
            parent_module = self.msdb.modulestore.find({"definition.children": resource_uri}).next()
        except StopIteration:
            # print resource_uri
            return None, -2
        parent_module_uri = self.__resolveResourceURI(parent_module)
        order = parent_module['definition']['children'].index(resource_uri) + 1  # Use 1-indexing
        return parent_module_uri, order


    def __extractOldEdxProblem(self):
        '''
        Extract problem data from old-style MongoDB modulestore.
        Inserts data into EdxProblem.
        '''
        problems = self.msdb.modulestore.find({"_id.category": "problem"}).batch_size(20)
        col_names     = ['problem_id',
                         'problem_display_name',
                         'course_display_name',
                         'problem_text',
                         'date',
                         'weight',
                         'revision',
                         'max_attempts',
                         'trackevent_hook'
                         ]
        
        
        table = []
        num_pulled = 0        
        
        for problem in problems:
            # Each row in the table is a dictionary
            course_display_name = self.__resolveCDN(problem)
            # Is this a test course?
            if TEST_COURSE_NAME_PATTERN.search(course_display_name) is not None:
                continue            
            
            # Reconstruct URI for problem
            problem_uri = self.__resolveResourceURI(problem)
            
            # Get URI for enclosing vertical and location of problem therein
            vertical_uri, problem_idx = self.__locateModuleInParent(problem_uri)
            # Get URI for enclosing sequential and location of vertical therein
            sequential_uri, vertical_idx = self.__locateModuleInParent(vertical_uri)
            
            staff_name = vertical_uri.split('/')[5]
            # Staff-only indicator
            if not vertical_uri:
                staff_only = False
            else:
                staff_only = self.msdb.modulestore.find({"_id.name": staff_name}).next()['metadata'].get('visible_to_staff_only', False)
            
            # URI for enclosing chapter and location of sequential
            chapter_uri, sequential_idx = self.__locateModuleInParent(sequential_uri)

            # Get URI for enclosing sequential and location of vertical therein
            sequential_uri, vertical_idx = self.__locateModuleInParent(vertical_uri)

            # URI for course and location of chapter
            course_uri, chapter_idx = self.__locateModuleInParent(chapter_uri) #@UnusedVariable

            data = (problem['_id'].get('name', 'False'), # problem_id
                    problem['metadata'].get('display_name', 'False'), # problem_display_name
                    course_display_name, # course_display_name
                    problem['definition'].get('data', 'False'), # problem_text
                    self.__resolveTimestamp(problem), # date
                    problem['metadata'].get('weight', -1), # weight
                    problem['_id'].get('revision', 'False'), # revision
                    problem['metadata'].get('max_attempts', -1), # max_attempts
                    problem_uri, # trackevent_hook
                    vertical_uri, # vertical_uri
                    problem_idx, # problem_idx
                    sequential_uri, # sequential_uri
                    vertical_idx, # vertical_idx
                    chapter_uri, # chapter_uri
                    sequential_idx, # sequential_idx
                    chapter_idx, # chapter_idx
                    staff_only # staff_only
                    )
            
            table.append(data)
            if len(table) >= ModulestoreExtractor.BULK_INSERT_NUM_ROWS:
                self.__loadToSQL('EdxProblem', col_names, table)
                num_pulled += len(table)
                if num_pulled > ModulestoreExtractor.REPORT_EVERY_N_ROWS:
                    self.logInfo("Ingested %s rows of old-modulestore problems." % num_pulled)
                
                table = []
                
        if len(table) > 0:
            self.__loadToSQL('EdxProblem', col_names, table)
            num_pulled += len(table)            
            self.logInfo("Ingested %s rows of old-modulestore problems." % num_pulled)
            
    def __extractSplitEdxProblem(self):
        '''
        Extract problem data from Split MongoDB modulestore.
        SQL load method expects a list of dicts mapping column names to data.
        '''
        table = []
        
        # Get a course generator and iterate through
        courses = self.msdb['modulestore.active_versions'].find()

        col_names     = ['problem_id',
                         'problem_display_name',
                         'course_display_name',
                         'problem_text',
                         'date',
                         'weight',
                         'revision',
                         'max_attempts',
                         'trackevent_hook'
                         ]
        num_pulled = 0

        for course in courses:
            cdn = "%s/%s/%s" % (course['org'], course['course'], course['run'])
            cid = course['versions'].get('published-branch', None)
            if not cid:
                continue

            # Retrieve course structure from published branch and filter out non-problem blocks
            try:
                structure = self.msdb['modulestore.structures'].find({"_id": cid, "blocks.block_type": "problem"}).next()
            except StopIteration:
                continue
            for block in filter(lambda b: b['block_type'] == 'problem', structure['blocks']):
                try:
                    definition = self.msdb['modulestore.definitions'].find({"_id": block['definition']}).next()
                except StopIteration:
                    continue

                # Construct data dict and append to table list
                data = (block['block_id'],                         # problem_id
                        block['fields'].get('display_name', "NA"), # problem_display_name 
                        cdn,                                       # course_display_name
                        definition['fields']['data'],              # problem_text
                # TODO: Test the below on real course data from split modulestore
                # TODO: Add context metadata
                        False,      							   # date                         
                        -1,         							   # weight
                        False,      							   # revision
                        -1,         							   # max_attempts
                        False         							   # trackeventhook
                        )
                table.append(data)
                if len(table) >= ModulestoreExtractor.BULK_INSERT_NUM_ROWS:
                    self.__loadToSQL('EdxProblem', col_names, table)
                    num_pulled += len(table)
                    if num_pulled > ModulestoreExtractor.REPORT_EVERY_N_ROWS:
                        self.logInfo("Ingested %s rows of new-modulestore problems." % num_pulled)
                    table = []
        if len(table) > 0:
            self.__loadToSQL('EdxProblem', col_names, table)
            num_pulled += len(table)
            self.logInfo("Ingested %s rows of new-modulestore problems." % num_pulled)            

    def __extractOldEdxVideo(self):
        '''
        Extract video metadata from old MongoDB modulestore.
        More or less identical to EdxProblem extract, but with different metadata.
        '''
        table = []
        num_pulled = 0        

        videos = self.msdb.modulestore.find({"_id.category": "video"}).batch_size(20)

        col_names     = ['video_id',
                         'video_display_name',
                         'course_display_name',
                         'video_uri',
                         'video_code',
                         'trackevent_hook',
                         'vertical_uri',
                         'problem_idx',
                         'sequential_uri',
                         'vertical_idx'
                         'chapter_uri',
                         'sequential_idx',
                         'chapter_idx'
                         ]
        
        for video in videos:
            course_display_name = self.__resolveCDN(video)
            # Is this a test course?
            if TEST_COURSE_NAME_PATTERN.search(course_display_name) is not None:
                continue

            video_uri = self.__resolveResourceURI(video)                     
            vertical_uri, problem_idx = self.__locateModuleInParent(video_uri)
            sequential_uri, vertical_idx = self.__locateModuleInParent(vertical_uri)
            chapter_uri, sequential_idx = self.__locateModuleInParent(sequential_uri)                                    
            course_uri, chapter_idx = self.__locateModuleInParent(chapter_uri) #@UnusedVariable            
            
                    # Identifiers:
            data = (video['_id'].get('name', 'NA'), # video_id
                    video['metadata'].get('display_name', 'NA'), # video_display_name
                    self.__resolveCDN(video), # course_display_name
                    video['metadata'].get('html5_sources', 'NA'), # video_uri
                    video['metadata'].get('youtube_id_1_0', 'NA'), # video_code
                    # Context
                    video_uri, # trackevent_hook
                    vertical_uri, # vertical_uri
                    problem_idx, # problem_idx
                    sequential_uri, # sequential_uri
                    vertical_idx, # vertical_idx
                    chapter_uri, # chapter_uri
                    sequential_idx, # sequential_idx
                    chapter_idx # chapter_idx
                    )

            table.append(data)
            if len(table) >= ModulestoreExtractor.BULK_INSERT_NUM_ROWS:
                self.__loadToSQL('EdxVideo', col_names, table)
                num_pulled += len(table)
                if num_pulled > ModulestoreExtractor.REPORT_EVERY_N_ROWS:
                    self.logInfo("Ingested %s rows of old-modulestore videos." % num_pulled)
                
                table = []
        if len(table) > 0:
            self.__loadToSQL('EdxVideo', col_names, table)
            num_pulled += len(table)            
            self.logInfo("Ingested %s rows of old-modulestore videos." % num_pulled)

    def __extractSplitEdxVideo(self):
        '''
        Extract video metadata from Split MongoDB modulestore.
        More or less identical to EdxProblem extract, but with different metadata.
        '''
        table = []
        num_pulled = 0
        
        # Get a course generator and iterate through
        courses = self.msdb['modulestore.active_versions'].find()
        
        col_names     = ['video_id',
                         'video_display_name',
                         'course_display_name',
                         'video_uri',
                         'video_code',
                         'trackevent_hook',
                         'vertical_uri',
                         'problem_idx',
                         'sequential_uri',
                         'vertical_idx'
                         'chapter_uri',
                         'sequential_idx',
                         'chapter_idx'
                         ]
        
        for course in courses:
            cdn = "%s/%s/%s" % (course['org'], course['course'], course['run'])
            cid = course['versions'].get('published-branch', None)
            if not cid:
                continue

            # Retrieve course structure from published branch and filter out non-problem blocks
            try:
                structure = self.msdb['modulestore.structures'].find({"_id": cid, "blocks.block_type": "video"}).next()
            except StopIteration:
                continue  # Some courses don't have any video content
            for block in filter(lambda b: b['block_type'] == 'video', structure['blocks']):
                try:
                    definition = self.msdb['modulestore.definitions'].find({"_id": block['definition']}).next() #@UnusedVariable
                except StopIteration:
                    continue

                data = (block['block_id'], # video_id'
                        block['fields'].get('display_name', 'NA'), # video_display_name
                        cdn, # course_display_name
                        block['fields'].get('html5_sources', 'NA'), # video_uri
                        block['fields'].get('youtube_id_1_0', 'NA') # video_code
                        )
                
                table.append(data)
                if len(table) >= ModulestoreExtractor.BULK_INSERT_NUM_ROWS:
                    self.__loadToSQL('EdxVideo', col_names, table)
                    num_pulled += len(table)
                    if num_pulled > ModulestoreExtractor.REPORT_EVERY_N_ROWS:
                        self.logInfo("Ingested %s rows of new-modulestore videos." % num_pulled)
                        
                    table = []
        if len(table) > 0:
            self.__loadToSQL('EdxVideo', col_names, table)
            num_pulled += len(table)            
            self.logInfo("Ingested %s rows of new-modulestore videos." % num_pulled)
            
    @staticmethod
    def inRange(date, quarter):
        '''
        Return boolean indicating whether date is contained in date_range.
        '''
        if not type(quarter) is Quarter:
            raise TypeError('Function inRange expects date_range of type Quarter.')
        msdb_time = lambda timestamp: datetime.datetime.strptime(timestamp, "%Y-%m-%dT%H:%M:%SZ")
        if (msdb_time(date) >= msdb_time(quarter.start_date)) and (msdb_time(date) <= msdb_time(quarter.end_date)):
            return quarter.quarter
        else:
            return False


    @staticmethod
    def genQuartersForAY(ay):
        '''
        Return date ranges for quarters for a given academic year.
        '''
        ayb = str(int(ay) + 1)  # academic years bleed over into the next calendar year
        AYfall = Quarter('%s-09-01T00:00:00Z' % ay, '%s-11-30T00:00:00Z' % ay, 'fall')
        AYwinter = Quarter('%s-12-01T00:00:00Z' % ay, '%s-02-28T00:00:00Z' % ayb, 'winter')
        AYspring = Quarter('%s-03-01T00:00:00Z' % ayb, '%s-05-31T00:00:00Z' % ayb, 'spring')
        AYsummer = Quarter('%s-06-01T00:00:00Z' % ayb, '%s-08-31T00:00:00Z' % ayb, 'summer')
        return AYfall, AYwinter, AYspring, AYsummer


    def __lookupAYDataFromDates(self, start_date, end_date):
        '''
        Return course calendar data from hardcoded lookup table.
        '''
        if start_date == '0000-00-00T00:00:00Z':
            return 0, 'NA', 0
        end_date = '0000-00-00T00:00:00Z' if not end_date else end_date

        if start_date.count(':') < 2:
            start_date = start_date[:-1] + ":00Z"
        # Quick functions to parse out month/year/academic year
        month = lambda x: int(x[5:7])
        year = lambda x: int(x[:4])

        # Generate quarters given start date and determine starting quarter
        start_ay = str(year(start_date)) if month(start_date) >= 9 else str(year(start_date) - 1)
        sFall, sWinter, sSpring, sSummer = self.genQuartersForAY(start_ay)
        start_quarter = self.inRange(start_date, sFall) or self.inRange(start_date, sWinter) or self.inRange(start_date, sSpring) or self.inRange(start_date, sSummer)

        # Calculate number of quarters
        months_passed = (year(end_date) - year(start_date)) * 12 + (month(end_date) - month(start_date))
        n_quarters = int(math.ceil(months_passed / 4))
        if n_quarters == 0:
            n_quarters = 1  # Round up to one quarter minimum
        if n_quarters < 0:
            n_quarters = 0  # Self-paced courses have no quarters

        return int(start_ay), start_quarter, n_quarters


    @staticmethod
    def isInternal(enroll_domain, org):
        '''
        Return boolean indicating whether course is internal.
        '''
        return 1 if (enroll_domain == SU_ENROLLMENT_DOMAIN) or (org in INTERNAL_ORGS) else 0


    def __extractOldCourseInfo(self):
        '''
        Extract course metadata from old-style MongoDB modulestore.
        Inserts all into CourseInfo table.
        '''
        table = []
        num_pulled = 0
        
        col_names     = ['course_display_name',
                         'course_catalog_name',
                         'start_date',
                         'end_date',
                         'academic_year',
                         'quarter',
                         'is_internal',
                         'enrollment_start',
                         'enrollment_end',
                         'grade_policy',
                         'certs_policy'
                         ]

        # Iterate through all 'course' type documents in modulestore
        courses = self.msdb.modulestore.find({"_id.category": "course"})
        
        for course in courses:
            course_display_name = self.__resolveCDN(course) 
            # Is this a test course?
            if TEST_COURSE_NAME_PATTERN.search(course_display_name) is not None:
                continue
            
            start_date = course['metadata'].get('start', '0000-00-00T00:00:00Z')
            end_date = course['metadata'].get('end', '0000-00-00T00:00:00Z')
            
            academic_year, quarter, num_quarters = self.__lookupAYDataFromDates(start_date, end_date) #@UnusedVariable
            if academic_year not in VALID_AYS:
                continue
            try:
                grade_policy = str(course['definition']['data'].get('grading_policy', 'NA').get('GRADER', 'NA'))
                certs_policy = str(course['definition']['data'].get('grading_policy', 'NA').get('GRADE_CUTOFFS', 'NA'))
            except AttributeError:
                grade_policy = 'NA'
                certs_policy = 'NA'
            
            data = (course_display_name, # course_display_name
                    course['metadata']['display_name'], # course_catalog_name
                    start_date, # start_date'
                    end_date, # end_date
                    academic_year, # academic_year
                    quarter, # quarter
                    self.isInternal(course['metadata'].get('enrollment_domain', 'NA'), course['_id']['org']), # is_internal
                    course['metadata'].get('enrollment_start', '0000-00-00T00:00:00Z'), # enrollment_start
                    course['metadata'].get('enrollment_end', '0000-00-00T00:00:00Z'), # enrollment_end
                    grade_policy, # grade_policy
                    certs_policy # certs_policy
                    )

            table.append(data)
            if len(table) >= ModulestoreExtractor.BULK_INSERT_NUM_ROWS:
                self.__loadToSQL('EdxProblem', col_names, table)
                num_pulled += len(table)
                if num_pulled > ModulestoreExtractor.REPORT_EVERY_N_ROWS:
                    self.logInfo("Ingested %s rows of old-modulestore course info." % num_pulled)
                
                table = []
        if len(table) > 0:
            self.__loadToSQL('EdxProblem', col_names, table)
            num_pulled += len(table)            
            self.logInfo("Ingested %s rows of old-modulestore course info." % num_pulled)

    def __extractSplitCourseInfo(self):
        '''
        Extract course metadata from Split MongoDB modulestore.
        Inserts results in table CourseInfo.
        '''
        table = []
        num_pulled = 0
        
        col_names     = ['course_display_name',
                         'course_catalog_name',
                         'start_date',
                         'end_date',
                         'academic_year',
                         'quarter',
                         'is_internal',
                         'enrollment_start',
                         'enrollment_end',
                         'grade_policy',
                         'certs_policy'
                         ]
        
        # Get all most recent versions of 'course' type documents from modulestore
        courses = self.msdb['modulestore.active_versions'].find()
        for course in courses:
            cid = course['versions'].get('published-branch', None)
            if not cid:
                continue  # Ignore if not a 'published' course
            # Get this course block and corresponding definition document from modulestore
            try:
                structure = self.msdb['modulestore.structures'].find({"_id": cid, "blocks.block_type": "course"}).next()
            except StopIteration:
                # No record found in structures:
                continue
            try:
                block = filter(lambda b: b['block_type'] == 'course', structure['blocks'])[0]
            except IndexError:
                self.logError('********** No course block found for course %s' % str(course))
                continue
            try:
                definition = self.msdb['modulestore.definitions'].find({"_id": block['definition']}).next()
            except StopIteration:
                continue

            datestr = lambda d: datetime.datetime.strftime(d, "%Y-%m-%dT%H:%M:%SZ")
            
            start_date = block['fields'].get('start', '0000-00-00T00:00:00Z')
            end_date = block['fields'].get('end', '0000-00-00T00:00:00Z')
            start_date = datestr(start_date) if type(start_date) is datetime.datetime else start_date
            end_date = datestr(end_date) if type(end_date) is datetime.datetime else end_date
            academic_year, quarter, num_quarters = self.__lookupAYDataFromDates(start_date, end_date) #@UnusedVariable
            
            if academic_year not in VALID_AYS:
                continue
            
            enrollment_start = block['fields'].get('enrollment_start', '0000-00-00T00:00:00Z')
            enrollment_end = block['fields'].get('enrollment_end', '0000-00-00T00:00:00Z')
            enrollment_start = datestr(enrollment_start) if type(enrollment_start) is datetime.datetime else enrollment_start
            enrollment_end = datestr(enrollment_end) if type(enrollment_end) is datetime.datetime else enrollment_end
            
            try:
                grade_policy = str(definition['fields'].get('grading_policy').get('GRADER', 'NA'))
                certs_policy = ("minimum_grade_credit: %s certificate_policy: " % block['fields'].get('minimum_grade_credit', 'NA')) + str(definition['fields'].get('grading_policy').get('GRADE_CUTOFFS', 'NA'))
            except AttributeError:
                grade_policy = 'NA'
                certs_policy = 'NA'
                        
            data = ("%s/%s/%s" % (course['org'], course['course'], course['run']), # course_display_name
                    block['fields']['display_name'], # course_catalog_name
                    start_date, # start_date
                    end_date,   # end_date
                    academic_year, # academic_year
                    quarter, # quarter
                    self.isInternal("", course['org']), # is_internal
                    enrollment_start, # enrollment_start
                    enrollment_end, # enrollment_end
                    grade_policy, # grade_policy
                    certs_policy # certs_policy
                    )

            table.append(data)
            if len(table) >= ModulestoreExtractor.BULK_INSERT_NUM_ROWS:
                self.__loadToSQL('CourseInfo', col_names, table)
                num_pulled += len(table)
                if num_pulled > ModulestoreExtractor.REPORT_EVERY_N_ROWS:
                    self.logInfo("Ingested %s rows of new-modulestore course info." % num_pulled)
                
                table = []
        if len(table) > 0:
            self.__loadToSQL('CourseInfo', col_names, table)
            num_pulled += len(table)
            self.logInfo("Ingested %s rows of new-modulestore course info." % num_pulled)

    # ----------------------- Utilities -------------------


    def __loadToSQL(self, table_name, columns, arr_of_tuples):
        '''
        Build columns tuple and list of row tuples for MySQLDB bulkInsert operation, then execute.
        We hold tables in memory to minimize query load on the receiving database.
        '''
        self.bulkInsert(table_name, columns, arr_of_tuples)

    #-------------------------
    # setupLogging
    #--------------
    
    def setupLogging(self, loggingLevel, logFile=None):
        # Set up logging:
        self.logger = logging.getLogger('newEvalIntake')
        self.logger.setLevel(loggingLevel)
        # Create file handler if requested:
        if logFile is not None:
            handler = logging.FileHandler(logFile)
        else:
            # Create console handler:
            handler = logging.StreamHandler()
        handler.setLevel(loggingLevel)
        # Add the handler to the logger
        self.logger.addHandler(handler)

    #-------------------------
    # logInfo
    #--------------

    def logInfo(self, msg):
        self.logger.info(msg)
    
    #-------------------------
    # logError 
    #--------------
        
    def logError(self, msg):
        self.logger.error(msg)
    
    #-------------------------
    # logWarn
    #--------------
        
    def logWarn(self, msg):
        self.logger.warning(msg)


if __name__ == '__main__':
    
    # Allow the --verbose argument
    if len(sys.argv) > 1 and (sys.argv[1] == '-v' or sys.argv[1] == '--verbose'):
        verbose = True
    else:
        verbose = False
    extractor = ModulestoreExtractor(verbose=verbose)
    extractor.export()
