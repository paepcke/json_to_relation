import json
import urllib2
from os.path import expanduser
import os.path
import sys
import xml.etree.ElementTree as ET
from pymysql_utils1 import MySQLDB
from string import Template
import zipfile as z
import StringIO as sio
from collections import OrderedDict
import getopt
import time
import logging
import datetime as dt
from ipToCountry import IpCountryDict

class QualtricsExtractor(MySQLDB):

    def __init__(self):
        '''
        Initializes extractor object with credentials from .ssh directory.
        Set log file directory.
        '''
        home = expanduser("~")
        userFile = home + '/.ssh/qualtrics_user'
        tokenFile = home + '/.ssh/qualtrics_token'
        dbFile = home + "/.ssh/mysql_user"
        if os.path.isfile(userFile) == False:
            sys.exit("User file not found: " + userFile)
        if os.path.isfile(tokenFile) == False:
            sys.exit("Token file not found: " + tokenFile)
        if os.path.isfile(dbFile) == False:
            sys.exit("MySQL user credentials not found: " + dbFile)

        self.apiuser = None
        self.apitoken = None
        dbuser = None
        dbpass = None

        with open(userFile, 'r') as f:
            self.apiuser = f.readline().rstrip()

        with open(tokenFile, 'r') as f:
            self.apitoken = f.readline().rstrip()

        with open(dbFile, 'r') as f:
            dbuser = f.readline().rstrip()
            dbpass = f.readline().rstrip()

        logging.basicConfig(filename="EdxQualtricsETL_%d%d%d_%d%d.log" % (dt.datetime.today().year, dt.datetime.today().month, dt.datetime.today().day, dt.datetime.now().hour, dt.datetime.now().minute),
                            level=logging.INFO)

        self.lookup = IpCountryDict()

        MySQLDB.__init__(self, db="EdxQualtrics", user=dbuser, passwd=dbpass)

## Database setup helper methods for client

    def resetSurveys(self):
        self.execute("DROP TABLE IF EXISTS `choice`;")
        self.execute("DROP TABLE IF EXISTS `question`;")

        choiceTbl = (       """
                            CREATE TABLE IF NOT EXISTS `choice` (
                              `SurveyId` varchar(50) DEFAULT NULL,
                              `QuestionId` varchar(50) DEFAULT NULL,
                              `ChoiceId` varchar(50) DEFAULT NULL,
                              `description` varchar(3000) DEFAULT NULL
                            ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
                            """ )

        questionTbl = (     """
                            CREATE TABLE IF NOT EXISTS `question` (
                              `SurveyID` varchar(50) DEFAULT NULL,
                              `QuestionID` varchar(5000) DEFAULT NULL,
                              `QuestionDescription` varchar(5000) DEFAULT NULL,
                              `ForceResponse` varchar(50) DEFAULT NULL,
                              `QuestionType` varchar(50) DEFAULT NULL,
                              `QuestionNumber` varchar(50) DEFAULT NULL
                            ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
                            """ )

        self.execute(choiceTbl)
        self.execute(questionTbl)

    def resetResponses(self):
        self.execute("DROP TABLE IF EXISTS `response`;")
        self.execute("DROP TABLE IF EXISTS `response_metadata`;")

        responseTbl = (     """
                            CREATE TABLE IF NOT EXISTS `response` (
                              `SurveyId` varchar(50) DEFAULT NULL,
                              `ResponseId` varchar(50) DEFAULT NULL,
                              `QuestionNumber` varchar(50) DEFAULT NULL,
                              `AnswerChoiceId` varchar(500) DEFAULT NULL,
                              `Description` varchar(5000) DEFAULT NULL
                            ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
                            """ )

        responseMetaTbl = ( """
                            CREATE TABLE IF NOT EXISTS `response_metadata` (
                              `SurveyID` varchar(50) DEFAULT NULL,
                              `ResponseID` varchar(50) DEFAULT NULL,
                              `Name` varchar(1200) DEFAULT NULL,
                              `EmailAddress` varchar(50) DEFAULT NULL,
                              `IPAddress` varchar(50) DEFAULT NULL,
                              `StartDate` datetime DEFAULT NULL,
                              `EndDate` datetime DEFAULT NULL,
                              `ResponseSet` varchar(50) DEFAULT NULL,
                              `ExternalDataReference` varchar(200) DEFAULT NULL,
                              `a` varchar(200) DEFAULT NULL,
                              `UID` varchar(200) DEFAULT NULL,
                              `userid` varchar(200) DEFAULT NULL,
                              `anon_screen_name` varchar(200) DEFAULT NULL,
                              `advance` varchar(200) DEFAULT NULL,
                              `Country` varchar(50) DEFAULT NULL,
                              `Finished` varchar(50) DEFAULT NULL,
                              `Status` varchar (200) DEFAULT NULL
                            ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
                            """ )

        self.execute(responseTbl)
        self.execute(responseMetaTbl)

    def resetMetadata(self):
        self.execute("DROP TABLE IF EXISTS `survey_meta`;")

        surveyMeta = (      """
                            CREATE TABLE IF NOT EXISTS `survey_meta` (
                              `SurveyId` varchar(50) DEFAULT NULL,
                              `PodioID` varchar(50) DEFAULT NULL,
                              `SurveyCreationDate` datetime DEFAULT NULL,
                              `UserFirstName` varchar(200) DEFAULT NULL,
                              `UserLastName` varchar(200) DEFAULT NULL,
                              `SurveyName` varchar(2000) DEFAULT NULL,
                              `responses` varchar(50) DEFAULT NULL,
                              `responses_actual` int DEFAULT NULL
                            ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
                            """ )

        self.execute(surveyMeta)

