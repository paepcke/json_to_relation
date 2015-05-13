'''
Created on Feb 12, 2014

@author: paepcke
'''
import unittest

from ipToCountry import IpCountryDict


class IpToCountryTester(unittest.TestCase):

    lookup = None
    
    def setUp(self):
        super(IpToCountryTester, self).setUp()
        IpToCountryTester.lookup = IpCountryDict()

    def testIpToCountryFileLoad(self):
        lookup = IpToCountryTester.lookup
        #self.lookup = IpCountryDict('ipToCountrySoftware77DotNet.csv')
        (ip,self.lookupKey) = lookup.ipStrToIntAndKey('171.64.64.64') #@UnusedVariable
        
    def testIpToCountryXlation(self):
        lookup = IpToCountryTester.lookup
        twoLetThreeLetCountryTuple = lookup.lookupIP('171.64.75.96')
        self.assertTupleEqual(twoLetThreeLetCountryTuple, ('US','USA','United States'))
        twoLetThreeLetCountryTuple = lookup.lookupIP('5.96.4.5')
        self.assertTupleEqual(twoLetThreeLetCountryTuple, ('IT','ITA','Italy'))
        twoLetThreeLetCountryTuple = lookup.lookupIP('91.96.4.5')
        self.assertTupleEqual(twoLetThreeLetCountryTuple, ('DE','DEU','Germany'))
        # Test dict key not explicitly in lookup:
        twoLetThreeLetCountryTuple = lookup.lookupIP('108.7.9.33')
        self.assertTupleEqual(twoLetThreeLetCountryTuple, ('US','USA','United States'))
        twoLetThreeLetCountryTuple = lookup.lookupIP('107.203.248.200')
        self.assertTupleEqual(twoLetThreeLetCountryTuple, ('US','USA','United States'))
        
        # This one tests case when guessed lookup index needs to backtrack:
        twoLetThreeLetCountryTuple = lookup.lookupIP('39.63.53.92')
        self.assertTupleEqual(twoLetThreeLetCountryTuple, ('PK','PAK','Pakistan'))
        

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()