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
   o The TSV file has the following schema:
   
        activity_grade_id, student_id, course_id, grade, max_grade, module_type, resource_display_name
        
     in that order.
     The activity_grade_id is renamed from the original 'id' in courseware_studentmodule
     the resource_display_name is renamed from 'module_id' in courseware_studentmodule.
   o The TSV file's resource_display_name contains the module_id string
     from courseware_studentmodule. Example::
         i4x://Medicine/HRP258/sequential/d62f01652c82413395189f660fa0fe8a
   o The TSV file's anon_screen_name column is empty. 

'''
import argparse
import getpass
import os
import string
import sys
import tempfile

from mysqldb import MySQLDB
from utils import Utils

class AnonAndModIDAdder(object):
    
    # Zero-origin column positions in TSV file:
    STUDENT_ID_COL_POS = 1
    GRADE_COL_POS = 3
    MAX_GRADE_COL_POS = 4
    MODULE_ID_COL_POS = 6
    
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
        # Modify the first line, the column names by adding the
        # new column-to-be: anon_screen_name:
        with open(self.tsvFileName, 'r') as tsvFd:
            headerRow = tsvFd.readline()
        colNames = headerRow.split('\t')
        # Take off the \n after the last col,
        # because we'll append the anon_screen_name header
        # col name:
        colNames[-1] = colNames[-1].strip()
        colNames.insert(AnonAndModIDAdder.NEW_PERCENT_GRADE_COL_POS, 'percent_grade')
        colNames.append('anon_screen_name\n') 
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
            moduleID = colVals[AnonAndModIDAdder.MODULE_ID_COL_POS]
            moduleName = Utils.getModuleNameFromID(moduleID)
            
            # Replace the existing module_id col with the human-readable 
            # moduleName; the column was already called
            # resource_display_name when cronRefreshActivityGradeCrTable.sql
            # was sourced into MySQL by cronRefreshActivityGrade.sh.
            colVals[AnonAndModIDAdder.MODULE_ID_COL_POS] = moduleName
            
            # Pick grade and max_grade out of the row,
            # compute the percentage, and *insert* that 
            # into the array at NEW_Percent_grade_COL_POS:
            grade = colVals[AnonAndModIDAdder.GRADE_COL_POS]
            max_grade = colVals[AnonAndModIDAdder.MAX_GRADE_COL_POS]
            percent_grade = 'NULL'
            try:
                percent_grade = int(grade) * 100.0/ int(max_grade)
            except:
                pass
            colVals.insert(AnonAndModIDAdder.NEW_PERCENT_GRADE_COL_POS, str(percent_grade)) 
            
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
    
