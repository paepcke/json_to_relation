#!/usr/bin/env python
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
        


