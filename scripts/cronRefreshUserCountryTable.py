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
Created on Feb 12, 2014

@author: paepcke
'''
import argparse
from collections import OrderedDict
import getpass
import os
import sys
import datetime

from pymysql_utils.pymysql_utils import MySQLDB

# Add json_to_relation source dir to $PATH
# for duration of this execution:
source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir

from ipToCountry import IpCountryDict

class UserCountryTableCreator(object):

    DEST_TABLE               = 'UserCountry'
    # Number of anon ids-country-2-letter-3-letter
    # tuples to accumulate before inserting into
    # UserCountry: 
    INSERT_BULK_SIZE = 15000
    
    def __init__(self, user, pwd):
        self.ipCountryXlater = IpCountryDict()
        self.user = user
        self.pwd  = pwd
        self.db = MySQLDB(user=self.user, passwd=self.pwd, db='Edx')
        # Make sure table exists. It should, and it should be filled
        # with all anon_screen_name and countries up the previous
        # load:
        createCmd = '''CREATE TABLE UserCountry (
                         anon_screen_name varchar(40) NOT NULL DEFAULT "",
                         two_letter_country varchar(2) NOT NULL DEFAULT "",
                         three_letter_country varchar(3) NOT NULL DEFAULT "",
                         country varchar(255) NOT NULL DEFAULT ""
                         ) ENGINE=MyISAM;
                         '''
        self.db.dropTable('UserCountry')
        print("Creating table UserCountry...")
        self.db.execute(createCmd)
        print("Done creating table UserCountry.")
        
    def fillTable(self):
        query = "SELECT DISTINCT anon_screen_name, ip_country FROM EventXtract"
        query_res_it = self.db.query(query)
        done = False
        # Order of columns for insert:
        colNameTuple = ('anon_screen_name','two_letter_country','three_letter_country','country')

        while not done: 
            values = []
            print("%s: Starting one set of %s lookups..." %\
                  (str(datetime.datetime.today()), 
                   UserCountryTableCreator.INSERT_BULK_SIZE))
            for _ in range(UserCountryTableCreator.INSERT_BULK_SIZE):
                try:
                    (anon_screen_name, ip3LetterCountry) = query_res_it.next();
                except StopIteration:
                    done = True
                    break
                # Try translating:
                try:
                    (twoLetterCode, threeLetterCode, country) = self.ipCountryXlater.getBy3LetterCode(ip3LetterCountry)
                except (ValueError,TypeError,KeyError):
                    twoLetterCode   = 'XX'
                    threeLetterCode = 'XXX'
                    country         = 'Not in lookup tbl'
                    #sys.stderr.write("Could not look up one country from (%s/%s): %s\n" % (user, ip3LetterCountry,`e`))
                values.append(tuple(['%s'%anon_screen_name,'%s'%twoLetterCode,'%s'%threeLetterCode,'%s'%country]))

            # Insert this chunk into the UserCountry table
            print("%s: Inserting %s rows into UserCountry table..." % (str(datetime.datetime.today()), len(values)))        
            (errors, warnings) = self.db.bulkInsert(UserCountryTableCreator.DEST_TABLE, colNameTuple, values)
            if errors is not None:
                print('Error(s) during UserCountry insert: %s' % errors)
                sys.exit(1)
            if warnings is not None:
                print('Warning(s) during UserCountry insert: %s' % warnings)
                
            print("%s: Done inserting %s rows into UserCountry table..." % (str(datetime.datetime.today()), len(values)))                    
            # ... and loop to process the next INSERT_BULK_SIZE batch

    def makeIndex(self):
        self.db.execute("CALL createIndexIfNotExists('UserCountryAnonIdx', 'UserCountry', 'anon_screen_name', 40);")
        self.db.execute("CALL createIndexIfNotExists('UserCountryThreeLetIdx', 'UserCountry', 'three_letter_country', 3);")

    def close(self):
        self.db.close()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog=os.path.basename(sys.argv[0]), 
                                     formatter_class=argparse.RawTextHelpFormatter,
                                     description='Create table UserCountry: learner IDs --> country via IP address')
    parser.add_argument('-u', '--user',
                        action='store',
                        help='For load: User ID that is to log into MySQL. Default: the user who is invoking this script.')
    parser.add_argument('-p', '--password',
                        action='store_true',
                        help='For load: request to be asked for pwd for operating MySQL;\n' +\
                             '    default: content of scriptInvokingUser$Home/.ssh/mysql if --user is unspecified,\n' +\
                             '    or, if specified user is root, then the content of scriptInvokingUser$Home/.ssh/mysql_root.'
                        )
    
    args = parser.parse_args();
    if args.user is None:
        user = getpass.getuser()
    else:
        user = args.user
        
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
                pwd = ''
    tblCreator = UserCountryTableCreator(user, pwd)
    print("%s: Filling UserCountry table..." % str(datetime.datetime.today()))
    tblCreator.fillTable()
    print("%s: Done filling UserCountry table..." % str(datetime.datetime.today()))
    print("%s: Indexing table..." % str(datetime.datetime.today()))
    tblCreator.makeIndex()
    print("%s: Done indexing table..." % str(datetime.datetime.today()))
    tblCreator.close()
