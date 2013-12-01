'''
Created on Nov 30, 2013

@author: paepcke
'''
import csv
import json
import os
import re


class ModulestoreImporter(object):
    '''
    Imports the result of a query to the modulestore (descriptions of OpenEdx courses).
    The result is assumed to be stored in a file whose path is given to __init__().
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


    def __init__(self, jsonFileName):
        '''
        '''
        if not os.path.exists(jsonFileName):
            raise IOError("File %s does not exist." % jsonFileName)
        
        # Pattern to ensure that the first non-comment char in the
        # file is '{', the opening brace. Allows any number of comments
        # that start with '#':
        self.legalJSONStartPattern = re.compile('^([\s]*[#][^\n]*\n)*[\s]*[{]')
        
        jsonStr = open(jsonFileName, 'r').read()
        if self.legalJSONStartPattern.search(jsonStr) is None:
            # Doesn't start with opening brace:
            jsonStr = '{"all" :' + jsonStr + "}"
        
        # Get dict {"all" : [{...}, {...},...]}
        self.modstoreDict = json.loads(jsonStr)
        
        # Create a lookup table mapping hashes of problems
        # and other modules into human-readable names:
        self.hashLookup = {}
        for modstoreEntryDict in self.modstoreDict['all']:
            # modstoreEntryDict is like this:
            # {u'_id': {u'category': u'annotatable', u'name': u'Annotation', u'course': u'templates', u'tag': u'i4x', u'org': u'edx', u'revision': None}, u'metadata': {u'display_name': u'Annotation'}}
            try:
                self.hashLookup[modstoreEntryDict['_id'].get('name', '')] = modstoreEntryDict['metadata'].get('display_name', '')
            except KeyError:
                # The 'about' entries don't have metadata; just ignore those entries:
                pass
        
    def getDisplayName(self, hashStr):
        return self.hashLookup.get(hashStr, None) 
        
    def export(self, outFilePath, addHeader=True):
        if not isinstance(outFilePath, basestring):
            outFilePath = outFilePath.name
        with open(outFilePath, 'w') as outFd:
            csvWriter = csv.writer(outFd, dialect='excel', delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
            if addHeader:
                csvWriter.writerow(['category','org', 'course_name','display_name','internal_name'])
            for modstoreEntryDict in self.modstoreDict['all']:
                # modstoreEntryDict is like this:
                # {u'_id': {u'category': u'annotatable', u'name': u'Annotation', u'course': u'templates', u'tag': u'i4x', u'org': u'edx', u'revision': None}, u'metadata': {u'display_name': u'Annotation'}}
                # 'About' entries have no metadata; skip them:
                try:
                    displayName = modstoreEntryDict['metadata'].get('display_name', ''),
                except KeyError:
                    continue

                values = [modstoreEntryDict['_id'].get('category', ''),
                          modstoreEntryDict['_id'].get('org', ''),
                          modstoreEntryDict['_id'].get('course', ''),
                          displayName,
                          modstoreEntryDict['_id'].get('name', '')]
                csvWriter.writerow(values)
            
        
        
        