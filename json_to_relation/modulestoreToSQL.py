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


import sys
import json
import math
import os.path
import datetime
from collections import defaultdict, namedtuple

from pymysql_utils1 import MySQLDB
import pymongo as mng


# Data type for AY_[quarter][year] date ranges
Quarter = namedtuple('Quarter', ['start_date', 'end_date', 'quarter'])

# Class variables for determining internal status of course
SU_ENROLLMENT_DOMAIN = "shib:https://idp.stanford.edu/"
INTERNAL_ORGS = ['ohsx', 'ohs']


class ModulestoreExtractor(MySQLDB):

    def __init__(self, split=True, old=True, edxproblem=True, courseinfo=True):
        '''
        Get interface to modulestore backup.
        Note: This class presumes modulestore was recently loaded to mongod.
        Class also presumes that mongod is running on localhost:27017.
        '''
        self.msdb = mng.MongoClient().modulestore

        # Need to handle Split and Old modulestore cases
        self.split = split
        self.old = old

        # Switch for updating EdxProblem and CourseInfo separately (useful for testing)
        self.update_EP = edxproblem
        self.update_CI = courseinfo

        # Initialize MySQL connection from config file
        home = os.path.expanduser('~')
        dbFile = home + "/.ssh/mysql_user"
        if not os.path.isfile(dbFile):
            sys.exit("MySQL user credentials not found: " + dbFile)
        dbuser = None
        dbpass = None
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
              `weight` INT DEFAULT NULL,
              `revision` VARCHAR(10) DEFAULT NULL,
              `max_attempts` INT DEFAULT NULL,
              `trackevent_hook` VARCHAR(200) DEFAULT NULL,
              `vertical_uri` VARCHAR(200) DEFAULT NULL,
              `problem_idx` INT DEFAULT NULL,
              `sequential_uri` VARCHAR(200) DEFAULT NULL,
              `vertical_idx` INT DEFAULT NULL,
              `chapter_uri` VARCHAR(200) DEFAULT NULL,
              `sequential_idx` INT DEFAULT NULL,
              `chapter_idx` INT DEFAULT NULL
            ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
        """

        # Execute table definition queries
        self.execute(dropOldTableQuery)
        self.execute(emptyEdxProblemTableQuery)


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
                `num_quarters` int(11) DEFAULT NULL,
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

        if self.split and self.update_EP:
            splitEPData = self.__extractSplitEdxProblem()
            self.__loadToSQL(splitEPData, "EdxProblem")

        if self.split and self.update_CI:
            splitCIData = self.__extractSplitCourseInfo()
            self.__loadToSQL(splitCIData, "CourseInfo")

        if self.old and self.update_EP:
            oldEPData = self.__extractOldEdxProblem()
            self.__loadToSQL(oldEPData, "EdxProblem")

        if self.old and self.update_CI:
            oldCIData = self.__extractOldCourseInfo()
            self.__loadToSQL(oldCIData, "CourseInfo")


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


    def __resolveCDN(self, problem):
        '''
        Extract course display name from modulestore.
        '''
        org = problem["_id"]["org"]
        course = problem["_id"]["course"]
        definition = self.msdb.modulestore.find({"_id.category": "course",
                                                 "_id.org": org,
                                                 "_id.course": course})
        name = definition[0]["_id"]["name"]
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
            print resource_uri
            return None, -2
        parent_module_uri = self.__resolveResourceURI(parent_module)
        order = parent_module['definition']['children'].index(resource_uri) + 1  # Use 1-indexing
        return parent_module_uri, order


    def __extractOldEdxProblem(self):
        '''
        Extract problem data from old-style MongoDB modulestore.
        SQL load method expects a list of dicts mapping column names to data.
        '''
        problems = self.msdb.modulestore.find({"_id.category": "problem"}).batch_size(20)
        table = []
        for problem in problems:
            # Each row in the table is a dictionary
            data = dict()
            data['problem_id'] = problem['_id'].get('name', 'False')
            data['problem_display_name'] = problem['metadata'].get('display_name', 'False')
            data['course_display_name'] = self.__resolveCDN(problem)
            data['problem_text'] = problem['definition'].get('data', 'False')
            data['date'] = self.__resolveTimestamp(problem)
            data['weight'] = problem['metadata'].get('weight', -1)
            data['revision'] = problem['_id'].get('revision', 'False')
            data['max_attempts'] = problem['metadata'].get('max_attempts', -1)

            # Reconstruct URI for problem
            problem_uri = self.__resolveResourceURI(problem)
            data['trackevent_hook'] = problem_uri

            # Get URI for enclosing vertical and location of problem therein
            vertical_uri, problem_idx = self.__locateModuleInParent(problem_uri)
            data['vertical_uri'] = vertical_uri
            data['problem_idx'] = problem_idx

            # Get URI for enclosing sequential and location of vertical therein
            sequential_uri, vertical_idx = self.__locateModuleInParent(vertical_uri)
            data['sequential_uri'] = sequential_uri
            data['vertical_idx'] = vertical_idx

            # URI for enclosing chapter and location of sequential
            chapter_uri, sequential_idx = self.__locateModuleInParent(sequential_uri)
            data['chapter_uri'] = chapter_uri
            data['sequential_idx'] = sequential_idx

            # URI for course and location of chapter
            course_uri, chapter_idx = self.__locateModuleInParent(chapter_uri)
            data['chapter_idx'] = chapter_idx

            table.append(data)

        return table


    def __extractSplitEdxProblem(self):
        '''
        Extract problem data from Split MongoDB modulestore.
        SQL load method expects a list of dicts mapping column names to data.
        '''
        table = []

        # Get a course generator and iterate through
        courses = self.msdb['modulestore.active_versions'].find()
        for course in courses:
            cdn = "%s/%s/%s" % (course['org'], course['course'], course['run'])
            cid = course['versions'].get('published-branch', None)
            if not cid:
                continue

            # Retrieve course structure from published branch and filter out non-problem blocks
            structure = self.msdb['modulestore.structures'].find({"_id": cid, "blocks.block_type": "problem"})[0]
            for block in filter(lambda b: b['block_type'] == 'problem', structure['blocks']):
                definition = self.msdb['modulestore.definitions'].find({"_id": block['definition']})[0]

                # Construct data dict and append to table list
                data = dict()
                data['problem_id'] = block['block_id']
                data['problem_display_name'] = block['fields'].get('display_name', "NA")
                data['course_display_name'] = cdn
                data['problem_text'] = definition['fields']['data']

                # TODO: Test the below on real course data from split modulestore
                data['date'] = False
                data['weight'] = -1
                data['revision'] = False
                data['max_attempts'] = -1
                data['trackevent_hook'] = False
                table.append(data)

        return table


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

        return int(start_ay), start_quarter, n_quarters


    @staticmethod
    def isInternal(enroll_domain, org):
        '''
        Return boolean indicating whether course is internal.
        '''
        return (enroll_domain == SU_ENROLLMENT_DOMAIN) or (org in INTERNAL_ORGS)


    def __extractOldCourseInfo(self):
        '''
        Extract course metadata from old-style MongoDB modulestore.
        Returns a list of dicts mapping column names to data.
        '''
        table = []

        # Iterate through all 'course' type documents in modulestore
        courses = self.msdb.modulestore.find({"_id.category": "course"})
        for course in courses:
            data = dict()
            data['course_display_name'] = self.__resolveCDN(course)
            data['course_catalog_name'] = course['metadata']['display_name']
            start_date = course['metadata']['start_date']
            end_date = course['metadata']['end_date']
            data['start_date'] = start_date
            data['end_date'] = end_date
            academic_year, quarter, num_quarters = self.__lookupAYDataFromDates(start_date, end_date)
            data['academic_year'] = academic_year
            data['quarter'] = quarter
            data['num_quarters'] = num_quarters
            data['is_internal'] = self.isInternal(course['metadata']['enrollment_domain'], course['_id']['org'])
            data['enrollment_start'] = course['metadata']['enrollment_start']
            data['enrollment_end'] = course['metadata']['enrollment_end']
            data['grade_policy'] = course['definition']['data']['grading_policy'].get('GRADER', 'NA')
            data['certs_policy'] = course['definition']['data']['grading_policy'].get('GRADE_CUTOFFS', 'NA')

            table.append(data)

        return table

    def __extractSplitCourseInfo(self):
        '''
        Extract course metadata from Split MongoDB modulestore.
        Returns a list of dicts mapping column names to data.
        '''
        table = []

        # Get all most recent versions of 'course' type documents from modulestore
        courses = self.msdb['modulestore.active_versions'].find()
        for course in courses:
            cid = course['versions'].get('published-branch', None)
            if not cid:
                continue  # Ignore if not a 'published' course
            # Get this course block and corresponding definition document from modulestore
            structure = self.msdb['modulestore.structures'].find({"_id": cid, "blocks.block_type": "course"})[0]
            block = filter(lambda b: b['block_type'] == 'course', structure['blocks'])[0]
            definition = self.msdb['modulestore.definitions'].find({"_id": block['definition']})[0]

            data = dict()
            data['course_display_name'] = "%s/%s/%s" % (course['org'], course['course'], course['run'])
            data['course_catalog_name'] = block['fields']['display_name']
            datestr = lambda d: datetime.datetime.strftime(d, "%Y-%m-%dT%H:%M:%SZ")
            start_date = block['fields'].get('start', '0000-00-00T00:00:00Z')
            end_date = block['fields'].get('end', '0000-00-00T00:00:00Z')
            start_date = datestr(start_date) if type(start_date) is datetime.datetime else start_date
            end_date = datestr(end_date) if type(end_date) is datetime.datetime else end_date
            data['start_date'] = start_date
            data['end_date'] = end_date
            academic_year, quarter, num_quarters = self.__lookupAYDataFromDates(start_date, end_date)
            data['academic_year'] = academic_year
            data['quarter'] = quarter
            data['num_quarters'] = num_quarters
            data['is_internal'] = self.isInternal("", course['org'])
            enrollment_start = block['fields'].get('enrollment_start', '0000-00-00T00:00:00Z')
            enrollment_end = block['fields'].get('enrollment_end', '0000-00-00T00:00:00Z')
            enrollment_start = datestr(enrollment_start) if type(enrollment_start) is datetime.datetime else enrollment_start
            enrollment_end = datestr(enrollment_end) if type(enrollment_end) is datetime.datetime else enrollment_end
            data['enrollment_start'] = enrollment_start
            data['enrollment_end'] = enrollment_end
            try:
                data['grade_policy'] = str(definition['fields'].get('grading_policy').get('GRADER', 'NA'))
                data['certs_policy'] = ("minimum_grade_credit: %s certificate_policy: " % block['fields']['minimum_grade_credit']) + str(definition['fields'].get('grading_policy').get('GRADE_CUTOFFS', 'NA'))
            except AttributeError:
                data['grade_policy'] = 'NA'
                data['certs_policy'] = 'NA'

            table.append(data)

        return table

    def __loadToSQL(self, table, table_name):
        '''
        Build columns tuple and list of row tuples for MySQLDB bulkInsert operation, then execute.
        We hold tables in memory to minimize query load on the receiving database.
        '''
        columns = table[0].keys()

        data = []
        for row in table:
            values = tuple(row.values())  # Convert each dict value set to tuple for loading
            data.append(values)

        self.bulkInsert(table_name, columns, data)



if __name__ == '__main__':
    extractor = ModulestoreExtractor(edxproblem=False)
    extractor.export()
