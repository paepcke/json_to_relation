'''
Created on Sep 23, 2013

@author: paepcke
'''
import StringIO
import ijson
import re

from col_data_type import ColDataType

class GenericJSONParser(object):
    '''
    Takes a JSON string, and returns a CSV row for later import into a relational database. 
    '''
    # Regex pattern to remove '.item.' from column header names.
    # (see removeItemFromString(). Example: employee.item.name
    # will be replaced by employee.name. When used in r.search(),
    # the regex below creates a Match result instance with two
    # groups: 'item' and 'name'.
    REMOVE_ITEM_FROM_STRING_PATTERN = re.compile(r'(item)\.([^.]*$)')

    def __init__(self, jsonToRelationConverter, logfileID='', progressEvery=1000):
        '''

        :param jsonToRelationConverter: JSONToRelation instance
        :type jsonToRelationConverter: JSONToRelation
        :param logfileID: an identfier of the tracking log file being processed. Used 
               to build error/warning msgs that cite a file and line number in
               their text
        :type logfileID: String
        :param progressEvery: number of input lines, a.k.a. JSON objects after which logging should report total done
        :type progressEvery: int 
        '''
        self.jsonToRelationConverter = jsonToRelationConverter
        self.logfileID = logfileID
        self.progressEvery = progressEvery
        self.totalLinesDoneSoFar = 0
        self.linesSinceLastProgReport = 0
        
        # Set to True if unittesting, so that warnings are not
        # printed:
        self.unittesting = False
        
        # Dict mapping table names into arrays of column names of that table.
        # These arrays are used with setValInRow() to place values into the
        # correct place in a value row. The entries in the dict get initialized
        # in subclasses, and the column names are added in setValInRow() as
        # that method is called to insert values.
        self.colNamesByTable = {} 
    
    def getReadyForNextRow(self):
        '''
        To be called after one row has been processed in
        processOneJSONObject() of this class or one of
        its subclasses. Cleans out any datastructures that
        are only good during creation of one row.
        '''
        # So far, no column has been entered into 
        # any table:
        for tableName in self.colNamesByTable.keys():
            self.colNamesByTable[tableName] = []
    
    def processOneJSONObject(self, jsonStr, row):
        '''
        Given a JSON string that is one entire JSON object, parse the
        string into nested dicts. Derive relational column names from the
        (possibly nested) labels. Cooperate with the parent JSONToRelations
        instance to build a schema of typed SQL columns. Fill the passed-in
        row with values from the JSON string. The following mappings from
        Python values are used::
        
       	    ('null', None)
    		('boolean', <true orfFalse>)
    		('number', <int or Decimal>)
    		('string', <unicode>)
    		('map_key', <str>)
    		('start_map', None)
    		('end_map', None)
    		('start_array', None)
    		('end_array', None)
		
		:param jsonStr: string of a single, self contained JSON object
		:type jsonStr: String
		:param row: partially filled array of values.
		:type row: List<<any>>
		:return: array of values. Fills into the passed-in row array
		:rtype: [<any>]
        '''
        self.jsonToRelationConverter.bumpLineCounter()
        try:
            try:
                parser = ijson.parse(StringIO.StringIO(jsonStr))
            except Exception as e:
                self.logWarn('Ill formed JSON in track log, line %d: %s' % (self.jsonToRelationConverter.makeFileCitation(), `e`))
                return row
            
            # Stack of array index counters for use with
            # nested arrays:
            arrayIndexStack = Stack()
            # Not currently processing 
            #for prefix,event,value in self.parser:
            for nestedLabel, event, value in parser:
                #print("Nested label: %s; event: %s; value: %s" % (nestedLabel,event,value))
                if event == "start_map":
                    if not arrayIndexStack.empty():
                        # Starting a new attribute/value pair within an array: need
                        # a new number to differentiate column headers                    
                        self.incArrayIndex(arrayIndexStack)
                    continue
                
                if (len(nestedLabel) == 0) or\
                   (event == "map_key") or\
                   (event == "end_map"):
                    continue
                
                if not arrayIndexStack.empty():
                    # Label is now something like
                    # employees.item.firstName. The 'item' is ijson's way of indicating
                    # that we are in an array. Remove the '.item.' part; it makes
                    # the relation column header unnecessarily long. Then append 
                    # our array index number with an underscore:
                    nestedLabel = self.removeItemPartOfString(nestedLabel) +\
                                  '_' +\
                                  str(arrayIndexStack.top(exceptionOnEmpty=True))
                
                # Ensure that label contains only MySQL-legal identifier chars. Else
                # quote the label:                
                nestedLabel = self.jsonToRelationConverter.ensureLegalIdentifierChars(nestedLabel)
                
                # Check whether caller gave a type hint for this column:
                try:
                    colDataType = self.jsonToRelationConverter.getSchemaHint(nestedLabel)
                except KeyError:
                    colDataType = None
                
                if event == "string":
                    if colDataType is None:
                        colDataType = ColDataType.TEXT
                    self.jsonToRelationConverter.ensureColExistence(nestedLabel, colDataType)
                    self.setValInRow(row, nestedLabel, value)
                    continue
    
                if event == "boolean":
                    if colDataType is None:
                        colDataType = ColDataType.SMALLINT
                    self.jsonToRelationConverter.ensureColExistence(nestedLabel, colDataType)
                    if value:
                        value = 1
                    else:
                        value = 0
                    self.setValInRow(row, nestedLabel,value)                                
                    continue 
    
                if event == "number":
                    if colDataType is None:
                        colDataType = ColDataType.DOUBLE
                    self.jsonToRelationConverter.ensureColExistence(nestedLabel, colDataType)
                    self.setValInRow(row, nestedLabel,value)
                    continue
    
                if event == "null":
                    if colDataType is None:
                        colDataType = ColDataType.TEXT
                    self.jsonToRelationConverter.ensureColExistence(nestedLabel, colDataType)
                    self.setValInRow(row, nestedLabel, '')
                    continue
    
                if event == "start_array":
                    # New array index entry for this nested label.
                    # Used to generate <label>_0, <label>_1, etc. for
                    # column names:
                    arrayIndexStack.push(-1)
                    continue
    
                if event == "end_array":
                    # Array closed; forget the array counter:
                    arrayIndexStack.pop()
                    continue
    
                raise ValueError("Unknown JSON value type at %s for value %s (ijson event: %s)" % (nestedLabel,value,str(event))) 
            return row
        finally:
            self.reportProgressIfNeeded()
            self.getReadyForNextRow()

    def setValInRow(self, theRow, colName, value, tableName=None):
        '''
        Given a column name, a value and a partially filled row,
        add the column to the row, or set the value in an already
        existing column. Uses the JSONToRelation instance passed to 
        __init__() to obtain current schema. 

        :param theRow: list of values in their proper column positions
        :type theRow: List<<any>>
        :param colName: name of column into which value is to be inserted.
        :type colName: String
        :param value: the field value
        :type value: <any>, as per ColDataType
        :return: the passed-in row, with the new value added at the proper index.

        :rtype: List<<any>>
        '''
    
        if tableName is None:
            tableName = self.jsonToRelationConverter.mainTableName
        
        # Assumes caller has called ensureColExistence() on the
        # JSONToRelation object; so the following won't have
        # a key failure (but check anyway):
        try:
            colSpec = self.jsonToRelationConverter.getSchemaHint(colName, tableName)
            defaultVal = colSpec.getDefaultValue()
            if value is None:
                value = defaultVal
        except KeyError:
            if not self.unittesting:
                self.logWarn("Unanticipated field name '%s' intended for table '%s' (%s)" %\
                             (colName, tableName, self.jsonToRelationConverter.makeFileCitation()))
            return theRow
            
        targetPos = colSpec.colPos
        
        # Is value to go just beyond the current row len?
        if len(theRow) == targetPos:
            theRow.append(value)
            # Append the col name to the INSERT column name list:
            self.colNamesByTable[tableName].append(colName)
            return theRow
        # Is value to go into an already existing column?
        if (len(theRow) > targetPos):
            theRow[targetPos] = value
            return theRow
        
        # Adding a column beyond the current end of the row, but
        # not just by one position.
        # Make a list that spans the missing columns, and fill
        # it with each column's default value; then concat that list with theRow:
        fillList = []
        # Not sure the following conditional is still needed...:
        if len(theRow) == 0 and tableName == self.jsonToRelationConverter.mainTableName:
            defaultingColSpec = self.jsonToRelationConverter.getSchemaHintByPos(0, tableName)            
            self.colNamesByTable[tableName].append(defaultingColSpec.getName())
        for colPos in range(len(theRow), targetPos):
            defaultingColSpec = self.jsonToRelationConverter.getSchemaHintByPos(colPos, tableName)
            fillList.append(defaultingColSpec.getDefaultValue())
            # Add that column's name to the INSERT col name list:
            colName = defaultingColSpec.getName()
            self.colNamesByTable[tableName].append(colName)
        #fillList = ['null']*(targetPos - len(theRow))
        fillList.append(value)
        # Add the new value's col name to the INSERT list:
        self.colNamesByTable[tableName].append(colSpec.getName())        
        
        # Append the series of nulls and value of the new column
        # to the row we will return:
        theRow.extend(fillList)
        
        return theRow

    def incArrayIndex(self, arrayIndexStack):
        currArrayIndex = arrayIndexStack.pop()
        currArrayIndex += 1
        arrayIndexStack.push(currArrayIndex)

    def decArrayIndex(self, arrayIndexStack):
        currArrayIndex = arrayIndexStack.pop()
        currArrayIndex -= 1
        arrayIndexStack.push(currArrayIndex)

    def removeItemPartOfString(self, label):
        '''
        Given a label, like employee.item.name, remove the last
        occurrence of 'item'

        :param label: string from which last 'item' occurrence is to be removed
        :type label: String
        :return: label after deletion of the substring

        :rtype: String
        '''
        # JSONToRelation.REMOVE_ITEM_FROM_STRING_PATTERN is a regex pattern to remove '.item.' 
        # from column header names. Example: employee.item.name
        # will be replaced by employee.name. When used in r.search(),
        # the regex below creates a Match result instance with two
        # groups: 'item' and 'name'.
        match = re.search(GenericJSONParser.REMOVE_ITEM_FROM_STRING_PATTERN, label)        
        if match is None:
            # no appropriate occurrence of 'item' fround
            return label
        # Get label portion up to last occurrence of 'item',
        # and add the last part of the label to that part: 
        res = label[:match.start(1)] + match.group(2)
        return res

    def reportProgressIfNeeded(self):
        self.linesSinceLastProgReport += 1
        self.totalLinesDoneSoFar += 1
        if self.linesSinceLastProgReport >= self.progressEvery:
            self.logInfo("Processed %d JSON objects..." % self.totalLinesDoneSoFar)
            self.linesSinceLastProgReport = 0
            
    def logWarn(self, msg):
        self.jsonToRelationConverter.__class__.logger.warn(msg)

    def logInfo(self, msg):
        self.jsonToRelationConverter.__class__.logger.info(msg)
     
    def logError(self, msg):
        self.jsonToRelationConverter.__class__.logger.error(msg)

    def logDebug(self, msg):
        self.jsonToRelationConverter.__class__.logger.debug(msg)


class Stack(object):
    '''
    Simple stack implementation for use in recursive descent.
    '''
    
    def __init__(self):
        self.stackArray = []

    def empty(self):
        return len(self.stackArray) == 0
        
    def push(self, item):
        self.stackArray.append(item)
        
    def pop(self):
        try:
            return self.stackArray.pop()
        except IndexError:
            raise ValueError("Stack empty.")
    
    def top(self, exceptionOnEmpty=False):
        if len(self.stackArray) == 0:
            if exceptionOnEmpty:
                raise ValueError("Call to Stack instance method 'top' when stack is empty.")
            else:
                return None
        return self.stackArray[len(self.stackArray) -1]
    
    def stackHeight(self):
        return len(self.stackArray)
    
    