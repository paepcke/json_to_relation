#!/usr/bin/env python
'''
Created on Jan 3, 2014

@author: paepcke

Used by cronRefreshActivityGrade.sh.
Accesses a TSV file of the ActivityGrade table being built. This TSV
file was previously extracted from the courseware_studentmodule at S3 by the
calling script cronRefreshActivityGrade.sh.

This class appends 'anon_sceen_name' to the header line in
the TSV file, and inserts 'percent_grade' after the 'max_grade'
column name.

For each row in the TSV file, the class then extracts the 
student_id column and computes the corresponding anonymization 
hash. That hash is appended as an additional column to the 
TSV row. 

The class then grabs the module_id value from the TSV row, and 
replaces it with a human-readable string.

Finally, the class computes the percentage grade using the
grade and max_grade columns, and inserts the result after the
max_grade column value

Assumptions:
   o The TSV file has the following schema::
   
        activity_grade_id, student_id, course_id, grade, max_grade, parts_correctness, module_type, resource_display_name
        
     in that order.
     The activity_grade_id is renamed from the original 'id' in courseware_studentmodule
     the resource_display_name is renamed from 'module_id' in courseware_studentmodule.
   o The TSV file's resource_display_name contains the module_id string
     from courseware_studentmodule. Example::
         i4x://Medicine/HRP258/sequential/d62f01652c82413395189f660fa0fe8a
   o The TSV file's anon_screen_name column is empty. 

When we are done with a row, its schema will be::

        activity_grade_id, student_id, course_id, grade, max_grade, parts_correctness, wrong_answers, numAttempts, module_type, resource_display_name

'''
import argparse
import getpass
import os
import string
import sys
import tempfile
import json
import collections
import re
import itertools

# Add json_to_relation source dir to $PATH
# for duration of this execution:
source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir

from mysqldb import MySQLDB
from utils import Utils


