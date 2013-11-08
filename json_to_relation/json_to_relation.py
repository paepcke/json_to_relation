#!/usr/bin/env python
#TODO: Edx unittest for detecting server downtimes in log
#TODO: /app21/tracking.log-20130831.gz:174310: event is not a dict in select_rubric event: '{u'category': 0, u'selection': u'1', u'location': u'i4x://Education/EDUC115N/combinedopenended/04d9f185e689415f9217a5423166891c'}' (TypeError('eval() arg 1 must be a string or code object',))
#TODO: documentation: eventID is not a key: used to hold together pointers to states or answers
#TODO: event is not a dict in problem_reset event: 'input_i4x-Engineering-QMSE01-problem-b6a3d17b9eca45f48eab332017e858ee_2_1=2.14'
#TODO: want courseid filled in for video events and some other event_types:
#   		   seq_goto     
#   		   /courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/sequential/5798494e781844498921bff40c5e014a/goto_position
#   		   show_transcript
#   		   /heartbeat
#   		   /courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/sequential/162de22b243243e9bf8111266303c9fa/goto_position
#   		   seq_next
#   		   pause_video
#   		   /courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/combinedopenended/b3c41df5b9ef40ea9c00e8252031207d/get_legend
#   		   /courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/combinedopenended/b3c41df5b9ef40ea9c00e8252031207d/get_last_response
#   		   load_video    
#TODO: ERROR 1064 (42000) at line 5291428 in file: './tracking.log-20131001.gz.2013-10-29T18_16_21.887671_25959.sql': You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.76 Safari/' at line 1
#TODO: testSaveAnswerInPath test case of test_edxJSON... not passing
#TODO: Scramble UID, adding table UIDMap
#TODO: change transformAndLoad to log in as root
#TODO: done still get None
#TODO: zipcode
'''
Created on Sep 14, 2013

@author: paepcke
'''

from cStringIO import StringIO
from collections import OrderedDict
import copy
import datetime
import logging
import math
import os
import re
import shutil
import tempfile
import time

from col_data_type import ColDataType
from generic_json_parser import GenericJSONParser
from input_source import InputSource, InURI, InString, InMongoDB, \
    InPipe #@UnusedImport
from output_disposition import OutputDisposition, OutputFile, OutputPipe


