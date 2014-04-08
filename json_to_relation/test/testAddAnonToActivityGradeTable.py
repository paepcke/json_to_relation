'''
Created on Apr 7, 2014

@author: paepcke
'''
from collections import OrderedDict
import datetime
import subprocess
import unittest

from addAnonToActivityGradeTable import AnonAndModIDAdder
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
    state1 = ' {"correct_map": {"i4x-Medicine-HRP258-problem-0c6cf38317be42e0829d10cc68e7451b_2_1": {"hint": "", "hintmode": null, "correctness": "correct", "npoints": null, "msg": "", "queuestate": null}}, "input_state": {"i4x-Medicine-HRP258-problem-0c6cf38317be42e0829d10cc68e7451b_2_1": {}}, "attempts": 1, "seed": 1, "done": true, "student_answers": {"i4x-Medicine-HRP258-problem-0c6cf38317be42e0829d10cc68e7451b_2_1": "choice_1"}} '
    state2 = '{"correct_map": {}, "seed": 1, "student_answers": {}, "input_state": {"i4x-Medicine-HRP258-problem-0c6cf38317be42e0829d10cc68e7451b_2_1": {}}}'
    state3 = '{"position": 1}'
    
    modid1 = 'i4x://Carnegie/2013/chapter/1fee4bc0d5384cb4aa7a0d65f3ac5d9b'
    modid2 = 'i4x://Carnegie/2013/chapter/5d08d2bae3ac4047bf5abe1d8dd16ac3'
    modid3 = 'i4x://Carnegie/2013/chapter/9a9455cd30bd4c14819542bcd11bfcf8'
    studentmoduleExcerptValues = \
                [
                [0,1,'myCourse',3,10,-1.0,state1,'',-1,'2014-01-10 04:10:45','2014-02-10 10:14:40','modtype1','','',modid1],
                [1,2,'myCourse',5,10,-1.0,state2,'',-1,'2014-01-10 11:30:23','2014-02-10 14:30:12','modtype2','','',modid2],                
                [2,3,'yourCourse',8,10,-1.0,state3,'',-1,'2014-01-10 18:34:12','2014-02-10 19:10:33','modtype2','','',modid3]                                
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
            AnonAndModIDAdder('unittest', '', db='unittest')
            self.db = MySQLDB(user='unittest', passwd='', db='unittest')
            for rowNum, row in enumerate(self.db.query('SELECT %s FROM ActivityGrade;' % self.allColNames)):
                #print(row)
                if rowNum == 0:
                    self.assertEqual((0, 1, 'myCourse', '3', 10.0, 30.0, '', '', -1, datetime.datetime(2014, 1, 10, 4, 10, 45), datetime.datetime(2014, 2, 10, 10, 14, 40), 'modtype1', '', 'Guided Walkthrough', 'i4x://Carnegie/2013/chapter/1fee4bc0d5384cb4aa7a0d65f3ac5d9b'), 
                                     row)
                elif rowNum == 1:
                    self.assertEqual((1, 2, 'myCourse', '5', 10.0, 50.0, '', '', -1, datetime.datetime(2014, 1, 10, 11, 30, 23), datetime.datetime(2014, 2, 10, 14, 30, 12), 'modtype2', '', 'Evaluation', 'i4x://Carnegie/2013/chapter/5d08d2bae3ac4047bf5abe1d8dd16ac3'),
                                     row)
                elif rowNum == 2:
                    self.assertEqual((2, 3, 'yourCourse', '8', 10.0, 80.0, '', '', -1, datetime.datetime(2014, 1, 10, 18, 34, 12), datetime.datetime(2014, 2, 10, 19, 10, 33), 'modtype2', '', 'Introduction', 'i4x://Carnegie/2013/chapter/9a9455cd30bd4c14819542bcd11bfcf8'),
                                     row)         
        finally:
            self.db.close()
        

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testAddAnonToActivityTable']
    unittest.main()