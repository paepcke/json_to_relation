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
        
    strings = {TINYTEXT : "TINYTEXT",
               TEXT     : "TEXT",
               MEDIUMTEXT : "MEDIUMTEXT",
               LONGTEXT : "LONGTEXT",
               TINYINT  : "TINYINT",
               SMALLINT : "SMALLINT",
               INT      : "INT",
               BIGINT   : "BIGINT",
               FLOAT    : "FLOAT",
               DOUBLE   : "DOUBLE",
               DATE     : "DATE",
               TIME     : "TIME",
               DATETIME : "DATETIME",
               BOOL     : "BOOL"
    }

    @classmethod
    def isinstance(cls, value):
        return value >= ColDataType.TINYTEXT and value <= ColDataType.BOOL

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
        @param cls: ColDataType, makes it a class method
        @type cls: ColDataType
        @param value: example value
        @type value: {str | unicode | int | float | bool | None}
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
        