class JSONToRelation(object):
    '''
    Given a source with JSON structures, derive a schema, and construct 
    a relational table. Source can be a local file name, a URL, a
    StringIO pseudofile, or a Unix pipe.
    
    JSON structures in the source must be one per line. That is, each line in 
    the source must be a self contained JSON object. Pretty printed strings
    won't work. 
    '''
    
    MAX_SQL_INT = math.pow(2,31) - 1
    MIN_SQL_INT = -math.pow(2,31)
    
    # Regex pattern to check whether a string
    # contains only chars legal in a MySQL identifier
    #, i.e. alphanumeric plus underscore plus dollar sign:
    LEGAL_MYSQL_ATTRIBUTE_PATTERN = re.compile("^[$\w]+$")

    # How long a MySQL packet is allowed to be.
    # MySQL server default is 1M as per documentation,
    # but 16M as per observation. Change that value
    # on server via either  
    #     mysqld --max_allowed_packet=32M
    # or putting this into /etc/mysql/my.cnf
    #       [mysqld]
    #       max_allowed_packet=16M
    # Then change the following constant to the
    # new limit minus about 1K to allow for
    # the INSERT, and column name specs. Or round
    # down like this:
    MAX_ALLOWED_PACKET_SIZE = 1000000; 
    

    # Remember whether logging has been initialized (class var!):
    loggingInitialized = False
    logger = None
        
    def __init__(self, 
                 jsonSource, 
                 destination, 
                 schemaHints=OrderedDict(),
                 jsonParserInstance=None,
                 loggingLevel=logging.INFO,
                 logFile=None,
                 mainTableName='Main',
                 progressEvery=1000):
        '''
        Create a JSON-to-Relation converter. The JSON source can be
        a file with JSON objects, a StringIO.StringIO string pseudo file,
        stdin, or a MongoDB
        
        The destination can be a file, where CSV is written in Excel-readable
        form, stdout, or a MySQL table specification, where the ouput rows
        will be inserted.
        
        SchemaHints optionally specify the SQL types of particular columns.
        By default the processJSONObs() method will be conservative, and
        specify numeric columns as DOUBLE. Even though all encountered values
        for one column could be examined, and a more appropriate type chosen,
        such as INT when only 4-byte integers are ever seen, future additions
        to the table might exceed the INT capacity for that column. Example
        
        If schemaHints is provided, it is a Dict mapping column names to ColDataType.
        The column names in schemaHints must match the corresponding (fully nested)
        key names in the JSON objects::
            schemaHints dict: {'msg.length' : ColDataType.INT,
                               'chunkSize' : ColDataType.INT}
        
        For unit testing isolated methods in this class, set jsonSource and
        destination to None.

        This constructor can be thought of as creating the main relational
        table that will hold all results from the JSON parsers in relational
        form. However, parsers may call startNewTable() to build any new tables
        they wish.
        
        @param jsonSource: subclass of InputSource that wraps containing JSON structures, or a URL to such a source
        @type jsonSource: {InPipe | InString | InURI | InMongoDB} (InMongoDB not implemented)
        @param destination: instruction to were resulting rows are to be directed
        @type destination: {OutputPipe | OutputFile }
        @param schemaHints: Dict mapping col names to data types (optional). Affects the default (main) table.
        @type schemaHints: OrderedDict<String,ColDataTYpe>
        @param jsonParserInstance: a parser that takes one JSON string, and returns a CSV row, or other
                                   desired output, like SQL dump statements. Parser also must inform this 
                                   parent object of any generated column names.
        @type jsonParserInstance: {GenericJSONParser | EdXTrackLogJSONParser | CourseraTrackLogJSONParser}
        @param loggingLevel: level at which logging output is show. 
        @type loggingLevel: {logging.DEBUG | logging.WARN | logging.INFO | logging.ERROR | logging.CRITICAL}
        @param logFile: path to file where log is to be written. Default is None: log to stdout.
                        A warning is logged if logFile is None and the destination is OutputPipe. In this
                        case logging messages will be mixed in with the data output
        @type logFile: String
        @param progressEvery: number of JSON object to process before reporting the number in a log info msg. If None, no reporting
        @type  progressEvery: {int | None}
        @raise ValueErrer: when value of jsonParserInstance is neither None, nor an instance of GenericJSONParser,
                        nor one of its subclasses.
        @raise ValueError: when jsonSource is not an instance of InPipe, InString, InURI, or InMongoDB  
        '''

        # If jsonSource and destination are both None,
        # the caller is just unit testing some of the methods
        # below:
        if jsonSource is None and destination is None:
            return
        if not isinstance(jsonSource, InputSource):
            raise ValueError("JSON source must be an instance of InPipe, InString, InURI, or InMongoDB; is %s" % type(jsonSource))
        
        if not isinstance(schemaHints, OrderedDict):
            raise ValueError("The schemaHints, if provided, must be an OrderedDict.")
        
        self.jsonSource = jsonSource
        self.destination = destination
        self.mainTableName = mainTableName
        # Greenwich Mean Time (UTC) as yyyymmddhhssmm
        self.loadDateTime = time.strftime('%Y%m%d%H%M%s', time.gmtime())
        self.loadFile = jsonSource.getSourceName()

        # Check schemaHints correctness:
        if schemaHints is not None:
            for typeHint in schemaHints.values():
                if not ColDataType.isinstance(typeHint):
                    raise ValueError("Schema hints must be of type ColDataType")
        self.userDefinedHints = schemaHints

        # The following three instance vars are used for accumulating INSERT
        # values when output is a MySQL dump. 
        # Current table for which insert values are being collected:
        self.currOutTable = None
        
        # Insert values so far (array of value arrays):
        self.currValsArray = []
        
        # Column names for which INSERT values are being collected.
        # Ex.: 'col1,col2':
        self.currInsertSig = None
        
        # Current approximate len of INSERT statement 
        # for cached values:
        self.valsCacheSize = 0;

        # Count JSON objects (i.e. JSON file lines) as they are passed
        # to us for parsing. Used for logging malformed entries:
        self.lineCounter = -1
        
        self.setupLogging(loggingLevel, logFile)

        # Check whether log output would interleave with data output:
        if logFile is None and isinstance(destination, OutputPipe):
            JSONToRelation.logger.warn("If output is to a Unix pipe and no log file name is provided, log output will be mixed with data output.")
        
        if jsonParserInstance is None:
            self.jsonParserInstance = GenericJSONParser(self)
        elif isinstance(jsonParserInstance, GenericJSONParser):
            self.jsonParserInstance = jsonParserInstance
        else:
            raise ValueError("Parameter jsonParserInstance needs to be of class GenericJSONParser, or one of its subclasses.")
        
        #************ Unimplemented Options **************
        #if self.outputFormat == OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS:
        #    raise NotImplementedError("Output as MySQL statements not yet implemented")
        #*************************************************
        
        # Dict col name to ColumnSpec object:
        self.cols = OrderedDict()
        
        # Position of column for next col name that is
        # newly encountered: 
        self.nextNewColPos = 0;

    def flush(self):
        '''
        MUST be called when no more items are to be converted. Needed
        because for SQL statements, value insertions are held back to
        accumulate multiple insert value for use in a single insert
        statement. This speeds up load times into the databases later.
        If flush() is not called, output may be missing.
        '''
        self.processFinishedRow('FLUSH', self.destination)        

    def setupLogging(self, loggingLevel, logFile):
        if JSONToRelation.loggingInitialized:
            # Remove previous file or console handlers,
            # else we get logging output doubled:
            JSONToRelation.logger.handlers = []
            
        # Set up logging:
        JSONToRelation.logger = logging.getLogger('jsonToRel')
        JSONToRelation.logger.setLevel(loggingLevel)
        # Create file handler if requested:
        if logFile is not None:
            handler = logging.FileHandler(logFile)
        else:
            # Create console handler:
            handler = logging.StreamHandler()
        handler.setLevel(loggingLevel)
