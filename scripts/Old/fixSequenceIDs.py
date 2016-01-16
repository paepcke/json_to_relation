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
Created on Dec 22, 2013

@author: paepcke
'''
import os
import re
import sys

from edxTrackLogJSONParser import EdXTrackLogJSONParser
from modulestoreImporter import ModulestoreImporter
from unidecode import unidecode

idExtractPat = re.compile(r'^"([^"]*)')
seqIDExtractPat = re.compile(r'","([^"]*)')


hashLookup = ModulestoreImporter(os.path.join(os.path.dirname(__file__),'data/modulestore_latest.json'), 
                   useCache=True)

def makeInsertSafe(unsafeStr):
    '''
    Makes the given string safe for use as a value in a MySQL INSERT
    statement. Looks for embedded CR or LFs, and turns them into 
    semicolons. Escapes commas and single quotes. Backslash is
    replaced by double backslash. This is needed for unicode, like
    \0245 (invented example)
    @param unsafeStr: string that possibly contains unsafe chars
    @type unsafeStr: String
    @return: same string, with unsafe chars properly replaced or escaped
    @rtype: String
    '''
    #return unsafeStr.replace("'", "\\'").replace('\n', "; ").replace('\r', "; ").replace(',', "\\,").replace('\\', '\\\\')
    if unsafeStr is None or not isinstance(unsafeStr, basestring) or len(unsafeStr) == 0:
        return ''
    # Check for chars > 128 (illegal for standard ASCII):
    for oneChar in unsafeStr:
        if ord(oneChar) > 128:
            # unidecode() replaces unicode with approximations. 
            # I tried all sorts of escapes, and nothing worked
            # for all cases, except this:
            unsafeStr = unidecode(unicode(unsafeStr))
            break
    return unsafeStr.replace('\n', "; ").replace('\r', "; ").replace('\\', '').replace("'", r"\'")


def fixSequencIDs():
    counter = 0
    with open('/home/paepcke/tmp/sequenceIDs.sql','w') as outfd:
        outfd.write("USE Edx;\nINSERT INTO EdxTrackEvent(_id,resource_display_name)\n")
        with open('/home/paepcke/tmp/sequenceIDs.csv','r') as fd:
            for idSeqID in fd:
                sqlid    = idExtractPat.search(idSeqID).group(1) 
                seqID = seqIDExtractPat.search(idSeqID).group(1)
                resourceNameMatch = EdXTrackLogJSONParser.findHashPattern.search(seqID)
                if resourceNameMatch is not None:
                    resourceName = makeInsertSafe(hashLookup.getDisplayName(resourceNameMatch.group(1)))
                    if counter == 0:
                        outfd.write('("%s","%s")' % (sqlid,resourceName))
                    else:
                        outfd.write(',\n("%s","%s")' % (sqlid,resourceName))
                else:
                    continue
                counter += 1
                #if counter > 10:
                #    break
        outfd.write("\nON DUPLICATE KEY UPDATE resource_display_name = VALUES(resource_display_name);\n")
        print("Created %d corrections." % counter)
if __name__ == '__main__':
    fixSequencIDs()
    
    
#INSERT INTO EdxTrackEvent (_id,long_answer) VALUES ('fbcefe06_fb7c_48aa_a12e_d85e6988dbda','first answer'),('bbd3ddf3_8ed0_4eee_8ff7_f5791b9e4a7e','second answer') ON DUPLICATE KEY UPDATE long_answer=VALUES(long_answer);

