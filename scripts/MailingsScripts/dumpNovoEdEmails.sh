#!/bin/bash

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
   		     ENCLOSED BY '"' \
   		     LINES TERMINATED BY '\n';" $db
done





