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

'''
Created on Jan 3, 2014

@author: paepcke

Used by cronRefreshGrade.sh.
Accesses a TSV file of the UserGrade table being built. Extracts the screen_name 
column for each TSV row in turn. Computes the corresponding anonymization 
hash, and updates table EdxPrivate.UserGrade's anon_sceen_name column 
in the TSV file with that hash. 
'''
import argparse
import getpass
import os
import sys
import string

# Add json_to_relation source dir to $PATH
# for duration of this execution:
source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir

from edxTrackLogJSONParser import EdXTrackLogJSONParser

# NOTE: I don't think the following 
#   import of either mysqldb or pymysql_utils
#   is needed, b/c the db is opened in __init__()
#   but never used. Leaving it only from laziness:

#from mysqldb import MySQLDB
from pymysql_utils.pymysql_utils import MySQLDB

class AnonAdder(object):
    
    def __init__(self, logFile, uid, pwd, tsvFileName, screenNamePos):
        '''
        Make connection to MySQL wrapper.
        @param logFile: file where log entries will be appended.
        @type logFile: String
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
        self.uid = uid
        self.pwd = pwd
        self.tsvFileName = tsvFileName
        self.screenNamePos = screenNamePos
        self.logFile = logFile
        
        if pwd is None:
            self.mysqldb = MySQLDB(user=uid, db='EdxPrivate')
        else:
            self.mysqldb = MySQLDB(user=uid, passwd=pwd, db='EdxPrivate')
        
        
    def computeAndAdd(self):
        '''
        The heavy lifting: reads all TSV rows from the certificates_generatedcertificate
        table into memory. the screenNamePos passed into the __init__() method
        is used to find the row's user screen name. That name is hashed
        and appended to the row as a new anon_screen_name column.
        '''
        with open(self.logFile, 'a') as logFd:
            with open(self.tsvFileName, 'r') as tsvFd:
                allRows = tsvFd.readlines()
            for (i, row) in enumerate(allRows[1:]):
                colVals = row.split('\t')
                # Each line's last TSV value element has
                # a \n glued to it. Get rid of that:
                colVals[-1] = colVals[-1].strip()
                # Pick the screen name out of the row:
                try:
                    screenName = colVals[self.screenNamePos]
                except IndexError:
                    logMsg =  "Ill formatted row number %d in user grade file %s: '%s' (dropping this row)\n" % \
                                (int(i), self.tsvFileName, str(row).strip())
                    logFd.write(logMsg)
                    logFd.flush()
                    continue
                # Add the new last element, including
                # the trailing \n:
                colVals.append(EdXTrackLogJSONParser.makeHash(screenName) + '\n')
                # Write the array back into allRows. The '+1'
                # is b/c the enumeration above starts i at 0,
                # which the allRows[1:] starts with the 2nd row,
                # the one after the header:
                allRows[i+1] = string.join(colVals, '\t')
    
            # The first (header column names) row needs to 
            # have the new column appended to it after 
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
    parser.add_argument('-l', '--logFile',
                        dest='logFile',
                        default='/tmp/addAnonToUserGradeTable.log',
                        help='File path to file where log entries are appended. Default: /tmp/addAnonToUserGradeTable.log.'
                        )
    parser.add_argument('tsvFileName',
                        help='File containing the TSV of the certificates_generatedcertificate table obtained from edxprod'
                        )  
    parser.add_argument('screenNameColPos',
                        type=int,
                        help='Zero-origin position of the screen_name column in the TSV of the certificates_generatedcertificate table obtained from edxprod'
                        )  
    args = parser.parse_args();

    if not os.access(args.tsvFileName, os.R_OK):
        print("File %s is not readable or does not exist." % args.tsvFileName)
        parser.print_usage()
        sys.exit()
        
    tsvFileName = args.tsvFileName
    logFile = args.logFile

    if args.screenNameColPos < 0:
        print("Screen name position must be the zero-origin column index of the screen name in the TSV file; was %s" % str(args.screenNameColPos))
        parser.print_usage()
        sys.exit()
    
    screenNameColPos = args.screenNameColPos
        
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
                    
    anonAdder = AnonAdder(logFile, user, pwd, tsvFileName, screenNameColPos)
    anonAdder.computeAndAdd()
    
