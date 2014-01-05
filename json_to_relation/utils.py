'''
Created on Jan 5, 2014

@author: paepcke
'''

import re
import os
import sys
from unidecode import unidecode

# Add json_to_relation source dir to $PATH
# for duration of this execution:
source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir

from modulestoreImporter import ModulestoreImporter

class Utils(object):
    '''
    Utilities for use in json_to_relation. All class level methods
    '''

    # Isolate 32-bit hash inside any string, e.g.:
    #   i4x-Medicine-HRP258-videoalpha-7cd4bf0813904612bcd583a73ade1d54
    # or:
    #   input_i4x-Medicine-HRP258-problem-98ca37dbf24849debcc29eb36811cb68_3_1_choice_3'
    findHashPattern = re.compile(r'([a-f0-9]{32})')
    
    # Facility for mapping resource names like sequenc_id into 
    # human-readable strings:
    hashMapper = None
    attemptedMakeHashMapper = False
    
    def __init__(self):
        pass
    
    @classmethod
    def makeInsertSafe(cls, unsafeStr):
        '''
        Makes the given string safe for use as a value in a MySQL INSERT
        statement. Looks for embedded CR or LFs, and turns them into 
        semicolons. Escapes commas and single quotes. Backslash is
        replaced by double backslash. This is needed for unicode, like
        \0245 (invented example)
        @param unsafeStr: string that possibly contains unsafe chars
        @type unsafeStr: String
        @return: same string, with unsafe chars properly replaced or escaped
        @rtype: String
        '''
        #return unsafeStr.replace("'", "\\'").replace('\n', "; ").replace('\r', "; ").replace(',', "\\,").replace('\\', '\\\\')
        if unsafeStr is None or not isinstance(unsafeStr, basestring) or len(unsafeStr) == 0:
            return ''
        # Check for chars > 128 (illegal for standard ASCII):
        for oneChar in unsafeStr:
            if ord(oneChar) > 128:
                # unidecode() replaces unicode with approximations. 
                # I tried all sorts of escapes, and nothing worked
                # for all cases, except this:
                unsafeStr = unidecode(unicode(unsafeStr))
                break
        return unsafeStr.replace('\n', "; ").replace('\r', "; ").replace('\\', '').replace("'", r"\'")
    
    
    @classmethod
    def ensureHashMapper(cls):
        '''
        Creates facility, ModulestoreImporter, which turns OpenEdX resource IDs into
        human readable strings. the ModulestoreImporter instance
        is placed in class variable hashMapper. The Creation can fail,
        so that variable may remain None after calling this method.
        Callers must check for this condition. 
        @param cls: this class instance; passed transparently by Python
        @type cls: Utils
        '''
        # Create a facility that can map resource name hashes
        # to human-readable strings:
        if Utils.hashMapper is None and not Utils.attemptedMakeHashMapper:
            try:
                Utils.hashMapper = ModulestoreImporter(os.path.join(os.path.dirname(__file__),'../json_to_relation/data/modulestore_latest.json'), 
                                                      useCache=True) 
            except Exception as e:
                print("Could not create a ModulestoreImporter in addAnonToActivityGradesTable.py: %s" % `e`)
                Utils.attemptedMakeHashMapper = True
    
    @classmethod
    def getModuleNameFromID(cls, moduleID):
        '''
        Given a module or sequence id hash, possibly 
        embedded in another string, return a human readable
        resolution if possible. Example input::
           i4x://Medicine/HRP258/sequential/99b37c2c139b45cab9a06fb49ff6594f
        @param cls: this class instance; passed transparently by Python
        @type cls: Utils
        @param moduleID: the sequence or module hash, possibly embedded in a string 
        @type moduleID: String
        '''
        if Utils.hashMapper is None:
            # Try to create the facility that maps resource ids to 
            # human-readable strings:
            Utils.ensureHashMapper()
            if Utils.hashMapper is None:
                # Can't create one:
                return ''
        moduleHash = Utils.extractOpenEdxHash(moduleID)
        if moduleHash is None:
            return ''
        else:
            moduleName = Utils.hashMapper.getDisplayName(moduleHash)
        return moduleName if moduleName is not None else ''

    @classmethod
    def extractOpenEdxHash(cls, idStr):
        '''
        Given a string, such as::
            i4x-Medicine-HRP258-videoalpha-7cd4bf0813904612bcd583a73ade1d54
            or:
            input_i4x-Medicine-HRP258-problem-98ca37dbf24849debcc29eb36811cb68_3_1_choice_3'
        extract and return the 32 bit hash portion. If none is found,
        return None. Method takes any string and finds a 32 bit hex number.
        It is up to the caller to ensure that the return is meaningful. As
        a minimal check, the method does ensure that there is at most one 
        qualifying string present; we know that this is the case with problem_id
        and other strings.
        @param cls: this class instance; passed transparently by Python
        @type cls: Utils
        @param idStr: problem, module, video ID and others that might contain a 32 bit OpenEdx platform hash
        @type idStr: string
        '''
        if idStr is None:
            return None
        match = Utils.findHashPattern.search(idStr)
        if match is not None:
            return match.group(1)
        else:
            return None

    