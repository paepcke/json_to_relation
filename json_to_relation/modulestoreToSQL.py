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
from collections import defaultdict

from pymysql_utils1 import MySQLDB
import pymongo as mng

class EdxProblemExtractor(MySQLDB):

    ## TODO: Which problems matter?
    # OLD_PROBLEM_CATEGORIES = [
    #     'annotatable',
    #     'combinedopenended',
    #     'freetextresponse',
    #     'imageannotation',
    #     'peergrading',
    #     'poll_question',
    #     'problem',
    #     'submit-and-compare',
    #     'textannotation',
    #     'videoannotation'
    # ]

    def __init__(self, split=True, old=True):
        '''
        Get interface to modulestore backup.
        Note: This class presumes modulestore was recently loaded to mongod.
        Class also presumes that mongod is running on localhost:27017.
        '''
        self.msdb = mng.MongoClient().modulestore ## XXX: am I reading all of MS into memory here?

        # Need to handle Split and Old modulestore cases
        self.split = split
        self.old = old

        # Initialize MySQL connection
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
        '''
        # Build table drop and table create queries
        dropOldTableQuery = """DROP TABLE IF EXISTS `EdxProblem`;"""
        emptyEdxProblemTableQuery = """
            CREATE TABLE IF NOT EXISTS `EdxProblem` (
              `problem_id` VARCHAR(32) DEFAULT NULL,
              `problem_display_name` VARCHAR(100) DEFAULT NULL,
              `course_display_name` VARCHAR(100) DEFAULT NULL,
              `problem_text` TEXT,
              `date` DATETIME DEFAULT NULL,
              `weight` INT DEFAULT NULL,
              `revision` VARCHAR(10) DEFAULT NULL,
              `max_attempts` INT DEFAULT NULL,
              `trackevent_hook` VARCHAR(200) DEFAULT NULL
            ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
        """
        ## TODO NOTE re: above table definition
        # published_date from metadata or edit_info? either?
        # revision is either 'draft' or null-- might help with 'was this a real question'
        # problem_text can have a lot of data and potentially code
        # get CDN from modulestoreImporter.py or just reproduce that here
        # trackevent_hook makes easy joins with EdxTrackEvent
        ####

        # Execute table definition queries
        self.execute(dropOldTableQuery)
        self.execute(emptyEdxProblemTableQuery)


    def export(self):
        '''
        Client method builds tables and loads various modulestore cases to MySQL.
        '''
        self.__buildEmptyEdxProblemTable()
        if self.split: self.__extractSplitMS()
        if self.old:
            table = self.__extractOldMS()
            self.__loadOldMS(table)


    @staticmethod
    def __extractLogHook(problem):
        '''
        Extract resource identifier as identifier for EdxTrackEvent hook.
        '''
        tag = problem["_id"]["tag"]
        org = problem["_id"]["org"]
        course = problem["_id"]["course"]
        category = problem["_id"]["category"]
        name = problem["_id"]["name"]
        hook = "%s://%s/%s/%s/%s" % (tag, org, course, category, name)
        return hook


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


    def __extractOldMS(self):
        '''
        '''
        problems = self.msdb.modulestore.find({"_id.category": "problem"})
        table = []
        for problem in problems:
            data = defaultdict(list)
            data['problem_id'] = problem['_id'].get('name', 'False')
            data['problem_display_name'] = problem['metadata'].get('display_name', 'False')
            data['course_display_name'] = self.__resolveCDN(problem)
            data['problem_text'] = problem['definition'].get('data', 'False')
            data['date'] = problem['metadata'].get('published_date', 'False')
            data['weight'] = problem['metadata'].get('weight', -1)
            data['revision'] = problem['_id'].get('revision', 'False')
            data['max_attempts'] = problem['metadata'].get('max_attempts', -1)
            data['trackevent_hook'] = self.__extractLogHook(problem)
            table.append(data)

        return table

    def __loadOldMS(self, table):
        #columns = 'problem_id', 'problem_display_name', 'course_display_name', 'problem_text', 'date', 'weight', 'revision', 'max_attempts', 'trackevent_hook'
        columns = table[0].keys()

        data = []
        for row in table:
            values = tuple(row.values())
            data.append(values)
        self.bulkInsert('EdxProblem', columns, data)


    def __extractSplitMS(self):
        '''
        '''
        print "Split case empty."



if __name__ == '__main__':
    extractor = EdxProblemExtractor(split=False)
    extractor.export()