## API extractor methods

    def __getSurveyMetadata(self):
        '''
        Pull survey metadata from Qualtrics API v2.4. Returns JSON object.
        '''
        url = "https://stanforduniversity.qualtrics.com/WRAPI/ControlPanel/api.php?API_SELECT=ControlPanel&Version=2.4&Request=getSurveys&User=%s&Token=%s&Format=JSON&JSONPrettyPrint=1" % (self.apiuser, self.apitoken)
        data = json.loads(urllib2.urlopen(url).read())
        return data

    def __genSurveyIDs(self, forceLoad=False):
        '''
        Generator for Qualtrics survey IDs. Generates only IDs for surveys with
        new data to pull from Qualtrics unless user specifies that load should be
        forced.
        '''
        data = self.__getSurveyMetadata()
        surveys = data['Result']['Surveys']
        total = len(surveys)
        logging.info("Extracting %d surveys from Qualtrics..." % total)

        for idx, sv in enumerate(surveys):
            svID = sv['SurveyID']
            logging.info("Processing survey %d out of %d total: %s" % (idx+1, total, svID))
            if (forceLoad==True):
                yield svID
                continue

            payload = int(sv.pop('responses', 0))
            logging.info(" Found %d responses." % payload)
            existing = (self.__numResponses(svID) or 0)
            logging.info(" Have %d responses already." % existing)
            if (existing < payload) or (forceLoad == True):
                yield svID
            else:
                logging.info("  Survey %s yielded no new data." % svID)
                continue

    def __getSurvey(self, surveyID):
        '''
        Pull survey data for given surveyID from Qualtrics API v2.4. Returns XML string.
        '''
        url="https://stanforduniversity.qualtrics.com//WRAPI/ControlPanel/api.php?API_SELECT=ControlPanel&Version=2.4&Request=getSurvey&User=%s&Token=%s&SurveyID=%s" % (self.apiuser, self.apitoken, surveyID)
        data = urllib2.urlopen(url).read()
        return ET.fromstring(data)

    def __getResponses(self, surveyID):
        '''
        Pull response data for given surveyID from Qualtrics. Method generates
        JSON objects containing batches of 5000 surveys.
        '''

        urlTemp = Template("https://dc-viawest.qualtrics.com:443/API/v1/surveys/${svid}/responseExports?apiToken=${tk}&fileType=JSON")
        reqURL = urlTemp.substitute(svid=surveyID, tk=self.apitoken)
        req = json.loads(urllib2.urlopen(reqURL).read())

        statURL = req['result']['exportStatus'] + "?apiToken=" + self.apitoken
        percent, tries = 0, 0
        while percent != 100 and tries < 20:
            time.sleep(5) # Wait 5 seconds between attempts to acquire data
            try:
                stat = json.loads(urllib2.urlopen(statURL).read())
                percent = stat['result']['percentComplete']
            except:
                logging.warning(" Recovered from HTTP error.")
                continue
            finally:
                tries += 1
        if tries >= 20:
            logging.error("  Survey %s timed out." % surveyID)
            return None

        dataURL = stat['result']['fileUrl']
        remote = urllib2.urlopen(dataURL).read()
        dataZip = sio.StringIO(remote)
        archive = z.ZipFile(dataZip, 'r')
        dataFile = archive.namelist()[0]
        data = json.loads(archive.read(dataFile), object_pairs_hook=OrderedDict)

        if not data['responses']:
            return None
        else:
            return data


