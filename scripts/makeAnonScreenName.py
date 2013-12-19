#!/usr/bin/env python
'''
Created on Dec 18, 2013
Given any number of user screen names---simple strings--- to
stdin, emit corresponding hashes as used to generat column
anon_screen_name.

@author: paepcke
'''
# Add json_to_relation source dir to $PATH
# for duration of this execution:
import os
import sys

source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir

from edxTrackLogJSONParser import EdXTrackLogJSONParser

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: makeAnonScreenName str1 str2 ...")
        sys.exit(1)
    for screenName in sys.argv[1:]:
        print EdXTrackLogJSONParser.makeHash(screenName)
    