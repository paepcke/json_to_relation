'''
Created on Nov 30, 2013

@author: paepcke
'''
import csv
import json
import os
import pickle
import re


class ModulestoreImporter(object):
    '''
    Imports the result of a query to the modulestore (descriptions of OpenEdx courses).
    That query is run by the script cronRefreshModuleStore.sh, and produces a JSON
    file that contains just the information needed for the mapping of an OpenEdx
    32-bit resource hash to a display_name.
    
    The result of that query is assumed to be stored in a file whose path is given to __init__().
    Instances of this class parse the JSON file, creating an in-memory dict that maps the hash strings
    to human-readable form, as extracted from modulestore via the above query (script call). 
    For future use the __init__() method also saves that dict to a pickle file in the main 
    source folder's 'data' subdirectory. 
    
    Method getDisplayName() returns display names given OpenEdx hash codes. Method
    export() outputs the mapping to a .csv file
    
    Example query::

      ssh goldengate.class.stanford.edu mongo \
          stanford-edx-prod.m0.mongolayer.com:27017/stanford-edx-prod -u readonly \
          --quiet \
          -p<PASSWORD> \
          --eval "\"printjson(db.modulestore.find({},\
          {'_id' : 1, \
    	  'metadata.display_name' : 1, \
    	  'metadata.discussion_category' : 1, \
    	  'metadata.discussion_target' : 1}).toArray())\"" > ~/tmp/test2.json
    
    The file must associate a JSON array of entries with the tag 'all'. Like this::
		 {"all" : [
		 	{
		 		"_id" : {
		 			"tag" : "i4x",
		 			"org" : "edx",
		 			"course" : "templates",
		 			"category" : "annotatable",
		 			"name" : "Annotation",
		 			"revision" : null
		 		},
		 		"metadata" : {
		 			"display_name" : "Annotation"
		 		}
		 	},
		 	{
		 		"_id" : {
		 			"tag" : "i4x",
		 			"org" : "edx",
		 			"course" : "templates",
		 			"category" : "conditional",
		 			"name" : "Empty",
		 			"revision" : null
		 		},
		 		"metadata" : {
		 			"display_name" : "Empty"
		 		}
		 	},
		     ...
		 ]}    
		 
	Note that the result of the above query will produce an array, i.e. the
	file will begin with a bracket, which is not legal json. We wrap the
	"all {...}" around the string in the file, if it is not already present: 
    
    Once the import is complete, the result may be used in two ways:
    as an in-memory database (see method query()), and as a CSV exporter.
    '''


    def __init__(self, jsonFileName, useCache=False, testLookupDict=None):
        '''
        Prepares instance for subsequent calls to getDisplayName() or
        export(). Preparations include looking for either the given file
        name, if useCache is False, or the cache file, which is a pickled
        Python dict containing OpenEdx hash codes to display_names as 
        extracted from modulestore.

        @param jsonFileName: file path to JSON file that contains an excerpt
                    of modulestore, the OpenEdx course db. This file is
                    created using script cronRefreshModuleStore.sh.
        @type jsonFileName: String
        @param useCache: if True, and a file hashLookup.pkl exists in this
                        file's 'data' subdirectory, treat .pkl file as a 
                        pickled dict that maps OpenEdx hashes to display
                        names. That file would have been created by an
                        earlier instantiation of this class. 
        @type useCache: Bool
        @param testLookupDict: strictly for use by unittests. Since many
                        such tests are run with fresh environments, parsing,
                        or even unpickling the cache file slows down the test
                        runs. This parameter, if non-null must be a dict
                        as would normally be created in this __init__()
                        method. 
        @type testLookupDict: {<String>:<String>}
        '''
        self.useCache = useCache
        self.testLookupDict = testLookupDict
        self.jsonFileName = jsonFileName
        
        if testLookupDict is not None:
            # Use passed-in lookup table:
            self.hashLookup = testLookupDict
            # Build lookup for short course name to three-part standard name:
            self.buildCourseShortNameToCourseName()            
            return
        
        self.pickleFileName = os.path.join(os.path.dirname(__file__), 'data/hashLookup.pkl')
        
        if not useCache and not os.path.exists(str(jsonFileName)):
            raise IOError("File %s does not exist. Try setting useCache=True to use possibly existing cache; if that fails, must run cronRefreshModuleStore.sh" % jsonFileName)
        elif useCache and not os.path.exists(self.pickleFileName):
            if not os.path.exists(jsonFileName):
                # Have neither a cache file nor a json file:
                raise IOError("Neither cache file %s nor JSON file %s exist. You need to run cronRefreshModuleStore.sh" % (self.pickleFileName, jsonFileName))
            # Ignore the 'use cache' given that we don't have one;
            # Just work with the JSON file, and create the cache:
            useCache = False
        
        # Pattern to ensure that the first non-comment char in the
        # file is '{', the opening brace. Allows any number of comments
        # that start with '#':
        self.legalJSONStartPattern = re.compile('^([\s]*[#][^\n]*\n)*[\s]*[{]')
        
        # Get dict {"all" : [{...}, {...},...]}
        if useCache:
            with open(self.pickleFileName, 'r') as pickleFd:
                self.hashLookup = pickle.load(pickleFd)
                # Build lookup for short course name to three-part standard name:
                self.buildCourseShortNameToCourseName()            
            return
    
        # No use of cache, or cache unavailble:
        self.loadModstoreFromJSON()
        
        # Save the lookup in a quick-to-load Python pickle file for future use
        # when option useCache is true:
        with open(self.pickleFileName, 'w') as pickleFd:
            pickle.dump(self.hashLookup, pickleFd)

    # ----------------------------  Public Methods -----------------------------
        
    def getDisplayName(self, hashStr):
        '''
        Given a 32-bit OpenEdx hash string, return
        a corresponding display_name. If none found,
        returns None
        @param hashStr: string of 32 hex digits
        @type hashStr: string
        @return: a display name as was used on the course Web site
        @rtype: {String | None} 
        '''
        infoDict = self.hashLookup.get(hashStr, None)
        if infoDict is None:
            return None
        return infoDict['display_name']
    
    def getOrganization(self, hashStr):
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
        @return: the organization that offered the class or resource
        @rtype: {String | None} 
        '''
        infoDict = self.hashLookup.get(hashStr, None)
        if infoDict is None:
            return None
        return infoDict['revision']
        
    def export(self, outFilePath, addHeader=True):

        if not isinstance(outFilePath, basestring):
            outFilePath = outFilePath.name
        # Unless we are using an existing in-memory stuct,
        # extract such a struct from a file:
        if not self.useCache and (self.testLookupDict is None):
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

    # ----------------------------  Private Methods -----------------------------
            
    def loadModstoreFromJSON(self):
        '''
        Given the JSON file path passed into __init__(), read that file,
        and extract a dict::
             OpenEdxHashNum --> {org, short_course_name, category, revision, display_name}
        That dict is stored in self.hashLookup().
        '''
        jsonStr = open(self.jsonFileName, 'r').read()
        if self.legalJSONStartPattern.search(jsonStr) is None:
            # Doesn't start with opening brace:
            jsonStr = '{"all" :' + jsonStr + "}"
        
        self.modstoreDict = json.loads(jsonStr)
        
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
                infoDict['display_name'] = modstoreEntryDict['metadata'].get('display_name', '')
                self.hashLookup[modstoreEntryDict['_id'].get('name', '')] = infoDict
            except KeyError:
                # The 'about' entries don't have metadata; just ignore those entries:
                pass
        # Build lookup for short course name to three-part standard name:
        self.buildCourseShortNameToCourseName()
                  
    def buildCourseShortNameToCourseName(self):
        self.courseNameLookup = {}
        for infoDictID in self.hashLookup.keys():
            if self.hashLookup['category'] == 'course':
                self.courseNameLookup[self.hashLookup['course_short_name']] =\
                                         self.hashLookup['org'] + '/' +\
                                         self.hashLookup['course_short_name'] + '/' +\
                                         infoDictID
        
        