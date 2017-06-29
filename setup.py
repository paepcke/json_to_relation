# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import multiprocessing
from setuptools import setup, find_packages


test_requirements = ['mongomock>=1.0.1', 'sentinels>=0.0.6', 'nose>=1.0', 'python-dateutil>=2.2']

setup(
    name = "json_to_relation",
    version = "0.4",
    packages = find_packages(),

    # Dependencies on other packages:
    setup_requires   = ['nose>=1.1.2'],
    tests_require    = test_requirements,
    install_requires = ['ijson>=1.0', 
			'pymongo>=2.6.2', 
			#'pymysql3>=0.5', 
                        'pymysql>=0.6.2',
			'pymysql_utils>=1.4',
			'configparser>=3.3.0r2', 
			'argparse>=1.2.1', 
			'unidecode>=0.04.14', 
			'boto>=2.16.0',
			'python-daemon>=1.5.5'
			#'online_learning_computations>=0.30'
			] + test_requirements,

    # Unit tests; they are initiated via 'python setup.py test'
    #test_suite       = 'json_to_relation/test',
    test_suite       = 'nose.collector', 

    #data_files = [('pymysql_utils/data', datafiles)],

    package_data = {
        # If any package contains *.txt or *.rst files, include them:
     #   '': ['*.txt', '*.rst'],
        # And include any *.msg files found in the 'hello' package, too:
     #   'hello': ['*.msg'],
    },

    # metadata for upload to PyPI
    author = "Andreas Paepcke",
    author_email = "paepcke@cs.stanford.edu",
    description = "Converts file with multiple JSON objects to one relational table.",
    license = "BSD",
    keywords = "json, relation, OpenEdX",
    url = "https://github.com/paepcke/json_to_relation",   # project home page, if any
)
