'''
Created on Nov 3, 2013

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
