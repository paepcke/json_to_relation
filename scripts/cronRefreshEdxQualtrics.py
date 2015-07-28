from surveyextractorimport QualtricsExtractor
import getopt
import sys

### Script for scheduling regular EdxQualtrics updates
### Usage for cron should be "cronRefreshEdxQualtrics.py -m -s -r"

# Append directory for dependencies to PYTHONPATH
# sys.path.append("/home/dataman/Code/qualtrics_etl/src/qualtrics_etl/")
source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir

from surveyextractor import QualtricsExtractor

qe = QualtricsExtractor()
opts, args = getopt.getopt(sys.argv[1:], 'amsr', ['--reset', '--loadmeta', '--loadsurveys', '--loadresponses'])
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
