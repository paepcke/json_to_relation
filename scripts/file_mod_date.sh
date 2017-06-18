#!/usr/bin/env bash

# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

############################################################################
#
# Given a filename, print its last-modified date as
# yyyy-mm-dd hh:mm:ss, whether on Linux or MacOS
#
# If file does not exists, return string 'null'
#
############################################################################

if [[ $# != 1 ]]
then
    echo "Usage: $(basename $0) filename"
    exit 1
fi


filename=$1

# Determine if this is a Mac. Some bash
# commands are not available there:
if [[ $(echo $OSTYPE | cut -c 1-6) == 'darwin' ]]
then
    PLATFORM='macos'
    BASH_VERSION=$(echo $(bash --version) | sed -n 's/[^0-9]*version \([0-9]\).*/\1/p')
    if [[ $BASH_VERSION < 4 ]]
    then
        echo "On MacOS Bash version must be 4.0 or higher."
        exit 1
    fi
else
    PLATFORM='other'
fi    

# Two ways to find the modification date of
# a directory/file, depending on OS. Either
# way, output will be of the form
#
#   2017-06-14 17:22:17   for MacOS
#
# or
#
#   2017-06-14 17:44:16.876790023 -0700 for Linux



if [[ ! -e $filename ]]
then
    echo 'null'
else
    if [[ $PLATFORM == 'macos' ]]
    then
        echo $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" $filename)
    else
        # Chop off all past the "." to make both outputs look like
        # the Mac output. The -r is for extended regexp that allows
        # use of capture group parens without backslashes:
        echo $(stat -c %y $filename) | sed -rn  's/([^.]*).*/\1/p'
    fi
fi
