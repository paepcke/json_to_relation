#!/usr/bin/env python
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
    