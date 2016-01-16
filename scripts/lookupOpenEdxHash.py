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

import os
import sys

# Command line tool to look up the human readable strings that
# correspond to edX platform generated hash strings for problems and
# videos. The given strings may be just the 32 bit hex numbers, or the 
# long strings in tracking logs that contain that hex number somewhere 
# inside it

# Add json_to_relation source dir to $PATH
# for duration of this execution:
source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir

from modulestoreImporter import ModulestoreImporter
from edxTrackLogJSONParser import EdXTrackLogJSONParser

if __name__ == '__main__':

    USAGE = 'Usage: lookupOpenEdxHash.py hashStr1 hashstr2 ...'
    if len(sys.argv) < 2:
        print(USAGE)
        sys.exit()
    
    hashLookup = ModulestoreImporter(os.path.join(os.path.dirname(__file__),'../json_to_relation/data/modulestore_latest.json'), 
                       useCache=True)
    for hashStr in sys.argv[1:]:
        match = EdXTrackLogJSONParser.findHashPattern.search(hashStr)
        if match is not None:
            print(hashLookup.getDisplayName(match.group(1)))
        else:
            print 'None'
        


