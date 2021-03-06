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
Created on Apr 7, 2014

@author: paepcke

NOTE: Requires existence of database 'unittest' and user 'unittest' without pwd
       and ALL privileges. (Could get away with fewer privileges, but who cares. 

'''
from collections import OrderedDict
import datetime
import unittest

from scripts.addAnonToActivityGradeTable import AnonAndModIDAdder
from pymysql_utils.pymysql_utils import MySQLDB


class TestAddAnonToActivityGrade(unittest.TestCase):

    studentmoduleExcerptSchema = OrderedDict({
                'activity_grade_id' : 'INT',
                'student_id' : 'INT',
                'course_display_name' : 'VARCHAR(255)',
                'grade' : 'VARCHAR(5)',
                'max_grade' : 'DOUBLE',
                'percent_grade' : 'DOUBLE',
                'parts_correctness' : 'VARCHAR(255)',
                'answers' : 'VARCHAR(255)',
                'num_attempts' : 'INT',
                'first_submit' : 'DATETIME',
                'last_submit' : 'DATETIME',
                'module_type' : 'VARCHAR(255)',
                'anon_screen_name' : 'VARCHAR(40)',
                'resource_display_name' : 'VARCHAR(255)',
                'module_id' : 'VARCHAR(255)'
                })
    
    studentmoduleExcerptColNames = [
                'activity_grade_id',
                'student_id',
                'course_display_name',
                'grade',
                'max_grade',
                'percent_grade',
                'parts_correctness',
                'answers',
                'num_attempts',
                'first_submit',
                'last_submit',
                'module_type',
                'anon_screen_name',
                'resource_display_name',
                'module_id'
                ]
    userGradeExcerptSchema = OrderedDict({
                              'name' : 'varchar(255)',
                              'screen_name' : 'varchar(255)',
                              'grade' : 'int',
                              'course_id' : 'varchar(255)',
                              'distinction' : 'tinyint',
                              'status' : 'varchar(50)',
                              'user_int_id' : 'int',
                              'anon_screen_name' : 'varchar(40)'
                              })
    
    userGradeExcerptColNames = [
                                  'name',
                                  'screen_name',
                                  'grade',
                                  'course_id',
                                  'distinction',
                                  'status',
                                  'user_int_id',
                                  'anon_screen_name'
                                  ]    
    
    state1 = ' {"correct_map": {"i4x-Medicine-HRP258-problem-0c6cf38317be42e0829d10cc68e7451b_2_1": {"hint": "", "hintmode": null, "correctness": "correct", "npoints": null, "msg": "", "queuestate": null}}, "input_state": {"i4x-Medicine-HRP258-problem-0c6cf38317be42e0829d10cc68e7451b_2_1": {}}, "attempts": 1, "seed": 1, "done": true, "student_answers": {"i4x-Medicine-HRP258-problem-0c6cf38317be42e0829d10cc68e7451b_2_1": "choice_1"}} '
    state2 = '{"correct_map": {}, "seed": 1, "student_answers": {}, "input_state": {"i4x-Medicine-HRP258-problem-0c6cf38317be42e0829d10cc68e7451b_2_1": {}}}'
    state3 = '{"position": 1}'
    
    modid1 = 'i4x://Carnegie/2013/chapter/1fee4bc0d5384cb4aa7a0d65f3ac5d9b'
    modid2 = 'i4x://Carnegie/2013/chapter/5d08d2bae3ac4047bf5abe1d8dd16ac3'
    modid3 = 'i4x://Carnegie/2013/chapter/9a9455cd30bd4c14819542bcd11bfcf8'
    studentmoduleExcerptValues = \
                [
                [0,1,'myCourse',3,10,-1.0,state1,'',-1,'2014-01-10 04:10:45','2014-02-10 10:14:40','modtype1','abc','Guided Walkthrough',modid1],
                [1,2,'myCourse',5,10,-1.0,state2,'',-1,'2014-01-10 11:30:23','2014-02-10 14:30:12','modtype2','def','Evaluation',modid2],                
                [2,3,'yourCourse',8,10,-1.0,state3,'',-1,'2014-01-10 18:34:12','2014-02-10 19:10:33','modtype2','ghi','Introduction',modid3]                                
               ]
                
    userGradeExcerptValues = \
                [
                ['John Doe','myScreenName',0,'engineering/myCourse/summer2014',0,'notpassing',1,'abc'],
                ['Jane Silver','herScreenName',100,'engineering/myCourse/summer2014',1,'passing',2,'def']
               ]
                

    def setUp(self):
        self.allColNames = TestAddAnonToActivityGrade.studentmoduleExcerptColNames[0]
        for colName in  TestAddAnonToActivityGrade.studentmoduleExcerptColNames[1:]:
            self.allColNames += ',' + colName
        
        self.db = MySQLDB(user='unittest', passwd='', db='unittest')
        self.db.dropTable('StudentmoduleExcerpt')
        self.db.createTable('StudentmoduleExcerpt', 
                            TestAddAnonToActivityGrade.studentmoduleExcerptSchema,
                            temporary=False)
                            #***temporary=True)
        self.db.bulkInsert('StudentmoduleExcerpt',
                           TestAddAnonToActivityGrade.studentmoduleExcerptColNames,
                           TestAddAnonToActivityGrade.studentmoduleExcerptValues)
        
        self.db.createTable('ActivityGrade', TestAddAnonToActivityGrade.studentmoduleExcerptSchema)
        # Make sure there isn't left over content (if the table existed):
        self.db.truncateTable('ActivityGrade')
        
        # Rudimentary UserGrade table:
        self.db.dropTable('UserGrade')
        self.db.createTable('UserGrade', 
                            TestAddAnonToActivityGrade.userGradeExcerptSchema,
                            temporary=False)
        self.db.bulkInsert('UserGrade',
                           TestAddAnonToActivityGrade.userGradeExcerptColNames,
                           TestAddAnonToActivityGrade.userGradeExcerptValues)
        
        
        self.db.close()
    def tearDown(self):
        self.db = MySQLDB(user='unittest', passwd='', db='unittest')
        # Can't drop tables: hangs
        #self.db.dropTable('StudentmoduleExcerpt')
        #self.db.dropTable('ActivityGrade')
        self.db.close()
        pass
        
        
    def testAddAnonToActivityTable(self):
        try:
            # Modify the fake courseware_studentmodule excerpt
            # to add anon_screen_name, computer plusses/minusses, 
            # compute grade percentage, etc:
            AnonAndModIDAdder('unittest', '', db='unittest', testing=True)
            self.db = MySQLDB(user='unittest', passwd='', db='unittest')
            for rowNum, row in enumerate(self.db.query('SELECT %s FROM ActivityGrade;' % self.allColNames)):
                #print(row)
                if rowNum == 0:
                    self.assertEqual((0, 1, 'myCourse', '3', 10.0, 30.0, '', '', -1, datetime.datetime(2014, 1, 10, 4, 10, 45), datetime.datetime(2014, 2, 10, 10, 14, 40), 'modtype1', 'abc', 'Guided Walkthrough', 'i4x://Carnegie/2013/chapter/1fee4bc0d5384cb4aa7a0d65f3ac5d9b'), 
                                     row)
                elif rowNum == 1:
                    self.assertEqual((1, 2, 'myCourse', '5', 10.0, 50.0, '', '', -1, datetime.datetime(2014, 1, 10, 11, 30, 23), datetime.datetime(2014, 2, 10, 14, 30, 12), 'modtype2', 'def', 'Evaluation', 'i4x://Carnegie/2013/chapter/5d08d2bae3ac4047bf5abe1d8dd16ac3'),
                                     row)
                elif rowNum == 2:
                    self.assertEqual((2, 3, 'yourCourse', '8', 10.0, 80.0, '', '', -1, datetime.datetime(2014, 1, 10, 18, 34, 12), datetime.datetime(2014, 2, 10, 19, 10, 33), 'modtype2', 'None', 'Introduction', 'i4x://Carnegie/2013/chapter/9a9455cd30bd4c14819542bcd11bfcf8'),
                                     row)         
        finally:
            self.db.close()
        
    def testCacheIdInt2Anon(self):
        try:
            infoAdder = AnonAndModIDAdder('unittest', '', db='unittest', testing=True)
            self.assertEqual({1:'abc', 2:'def', 3: None}, infoAdder.int2AnonCache)
        finally:
            self.db.close()

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testAddAnonToActivityTable']
    unittest.main()
