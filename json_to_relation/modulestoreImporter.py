'''
Created on Nov 30, 2013

@author: paepcke
'''
from UserDict import DictMixin
import csv
import json
import os
import pickle
import re
import subprocess

class ModulestoreImporter(DictMixin):
    '''
    Imports the result of a query to the modulestore (descriptions of OpenEdx courses).
    That query is run by the script cronRefreshModuleStore.sh, and produces a JSON
    file that contains just the information needed for the mapping of an OpenEdx
    32-bit resource hash to an associated organization (e.g. Medicine, Engineering, CME,...), 
    course_short_name (e.g. ENGR14), category (e.g. problem, video, course,...), 
    revision (e.g. Draft), and display name. Example for the latter: 'Problem 2.4' for a category
    'problem' case, or 'Finding the p value' for a category 'video' entry.
    
    The result of that query is assumed to be stored in a file whose path is given to the constructor
    of this class, which is user facing.
    
    Instances of this class parse the JSON file, creating two in-memory dicts whose contents
    are available via public methods. The first dict maps a short course name, like 'ENGR14' to a 
    canonical name, like 'Engineering/ENGR14/Stats_in_engineering'. The second maps OpenEdx
    32-bit hash number strings to information associated with that hash: organization, course
    short name, category, revision, and display name.
    
    To find the canonical course name from a short course name, treat your instance
    of this class like a dict: anonName = myModStoreImporter['ENGR14']. To find a
    category, revision, etc., given a hash, use the corresponding methods:
    getCategory(hash), getRevision(hash), etc. 
    
    In addition to these services that are intended to be used by Python programs,
    an instance of this class can export either or both of the dicts to .csv files.
    See methods exportCourseNameLookup() and exportHashInfo()  
    
    To save time for Python clients, the hash-to-info dict is pickled to a file
    as a cache. Clients may choose to use this cache as part of instance construction.
    '''

    hashLookupCache = None

    def __init__(self, jsonFileName, useCache=False, pickleCachePath=None, parent=None):
        '''
        Prepares instance for subsequent calls to getDisplayName() or
        export(). Preparations include looking for either the given file
        name, if useCache is False, or the cache file, which is a pickled
        Python dict containing OpenEdx hash codes to display_name mappings
        is missing, then the modulestore is refreshed from S3.

        @param jsonFileName: file path to JSON file that contains an excerpt
                    of modulestore, the OpenEdx course db. This file is
                    created using script cronRefreshModuleStore.sh.
        @type jsonFileName: String
        @param useCache: if True, and a file hashLookup.pkl exists in this
                        file's 'data' subdirectory, treat .pkl file as a 
                        pickled dict that maps OpenEdx hashes to display
                        names. That file would have been created by an
                        earlier instantiation of this class. 
                        If False, or the pickle file is missing, then
                        the cache is created by accessing the modulestore
                        MongoDB on S3.
        @type useCache: Bool
        @param pickleCachePath: destination for cache of the hash-->info dict.
                                Default is data/hashLookup.pkl 
        @type pickleCachePath: String
        @param parent: the caller object. If provided, that object must provide
               methods logInfo(), logWarn(), logDebug(), and logError(). If this
               argument is left at None, no logging is done.
        @type parent: GenericJSONParser
        @raise OSError: when there is a problem calling the cronRefreshModuleStore.sh script.
        @raise ValueError: when modulestore JSON could not be parsed.
        '''
        self.useCache = useCache
        self.jsonFileName = jsonFileName
        self.parent = parent
        
        # Regex to identify long course names that end
        # with an edX hash string: 'Medicine/HRP259/4820b254e28c4889b760884ffd049ce'
        # is a hit, but 'Medicine/HRP259/Stats_is_fun' is not a hit: 
        self.nameEndsWithHashPattern =  re.compile(r'(([^/]*/){2}[a-fA-F0-9]{32}$)')

        # Regex to identify a 32-bit hex hash string without other info in the string:
        self.hashStringOnlyPattern =  re.compile(r'^[a-fA-F0-9]{32}$')
        
        if pickleCachePath is None:
            self.pickleCachePath = os.path.join(os.path.dirname(__file__), 'data/hashLookup.pkl')
        else:
            self.pickleCachePath = pickleCachePath
            
        # Ensure the target directory exists:
        if not os.path.exists(os.path.dirname(self.pickleCachePath)):
            os.makedirs(os.path.dirname(self.pickleCachePath))
        
        if not useCache and not os.path.exists(str(jsonFileName)):
            self.importModstore(jsonFileName)
            #raise IOError("File %s does not exist. Try setting useCache=True to use possibly existing cache; if that fails, must run cronRefreshModuleStore.sh" % jsonFileName)
        elif useCache and not os.path.exists(self.pickleCachePath):
            if not os.path.exists(jsonFileName):
                # Have neither a cache file nor a json file:
                self.importModstore(jsonFileName)
                # raise IOError("Neither cache file %s nor JSON file %s exist. You need to run cronRefreshModuleStore.sh" % (self.pickleCachePath, jsonFileName))
            # Ignore the 'use cache' given that we don't have one;
            # Just work with the JSON file, and create the cache:
            useCache = False
        
        # Pattern to ensure that the first non-comment char in the
        # file is '{', the opening brace. Allows any number of comments
        # that start with '#':
        self.legalJSONStartPattern = re.compile('^([\s]*[#][^\n]*\n)*[\s]*[{]')
        
        cacheAccessSucceeded = True
        # Get dict {"all" : [{...}, {...},...]}
        if useCache:
            if ModulestoreImporter.hashLookupCache is not None:
                self.hashLookup = ModulestoreImporter.hashLookupCache
            else:
                try:
                    with open(self.pickleCachePath, 'r') as pickleFd:
                        self.hashLookup = pickle.load(pickleFd)
                        ModulestoreImporter.hashLookupCache = self.hashLookup
                except IOError:
                    cacheAccessSucceeded = False
            if cacheAccessSucceeded:
                # Build lookup for short course name to three-part standard name:
                self.buildCourseShortNameToCourseName()            
                return
    
        # No use of cache, or cache unavailable:
        self.loadModstoreFromJSON()
        
        # Save the lookup in a quick-to-load Python pickle file for future use
        # when option useCache is true.
        with open(self.pickleCachePath, 'w') as pickleFd:
            pickle.dump(self.hashLookup, pickleFd)
        # Also save it in a class var to share with other instances:
        ModulestoreImporter.hashLookupCache = self.hashLookup

    # ----------------------------  Public Methods -----------------------------
        
    def getDisplayName(self, hashStr):
        '''
        Given a 32-bit OpenEdx hash string, return
        a corresponding display_name. If none found,
        returns None.
        @param hashStr: string of 32 hex digits
        @type hashStr: string
        @return: a display name as was used on the course Web site
        @rtype: {String | None} 
        '''
        infoDict = self.hashLookup.get(hashStr, None)
        if infoDict is None:
            return None
        return infoDict['display_name']
    
    def getOrg(self, hashStr):
        '''
        Given a 32-bit OpenEdx hash string, return
        a corresponding 'org' entry. If none found,
        returns None
        @param hashStr: string of 32 hex digits
        @type hashStr: string
        @return: the organization that offered the class or resource
        @rtype: {String | None} 
        '''
        infoDict = self.hashLookup.get(hashStr, None)
        if infoDict is None:
            return None
        return infoDict['org']
    
    def getCourseShortName(self, hashStr):
        '''
        Given a 32-bit OpenEdx hash string, return
        a corresponding 'org' entry. If none found,
        returns None
        @param hashStr: string of 32 hex digits
        @type hashStr: string
        @return: the short name of the course associated with the hash. Ex: 'HRP258'
        @rtype: {String | None} 
        '''
        infoDict = self.hashLookup.get(hashStr, None)
        if infoDict is None:
            return None
        return infoDict['course_short_name']
    
    def getCategory(self, hashStr):
        '''
        Given a 32-bit OpenEdx hash string, return
        a corresponding 'org' entry. If none found,
        returns None
        @param hashStr: string of 32 hex digits
        @type hashStr: string
        @return: the category associated with the hash. Ex.: 'problem', 'vertical', 'video'
        @rtype: {String | None} 
        '''
        infoDict = self.hashLookup.get(hashStr, None)
        if infoDict is None:
            return None
        return infoDict['category']

    def getRevision(self, hashStr):
        '''
        Given a 32-bit OpenEdx hash string, return
        a corresponding 'org' entry. If none found,
        returns None
        @param hashStr: string of 32 hex digits
        @type hashStr: string
        @return: the revision of the resource associated with the hash
        @rtype: {String | None} 
        '''
        infoDict = self.hashLookup.get(hashStr, None)
        if infoDict is None:
            return None
        return infoDict['revision']
        
    def exportHashInfo(self, outFilePath, addHeader=True):
        '''
        Export the dict hash --> org/category/... to 
        CSV with header::
            'name_hash','org','short_course_name','category','revision','display_name'

        @param outFilePath: fully qualified name of .csv output file
        @type outFilePath: {String | File}
        @param addHeader: whether or not to add a header line
        @type addHeader: Bool
        @raise ValueError: when modulestore JSON could not be parsed.
        '''

        if not isinstance(outFilePath, basestring):
            outFilePath = outFilePath.name
        # Unless we are using an existing in-memory stuct,
        # extract such a struct from a file:
        if not self.useCache:
            # Create the in-memory data structure from the file:
            self.loadModstoreFromJSON()
            
        with open(outFilePath, 'w') as outFd:
            csvWriter = csv.writer(outFd, dialect='excel', delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
            if addHeader:
                csvWriter.writerow(['name_hash','org','short_course_name','category','revision','display_name'])
            # Go through each OpenEdx hash, retrieve the little modstore dict that's
            # associated with it, and write to CSV:
            for modstoreID in self.hashLookup.keys():
                entryDict = self.hashLookup[modstoreID]
                values = [modstoreID,
                          entryDict['org'],
                          entryDict['course_short_name'],
                          entryDict['category'],
                          entryDict['revision'],
                          entryDict['display_name']]
                csvWriter.writerow(values)


    def exportCourseNameLookup(self, outFilePath, addHeader=True):
        '''
        Export the dict shortCourseName --> canonicalName to
        CSV with header::
            'course_short_name',course_name
        @param outFilePath: fully qualified name of .csv output file
        @type outFilePath: {String | File}
        @param addHeader: whether or not to add a header line
        @type addHeader: Bool
        @raise ValueError: when modulestore JSON could not be parsed.
        '''

        if not isinstance(outFilePath, basestring):
            outFilePath = outFilePath.name
        # Unless we are using an existing in-memory stuct,
        # extract such a struct from a file:
        if not self.useCache:
            # Create the in-memory data structure from the file:
            self.loadModstoreFromJSON()
            
        with open(outFilePath, 'w') as outFd:
            csvWriter = csv.writer(outFd, dialect='excel', delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
            if addHeader:
                csvWriter.writerow(['course_short_name','course_name'])
            # Go through each short course name, and output:
            for shortCourseName in self.keys():
                values = [shortCourseName,self[shortCourseName]]
                csvWriter.writerow(values)

    # ----------------------------  Private Methods -----------------------------

    # ------------- Dict Methods -------------------
    
    def __getitem__(self, course_short_name):
        return self.courseNameLookup[course_short_name]
    
    def __setitem__(self, course_short_name, canonName):
        self.courseNameLookup[course_short_name] = canonName
    
    def __delitem__(self, course_short_name):
        del self.courseNameLookup[course_short_name]
    
    def keys(self):
        return self.courseNameLookup.keys()
    
    # ------------- Support Methods -------------------
 
    def importModstore(self, jsonFileName):
        '''
        Connects to S3 modulestore MongoDB and loads an
        excerpt into the jsonFileName's directory, where
        the methods above can find it.
        @param jsonFileName: target name of JSON file into which the modstore excerpt
               is to be loaded. The underlying script, cronRefreshModuleStore.sh,
               is hard-coded to link the JSON file to modulestore_latest.json. So
               only the directory part of jsonFileName is used.
        @type jsonFileName: String
        @raise OSError: when there is a problem calling the cronRefreshModuleStore.sh script.
        '''
        self.logInfo("About to pull module store from S3 (useCache=%s; jsonFileName=%s..." % (self.useCache, self.jsonFileName))
        thisProgsDir = os.path.dirname(__file__)
        modstoreRefreshScriptDir = os.path.join(thisProgsDir, '../scripts')
        shellCommand = [os.path.join(modstoreRefreshScriptDir, 'cronRefreshModuleStore.sh'), os.path.dirname(jsonFileName)]
        subprocess.call(shellCommand)
        self.logInfo("Done pulling module store from S3")
 
    def loadModstoreFromJSON(self):
        '''
        Given the JSON file path passed into __init__(), read that file,
        and extract a dict::
             OpenEdxHashNum --> {org, short_course_name, category, revision, display_name}
        That dict is stored in self.hashLookup().
        Input is the raw JSON from the modulestore. Sample lines, all regarding
        the same class, HRP259::
			 { "_id" : { "tag" : "i4x", "org" : "Medicine", "course" : "HRP259", "category" : "about", "name" : "video", "revision" : null } }
			 { "_id" : { "tag" : "i4x", "org" : "Medicine", "course" : "HRP259", "category" : "chapter", "name" : "495757ee7b25401599b1ef0495b068e4", "revision" : null } }
			 { "_id" : { "tag" : "i4x", "org" : "Medicine", "course" : "HRP259", "category" : "course", "name" : "Fall2013", "revision" : null } }
			 { "_id" : { "tag" : "i4x", "org" : "Medicine", "course" : "HRP259", "category" : "course_info", "name" : "handouts", "revision" : null } }
			 { "_id" : { "tag" : "i4x", "org" : "Medicine", "course" : "HRP259", "category" : "course_info", "name" : "updates", "revision" : null } }

        When '_id.name' is a hash str, we want it to be the key of the
        self.hashLookup dict we are building; these quantities are unique.
        
        However, very important entry for each class is the one with _id.category=='course'.
        Its _id.name field usually holds the long name of a class, as in::
        
           { "_id" : { "tag" : "i4x", "org" : "Medicine", "course" : "HRP258", "category" : "course", "name" : "Statistics_in_Medicine", "revision" : null } }
           
        So we need to use a different key than _id.name in our self.hashLookup.
        We *cannot* just use _id.name! In the above case, HRP258, that key would
        be Statistics_in_Medicine, and it would work fine. But _id.name is often
        not unique, and entries in the self.hashLookup dict would be overwritten.
        Like this::  
        
		   { "_id" : { "tag" : "i4x", "org" : "HumanitiesSciences", "course" : "Bio41", "category" : "course", "name" : "Fall2013", "revision" : null } }
		   { "_id" : { "tag" : "i4x", "org" : "HumanitiesSciences", "course" : "CHEM291", "category" : "course", "name" : "Fall2013", "revision" : null } }

        Conclusion:
           1. _id.category == 'course': self.hashLookup key <-- _id.course (e.g. 'HRP259')
           2. _id.category != 'course' and _id.name is a hash string: self.hashLookup key <-- _id.name
           3. _id.category != 'course' and _id.name is not a hash string: self.hashLookup key <-- '_id.course'_'_id.category'_'_id.name'
        This scheme is not perfect, but it suffices for what we want to do.
        '''
        jsonStr = open(self.jsonFileName, 'r').read()
        if self.legalJSONStartPattern.search(jsonStr) is None:
            # Doesn't start with opening brace:
            jsonStr = '{"all" :' + jsonStr + "}"
        
        try:
            self.modstoreDict = json.loads(jsonStr)
        except ValueError:
            errMsg = "Bad JSON found in module store extract file %s: %s" % (self.jsonFileName, jsonStr)
            self.logError(errMsg)
            raise ValueError(errMsg)
        
        # Create a lookup table mapping hashes of problems
        # and other modules into human-readable names:
        self.hashLookup = {}
        for modstoreEntryDict in self.modstoreDict['all']:
            # modstoreEntryDict is like this:
            # {u'_id': {u'category': u'annotatable', u'name': u'Annotation', u'course': u'templates', u'tag': u'i4x', u'org': u'edx', u'revision': None}, u'metadata': {u'display_name': u'Annotation'}}
            try:
                infoDict = {}
                infoDict['org'] = modstoreEntryDict['_id'].get('org', '')
                infoDict['course_short_name'] = modstoreEntryDict['_id'].get('course', '')
                infoDict['category'] = modstoreEntryDict['_id'].get('category', '')
                infoDict['revision'] = modstoreEntryDict['_id'].get('revision', '')
                infoDict['name'] = modstoreEntryDict['_id'].get('name', '')                
                infoDict['display_name'] = modstoreEntryDict['metadata'].get('display_name', '')
                
                if infoDict['category'] == 'course':
                    key = modstoreEntryDict['_id'].get('course', '')
                    self.hashLookup[key] = infoDict
                elif self.hashStringOnlyPattern.search(infoDict['name']) is not None:
                    # Name is a hash str:
                    key = modstoreEntryDict['_id'].get('name', '')
                    self.hashLookup[key] = infoDict
                else:
                    key = modstoreEntryDict['_id'].get('course', '') + '_' +\
                          modstoreEntryDict['_id'].get('category', '') + '_' +\
                          modstoreEntryDict['_id'].get('name', '')
                    self.hashLookup[key] = infoDict
            except KeyError:
                # The 'about' entries don't have metadata; just ignore those entries:
                pass
        # Build lookup for short course name to three-part standard name:
        self.buildCourseShortNameToCourseName()
                  
    def buildCourseShortNameToCourseName(self):
        '''
        Creates a dict self.courseNameLookup, which maps a
        short course name, like ENGR14 to a canonical name,
        like 'Engineering/ENGR14/Stats_in_engineering'.
        The canonical name is constructed like this:
        org/course_short_name/<longCourseName>, where
        <longCourseName> is the (JSON) _id.name field of
        an entry of category 'course'. Those fields
        contain the long course name.
        Input is self.hashLookup, a dict mapping hash
        keys to little dicts with the contents of one modulestore
        entry.
        '''
        self.courseNameLookup = {}
        for infoDictID in self.hashLookup.keys():
            infoDict = self.hashLookup[infoDictID]
            if infoDict.get('category', None) != 'course':
                continue
            shortName = infoDict['course_short_name']
            # Weed out test course names, like '1' and '123', and '2013':
            # Require the course name to start with a letter.
            # (Should we require at least two letter?)
            if re.search(r'^[a-zA-Z]', shortName) is None:
                continue
            self.courseNameLookup[shortName] =\
                                  infoDict['org'] + '/' +\
                                  shortName + '/' +\
                                  infoDict['name']
        
#         for infoDictID in self.hashLookup.keys():
#             infoDict = self.hashLookup[infoDictID]
#             shortName = infoDict['course_short_name']
#             # If we already have an entry for this short name,
#             # leave it alone, unless its long name contains
#             # a hash str:
#             try:
#                 currLongName = self.courseNameLookup[shortName]
#                 # Check quality: if this existing entry has an edX hash
#                 # string, then try for something better. Example:
#                 # Might have  Medicine/HRP259/4820b254e28c4889b760884ffd049ce7
#                 # when we could have Medicine/HRP259/Working_with_stats.
#                 if self.nameEndsWithHashPattern.search(currLongName) is None:
#                     # Already have a better long name than a hash str:
#                     continue
#             except KeyError:
#                 # No name mapping known yet:
#                 pass
#             # Weed out test course names, like '1' and '123', and '2013':
#             # Require the course name to start with a letter.
#             # (Should we require at least two letter?)
#             if re.search(r'^[a-zA-Z]', shortName) is None:
#                 continue
#             self.courseNameLookup[shortName] =\
#                                   infoDict['org'] + '/' +\
#                                   shortName + '/' +\
#                                   infoDictID
        
    def logInfo(self, msg):
        if self.parent is not None:
            self.parent.logInfo(msg)
            
    def logError(self, msg):
        if self.parent is not None:
            self.parent.logError(msg)
            
    def logDebug(self, msg):
        if self.parent is not None:
            self.parent.logDebug(msg)
    