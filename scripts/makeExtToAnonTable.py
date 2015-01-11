'''
Created on Jan 11, 2015

@author: paepcke
'''
import os
import random
import string
import tempfile

from pymysql_utils.pymysql_utils import MySQLDB


class ExtToAnonTableMaker(object):
    
    def __init__(self, extIdsFileName):
        
        user = 'root'
        # Try to find pwd in specified user's $HOME/.ssh/mysql
        currUserHomeDir = os.getenv('HOME')
        if currUserHomeDir is None:
            pwd = None
        else:
            try:
                # Need to access MySQL db as its 'root':
                with open(os.path.join(currUserHomeDir, '.ssh/mysql_root')) as fd:
                    pwd = fd.readline().strip()
                # Switch user to 'root' b/c from now on it will need to be root:
                user = 'root'
                
            except IOError:
                # No .ssh subdir of user's home, or no mysql inside .ssh:
                pwd = None
        
        self.db = MySQLDB(user=user, passwd=pwd, db='Misc')
        
        self.makeTmpExtsTable()
        self.loadExtIds(extIdsFileName)
        outfile = tempfile.NamedTemporaryFile(prefix='extsIntsScreenNames', suffix='.csv', delete=True)
        # Need to close this file, and thereby delete it,
        # so that MySQL is willing to write to it. Yes,
        # that's a race condition. But this is an
        # admin script, run by one person:
        outfile.close()
        self.computeConversion(outfile.name)
        
        print('Outfile in %s' % outfile.name)

    def makeTmpExtsTable(self):
        # Create table to load the CSV file into:
        self.externalsTblNm = self.idGenerator(prefix='ExternalsTbl_')
        mysqlCmd = 'CREATE TEMPORARY TABLE %s (ext_id varchar(33));' % self.externalsTblNm
        self.db.execute(mysqlCmd)
        
    def loadExtIds(self, csvExtsFileName):
        mysqlCmd = "LOAD DATA INFILE '%s' " % csvExtsFileName +\
                   'INTO TABLE %s ' % self.externalsTblNm +\
                   "FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;"
        self.db.execute(mysqlCmd)
        
    def computeConversion(self, outCSVFileName):
        
        mysqlCmd = "SELECT 'ext_id','user_int_id','screen_name'" +\
		    	   "UNION " +\
		    	   "SELECT ext_id," +\
		    	   "       user_int_id," +\
		    	   "       username " +\
		    	   "  INTO OUTFILE '%s'" % outCSVFileName +\
		    	   "  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n'" +\
		    	   "  FROM "  +\
		    	   "    (SELECT ext_id,"  +\
		    	   "       user_id AS user_int_id "  +\
		    	   "       FROM %s LEFT JOIN edxprod.student_anonymoususerid " % self.externalsTblNm +\
		    	   "           ON %s.ext_id = edxprod.student_anonymoususerid.anonymous_user_id " % self.externalsTblNm +\
		    	   "    ) AS ExtAndInts " +\
		    	   "    LEFT JOIN edxprod.auth_user "  +\
		    	   "      ON edxprod.auth_user.id = ExtAndInts.user_int_id;"
        self.db.execute(mysqlCmd)
              
        
    def idGenerator(self, prefix='', size=6, chars=string.ascii_uppercase + string.digits):
        randPart = ''.join(random.choice(chars) for _ in range(size))
        return prefix + randPart


    
if __name__ == '__main__':
    
    converter = ExtToAnonTableMaker('/tmp/unmappables.csv');
