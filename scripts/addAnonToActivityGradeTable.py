#!/usr/bin/env python
'''
Created on Jan 3, 2014

@author: paepcke

Used by cronRefreshActivityGrade.sh.
Accesses a TSV file of the ActivityGrade table being built. This TSV
file was extracted from the courseware_studentmodule at S3. 
This script extracts the student_id 
column for each TSV row in turn. Computes the corresponding anonymization 
hash, and updates table Edx.ActivityGrade's anon_sceen_name column 
in the TSV file with that hash. Then grabs the module_id from the 
TSV row, and replaces it with a human-readable string.

'''
import argparse
import getpass
import os
import re
import string
import sys
import tempfile
import shutil

# Add json_to_relation source dir to $PATH
# for duration of this execution:
source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir

from modulestoreImporter import ModulestoreImporter
from mysqldb import MySQLDB


class AnonAndModIDAdder(object):
    
    # Isolate 32-bit hash inside any string, e.g.:
    #   i4x-Medicine-HRP258-videoalpha-7cd4bf0813904612bcd583a73ade1d54
    # or:
    #   input_i4x-Medicine-HRP258-problem-98ca37dbf24849debcc29eb36811cb68_3_1_choice_3'
    findHashPattern = re.compile(r'([a-f0-9]{32})')
    
    def __init__(self, uid, pwd, tsvFileName, studentIdColPos, moduleIdColPos):
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
        @param screenNamePos: Zero-origin position of the screen name column
               in the TSV file from certificates_generatedcertificate
        @type screenNamePos: int
        '''

        if not os.access(tsvFileName, os.R_OK):
            print('Courseware_studentmodule tsv file does not exist: %s' % str(tsvFileName))
            return
        
        self.uid = uid
        self.pwd = pwd
        self.tsvFileName = tsvFileName
        self.studentIdColPos = studentIdColPos
        self.moduleIdColPos = moduleIdColPos
        
        if pwd is None:
            self.mysqldb = MySQLDB(user=uid, db='EdxPrivate')
        else:
            self.mysqldb = MySQLDB(user=uid, passwd=pwd, db='EdxPrivate')

        # Create a facility that can map resource name hashes
        # to human-readable strings:
        self.hashMapper = None
        try:
            self.hashMapper = ModulestoreImporter(os.path.join(os.path.dirname(__file__),'../json_to_relation/data/modulestore_latest.json'), 
                                                  useCache=True) 
        except Exception as e:
            print("Could not create a ModulestoreImporter in addAnonToActivityGradesTable.py: %s" % `e`)

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
        tmpFd = tempfile.NamedTemporaryFile(dir=os.path.dirname(self.tsvFileName), 
                                            suffix='studMod',
                                            delete=False)
        # Modify the first line, the column names by adding the
        # new column-to-be: anon_screen_name:
        with open(self.tsvFileName, 'r') as tsvFd:
            headerRow = tsvFd.readline()
        colNames = headerRow.split('\t')
        colNames[-1] = colNames[-1].strip()
        colNames.append('anon_screen_name\n') 
        tmpFd.write(string.join(colNames, '\t'))

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
            intStudentId = colVals[self.studentIdColPos]
            # Get the equivalent anon_screen_name:
            try:
                theAnonName = self.getAnonFromIntID(int(intStudentId))
            except TypeError:
                theAnonName = ''
            
            # Get the module_id:
            moduleID = colVals[self.moduleIdColPos]
            moduleName = self.getModuleNameFromID(moduleID)
            
            # Replace the existing module_id col with the human-readable 
            # moduleName; the column was already called
            # resource_display_name when cronRefreshActivityGradeCrTable.sql
            # was sourced into MySQL by cronRefreshActivityGrade.sh.
            colVals[self.moduleIdColPos] = moduleName
            
            # Append the anon name
            # to the end of the .tsv row, where it will end up 
            # as column anon_screen_name
            # in table Edx.ActivityGrade:
            colVals.append('%s\n' % theAnonName)

            # Write the array into the tmp file:
            tmpFd.write(string.join(colVals, '\t'))
        
        #tmpFd.flush()
        tmpFd.close()        
        # Now mv the temp file into the tsv file, replacing it:
        os.rename(tmpFd.name, self.tsvFileName)
        
    def computeAndAddRAMBased(self):
        '''
        The heavy lifting: reads all TSV rows from the courseware_studentmodule
        table into memory. Relies on the integer user id being the last column. Grabs
        Each integer id, and computes
        '''
        with open(self.tsvFileName, 'r') as tsvFd:
            allRows = tsvFd.readlines()
        for (i, row) in enumerate(allRows[1:]):
            colVals = row.split('\t')
            # Each line's last TSV value element has
            # a \n glued to it. Get rid of that:
            colVals[-1] = colVals[-1].strip()
            
            # Pick the int-typed student ID out of the row:
            intStudentId = colVals[self.studentIdColPos]
            # Get the equivalent anon_screen_name:
            try:
                theAnonName = self.getAnonFromIntID(int(intStudentId))
            except TypeError:
                theAnonName = ''
            
            # Get the module_id:
            moduleID = colVals[self.moduleIdColPos]
            moduleName = self.getModuleNameFromID(moduleID)
            
            # Replace the existing module_id col with the human-readable 
            # moduleName; the column was already called
            # resource_display_name when cronRefreshActivityGradeCrTable.sql
            # was sourced into MySQL by cronRefreshActivityGrade.sh.
            colVals[self.moduleIdColPos] = moduleName
            
            # Append the anon name
            # to the end of the .tsv row, where it will end up 
            # as column anon_screen_name
            # in table Edx.ActivityGrade:
            colVals.append('%s\n' % theAnonName)

            # Write the array back into allRows. The '+1'
            # is b/c the enumeration above starts i at 0,
            # which the allRows[1:] starts with the 2nd row,
            # the one after the header:
            allRows[i+1] = string.join(colVals, '\t')

        # The first (header column names) row needs to 
        # have the new columns appended to it after 
        # again stripping the newline off the last
        # column name, and tagging it onto the 
        # new last col name: 
        colNames = allRows[0].split('\t')
        colNames[-1] = colNames[-1].strip()
        colNames.append('anon_screen_name\n') 
        allRows[0] = string.join(colNames, '\t')
        # Write the new TSV back into the file:
        with open(self.tsvFileName, 'w') as tsvFd:
            tsvFd.writelines(allRows)

    def getAnonFromIntID(self, intStudentId):
        theAnonName = ''
        for anonName in self.mysqldb.query("SELECT idInt2Anon(%d)" % intStudentId):
            if anonName is not None:
                # Results come back as tuples; singleton tuple in this case:
                return anonName[0]
            else:
                theAnonName

    def getModuleNameFromID(self, moduleID):
        if self.hashMapper is None:
            return ''
        moduleHash = self.extractOpenEdxHash(moduleID)
        if moduleHash is None:
            return ''
        else:
            moduleName = self.hashMapper.getDisplayName(moduleHash)
        return moduleName if moduleName is not None else ''

    
    def extractOpenEdxHash(self, idStr):
        '''
        Given a string, such as::
            i4x-Medicine-HRP258-videoalpha-7cd4bf0813904612bcd583a73ade1d54
            or:
            input_i4x-Medicine-HRP258-problem-98ca37dbf24849debcc29eb36811cb68_3_1_choice_3'
        extract and return the 32 bit hash portion. If none is found,
        return None. Method takes any string and finds a 32 bit hex number.
        It is up to the caller to ensure that the return is meaningful. As
        a minimal check, the method does ensure that there is at most one 
        qualifying string present; we know that this is the case with problem_id
        and other strings.
        @param idStr: problem, module, video ID and others that might contain a 32 bit OpenEdx platform hash
        @type idStr: string
        '''
        if idStr is None:
            return None
        match = AnonAndModIDAdder.findHashPattern.search(idStr)
        if match is not None:
            return match.group(1)
        else:
            return None

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
    parser.add_argument('studentIdColPos',
                        type=int,
                        help='Zero-origin position of the student_id column in the TSV of the courseware_studentmodule table obtained from edxprod'
                        )  
    parser.add_argument('moduleIdColPos',
                        type=int,
                        help='Zero-origin position of the module_id column in the TSV of the courseware_studentmodule table obtained from edxprod'
                        )  
    args = parser.parse_args();

    if not os.access(args.tsvFileName, os.R_OK):
        print("File %s is not readable or does not exist." % args.tsvFileName)
        parser.print_usage()
        sys.exit()
        
    tsvFileName = args.tsvFileName

    if args.studentIdColPos < 0:
        print("Student ID column position must be the zero-origin column index of the student_id in the TSV file; was %s" % str(args.studentIdColPos))
        parser.print_usage()
        sys.exit()
    
    studentIdColPos = args.studentIdColPos
        
    if args.moduleIdColPos < 0:
        print("Module ID column position must be the zero-origin column index of the module_id in the TSV file; was %s" % str(args.moduleIdColPos))
        parser.print_usage()
        sys.exit()
    
    moduleIdColPos = args.moduleIdColPos
        
        
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
                    
    anonAdder = AnonAndModIDAdder(user, pwd, tsvFileName, studentIdColPos, moduleIdColPos)
    anonAdder.computeAndAddFileBased()
    
