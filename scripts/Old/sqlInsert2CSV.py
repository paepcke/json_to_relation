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
Created on Nov 14, 2013

@author: paepcke
'''

import os
import re
import sys


class SQLInserts2CSVConverter(object):

    # When looking at INSERT INTO tableName (...,
    # grab 'tableName':
    TABLE_NAME_PATTERN = re.compile(r'[^\s]*\s[^\s]*\s([^\s]*)\s')
    
    # When looking at:"     ('7a286e24_b578_4741_b6e0_c0e8596bd456','Mozil...);\n"
    # grab everything inside the parens, including the trailing ');\n', which
    # we'll cut out in the code:
    VALUES_PATTERN = re.compile(r'^[\s]{4}\(([^\n]*)\n')

    
    def __init__(self, outDir, infilePath):

        if not os.path.isdir(outDir) or not os.access(outDir, os.W_OK):
            raise ValueError('Output directory %s does not exist, or is not writable' % outDir)
        if not os.path.exists(infilePath) or not os.access(infilePath, os.R_OK):
            raise ValueError('Input file %s does not exist, or is not readable' % infilePath)
        
        self.infilePath = infilePath
        self.outDir = outDir
        
        # From infile name like /foo/bar/moosefish.sql, get /foo/bar/moosefish
        self.outFilePathWithoutTableName = os.path.splitext(os.path.basename(infilePath))[0]
        
        # Dict mapping table name to output file FD where that
        # table's insert values are to go:
        self.outFileFDs = {}
        
    def sqlInserts2CSV(self):
        
        try:
            with open(self.infilePath) as inFd:
                insertIntoLine = inFd.readline()
                done = False
                while not done:
                    if not insertIntoLine.startswith('INSERT INTO'):
                        insertIntoLine = inFd.readline()
                        if len(insertIntoLine) == 0:
                            done = True
                            continue
                        continue
                    try:
                        tblNameMatch = SQLInserts2CSVConverter.TABLE_NAME_PATTERN.search(insertIntoLine)
                        if tblNameMatch is None:
                            self.logWarn('No match when trying to extract table name from "%s"' % insertIntoLine)
                        tblName = tblNameMatch.group(1)
                    except IndexError:
                        self.logWarn('Could not extract table name from "%s"' % insertIntoLine)
                        continue
                    
                    readAllValueTuples = False
                    
                    while not readAllValueTuples:
                        # Get values list that belongs to this insert statement:
                        valuesLine = inFd.readline()
                        if not valuesLine.startswith('    ('):
                            readAllValueTuples = True
                            # We likely just read the start of the next INSERT statement:
                            insertIntoLine = valuesLine
                            continue # while not done
                        # Extract the comma-separated values list out from the parens;
                        # first get "'fasdrew_fdsaf...',...);\n":
                        oneValuesLineMatch = SQLInserts2CSVConverter.VALUES_PATTERN.search(valuesLine)
                        if oneValuesLineMatch is None:
                            # Hopefully never happens:
                            self.logWarn('No match for values line "%s"' % insertIntoLine)
                            continue
                        # Get just the comma-separated values list from
                        # 'abfd_sfd,...);\n
                        valuesList = oneValuesLineMatch.group(1)[:-2] + '\n'
                        try:
                            theOutFd = self.outFileFDs[tblName]
                        except KeyError:
                            # Don't yet have an output file going for this table:
                            theOutFd = self.startTblOutFile(tblName)
                        theOutFd.write(valuesList)
        finally:
                for fd in self.outFileFDs.values():
                    fd.close()
                    
                    
    def startTblOutFile(self, tblName):
        outpath = self.outFilePathWithoutTableName + '_%s' % tblName + '_Unsorted.csv'
        outpath = os.path.join(self.outDir, outpath)
        fd = open(outpath, 'w')
        self.outFileFDs[tblName] = fd
        return fd
            
    def logWarn(self, msg):
        sys.stderr.write('Warning (file %s): ' + msg + '\n' % self.infilePath)        
            
    

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('Usage: sqlInsert2CSV outDir infile')
        sys.exit(1)
    
    converter = SQLInserts2CSVConverter(sys.argv[1], sys.argv[2])
    converter.sqlInserts2CSV()
    