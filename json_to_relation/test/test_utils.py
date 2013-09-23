'''
Created on Sep 22, 2013

@author: paepcke
'''
import unittest

from json_to_relation.json_to_relation import Stack, JSONToRelation


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
        converter = JSONToRelation(None,None)
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
            
        
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testStack']
    unittest.main()