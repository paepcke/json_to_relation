Scripts in this directory operate the edX tracking log translations to 
a relational schema. Only the 'public scripts' below are of interest.
The others are mentioned just to satisfy curiosity; they are not
of interest to regular users.

The main script of interest is manageEdxDb.py. Use it to
    o Pull OpenEdX tracking log files from S3 to localhost.
      Only files not already present at localhost are
      pulled
    o Transform tracking log files to the relational tables.
      For each tracking log file this operation constructs 
      one .sql file, and several .csv files.
    o Load results of the transforms into the Edx an EdxPrivate
      databases.
Use --help for details. Note that manageEdxDb.py can run
each of its actions in 'pretend' mode, if given the 
--dryRun commandline option.

# ------------ Public Scripts ---------------

Script manageEdxDb.py: most used script.

Script makeCourseExtract.sh takes a MySQL compatible regex pattern
that selects course names from data column course_display_name in
table EdxTrackEvent. Creates a table in database Extracts that
contains tracking log data only from the respective course.

The cronRefreshModuleStore.sh script is a Stanford-specific utility
that retrieves the latest copy of the modulestore to localhost so that
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

Script createEmptyEdxDbs.sh is dangerous! After requesting
confirmation, the script deletes all content from databases 
Edx and EdxPrivate. Do use this script, rather than manually
dropping and re-creating these two databases. Reason: the
script also defines stored procedures and functions needed
for db administration.


# ------------ Private Scripts ---------------

The json2sql.py scripts is used by transformGivenLogfiles.sh. 

Script createIndexForTable.sh takes one table name and creates
all indexes on that table, if it does not exist. Without args,
it creates all indexes. Used by executeCSVLoad.sh

Script defineMySQLProcedures.sh (re)-defines all required
stored procedures/functions. Used by createEmptyEdxDbs.

Script transformGivenLogfiles.sh in this directory runs the conversion
of edX tracking log files to a relational model. Output is a set of
file collections, one for each tracking log file. Each file collection
consists of one .csv file per table, plus one .sql file that imports
those files. Pass those .sql files as command line parameters to the
executeCSVLoad.sh script

The script executeCSVLoad.sh loads the file collections into the
Edx/EdxPrivate databases.


The testAllTruthFiles.py script is used to ensure that all unittest
gold .sql files work. 
