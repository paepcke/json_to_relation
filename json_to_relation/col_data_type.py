# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

'''
Created on Sep 23, 2013

@author: paepcke
'''
import sys


TINY_TEXT_LEN = 2**8
TEXT_LEN = 2**16
MEDIUM_TEXT_LEN = 2**24
LONG_TEXT_LEN = 2**32

TINY_INT_MAX = 2**8 - 1
TINY_INT_MIN = -2**7

SMALL_INT_MAX = 2**16 - 1
SMALL_INT_MIN = 2**15

MEDIUM_INT_MAX = 2**24 - 1
MEDIUM_INT_MIN = -2**23

INT_MAX = 2**32 - 1
INT_MIN = -2**31

BIG_INT_MAX = 2**64 - 1
BIG_INT_MIN = -2**63

FLOAT_MAX = sys.float_info.max
FLOAT_MIN = sys.float_info.min

class ColDataType:
    '''
    Enum for datatypes that can be converted to 
    MySQL datatypes
    '''
    TINYTEXT=0     # length < 2^8
    TEXT=1         # length < 2^16
    MEDIUMTEXT=2   # length < 2^24
    LONGTEXT=3     # length < 2^32
    TINYINT=4      # 1 byte
    SMALLINT=5     # 2 bytes
    MEDIUMINT=6    # 3 bytes
    INT=7          # 4 bytes
    BIGINT=8       # 8 bytes
    FLOAT=9        # 4 bytes
    DOUBLE=10      # 8 bytes
    DATE=11
    TIME=12
    DATETIME=13
    BOOL=14        # IF YOU ADD ENTRIES, MODIFY isistance method below
    UUID=15        # 32 byte key via uuid.uuid4()
        
    strings = {TINYTEXT : "VARCHAR(255)",
               TEXT     : "TEXT",
               MEDIUMTEXT : "MEDIUMTEXT",
               LONGTEXT : "LONGTEXT",
               TINYINT  : "TINYINT",
               SMALLINT : "SMALLINT",
               MEDIUMINT: "MEDIUMINT",
               INT      : "INT",
               BIGINT   : "BIGINT",
               FLOAT    : "FLOAT",
               DOUBLE   : "DOUBLE",
               DATE     : "DATE",
               TIME     : "TIME",
               DATETIME : "DATETIME",
               BOOL     : "BOOL",
               UUID     : "VARCHAR(40)"
    }
    
    defaultValues = {TINYTEXT : '',
                	 TEXT     : '',
                	 MEDIUMTEXT : '',
                	 LONGTEXT : '',
                	 TINYINT  : -1,
                	 SMALLINT : -1,
                	 INT      : -1,
                	 BIGINT   : -1,
                	 FLOAT    : -1.0,
                	 DOUBLE   : -1.0,
                	 DATE     : '00000000',
                	 TIME     : '000000',
                	 DATETIME : '00000000000000',
                	 BOOL     : 0,
                	 UUID     : ''
                     }

    @classmethod
    def isinstance(cls, value):
        return value >= ColDataType.TINYTEXT and value <= ColDataType.UUID

    def toString(self, val):
        try:
            return ColDataType.strings[val]
        except KeyError:
            raise ValueError("The code %s does not refer to a known datatype." % str(val))
        
    @classmethod
    def sqlTypeFromValue(cls, value):
        '''
        Given a value, return the best fitting MySQL data type
        Special case: None: we return TEXT.

        :param cls: ColDataType, makes it a class method
        :type cls: ColDataType
        :param value: example value
        :type value: {str | unicode | int | float | bool | None}
        '''

        if value is None:
            # Tough one: we'll guess that non-null values will
            # be text. Arbitrary choice:
            return ColDataType.TEXT
        
        if isinstance(value, bool):
            return ColDataType.BOOL
        
        if isinstance(value, str) or isinstance(value, unicode):
            if len(value) < TINY_TEXT_LEN:
                return ColDataType.TINYTEXT
            elif len(value) < MEDIUM_TEXT_LEN:
                return ColDataType.MEDIUMTEXT
            else:
                return ColDataType.LONGTEXT
            
        elif isinstance(value, int):
            if value < TINY_INT_MAX and value >= TINY_INT_MIN:
                return ColDataType.TINYINT
            elif value < MEDIUM_INT_MAX and value >= MEDIUM_INT_MIN:
                return ColDataType.MEDIUMINT
            elif value < INT_MAX and value >= INT_MIN:
                return ColDataType.INT
            else:
                return ColDataType.BIGINT
            
        elif isinstance(value, float):
            if value < FLOAT_MAX and value >= FLOAT_MIN:
                return ColDataType.FLOAT
            else:
                return ColDataType.DOUBLE
        else:
            raise ValueError("Unknown type for value '%s'" % str(value) )
        