## Helper methods for interfacing with DB

    def __assignPodioID(self, survey, surveyID):
        '''
        Given a survey from Qualtrics, finds embedded field 'c' and returns
        field value. For mapping surveys to course names via Podio project IDs.
        '''
        try:
            podioID = "NULL"
            embeddedFields = survey.findall('./EmbeddedData/Field')
            for ef in embeddedFields:
                if ef.find('Name').text == 'c':
                    podioID = ef.find('Value').text
        except AttributeError as e:
            logging.warning("%s podioID getter failed with error: %s" % (surveyID, e))

        # Update DB with retrieved Podio ID
        query = "UPDATE survey_meta SET PodioID='%s' WHERE SurveyId='%s'" % (podioID, surveyID)
        self.execute(query.encode('UTF-8', 'ignore'))

    def __isLoaded(self, svID):
        '''
        Checks survey_meta table for given surveyID. Returns 1 if loaded, 0 otherwise.
        '''
        return self.query("SELECT count(*) FROM survey_meta WHERE SurveyID='%s'" % svID).next()[0]

    def __numResponses(self, svID):
        '''
        Given a survey ID, fetches number of responses loaded from survey_meta table.
        '''
        return self.query("SELECT responses_actual FROM survey_meta WHERE SurveyID='%s'" % svID).next()[0]

    def __getAnonUserID(self, uid):
        '''
        Given a userID from Qualtrics, returns translated anon user ID from platform data.
        '''
        q = "SELECT edxprod.idExt2Anon('%s')" % uid
        return self.query(q).next()[0]


