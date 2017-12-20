#!/usr/bin/env bash

#---------------------------------------------------------
#
# Copies a given MySQL table into a new table, in which
# all rows with test courses are removed. The column that
# holds course names is passed into the script.
#
#   USAGE: removeTestCourses.sh <mysql_user> <full_src_tbl_name> <crse_name_index> <full_new_table_name>
#
# The full_src_tbl_name is the table whose rows are to be
# filtered. The 'full' means that the database must be included
# in the name. Same for the full_new_table_name.
#
# The crse_name_index is the column number from left to right,
# starting with zero, where the course_display_name (course_id, course name)
# reside.
#
# If a select condition is provided, it must be a MySQL "where" clause.
# It will be applied to the exported table.
#
#     Example: removeTestCourses.sh dataman edxprod.courseware_studentmodule 10 Misc.courseware_studentmodule_clean
#     Example: removeTestCourses.sh dataman edxprod.courseware_studentmodule 10 Misc.courseware_studentmodule_clean "where the_date > '2010-09-03'"
#
# Strategy:
#
# - Write source table as .csv to /tmp
# - Use awk to filter out the damned test courses
# - Read the table back
# 
# Cleanup: unfortunately, the script cannot remove the
#          created output table, b/c it is owned by mysql
#
# WARNING: full_new_table_name will be replaced if it exists.
#
# WARNING: this script is naive about commas:
#          it knows naught of text columns that contain commas.
#          Use only for tables that have no commas in their columns.
#          To fix this shortcoming: edit removeTestCourses.awk.
#
# Possible Test table:
# 
#  SELECT * FROM VideoInteraction;
#  
#  -->+----------+-------------------------------------+------------+------------------+------------+
#     | video_id | course_display_name                 | quarter    | anon_screen_name | date       |
#     +----------+-------------------------------------+------------+------------------+------------+
#     | v1       | engineering/sefu/winter2015         | spring2015 | s0               | NULL       |
#     | v1       | internal/101/private_testing_course | winter2016 | s1               | 2014-01-01 |
#     | v2       | humanities/phil202/spring2015       | spring2015 | s1               | 2015-01-01 |
#     | v2       | humanities/phil202/spring2015       | winter2016 | s1               | 2015-01-01 |
#     | v2       | engineering/cs101/winter2016        | winter2016 | s2               | 2016-01-01 |
#     +----------+-------------------------------------+------------+------------------+------------+
#     5 rows in set (0.01 sec)
#
#  removeTestCourses.sh paepcke Trash.VideoInteraction 1 Trash.VideoInteraction_clean "where year(date) < 2016"
#
#  Should yield in db:
#
# SELECT * FROM Trash.VideoInteraction_clean;
#
#     +----------+-------------------------------+------------+------------------+------------+
#     | video_id | course_display_name           | quarter    | anon_screen_name | date       |
#     +----------+-------------------------------+------------+------------------+------------+
#     | v2       | humanities/phil202/spring2015 | spring2015 | s1               | 2015-01-01 |
#     | v2       | humanities/phil202/spring2015 | winter2016 | s1               | 2015-01-01 |
#     +----------+-------------------------------+------------+------------------+------------+
#
# 
#
#---------------------------------------------------------

USAGE="USAGE: $(basename $0) <mysql_user> <full_src_tbl_name> <crse_name_index> <full_new_table_name> [<select_condition>]"

if [[ $# < 4 ]]
then
    echo $USAGE
    exit 1
fi

MYSQL_USER=$1
SRC_TBL_NAME=$2
CRSE_NAME_INDEX=$3
NEW_TBL_NAME=$4

# Was a select condition provided on the CLI?

SELECT_CONDITION=''
if [[ $# == 5 ]]
then
    SELECT_CONDITION=$5
fi    

#****************
# echo "MYSQL_USER      : ${MYSQL_USER}"
# echo "SRC_TBL_NAME    : ${SRC_TBL_NAME}"
# echo "CRSE_NAME_INDEX : ${CRSE_NAME_INDEX}"
# echo "NEW_TBL_NAME    : ${NEW_TBL_NAME}"
# echo "SELECT_CONDITION: ${SELECT_CONDITION}"
#****************

# Where this script is running:
CURR_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ensure that src and dest have database names:
# such as MyDb.myTable:

if [[ -z $(echo ${SRC_TBL_NAME} | grep '\.') || -z $(echo ${NEW_TBL_NAME} | grep '\.') ]]
then
    echo "Source and destination tables must include their database specifications."
    exit 1
fi
    
# Won't be able to remove this file from this script once
# MySQL writes to it:

TMP_FILE=$(mktemp /tmp/removeTestCourses_XXXXXXXXXXX.csv)

# But at this point, remove file so that MySQL won't complain about
# its existence. This is a race condition if we run this script in
# multiple simultaneous copies, which we won't:

rm ${TMP_FILE}

# Ensure that at least the temporary clean-up .csv file is removed
# on exit (cleanly or otherwise):

function cleanup {

    # The $TMP_FILE is writen by MySQL, so
    # this user cannot remove it from /tmp,
    # which generally has the sticky bit set
    # (ls -l shows .......t). So only owner
    # can write even though rw for all:
    
    #if [[ -e ${TMP_FILE} ]]
    #then
    #    rm ${TMP_FILE}
    #fi
    
    if [[ -e ${CLEANED_FILE} ]]
    then
        rm ${CLEANED_FILE}
    fi
}

trap cleanup EXIT

# Export the table from which to delete
# test courses:

read -rd '' TBL_EXPORT_CMD <<EOF
SELECT * FROM ${SRC_TBL_NAME}
  ${SELECT_CONDITION}
  INTO OUTFILE '${TMP_FILE}'
  FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n';
  
EOF

#***********
#echo "TBL_EXPORT_CMD: ${TBL_EXPORT_CMD}"
#***********

mysql --login-path=${MYSQL_USER} -e "$TBL_EXPORT_CMD"

# .csv file name for AWK to write the redacted result to:

CLEANED_FILE=/tmp/$(basename ${TMP_FILE} .csv)_Cleaned.csv

#*********
#echo "CLEANED_FILE: ${CLEANED_FILE}"
#*********

# Pump the dirty .csv file through AWK into the new .csv file:
cat ${TMP_FILE} | awk -v COURSE_NAME_INDEX=${CRSE_NAME_INDEX} -f ${CURR_SCRIPTS_DIR}/removeTestCourses.awk > ${CLEANED_FILE}

# Load the new file into a newly created
# table:

read -rd '' TBL_IMPORT_CMD <<EOF
DROP TABLE if exists ${NEW_TBL_NAME};
CREATE TABLE ${NEW_TBL_NAME} LIKE ${SRC_TBL_NAME};
LOAD DATA LOCAL INFILE '${CLEANED_FILE}'
  INTO TABLE ${NEW_TBL_NAME}
   FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n';
EOF

mysql --login-path=${MYSQL_USER} -e "$TBL_IMPORT_CMD"
