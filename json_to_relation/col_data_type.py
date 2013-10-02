'''
Created on Sep 23, 2013

@author: paepcke
'''

class ColDataType:
    '''
    Enum for datatypes that can be converted to 
    MySQL datatypes
    '''
    TEXT=0
    LONGTEXT=1
    SMALLINT=2
    INT=3
    FLOAT=4
    DOUBLE=5
    DATE=6
    TIME=7
    DATETIME=8
    
    strings = {TEXT     : "TEXT",
               LONGTEXT : "LONGTEXT",
               SMALLINT : "SMALLINT",
               INT      : "INT",
               FLOAT    : "FLOAT",
               DOUBLE   : "DOUBLE",
               DATE     : "DATE",
               TIME     : "TIME",
               DATETIME : "DATETIME"
    }
    
    @classmethod
    def toString(val):
        try:
            return ColDataType.strings[val]
        except KeyError:
            raise ValueError("The code %s does not refer to a known datatype." % str(val))
        