## Transform methods

    def __parseSurveyMetadata(self, rawMeta):
        '''
        Given survey metadata for active user, returns a dict of dicts mapping
        column names to values for each survey. Skips over previously loaded surveys.
        '''
        svMeta = []
        for sv in rawMeta:
            keys = ['SurveyID', 'SurveyName', 'SurveyCreationDate', 'UserFirstName', 'UserLastName', 'responses']
            data = dict()
            svID = sv['SurveyID']
            if self.__isLoaded(svID):
                continue
            for key in keys:
                try:
                    val = sv[key].replace('"', '')
                    data[key] = val
                except KeyError as k:
                    data[k[0]] = 'NULL' # Set value to NULL if no data found
            svMeta.append(data) # Finally, add row to master dict
        return svMeta

    def __parseSurvey(self, svID):
        '''
        Given surveyID, parses survey from Qualtrics and returns:
         1. a dict mapping db column names to values corresponding to survey questions
         2. a dict of dicts mapping db column names to choices for each question
        Method expects an XML ElementTree object corresponding to a single survey.
        '''
        # Get survey from surveyID
        sv=None
        try:
            sv = self.__getSurvey(svID)
        except urllib2.HTTPError:
            logging.warning("Survey %s not found." % svID)
            return None, None

        masterQ = dict()
        masterC = dict()

        # Handle PodioID mapping in survey_meta table
        self.__assignPodioID(sv, svID)

        # Parse data for each question
        questions = sv.findall('./Questions/Question')
        for idx, q in enumerate(questions):
            parsedQ = dict()
            qID = q.attrib['QuestionID']
            parsedQ['SurveyID'] = svID
            parsedQ['QuestionID'] = qID
            parsedQ['QuestionNumber'] = q.find('ExportTag').text
            parsedQ['QuestionType'] = q.find('Type').text
            try:
                parsedQ['ForceResponse'] = q.find('Validation/ForceResponse').text
            except:
                parsedQ['ForceResponse'] = 'NULL'
            try:
                text = q.find('QuestionDescription').text.replace('"', '')
                if len(text) > 2000:
                    text = text[0:2000]
                parsedQ['QuestionDescription'] = text
            except:
                parsedQ['QuestionDescription'] = 'NULL'

            masterQ[idx] = parsedQ

            # For each question, load all choices
            choices = q.findall('Choices/Choice')
            for c in choices:
                parsedC = dict()
                cID = c.attrib['ID']
                parsedC['SurveyID'] = svID
                parsedC['QuestionID'] = qID
                parsedC['ChoiceID'] = cID
                cdesc = c.find('Description').text
                parsedC['Description'] = cdesc.replace("'", "").replace('"', '') if (cdesc is not None) else 'N/A'
                masterC[qID+cID] = parsedC

        return masterQ, masterC

    def __parseResponses(self, svID):
        '''
        Given a survey ID, parses responses from Qualtrics and returns:
        1. A list of dicts containing response metadata
        2. A list of dicts containing question responses
        Method expects a JSON formatted object with raw survey data.
        '''
        # Get responses from Qualtrics-- try multiple times to ensure API request goes through
        rsRaw = None
        for x in range(0,10):
            try:
                rsRaw = self.__getResponses(svID)
                break
            except urllib2.HTTPError as e:
                logging.error("  Survey %s gave error '%s'." % (svID, e))
                if e.getcode() == '400':
                    continue
                else:
                    return None, None

        # Return if API gave us no data
        if rsRaw == None:
            logging.info("  Survey %s gave no responses." % svID)
            return None, None

        # Get total expected responses
        rq = 'SELECT `responses` FROM survey_meta WHERE SurveyID = "%s"' % svID
        rnum = self.query(rq).next()

        logging.info(" Parsing %s responses from survey %s..." % (len(rsRaw['responses']), svID))

        responses = []
        respMeta = []
        rsID = None

        for rs in rsRaw['responses']:
            rsID = rs.pop('ResponseID', 'NULL')
            # Get response metadata for each response
            # Method destructively reads question fields
            rm = dict()
            rm['SurveyID'] = svID
            rm['ResponseID'] = rsID
            rm['Name'] = rs.pop('RecipientFirstName', 'NULL') + rs.pop('RecipientLastName', 'NULL')
            rm['EmailAddress'] = rs.pop('RecipientEmail', 'NULL')
            rm['IPAddress'] = rs.pop('IPAddress', 'NULL')
            rm['StartDate'] = rs.pop('StartDate', 'NULL')
            rm['EndDate'] = rs.pop('EndDate', 'NULL')
            rm['ResponseSet'] = rs.pop('ResponseSet', 'NULL')
            rm['ExternalDataReference'] = rs.pop('ExternalDataReference', 'NULL')
            rm['a'] = rs.pop('a', 'NULL')
            rm['UID'] = rs.pop('uid', 'NULL')
            rm['userid'] = rs.pop('user_id', 'NULL') #NOTE: Not transformed, use unclear
            if(len(rm['UID']) >= 40):
                rm['anon_screen_name'] = rm['UID']
            elif (len(rm['a']) >= 32):
                rm['anon_screen_name'] = self.__getAnonUserID(rm['a'])
            if (len(rm['IPAddress']) in range(8,16)):
                rm['Country'] = self.lookup.lookupIP(rm['IPAddress'])[1]
            elif (len(rm['UID']) in range(8,16)):
                rm['Country'] = self.lookup.lookupIP(rm['UID'])[1]
            rm['advance'] = rs.pop('advance', 'NULL')
            rm['Finished'] = rs.pop('Finished', 'NULL')
            rm['Status'] = rs.pop('Status', 'NULL')
            del rs['LocationLatitude']
            del rs['LocationLongitude']
            respMeta.append(rm)

            # Parse remaining fields as question answers
            fields = rs.keys()
            for q in fields:
                qs = dict()
                if 'Q' and '_' in q:
                    qSplit = q.split('_')
                    qNum = qSplit[0]
                    cID = qSplit[1]
                else:
                    qNum = q
                    cID = 'NULL'
                qs['SurveyID'] = svID
                qs['ResponseID'] = rsID
                qs['QuestionNumber'] = qNum
                qs['AnswerChoiceID'] = cID
                desc = rs[q].replace('"', '').replace("'", "").replace('\\', '').lstrip('u')
                if len(desc) >= 5000:
                    desc = desc[:5000] #trim past max field length
                qs['Description'] = desc
                responses.append(qs)

        return responses, respMeta


