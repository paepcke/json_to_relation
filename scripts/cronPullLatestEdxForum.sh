#!/bin/bash

# Pull the latest EdX Forum dump from deploy.prod.class.stanford.edu to datastage. 
# Untar, and load into datastage Edx.Forum****

scp deploy.prod.class.stanford.edu:/data/dump/forum-latest.tar.gz \
    ~dataman/Data/FullDumps/EdxForum
cd ~dataman/Data/FullDumps/EdxForum/
tar -zxvf forum-latest.tar.gz

#python extractor.py

