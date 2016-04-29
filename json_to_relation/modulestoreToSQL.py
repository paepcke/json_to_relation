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


## Class: EdxProblemExtractor
## Author: Alex Kindel
## Date: 8 February 2016
## Converts modulestore mongo structure to SQL.
##
## On 25 January 2016, Lagunita (OpenEdX @ Stanford) switched from a single modulestore (one Mongo database)
##  to a split modulestore (three Mongo databases). This class provides an interface to explicitly handle
##  either modulestore case.


import sys
import json
import os.path
import datetime
from collections import defaultdict

from pymysql_utils1 import MySQLDB
import pymongo as mng


class EdxProblemExtractor(MySQLDB):

    def __init__(self, split=True, old=True):
        '''
        Get interface to modulestore backup.
        Note: This class presumes modulestore was recently loaded to mongod.
        Class also presumes that mongod is running on localhost:27017.
        '''
        self.msdb = mng.MongoClient().modulestore

        # Need to handle Split and Old modulestore cases
        self.split = split
        self.old = old

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
              `vertical_idx` INT DEFAULT NULL
            ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
        """

        # Execute table definition queries
        self.execute(dropOldTableQuery)
        self.execute(emptyEdxProblemTableQuery)


    def export(self):
        '''
        Client method builds tables and loads various modulestore cases to MySQL.
        We reload each time. The full load takes less than a minute.
        '''
        self.__buildEmptyEdxProblemTable()
        if self.split:
            splitdata = self.__extractSplitMS()
            self.__loadToSQL(splitdata)
        if self.old:
            oldmsdata = self.__extractOldMS()
            self.__loadToSQL(oldmsdata)


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
        try:
            parent_module = self.msdb.modulestore.find({"definition.children": resource_uri}).next()
        except StopIteration:
            print vertical_uri
            return None
        parent_module_uri = self.__resolveResourceURI(parent_module)
        order = parent_module['defintion']['children'].index(resource_uri)
        return parent_module_uri, order


    def __extractOldMS(self):
        '''
        Extract problem data from old-style MongoDB modulestore.
        SQL load method expects a list of dicts mapping column names to data.
        '''
        problems = self.msdb.modulestore.find({"_id.category": "problem"})
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

            problem_uri = self.__resolveResourceURI(problem)
            data['trackevent_hook'] = problem_uri

            vertical_uri, problem_idx = self.__locateModuleInParent(problem_uri)
            data['vertical_uri'] = vertical_uri
            data['problem_idx'] = problem_idx  # We leave this as is but there may be additional modules on the page

            sequential_uri, vertical_idx = self.__locateModuleInParent(vertical_uri)
            data['sequential_uri'] = sequential_uri
            data['vertical_idx'] = vertical_idx + 1  # EdxTrackEvent sequence navigation track events are 1-indexed
            table.append(data)

        return table


    def __extractSplitMS(self):
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


    def __loadToSQL(self, table):
        '''
        Build columns tuple and list of row tuples for MySQLDB bulkInsert operation, then execute.
        '''
        columns = table[0].keys()

        data = []
        for row in table:
            values = tuple(row.values())  # Convert each dict value set to tuple for loading
            data.append(values)

        self.bulkInsert('EdxProblem', columns, data)



if __name__ == '__main__':
    extractor = EdxProblemExtractor()
    extractor.export()
