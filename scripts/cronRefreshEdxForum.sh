#!/bin/bash

export FORUM_EXTRACT_ROOT=/home/paepcke/EclipseWorkstations/forum_etl

# Pull the latest EdX Forum dump from deploy.prod.class.stanford.edu to datastage. 
# Untar, and load into datastage EdxForum.contents. Two options:
# 

scp deploy.prod.class.stanford.edu:/data/dump/forum-latest.tar.gz \
    ~dataman/Data/FullDumps/EdxForum
cd ~dataman/Data/FullDumps/EdxForum/
tar -zxvf forum-latest.tar.gz

# Now we have at least one subdirectory of the form
# forum-20140405. There may also be older ones. We
# want to symlink the latest of them to forum-latest
#
# The pipe below this comment does that linking. The pieces:
#
#      ls -t -r -d forum-[0-9]*
#
# list, sorted by modification time (-t) in
# reverse order, i.e. latest first (-r) all
# directories (-d) whose names start with 
# 'forum-' and are are followed by nothing but 
# digits (forum-[0-9]*)
#
# Grab the first line (tail -1). Now we have
# just the directory name that resulted from the
# tar -x above.
#
# Symbolically link the result to forum-latest:
# ln -s using backticks.

 rm --force forum-latest
 ln -s `ls -t -r -d forum-[0-9]* | tail -1` forum-latest

# Anonymize and load:
python $FORUM_EXTRACT_ROOT/src/forum_etl/extractor.py --anonymize $PWD/forum-latest/app*/contents.bson

