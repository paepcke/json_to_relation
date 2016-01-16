#!/bin/bash
# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


dbNames=( novoed-crs_email_13_ACrashCourseonCreativity \
      	  novoed-crs_email_14_DesigningaNewLearningEnvironment \
      	  novoed-crs_email_23_ACrashCourseonCreativity \
      	  novoed-crs_email_24_TechnologyEntrepreneurshipPart1 \
      	  novoed-crs_email_25_Finance \
      	  novoed-crs_email_27_GraphPartitioningandExpanders \
      	  novoed-crs_email_28_MobileHealthWithoutBorders \
      	  novoed-crs_email_29_OrganizationalBehavior \
      	  novoed-crs_email_30_HippocratesChallenge \
      	  novoed-crs_email_31_StartupBoards \
      	  novoed-crs_email_32_SustainableProductDevelopment \
      	  novoed-crs_email_33_EntrepreneurshipinEnvironmentalEngineering \
      	  novoed-crs_email_46_DesignThinkingActionLab \
      	  novoed-crs_email_BusinessManagementforEEandCSStudents \
      	  novoed-crs_email_Finance \
      	  novoed-crs_email_OrganizationalBehavior \
      	  novoed-crs_email_StartupBoards \
      	  novoed-crs_email_TechnologyEntrepreneurship \
        )

for db in "${dbNames[@]}"
do
   mysql -u root -e "SELECT email \
   	    	     FROM email \
   		     INTO OUTFILE '/tmp/email_${db}.csv' \
   		     FIELDS TERMINATED BY ',' \
   		     LINES TERMINATED BY '\n';" $db
done