class AnonAndModIDAdder(object):
    
    # For explanation of the following regex patterns,
    # see header comment of parseStateJSON:
    SOLUTION_RESULT_PATTERN  = re.compile(r'[^"]*correctness": "([^"]*)')
    SOLUTION_ANSWERS_PATTERN = re.compile(r'[^:]*: "([^"]*)"')
    
    # Zero-origin column positions in TSV file:
    STUDENT_ID_COL_POS = 1
    GRADE_COL_POS = 3
    MAX_GRADE_COL_POS = 4    
    
    # In TSV the following contains the JSON 
    # content of the 'state' col, but we will
    # replace that with the plus/minus signs;
    # therefore the col name 'parts_correctness':
    PARTS_CORRECTNESS_COL_POS = 5
    
    # In TSV the following contains the 
    # content of column module_id, but below
    # we convert that id to a human-readable
    # string, therefore the col name resource_display_name:
    RESOURCE_DISPLAY_NAME_COL_POS = 9
    
    # Position before which the newly computed
    # percentage grade will be inserted:
    NEW_PERCENT_GRADE_COL_POS = 5
    
    def __init__(self, uid, pwd, tsvFileName):
        '''
        ****** Update this comment header
        Make connection to MySQL wrapper.
        @param uid: MySQL user under which to log in. Assumed to be other than None
        @type uid: String
        @param pwd: MySQL password for user uid. May be None.
        @type pwd: {String | None}
        @param tsvFileName: name of TSV file where rows of edxprod's
               certificates_generatedcertificate table are located.
               It is assumed that the caller verified existence and
               readability of this file.
        @type String
        '''

        if not os.access(tsvFileName, os.R_OK):
            print('Courseware_studentmodule tsv file does not exist: %s' % str(tsvFileName))
            return
        
        self.uid = uid
        self.pwd = pwd
        self.tsvFileName = tsvFileName
        
        if pwd is None:
            self.mysqldb = MySQLDB(user=uid, db='EdxPrivate')
        else:
            self.mysqldb = MySQLDB(user=uid, passwd=pwd, db='EdxPrivate')

    def computeAndAddFileBased(self):
        '''
        The heavy lifting: reads TSV rows from the courseware_studentmodule one by one 
        into memory. Makes two changes to each row: The last column, which 
        is populated with the courseware_studentmodule's module_id value is
        replaced by a human-readable value, or an empty string if there is no
        human-readable equivalent (as is the case for module_type 'course').
        Additionally, the courseware_studentmodule's integer student_id
        is use to generate an equivalent hash value, which is added as an
        additional column at the end of each row. 
        
        Once these changes are made, the row is written to a temp file.
        When all rows have been processed that way, the temp file is
        'mv'ed to the original file.
        '''
        # If delete is not set to False in the following,
        # then the rename() further down will fail, b/c it
        # closes the tmp file first:
        self.tmpFd = tempfile.NamedTemporaryFile(dir=os.path.dirname(self.tsvFileName), 
                                            suffix='studMod',
                                            delete=False)
        # Modify the first line, the column names,
        # to conform to what we'll do to the rest
        # of the TSV file's data:
        with open(self.tsvFileName, 'r') as tsvFd:
            headerRow = tsvFd.readline()
        
        colNames = ['activity_grade_id', 
                    'student_id', 
                    'course_id', 
                    'grade', 
                    'max_grade', 
                    'parts_correctness', 
                    'wrong_answers', 
                    'numAttempts',
                    'first_submit',
                    'last_submit',
                    'module_type', 
                    'resource_display_name']
        self.tmpFd.write(string.join(colNames, '\t'))

        # We tested for self.tsvFileName being readable
        # in __init__() msg; so no need to do it here:
        tsvFd = open(self.tsvFileName, 'r')
        # Read and discard the header row we dealt
        # with above:
        tsvFd.readline()
        
        for row in tsvFd:
            colVals = row.split('\t')
            # Each line's last TSV value element has
            # a \n glued to it. Get rid of that:
            colVals[-1] = colVals[-1].strip()
            
            # Pick the int-typed student ID out of the row:
            intStudentId = colVals[AnonAndModIDAdder.STUDENT_ID_COL_POS]
            # Get the equivalent anon_screen_name:
            try:
                theAnonName = self.getAnonFromIntID(int(intStudentId))
            except TypeError:
                theAnonName = ''
            
            # Get the module_id:
            moduleID = colVals[AnonAndModIDAdder.RESOURCE_DISPLAY_NAME_COL_POS]
            moduleName = Utils.getModuleNameFromID(moduleID)
            
            # Replace the existing module_id col with the human-readable 
            # moduleName; the column was already called
            # resource_display_name when cronRefreshActivityGradeCrTable.sql
            # was sourced into MySQL by cronRefreshActivityGrade.sh.
            colVals[AnonAndModIDAdder.RESOURCE_DISPLAY_NAME_COL_POS] = moduleName
            
            # Pick grade and max_grade out of the row,
            # compute the percentage, and *insert* that 
            # into the array at NEW_Percent_grade_COL_POS:
            grade = colVals[AnonAndModIDAdder.GRADE_COL_POS]
            max_grade = colVals[AnonAndModIDAdder.MAX_GRADE_COL_POS]
            percent_grade = 'NULL'
            try:
                percent_grade = round((int(grade) * 100.0/ int(max_grade)), 2)
            except:
                pass
            colVals.insert(AnonAndModIDAdder.NEW_PERCENT_GRADE_COL_POS, str(percent_grade))

            # Pick the JSON of the courseware_studentmodule's
            # 'state' col from the TSV row, and replace it
            # with the plusses and minusses. The '+1' accounts
            # for the percent_grade we just inserted above: 
            (partsCorrectness, wrongAnswers, numAttempts) = \
                self.parseStateJSON(colVals[AnonAndModIDAdder.PARTS_CORRECTNESS_COL_POS + 1])
            colVals[AnonAndModIDAdder.PARTS_CORRECTNESS_COL_POS + 1] = partsCorrectness
            # Next *insert* the wrongAnswers and numAttempts as
            # new columns in front of the RESOURCE_DISPLAY_NAME_COL_POS:
            colVals.insert(AnonAndModIDAdder.RESOURCE_DISPLAY_NAME_COL_POS, ','.join(wrongAnswers))
            # The +1 below accounts for the wrongAnswers we just inserted:
            colVals.insert(AnonAndModIDAdder.RESOURCE_DISPLAY_NAME_COL_POS + 1, str(numAttempts))
            
            # Append the anon name
            # to the end of the .tsv row, where it will end up 
            # as column anon_screen_name
            # in table Edx.ActivityGrade:
            colVals.append('%s\n' % theAnonName)

            # Write the array into the tmp file:
            try:
                self.tmpFd.write(string.join(colVals, '\t'))
            except UnicodeEncodeError:
                strToWrite = string.join(colVals, '\t')
                self.tmpFd.write(Utils.makeInsertSafe(strToWrite))
        
        #self.tmpFd.flush()
        self.tmpFd.close()        
        # Now mv the temp file into the tsv file, replacing it:
        os.rename(self.tmpFd.name, self.tsvFileName)

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
        '''
        successResults = ''
        badAnswers = []
        numAttempts = -1
        
        # Many state entries are not student problem result 
        # submissions, but of the form "{'postion': 4}".
        # Weed those out:
        if jsonStateStr.find('correct_map') == -1:
            return (successResults, badAnswers, numAttempts)
        
        # Get the ['correct','incorrect',...] array;
        # we'll use it later on:
        allSolutionResults = AnonAndModIDAdder.SOLUTION_RESULT_PATTERN.findall(jsonStateStr)
        
        
        # Next, get all the answers themselves.
        # Chop off all the JSON up to 'student_answers":':
        chopTxtMarker = 'student_answers":'
        chopPos = jsonStateStr.find(chopTxtMarker)
        if chopPos == -1:
            # Couldn't find the student answers; fine;
            return (successResults, badAnswers, numAttempts)
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
               numAttempts = int("".join(itertools.takewhile(str.isdigit, upToNum)))
           except ValueError:
                # Couldn't find the number of attempts.
                # Just punt.
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

        return (successResults, badAnswers, numAttempts)
        
    def getAnonFromIntID(self, intStudentId):
        theAnonName = ''
        for anonName in self.mysqldb.query("SELECT idInt2Anon(%d)" % intStudentId):
            if anonName is not None:
                # Results come back as tuples; singleton tuple in this case:
                return anonName[0]
            else:
                theAnonName

    
    def cleanup(self):
        try:
            os.remove(self.tmpFd.name)
        except:
            pass

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
    parser.add_argument('tsvFileName',
                        help='File containing the TSV of the certificates_generatedcertificate table obtained from edxprod'
                        )  
    args = parser.parse_args();

    if not os.access(args.tsvFileName, os.R_OK):
        print("File %s is not readable or does not exist." % args.tsvFileName)
        parser.print_usage()
        sys.exit()
        
    tsvFileName = args.tsvFileName

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
                    
    anonAdder = AnonAndModIDAdder(user, pwd, tsvFileName)
    try:
        anonAdder.computeAndAddFileBased()
    finally:
        anonAdder.cleanup()
    
