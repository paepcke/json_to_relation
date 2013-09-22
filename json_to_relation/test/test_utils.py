'''
Created on Sep 22, 2013

@author: paepcke
'''
import unittest

from json_to_relation.json_to_relation import Stack


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
        
        
        
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testStack']
    unittest.main()