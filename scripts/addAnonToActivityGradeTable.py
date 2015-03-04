#!/usr/bin/env python
'''
Created on Jan 3, 2014

@author: paepcke

Used by cronRefreshActivityGrade.sh, which
prepares a temp table with information from
courseware_studentmodule (see below for detail).
This script processes the information in that
temp table, and addes the result to table
ActivityGrade. In particular, the following
happens here:

- fill in resource_display_name
- fill in anon_screen_name
- compute the percent_grade column
- parse the original 'state' column's JSON and replace with plusses/minuses


Assumptions:
    o (Optionally) TEMPORARY table StudentmoduleExcerpt holds 
       the result of the following query to courseware_studentmodule:

    	 SET @emptyStr:='';
    	 SET @floatPlaceholder:=-1.0;
    	 SET @intPlaceholder:=-1;
    	 USE edxprod;
    	 CREATE TABLE StudentmoduleExcerpt  (activity_grade_id INT PRIMARY KEY) ENGINE=myISAM \
    	 SELECT id AS activity_grade_id, \
    	        student_id, \
    	        course_id AS course_display_name, \
    	        grade, \
    	        max_grade, \
    	        @floatPlaceholder AS percent_grade, \
    	        state AS parts_correctness, \
    	        @emptyStr AS answers, \
    	        @intPlaceholder AS num_attempts, \
    	        created AS first_submit, \
    	        modified AS last_submit, \
    	        module_type, \
    	        @emptyStr AS anon_screen_name, \
    	        @emptyStr AS resource_display_name, \
    	        module_id
    	 FROM courseware_studentmodule \
    	 WHERE modified > '"$LATEST_DATE"'; \" \

'''
import argparse
import getpass
import itertools
import os
import re
import sys

from pymysql_utils.pymysql_utils import MySQLDB

# Add json_to_relation source dir to $PATH
# for duration of this execution:
source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir
from utils import Utils

