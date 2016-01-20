# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

'''
Created on Sep 22, 2013

@author: paepcke
'''
import unittest

from json_to_relation.generic_json_parser import GenericJSONParser, Stack
from json_to_relation.mysqldb import MySQLDB


class Test(unittest.TestCase):


    def testStack(self):
        myStack = Stack()
        myStack.push(3)
        self.assertEqual(3, myStack.pop(), "Bad push/pop of atomic item")
        self.assertEqual(0, myStack.stackHeight(), "Stack not empty after pop")
        self.assertIsNone(myStack.top(), "Top did not return None with empty stack")
        self.assertRaises(ValueError, myStack.top, exceptionOnEmpty=True)
        
        counter = 0
        myStack.push(counter)
        currCounter = myStack.pop()
        currCounter += 10
        myStack.push(currCounter)
        self.assertEqual(10, myStack.top(exceptionOnEmpty=True), "Modifying top of stack did not modify.")
        
    def testRemoveItemPartFromString(self):
        converter = GenericJSONParser(None)
        res = converter.removeItemPartOfString('employee.item.name')
        self.assertEquals('employee.name', res, 'Failed on simple case.')
        
        res = converter.removeItemPartOfString('employee.name')
        self.assertEquals('employee.name', res, "Failed when no 'item' present.")
        
        res = converter.removeItemPartOfString('employee.item')
        self.assertEquals('employee.item', res, "Failed when no trailing 'item', followed by an additional component.")

        res = converter.removeItemPartOfString('item')
        self.assertEquals('item', res, "Failed when only'item' is present.")

        res = converter.removeItemPartOfString('employee.item.lostFound.item.location')
        self.assertEquals('employee.item.lostFound.location', res, "Failed to only remove the last occurrence of 'item'.")
            
        
    def testEnsureMySQLTyping(self):
        mysqlDb = MySQLDB(None,None,None,None,None)
        self.assertEqual('10,"My Poem"', mysqlDb.ensureSQLTyping((10, 'My Poem')))
        self.assertEqual('10,11.23,"My Poem"', mysqlDb.ensureSQLTyping((10, 11.23, 'My Poem')))
        self.assertEqual('10', mysqlDb.ensureSQLTyping((10,)))
        self.assertEqual('"foo"', mysqlDb.ensureSQLTyping(('foo',)))
        
        
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testStack']
    unittest.main()