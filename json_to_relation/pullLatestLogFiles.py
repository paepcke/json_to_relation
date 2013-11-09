'''
Created on Nov 9, 2013

@author: paepcke
'''

class TrackLogLoader(object):
    '''
    Logs into S3 service, and pull JSON track log files that have not
    been pulled and transformed yet. Makes the list of all new
    absolute log file paths available in class variable newLogPaths.
    
    Based in large part on draft by Sef Kloninger. 
    '''


    def __init__(self):
        '''
        Constructor
        '''
    @classmethod
    def identifyNewLogFiles(cls, localLogFileDir):
        '''
        Logs into S3, and retrieves list of all log files there.
        Pulls list of previously examined log files from
        localLogFileDir/pullHistory.txt
        @param cls:
        @type cls:
        '''
        