#         # create formatter and add it to the handlers
#         formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
#         fh.setFormatter(formatter)
#         ch.setFormatter(formatter)
        # Add the handler to the logger
        JSONToRelation.logger.addHandler(handler)
        #**********************
        #JSONToRelation.logger.info("Info for you")
        #JSONToRelation.logger.warn("Warning for you")
        #JSONToRelation.logger.debug("Debug for you")
        #**********************
        
        JSONToRelation.loggingInitialized = True

    def setParser(self, parserInstance):
        '''
        Set the parser instance to use for upcoming calls to the convert() method.
        @param parserInstance: must be instance of GenericJSONParser or one of its subclasses 
        @type parserInstance: {GenericJSONParser | subclass}
        '''
        self.jsonParserInstance = parserInstance


    def startNewTable(self, tableName, schemaHintsNewTable):
        '''
        Called by parsers when they need to start a new relational
        table beyond the one that is created for them. Ex: edxTrackLogJSONParser.py
        needs auxiliary tables for deeply embedded JSON structures with unpredictable
        numbers of elements (e.g. problem state). The schemaHintsNewTable 
        is an optionally ordered dict. Parsers may add additional columns later
        via calls to ensureColExistence(). Note that for MySQL load files such
        subsequent addition generates ALTER table, which might be expensive. So,
        completeness of the schemaHintsNewTable dict is recommended for MySQL
        load file outputs.
        @param tableName: name by which parser will refer to this table.
        @type tableName: String
        @param schemaHintsNewTable: dict that map column names to SQL types
        @type schemaHintsNewTable: [Ordered]Dict<String,ColumnSpec>
        '''
        self.destination.startNewTable(tableName, schemaHintsNewTable)
        
    def getSourceName(self):
        '''
        Request a human-readable name of the JSON source, which 
        might be a pipe, or a file, or something else. Each input source
        class knows to provide such a name.
        '''
        return self.jsonSource.getSourceName()
        
    def setSchemaHints(self, schemaHints, tableName=None):
        '''
        Given a schema hint dictionary, set the given table's schema
        to the given dictionary. Any schema fragments already defined
        for table tableName will be removed
        @param schemaHints: dict mapping column names to ColumnSpec instances
        @type schemaHints: [Ordered]Dict<String,ColumnSpec>
        @param tableName: name of table whose schema is to be changed. None changes the main (default) table's schema
        @type tableName: String
        '''
        if tableName is None:
            tableName = self.mainTableName
        self.destination.addSchemaHints(tableName, schemaHints)

    def getSchemaHint(self, colName, tableName=None):
        '''
        Given a column name, and a table name, return the ColumnSpec for that column in that table.
        If tableName is None, the table is assumed to be the main (default) table.
        @param colName: name of column whose ColumnSpec instance is wanted
        @type colName: String
        @param tableName: name of table of which the column is a part 
        @type tableName: {String | None}
        @return: a ColumnSpec object that contains the SQL type name of the column
        @rtype: ColumnSpec
        @raise KeyError: if either the table or the column don't exist.  
        '''
        if tableName is None:
            tableName = self.mainTableName
        return self.destination.getSchemaHint(colName, tableName)

    def getSchemaHintByPos(self, pos, tableName=None):
        if tableName is None:
            tableName = self.mainTableName
        return self.destination.getSchemaHintByPos(pos, tableName)
        
    
    def ensureColExistence(self, colName, colDataType, tableName=None):
        if tableName is None:
            tableName = self.mainTableName
        userDefinedHintType = self.userDefinedHints.get(colName, None)
        if userDefinedHintType is not None:
            # We checked type correctness in __init__() method, so trust it here:
            colDataType = userDefinedHintType
        self.destination.ensureColExistence(colName, colDataType, self, tableName)

    def convert(self, prependColHeader=False):
        '''
        Main user-facing API method. Read from the JSON source establish
        in the __init__() call. Create a MySQL schema as the JSON is read.
        Convert each JSON object into the requested output format (e.g. CSV),
        and deliver it to the destination (e.g. a file)
        @param prependColHeader: If true, the final destination, if it is stdout or a file,
                will have the column names prepended. Note that this option requires that
                the output file is first written to a temp file, and then merged with the
                completed column name header row to the final destination that was specified
                by the client. 
        @type prependColHeader: Boolean
        '''
        savedFinalOutDest = None
        if self.destination.getOutputFormat() != self.destination.OutputFormat.SQL_INSERT_STATEMENTS: 
            if prependColHeader:
                savedFinalOutDest = self.destination
                (tmpFd, self.tmpFileName)  = tempfile.NamedTemporaryFile(suffix='.csv',prefix='jsonToRelationTmp')
                os.close(tmpFd)
                self.destination = OutputFile(self.tmpFileName)

        with self.destination as outFd, self.jsonSource as inFd:
            for jsonStr in inFd:
                newRow = []
                try:
                    # processOneJSONObject will call pushtToTable() for all 
                    # tables necessary for each event type. The method will
                    # direct the top level event information to the table
                    # called self.mainTableName.
                    self.jsonParserInstance.processOneJSONObject(jsonStr, newRow)
                except (ValueError, KeyError) as e:
                    JSONToRelation.logger.warn('Line %s: bad JSON object: %s' % (self.makeFileCitation(), `e`))
                self.bumpLineCounter()

            # Since we hold back SQL insertion values to include them
            # all into one INSERT statement, need to flush after last
            # call to processOneJSONObject, after pushing COMMIT:
            if self.destination.getOutputFormat() == OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS:
                self.processFinishedRow('FLUSH', outFd) 
                self.pushString(self.jsonParserInstance.getDumpPostscript())
        
        # If output to other than MySQL table (e.g. CSV file), check whether
        # we are to prepend the column header row:
        if prependColHeader and savedFinalOutDest is not None:
            try:
                with open(self.destination.name, 'rb') as inFd, OutputDisposition(savedFinalOutDest) as finalOutFd:
                    colHeaders = self.getColHeaders()
                    self.pushToTable(colHeaders, finalOutFd)
                    shutil.copyfileobj(inFd, finalOutFd.fileHandle)
            finally:
                self.tmpFileName.close() # This deletes the file
                

    def pushString(self, whatToWrite):
        '''
        Pushes the given string straight to the output (pipe or file).
        No error checking is done. Used by underlying parsers 
        for SQL other than INSERT statements, such as DROP, CREATE. 
        @param whatToWrite: a complete SQL statement.
        @type whatToWrite: String
        '''
        self.destination.write(whatToWrite)
        
    def pushToTable(self, row, outFd=None):
        '''
        Called both from convert(), and from some parsers to add one row to 
        one table. For CSV outputs the target table is implied: there is only
        one. But for parsers that generate INSERT statements, the targets
        might be different tables on each call. 
        @param row: either an array of CSV values, or a triplet (tableName, insertSig, valsArray) (from MySQL INSERT-generating parsers)
        @type row: {[<any>] | (String, String, [<any>])}
        @param outFd: subclass of OutputDisposition
        @type outFd: subclass of OutputDisposition
        '''
        #****************************
        #if row.count('eventID') > 1:
        #    raise ValueError("Found it!: %s" % self.tmpJSONStr)
        #****************************        
        if outFd is None:
            outFd = self.destination
        self.processFinishedRow(row, outFd)

    def processFinishedRow(self, filledNewRow, outFd):
        '''
        When a row is finished, this method processes the row as per
        the user's disposition. The method writes the row to a CSV
        file, or pipe, or generates an SQL insert statement for later.
        
        The filledNewRow parameter looks different, depending on whether
        the underlying parser generates MySQL insert statement information,
        or CSV rows. The latter are just written to outFD. MySQL insert info
        looks like this: ('tableName', 'insertSig', [valsArray]). The insertSig
        is a string as needed for the INSERT statement's column names part. 
        Ex.: 'col1,col2'. 
        
        @param filledNewRow: the list of values for one row, possibly including empty fields  
        @type filledNewRow: List<<any>>
        @param outFd: an instance of a class that writes to the destination
        @type outFd: OutputDisposition
        '''
        # We handle 'rows' destined for MySQL dumps differently
        # from rows destined to CSV. Parsers that generate dump
        # information as they translate JSON provide different
        # information than CSV destined parsers. MySQL dumps provide
        # a list 
        if self.destination.getOutputFormat() == OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS:
            filledNewRow = self.prepareMySQLRow(filledNewRow)
        if filledNewRow is not None:
            outFd.writerow(filledNewRow)

    def prepareMySQLRow(self, insertInfo):
        '''
        Receives either a triple ('tableName', 'insertSig', [valsArray]),
        or the string 'FLUSH'. Generates either None, or a legal MySQL insert statement. 
        The method is lazy.
        
        It collects values to be inserted into the same table, and the same
        columns within that table, and returns a non-Null string only when
        the incoming insertInfo is for a different table, or a different set
        of columns in the same table (as the previous calls). In that case the
        returned string is a legal MySQL INSERT statement, possibly multi-valued.
        
        If insertInfo is the string 'FLUSH', then an INSERT statement is
        returned for any held-back prior values. 
        
        @param insertInfo: information on what to generate for MySQL dumps
        @type insertInfo: {(String, String, [<any>]) | String)}
        '''
        try:
            (tableName, insertSig, valsArray) = insertInfo
        except ValueError:
            if insertInfo == 'FLUSH':
                return self.finalizeInsertStatement()
            else:
                raise ValueError('Bad argument to prepareMySQLRow: %s' % str(insertInfo))

        # Compute approximate new size of hold-back buffer with these new values:
        newCacheSize = self.valsCacheSize + self.calculateHeldBackDataSize(valsArray)
        
        # Have we started accumulating values in an earlier call?
        if self.currInsertSig is not None: 
            if tableName == self.currOutTable and insertSig == self.currInsertSig:
                if newCacheSize > JSONToRelation.MAX_ALLOWED_PACKET_SIZE:
                    # New vals could be held back, but buffer is full:
                    # Construct INSERT statement from the cached values:
                    insertStatement = self.finalizeInsertStatement()
                    # Start accumulating values for this new INSERT request:
                    self.currOutTable = tableName
                    self.currInsertSig = insertSig
                    self.currValsArray.append(copy.copy(valsArray))
                    return insertStatement
                else:
                    # Can hold back the new values:
                    self.valsCacheSize = newCacheSize
                    self.currValsArray.append(copy.copy(valsArray))
                    return None
            else:
                # Were accumulating vals, but this call is for a different
                # table or set of columns:
                insertStatement = self.finalizeInsertStatement()
                # Start accumulating values for this new INSERT request:
                self.currOutTable = tableName
                self.currInsertSig = insertSig
                # Copy the array into the cache buffer: valsArray
                # is passed by reference, and subsequent changes
                # would overwrite the cache. Shallow copy suffices,
                # because all row values are base types:
                self.currValsArray = [copy.copy(valsArray)]
                return insertStatement
            
        # We have not yet started to accumulate values:
        else:
            # If even the first INSERT values are too big for
            # the empty hold-back buffer: just send the INSERT
            # right away:
            if newCacheSize > JSONToRelation.MAX_ALLOWED_PACKET_SIZE:
                valuesPartFileStr = self.constructValuesStr(valsArray)
                insertStatement = "INSERT INTO %s (%s) VALUES %s;" % (tableName, insertSig, valuesPartFileStr.getvalue())
                return insertStatement
            # Hold back the new values:
            self.valsCacheSize = newCacheSize
            self.currOutTable = tableName
            self.currInsertSig = insertSig
            # Copy the array into the cache buffer: valsArray
            # is passed by reference, and subsequent changes
            # would overwrite the cache. Shallow copy suffices,
            # because all row values are base types:
            self.currValsArray = [copy.copy(valsArray)]
            return None
         
    def finalizeInsertStatement(self):
        '''
        Create a possibly multivalued INSERT statement from what is
        stored in self.currOutTable, self.currInsertSig, and self.currValsArray.
        Example return::
           INSERT INTO myTable (col2, col2) VALUES
              ('foo',10),
              ('bar',20);
        @return: a fully formed SQL INSERT statement, possibly including multiple values. None if nothing to insert.
        @rtype: {String | None}
        '''
        
        try:
            if len(self.currValsArray) == 0:
                # Nothing to INSERT:
                res = None
                return 
            
            valsFileStr = self.constructValuesStr(self.currValsArray)
            
            res = "INSERT INTO %s (%s) VALUES %s;" % (self.currOutTable, self.currInsertSig, valsFileStr.getvalue())
        finally:
            # We are no longer accumulating INSERT values right now:
            self.currOutTable = None
            self.currInsertSig = None
            self.currValsArray = []
            self.insertValCacheSize = 0
            return res

    def constructValuesStr(self, valsArrays):
        '''
        Takes an array of arrays that hold the values to use in 
        an INSERT statement. Ex: [['foo',10],['bar',20]]. Returns
        a StringIO string file containing a legal INSERT statement's
        VALUES part: ('foo',10),('bar',20)
        @param valsArrays: array of values arrays
        @type valsArrays: [[<any>]]
        @return: IOString string file with legal VALUES section of INSERT statement
        @rtype: IOString
        '''
        # Build the values part:
        valsFileStr = StringIO()
        # Avoid putting anything into the 
        # file string in the nested loop below, so
        # that noting needs to be stripped
        # out afterwards; avoids a string copy.
        # Not sure whether this optimization is
        # needed, but there it is:
        isFirstValTuple = True
        isFirstVal = True
        for insertVals in valsArrays:
            if isFirstValTuple:
                valsFileStr.write('\n    (')
                isFirstValTuple = False
            else:
                valsFileStr.write(',\n    (')
            for insertVal in insertVals:
                if isFirstVal:
                    isFirstVal = False
                else:
                    valsFileStr.write(str(','))
                # Ensure that strings get a quote char arround them, except
                # for 'null', which needs to be written without quotes:
                if insertVal == 'null':
                    valsFileStr.write(insertVal)
                # Turn 'None' entries from JSON-converted empty JSON flds to null: 
                elif insertVal == None:
                    valsFileStr.write('null')
                else:
                    valsFileStr.write("'" + insertVal + "'" if isinstance(insertVal,basestring) else str(insertVal))
            valsFileStr.write(')')
            isFirstVal = True
        return valsFileStr

    def getSchema(self, tableName=None):
        '''
        Returns an ordered list of ColumnSpec instances.
        Each such instance holds column name and SQL type.
        @param tableName: name of table for which schema is wanted. None: the main (default) table. 
        @type tableName: String
        @return: ordered list of column information
        @rtype: (ColumnSpec) 
        '''
        if tableName is None:
            tableName = self.mainTableName
        return self.destination.getSchema(tableName)

    def getColHeaders(self, tableName=None):
        '''
        Returns a list of column header names collected so far.
        @return: list of column headers that were discovered so far by an 
                 associated JSON parser descending into a JSON structure.
        @rtype: [String]
        '''
        headers = []
        for colSpec in self.getSchema(tableName):
            headers.append(colSpec.colName)
        return headers

    def getNextNewColPos(self):
        '''
        Returns the position of the next new column that
        may need to be added when a previously unseen JSON
        label is encountered.
        @return: position in schema where the next new discovered column header is to go.
        @rtype: int 
        '''
        return self.nextNewColPos
    
    def bumpNextNewColPos(self):
        self.nextNewColPos += 1

    def calculateHeldBackDataSize(self, valueArray):
        '''
        Computes number of ASCII bytes needed for the
        values in the given array. Used to estimate 
        when held-back INSERT data needs to be flushed
        to server. Ex: ['foo', 10] returns 7.
        
        @param valueArray: array of mixed-type values to be INSERTed into MySQL at some point
        @type valueArray: [<any>]
        '''
        arrSize = 0
        for val in valueArray:
            arrSize += len(str(val))
        # Add bytes for commas, spaces after the commas, and
        # a pair of quotes around strings (assume worst case of
        # every value being a string:
        arrSize += 4*len(valueArray)
        return arrSize
    
    def ensureLegalIdentifierChars(self, proposedMySQLName):
        '''
        Given a proposed MySQL identifier, such as a column name,
        return a possibly modified name that will be acceptable to
        a MySQL database. MySQL accepts alphanumeric, underscore,
        and dollar sign. Identifiers with other chars must be quoted.
        Quote characters embedded within the identifiers must be
        doubled to be escaped. 
        @param proposedMySQLName: input name
        @type proposedMySQLName: String
        @return: the possibly modified, legal MySQL identifier
        @rtype: String
        '''
        if JSONToRelation.LEGAL_MYSQL_ATTRIBUTE_PATTERN.match(proposedMySQLName) is not None:
            return proposedMySQLName
        # Got an illegal char. Quote the name, doubling any
        # embedded quote chars (sick, sick, sick proposed name): 
        quoteChar = '"'
        if proposedMySQLName.find(quoteChar) > -1:
            quoteChar = "'"
            if proposedMySQLName.find(quoteChar) > -1:
                # Need to double each occurrence of quote char in the proposed name;
                # get a list of the chars, i.e. 'explode' the string into letters:
                charList = list(proposedMySQLName)
                newName = ""
                for letter in charList:
                    if letter == quoteChar:
                        letter = quoteChar + quoteChar
                    newName += letter
                proposedMySQLName = newName
        return quoteChar + proposedMySQLName + quoteChar

    def makeFileCitation(self):
        return self.getSourceName() + ':' + str(self.lineCounter)

    def bumpLineCounter(self):
        self.lineCounter += 1