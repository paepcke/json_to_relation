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

The cronRefreshModuleStore.sh script is a Stanford-specific utility
that retrieves the latest copy of the modulestore to datastage so that
it can be used in the transform process to dereference video and
problem hashes to human-readable form.

The lookupOpenEdxHash.py script is a command line tool to look up the
human readable strings that correspond to edX platform generated hash
strings for problems and videos. The given strings may be just the 32
bit hex numbers, or the long strings in tracking logs that contain
that hex number somewhere inside it.

# ------------ Private Scripts ---------------

The json2sql.py scripts is used by transformGivenLogfiles.sh. 

The testAllTruthFiles.py script is used to ensure that all unittest
gold .sql files work. 
