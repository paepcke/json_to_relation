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
Created on Nov 3, 2013

Manages fast lookup of countries, given words that *might* be countries.


@author: paepcke
'''
import os


class LocationManager(object):
    '''
    Manages fast lookup of countries, given words that *might* be countries.
    '''


    def __init__(self):
        '''
        Prepare the first-two-letter country dict.
        '''
        # Dict mapping first two letters of countries to list
        # of countries that start with those two letters:
        self.countryLookup = {}
        
        countryFile = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data/countries.txt')
        with open(countryFile, 'r') as fd:
            allCountries = fd.readlines()
        for country in allCountries:
            country = country.strip()
            existingList = self.countryLookup.get(country[:2].upper(), None)
            if existingList is None:
                self.countryLookup[country[:2].upper()] = [country]
            else:
                self.countryLookup[country[:2].upper()].append(country)
                
    def isCountry(self, candidateStr):
        countryList = self.countryLookup.get(candidateStr[:2].upper(), None)
        if countryList is None:
            return ''
        candidateStr = candidateStr[0].upper() + candidateStr[1:]
        for country in countryList:
            if candidateStr == country:
                if country == 'US' or\
                   country == 'United States' or\
                   country == 'United States of America':
                    country = 'USA'
                return country
        return ''
