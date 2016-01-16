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


import getopt
import sys
import os

### Script for scheduling regular EdxQualtrics updates
### Usage for cron should be "cronRefreshEdxQualtrics.py -m -s -r"

# Add json_to_relation source directory to $PATH
source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir

from surveyextractor import QualtricsExtractor

qe = QualtricsExtractor()
opts, args = getopt.getopt(sys.argv[1:], 'amsr', ['--reset', '--loadmeta', '--loadsurveys', '--loadresponses'])
for opt, arg in opts:
    if opt in ('-a', '--reset'):
        qe.resetMetadata()
        qe.resetSurveys()
        qe.resetResponses()
    elif opt in ('-m', '--loadmeta'):
        qe.loadSurveyMetadata()
    elif opt in ('-s', '--loadsurvey'):
        qe.resetSurveys()
        qe.loadSurveyData()
    elif opt in ('-r', '--loadresponses'):
        qe.loadResponseData()
