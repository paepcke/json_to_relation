#!/usr/bin/env python

import sys
import tempfile
import cProfile

def runCmd(jsonInFile):
    outFullPath = tempfile.TemporaryFile
    jsonConverter = JSONToRelation(InURI(jsonInFile),
                                   OutputFile(outFullPath,
                                              OutputDisposition.OutputFormat.SQL_INSERT_STATEMENTS,
                                              options='wb'),  # overwrite any sql file that's there
				              mainTableName='EdxTrackEvent'
                                   )
    jsonConverter.setParser(EdXTrackLogJSONParser(jsonConverter, 
						  'EdxTrackEvent', 
						  replaceTables=args.dropTables, 
						  dbName='Edx'
						  ))
    jsonConverter.convert()


if __name__ == '__main__':
    
    if len(sys.argv) < 2:
      print("Usage: speedTest.py <jsonInputFile>")
      sys.exit()

cProfile.run('runCmd, sys.argv[1]')