## Convenience method for handling query calls to MySQL DB.

    def __loadDB(self, data, tableName):
        '''
        Convenience function for writing data to named table. Expects data to be
        represented as a list of dicts mapping column names to values.
        '''
        try:
            columns = tuple(data[20].keys())
            table = []
            # logging.info("     " + ", ".join(columns))
            for row in data:
                vals = tuple(row.values())
                # logging.info("     " + ", ".join(vals))
                table.append(vals)
            self.bulkInsert(tableName, columns, table)
        except Exception as e:
            logging.error("  Insert query failed: %s" % e)


## Client data load methods

    def loadSurveyMetadata(self):
        '''
        Client method extracts and transforms survey metadata and loads to MySQL
        database using query interface inherited from MySQLDB class.
        '''
        rawMeta = self.__getSurveyMetadata()
        svMeta = rawMeta['Result']['Surveys']
        parsedSM = self.__parseSurveyMetadata(svMeta)
        if len(parsedSM) > 0:
            self.__loadDB(parsedSM, 'survey_meta')

    def loadSurveyData(self):
        '''
        Client method extracts and transforms survey questions and question
        choices and loads to MySQL database using MySQLDB class methods.
        '''
        sids = self.__genSurveyIDs(forceLoad=True)
        for svID in sids:
            questions, choices = self.__parseSurvey(svID)
            if (questions == None) and (choices == None):
                continue
            self.__loadDB(questions.values(), 'question')
            self.__loadDB(choices.values(), 'choice')

    def loadResponseData(self, startAfter=0):
        '''
        Client method extracts and transforms response data and response metadata
        and loads to MySQL database using MySQLDB class methods. User can specify
        where to start in the list of surveyIDs.
        '''
        sids = self.__genSurveyIDs()
        for idx, svID in enumerate(sids):
            if idx < startAfter:
                logging.info("  Skipped surveyID %s" % svID)
                continue # skip first n surveys
            responses, respMeta = self.__parseResponses(svID)
            retrieved = len(respMeta) if respMeta is not None else 0
            logging.info(" Inserting %d responses on survey %s to database." % (retrieved, svID))
            self.execute("UPDATE survey_meta SET responses_actual='%d' WHERE SurveyID='%s'" % (retrieved, svID))
            if (responses == None) or (respMeta == None):
                continue
            self.__loadDB(responses, 'response')
            self.__loadDB(respMeta, 'response_metadata')



if __name__ == '__main__':
    qe = QualtricsExtractor()
    opts, args = getopt.getopt(sys.argv[1:], 'amsrt', ['--reset', '--loadmeta', '--loadsurveys', '--loadresponses', '--responsetest'])
    for opt, arg in opts:
        if opt in ('-a', '--reset'):
            qe.resetMetadata()
            qe.resetSurveys()
            qe.resetResponses()
        elif opt in ('-m', '--loadmeta'):
            qe.loadSurveyMetadata()
        elif opt in ('-s', '--loadsurvey'):
            qe.resetSurveys()
            qe.loadSurveyData()
        elif opt in ('-r', '--loadresponses'):
            qe.loadResponseData()
        elif opt in ('-t', '--responsetest'):
            qe.resetMetadata()
            qe.loadSurveyMetadata()
            qe.resetResponses()
            qe.loadResponseData()
