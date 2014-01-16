#!/usr/bin/python


#!/usr/bin/env python
'''
Created on Jan 14, 2014

@author: paepcke
'''
import cgi
import cgitb
import os
import subprocess
import sys


cgitb.enable()

class MockCGI:
    
    def __init__(self):
        self.parms = {'courseId' : "Engineering/CS106A/Fall2013"}
        
    def getvalue(self, parmName, default=None):
        try:
            return self.parms[parmName]
        except KeyError:
            return default

class CourseTSVServer:
    
    def __init__(self, testing=False):
        if testing:
            self.parms = MockCGI()
        else:
            self.parms = cgi.FieldStorage()
        # Locate the makeCourseTSV.sh script:
        thisScriptDir = os.path.dirname(__file__)
        self.exportTSVScript = os.path.join(thisScriptDir, '../../scripts/makeCourseTSVs.sh')
    
    def exportClass(self):
        subprocess.call([self.exportTSVScript, '-u', 'www-data', self.parms.getvalue('courseId', '')],
                        stdout=sys.stdout, stderr=sys.stderr)
        
    
    def echoParms(self):
        for parmName in self.parms.keys():
            print("Parm: '%s': '%s'" % (self.parms.getvalue(parmName, '')))


if __name__ == '__main__':
    print("Content-type: text/html\n")
    
    print("<html>")
    print("<head></head>")
    print("<body>")
    
    server = CourseTSVServer(testing=True)
    server.exportClass()

    print("</body>")
