#!/usr/bin/env python
'''
Created on Jan 14, 2014

@author: paepcke
'''
import cgi
import cgitb
import os
import subprocess


cgitb.enable()

class CourseTSVServer:
    
    def __init__(self):
        self.parms = cgi.FieldStorage()
    
    def exportClass(self):
        thisScriptDir = os.path.dirname(__file__)
        exportTSVScript = os.path.join(thisScriptDir, '../../scripts/makeCourseTSV.sh')
        subprocess.call([exportTSVScript, '-u', 'www-data', self.parms.getvalue('courseId', '')])
        
    
    def echoParms(self):
        for parmName in self.parms.keys():
            print("Parm: '%s': '%s'" % (self.parms.getvalue(parmName, '')))


if __name__ == '__main__':
    print("Content-type: text/html\n\n")
    
    server = CourseTSVServer()
  
