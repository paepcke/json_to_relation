Scripts in this directory operate the edX tracking log translations to 
a relational schema. Only the 'public scripts' below are of interest.
The others are mentioned just to satisfy curiosity; they are not
of interest to regular users.

# ------------ Public Scripts ---------------

Script transformGivenLogfiles.sh in this directory runs the conversion
of edX tracking log files to a relational model. Output is a set of
file collections, one for each tracking log file. Each file collection
consists of one .csv file per table, plus one .sql file that imports
those files. Pass those .sql files as command line parameters to the
executeCSVLoad.sh script

The script executeCSVLoad.sh loads the file collections into the
Edx/EdxPrivate databases.

Script makeCourseExtract.sh takes a MySQL compatible regex pattern
that selects course names from data column course_display_name in
table EdxTrackEvent. Creates a table in database Extracts that
contains tracking log data only from the respective course.

The cronRefreshModuleStore.sh script is a Stanford-specific utility
that retrieves the latest copy of the modulestore to datastage so that
it can be used in the transform process to dereference video and
problem hashes to human-readable form.

The lookupOpenEdxHash.py script is a command line tool to look up the
human readable strings that correspond to OpenEdX platform generated
hash strings for problems, videos, and sequences. The given strings
may be just the 32 bit hex numbers, or the long strings in tracking
logs that contain that hex number somewhere inside them.

Script makeScreenNameToAnonTable.sh takes a GREP compatible regular
expression that searches for (partial) course names in an also given
list of gzipped OpenEdx tracking log files. Creates a two-column CSV table
mapping screen names in the log files to their hashed equivalents 
as used in anon_screen_name fields of table EdxTrackEvents.

The listCourseScreenNames.sh script takes a list of gzipped OpenEdx 
tracking log files, and generates a list of all screen names, i.e.
values of the field with key 'username.' The script can be used alone,
but is mostly used by makeScreenNameToAnonTable.sh.


# ------------ Private Scripts ---------------

The json2sql.py scripts is used by transformGivenLogfiles.sh. 

The testAllTruthFiles.py script is used to ensure that all unittest
gold .sql files work. 