class AnonAndModIDAdder(object):

    # Number of rows to process in memory
    # before writing to ActivityGrade:
    BATCH_SIZE = 10000
    
    # For explanation of the following regex patterns,
    # see header comment of parseStateJSON:
    SOLUTION_RESULT_PATTERN  = re.compile(r'[^"]*correctness": "([^"]*)')
    SOLUTION_ANSWERS_PATTERN = re.compile(r'[^:]*: "([^"]*)"')
    
    ACTIVITY_GRADE_COL_NAMES = [
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
    
    # Indices into tuples from StudentmoduleExcerpt:
    STUDENT_INT_ID_INDEX = 1
    GRADE_INDEX = 3
    MAX_GRADE_INDEX = 4
    PERCENT_GRADE_INDEX = 5
    PARTS_CORRECTNESS_INDEX = 6
    ANSWERS_INDEX = 7
    NUM_ATTEMPTS_INDEX = 8
    ANON_SCREEN_NAME_INDEX = 12
    RESOURCE_DISPLAY_NAME_INDEX = 13
    MODULE_ID_INDEX = 14
    
    
    def __init__(self, uid, pwd, db='Edx', testing=False):
        '''
        ****** Update this comment header
        Make connection to MySQL wrapper.
        @param uid: MySQL user under which to log in. Assumed to be other than None
        @type uid: String
        @param pwd: MySQL password for user uid. May be None.
        @type pwd: {String | None}
        '''
        self.db = db
        if pwd is None:
            self.mysqldbStudModule = MySQLDB(user=uid, db=db)
        else:
            self.mysqldbStudModule = MySQLDB(user=uid, passwd=pwd, db=db)
        # Create a string with the parameters of the SELECT call,
        # (activity_grade_id,student_id,...):
        self.colSpec = AnonAndModIDAdder.ACTIVITY_GRADE_COL_NAMES[0]
        for colName in AnonAndModIDAdder.ACTIVITY_GRADE_COL_NAMES[1:]:
            self.colSpec += ',' + colName
    
        self.cacheIdInt2Anon(testing)
        self.pullRowByRow()

    def cacheIdInt2Anon(self, testing=False):
        '''
        Builds a dict to map platform integers to anon_screen_names. 
        
    :param testing: If set true, then all tables are assumed to be in MySQL DB unittest.
        :type testing: boolean
        '''
        self.int2AnonCache = {}
        if testing:
            queryIt = self.mysqldbStudModule.query("SELECT student_id AS user_int_id, \
                                                           unittest.UserGrade.anon_screen_name \
                                                      FROM unittest.StudentmoduleExcerpt LEFT JOIN unittest.UserGrade \
                                                        ON unittest.StudentmoduleExcerpt.student_id = unittest.UserGrade.user_int_id;")
        else:
            queryIt = self.mysqldbStudModule.query("SELECT student_id AS user_int_id, \
                                                           EdxPrivate.UserGrade.anon_screen_name \
                                                      FROM edxprod.StudentmoduleExcerpt LEFT JOIN EdxPrivate.UserGrade \
                                                        ON edxprod.StudentmoduleExcerpt.student_id = EdxPrivate.UserGrade.user_int_id;")
        for user_int_id, anon_screen_name in queryIt:
            self.int2AnonCache[user_int_id] = anon_screen_name;

    def pullRowByRow(self):
        rowBatch = []
        theQuery = "SELECT activity_grade_id,student_id,\
                    	   course_display_name,grade,max_grade,percent_grade,\
                    	   parts_correctness,answers,num_attempts,first_submit,\
                    	   last_submit,module_type,anon_screen_name,\
                    	   resource_display_name,module_id \
                    FROM edxprod.StudentmoduleExcerpt \
                    WHERE isTrueCourseName(course_display_name) = 1;"
        if self.db == 'unittest':
            queryIt = self.mysqldbStudModule.query("SELECT %s FROM unittest.StudentmoduleExcerpt;" % self.colSpec)
        else:
            #**********queryIt = self.mysqldbStudModule.query("SELECT %s FROM edxprod.StudentmoduleExcerpt;" % self.colSpec)
            queryIt = self.mysqldbStudModule.query(theQuery)
        for studmodTuple in queryIt:
            # Results return as tuples, but we need to change tuple items by index.
            # So must convert to list:
            studmodTuple = list(studmodTuple)
            # Resolve the module_id into a human readable resource_display_name:
            moduleID = studmodTuple[AnonAndModIDAdder.MODULE_ID_INDEX]
            studmodTuple[AnonAndModIDAdder.RESOURCE_DISPLAY_NAME_INDEX] = self.getResourceDisplayName(moduleID)
            
            # Compute the anon_screen_name:
            studentIntId = studmodTuple[AnonAndModIDAdder.STUDENT_INT_ID_INDEX]
            try:
                studmodTuple[AnonAndModIDAdder.ANON_SCREEN_NAME_INDEX] = self.int2AnonCache[studentIntId]
            except TypeError:
                studmodTuple[AnonAndModIDAdder.ANON_SCREEN_NAME_INDEX] = ''

            # Pick grade and max_grade out of the row,
            # compute the percentage, and place that 
            # back into the row in col 
            grade = studmodTuple[AnonAndModIDAdder.GRADE_INDEX]
            max_grade = studmodTuple[AnonAndModIDAdder.MAX_GRADE_INDEX]
            percent_grade = 'NULL'
            try:
                percent_grade = round((int(grade) * 100.0/ int(max_grade)), 2)
            except:
                pass
            studmodTuple[AnonAndModIDAdder.PERCENT_GRADE_INDEX] = str(percent_grade)

            # Parse 'state' column from JSON and put result into plusses/minusses column:
            (partsCorrectness, answers, numAttempts) = \
                self.parseStateJSON(studmodTuple[AnonAndModIDAdder.PARTS_CORRECTNESS_INDEX])
            
            studmodTuple[AnonAndModIDAdder.PARTS_CORRECTNESS_INDEX] = partsCorrectness
            studmodTuple[AnonAndModIDAdder.ANSWERS_INDEX] = ','.join(answers)
            studmodTuple[AnonAndModIDAdder.NUM_ATTEMPTS_INDEX] = numAttempts
            
            rowBatch.append(studmodTuple)
            if len(rowBatch) >= AnonAndModIDAdder.BATCH_SIZE:
                self.mysqldbStudModule.bulkInsert('ActivityGrade', AnonAndModIDAdder.ACTIVITY_GRADE_COL_NAMES, rowBatch)
                rowBatch = []
        if len(rowBatch) > 0:
            self.mysqldbStudModule.bulkInsert('ActivityGrade', AnonAndModIDAdder.ACTIVITY_GRADE_COL_NAMES, rowBatch)
    
    def getResourceDisplayName(self, moduleID):
        moduleName = Utils.getModuleNameFromID(moduleID)
        return moduleName


    def parseStateJSON(self, jsonStateStr, srcTableName='courseware_studentmodule'):
        '''
        Given the 'state' column from a courseware_studentmodule
        column, return a 3-tuple: (plusMinusStr, answersArray, numAttempts)
        The plusMinusStr will be a string of '+' and '-'. A
        plus means that the problem solution part of an assignment
        submission was correct; a '-' means it was incorrect. The
        plus/minus indicators are arranged in the order of the problem
        subparts; like '++-' for a three-part problem in which the student
        got the first two correct, the last one incorrect.
        
        The answersArray will be an array of answers to the corresponding
        problems, like ['choice_0', 'choice_1'].
        
        Input for a problem solution with two parts looks like this::
            {   		           
    		 "correct_map": {
    		   "i4x-Medicine-HRP258-problem-8dd11b4339884ab78bc844ce45847141_2_1": {
    		     "hint": "",
    		     "hintmode": null,
    		     "correctness": "correct",
    		     "npoints": null,
    		     "msg": "",
    		     "queuestate": null
    		   },
    		   "i4x-Medicine-HRP258-problem-8dd11b4339884ab78bc844ce45847141_3_1": {
    		     "hint": "",
    		     "hintmode": null,
    		     "correctness": "correct",
    		     "npoints": null,
    		     "msg": "",
    		     "queuestate": null
    		   }
    		 },
    		 "input_state": {
    		   "i4x-Medicine-HRP258-problem-8dd11b4339884ab78bc844ce45847141_2_1": {
    		     
    		   },
    		   "i4x-Medicine-HRP258-problem-8dd11b4339884ab78bc844ce45847141_3_1": {
    		     
    		   }
    		 },
    		 "attempts": 3,
    		 "seed": 1,
    		 "done": true,
    		 "student_answers": {
    		   "i4x-Medicine-HRP258-problem-8dd11b4339884ab78bc844ce45847141_2_1": "choice_3",
    		   "i4x-Medicine-HRP258-problem-8dd11b4339884ab78bc844ce45847141_3_1": "choice_0"
    		 }
        }   		        
        
        This structure is ugly enough even when imported into a dict
        via json.loads() that a regular expression solution is faster.
        Three regexp are used:
          - SOLUTION_RESULT_PATTERN  = re.compile(r'[^"]*correctness": "([^"]*)')
              looks for the correctness entries: 'correct', 'incorrect'.
              First the regex throws away front parts the JSON that do not consist
              of 'correctness": '. That's the '"[^"]*correctness": "' par
              of the regex
              Next, a capture group grabs all letters that are not a double
              quote. That's the '([^"]*)' part of the regex. Those capture
              groups will contain the words 'correct' or 'incorrect'.
               
          - SOLUTION_ANSWERS_PATTERN = re.compile(r'[^:]*: "([^"]*)"')
              looks for the answers themselves: 'choice_0', etc. This pattern
              assumes that we first cut off from the JSON all the front part up
              to 'student_answers":'. The regex operates over the rest:
              The '[^:]*: "' skips over all text up to the next colon, followed
              by a space and opening double quote. The capture group grabs the 
              answer, as in 'choice_0'. 
        
        @param jsonStateStr:
        @type jsonStateStr:
        @param srcTableName:
        @type srcTableName:
        @return: plus/minus string, array of participant's answers, number of attempts. 
               If number of attempts is -1 the row was not a problem statement,
               or number of attempts was otherwise unavailable.
        @rtype: (string, [string], int)
        '''
        successResults = ''
        # The following badAnswers array is filled with
        # just the wrong answers. It's maintained, but
        # not currently returned, b/c users didn't feel
        # they needed it.
        badAnswers = [] 
        answers = []
        numAttempts = -1
        
        # Many state entries are not student problem result 
        # submissions, but of the form "{'postion': 4}".
        # Weed those out:
        if jsonStateStr.find('correct_map') == -1:
            #return (successResults, badAnswers, numAttempts)
            return (successResults, answers, numAttempts)
        
        # Get the ['correct','incorrect',...] array;
        # we'll use it later on:
        allSolutionResults = AnonAndModIDAdder.SOLUTION_RESULT_PATTERN.findall(jsonStateStr)
        
        
        # Next, get all the answers themselves.
        # Chop off all the JSON up to 'student_answers":':
        chopTxtMarker = 'student_answers":'
        chopPos = jsonStateStr.find(chopTxtMarker)
        if chopPos == -1:
            # Couldn't find the student answers; fine;
            #return (successResults, badAnswers, numAttempts)
            return (successResults, answers, numAttempts)
        else:
            # Get left with str starting at '{' in
            # "student_answers": {
            #   "i4x-Medicine-HRP258-problem-8dd11b4339884ab78bc844ce45847141_2_1": "choice_3",
            #   "i4x-Medicine-HRP258-problem-8dd11b4339884ab78bc844ce45847141_3_1": "choice_0"
            restJSON = jsonStateStr[chopPos+len(chopTxtMarker):]
            # ... and put the regex to work:
            answers = AnonAndModIDAdder.SOLUTION_ANSWERS_PATTERN.findall(restJSON)
        
        # Find number of attempts:
        # Find '"attempts": 3,...':
        chopTxtMarker = '"attempts": '
        chopPos = jsonStateStr.find(chopTxtMarker)
        if chopPos > 0:
            upToNum = jsonStateStr[chopPos+len(chopTxtMarker):]
            try:
                # The 'str' part of 'str(upToNum)' is needed b/c
                # the JSON is unicode, and isdigit() barfs when given
                # unicode:
                numAttempts = int("".join(itertools.takewhile(str.isdigit, str(upToNum))))
            except ValueError:
                # Couldn't find the number of attempts.
                # Just punt.
                pass
            except TypeError:
                # Unicode garbage, clearly not a digit
                pass
                
        # Go through the ['correct','incorrect',...] array,
        # and take two actions: if correct, add a '+' to
        # the successResults str; if 'incorrect' then add
        # a '-' to successResults, and transfer the 'bad'
        # answer to the badAnswers array:
        
        for (i, correctness) in enumerate(allSolutionResults):
            if  correctness == 'correct':
                successResults += '+'
            else:
                successResults += '-'
                try:
                    badAnswers.append(answers[i])
                except IndexError:
                    badAnswers.append('<unknown>')

        #return (successResults, badAnswers, numAttempts)
        return (successResults, answers, numAttempts)
        
      # Commented, because replaced by an in-memory cache:
#     def getAnonFromIntID(self, intStudentId):
#         theAnonName = ''
#         for anonName in self.mysqldbStudModule.query("SELECT Edx.idInt2Anon(%d)" % intStudentId):
#             if anonName is not None:
#                 # Results come back as tuples; singleton tuple in this case:
#                 return anonName[0]
#             else:
#                 theAnonName

if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog=os.path.basename(sys.argv[0]), formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-u', '--user',
                        action='store',
                        help='User ID that is to log into MySQL. Default: the user who is invoking this script.')
    parser.add_argument('-p', '--password',
                        action='store_true',
                        help='request to be asked for pwd for operating MySQL;\n' +\
                             '    default: content of scriptInvokingUser$Home/.ssh/mysql if --user is unspecified,\n' +\
                             '    or, if specified user is root, then the content of scriptInvokingUser$Home/.ssh/mysql_root.')
    parser.add_argument('-w', '--givenPass',
                        dest='givenPass',
                        help='Mysql password. Default: see --password. If both -p and -w are provided, -w is used.'
                        )
    args = parser.parse_args();

    if args.user is None:
        user = getpass.getuser()
    else:
        user = args.user
        
    if args.givenPass is not None:
        pwd = args.givenPass
    else:
        if args.password:
            pwd = getpass.getpass("Enter %s's MySQL password on localhost: " % user)
        else:
            # Try to find pwd in specified user's $HOME/.ssh/mysql
            currUserHomeDir = os.getenv('HOME')
            if currUserHomeDir is None:
                pwd = None
            else:
                # Don't really want the *current* user's homedir,
                # but the one specified in the -u cli arg:
                userHomeDir = os.path.join(os.path.dirname(currUserHomeDir), user)
                try:
                    if user == 'root':
                        with open(os.path.join(currUserHomeDir, '.ssh/mysql_root')) as fd:
                            pwd = fd.readline().strip()
                    else:
                        with open(os.path.join(userHomeDir, '.ssh/mysql')) as fd:
                            pwd = fd.readline().strip()
                except IOError:
                    # No .ssh subdir of user's home, or no mysql inside .ssh:
                    pwd = None
                    
    #************
    #print('UID:'+user)
    #print('PWD:'+str(pwd))
    #sys.exit()
    #************
                    
    anonAdder = AnonAndModIDAdder(user, pwd)
