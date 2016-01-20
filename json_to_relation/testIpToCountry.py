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
        
        twoLetThreeLetCountryTuple = lookup.lookupIP('120.126.76.165')
        self.assertTupleEqual(twoLetThreeLetCountryTuple, ('TW','TWN','Taiwan; Republic of China (ROC)'))
        
        twoLetThreeLetCountryTuple = lookup.lookupIP('121.247.4.157')
        self.assertTupleEqual(twoLetThreeLetCountryTuple, ('IN','IND','India'))
        
        twoLetThreeLetCountryTuple = lookup.lookupIP('203.38.148.185')
        self.assertTupleEqual(twoLetThreeLetCountryTuple, ('AU','AUS','Australia'))
        
        

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()