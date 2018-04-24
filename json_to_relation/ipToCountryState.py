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

Implements an in-memory lookup table that maps IP addresses
to the countries they are assigned to. For any IP the two and
three letter codes, and the country name can be obtained.

Instance creation builds the table from information on disk.
It is therefore recommended that only one instance is made,
and then used for many lookups. But creating multiple instances
does no harm.

The out-facing method is lookupIP(ipString)

The underlying IP->Country information comes from http://software77.net/geo-ip/

@author: paepcke
'''

import csv
import os
import unittest

class IpCountryStateDict(unittest.TestCase):
    '''
    Implements lookup mapping IP to country.
    '''
    START_IP_POS = 0
    END_IP_POS   = 1
    TWO_LETTER_POS = 2
    COUNTRY_POS = 3
    STATE_POS = 4
    CITY_POS = 5

    def __init__(self, ipTablePath=None):
        '''
        Create an in-memory dict for quickly looking up IP addresses.
        The underlying IP->Country information comes from http://software77.net/geo-ip/
        If an unzipped table from their Web site is not passed in, then 
        the table is expected to reside in subdirectory 'data' of this script's directory
        under the name ipToCountrySoftware77DotNet.csv. Their table contains
        columns for (decimal)startRange, endRange, assigning agency, assignment
        date, two-letter-country code, three-letter-country code, and country.
        
        The lookup table we construct uses the first four digits of the 
        starting ranges as key. Values are an array of tuples:
            (startIpRange,endIPRange,2-letterCode,3-letterCode,Country)
        All IPs in one key's values thus start with the key's digits.
        The arrays are just a few tuples long, so the scan through them
        is fast. The arrays are ordered by rising start and (therefore)
        end IP.
        
        We also construct a simpler dict that maps a country's three-letter
        code to a tuple: (two-letter code, three-letter code, full country name).
        '''
        currKey = 0
        self.ipToCountryDict = {currKey : []}
        self.twoLetterKeyedDict = {}
        if ipTablePath is None:
            tableSubPath = os.path.join('data/', 'ipToCountrySoftware77DotNet.csv')
            ipTablePath = os.path.join(os.path.dirname(__file__), tableSubPath)
        with open(ipTablePath, 'r') as fd:
            for line in csv.reader(fd):
                if len(line) == 0 or line[0] == '#' or line == '\n':
                    continue
                try: 
                    (startIPStr,endIPStr,twoLetterCountry,country, state, city) = line
                except ValueError as e:
                    print("Irregularity in IP db line '%s': %s" % (line, `e`))
                    continue
                # Use first four digits of start ip as hash key:
                hashKey = startIPStr.strip('"').zfill(10)[0:4]
                if hashKey != currKey:
                    self.ipToCountryDict[hashKey] = []
                    currKey = hashKey
                self.ipToCountryDict[hashKey].append((int(startIPStr.strip('"')), 
                                                       int(endIPStr.strip('"')), 
                                                       twoLetterCountry.strip('"'), 
                                                       country.strip('"'), 
                                                       state.strip('"'),
                                                       city.strip('"')
                                                       )
                                                    )
                self.twoLetterKeyedDict[twoLetterCountry.strip('"')] = (twoLetterCountry.strip('"'), 
                                                                        country.strip('"'),
                                                                        state.strip('"'),
                                                                        city.strip('"')
                                                                        )

    def get(self, ipStr, default=None):
        '''
        Same as lookupIP, but returns default if
        IP not found, rather than throwing a KeyError.
        This method is analogous to the get() method
        on dictionaries.
        :param ipStr: string of an IP address 
        :type ipStr: String
        :param default: return value in case IP address country is not found.
        :type default: <any>
        :return: 2-letter country code, 3-letter country code, and country string
        :rtype: {(str,str,str) | defaultType}
        '''
        try:
            return self.lookupIP(ipStr)
        except KeyError:
            return None

    def getBy3LetterCode(self, threeLetterCode):
        return self.twoLetterKeyedDict[threeLetterCode]

    def lookupIP(self,ipStr):
        '''
        Top level lookup: pass an IP string, get a
        four-tuple: two-letter country code, full country name, region, and city:
        :param ipStr: string of an IP address
        :type ipStr: string
        :return: 2-letter country code, country, region, city
        :rtype: (str,str,str,str)
        :raise ValueError: when given IP address is None
        :raise KeyError: when the country for the given IP is not found. 
        '''
        (ipNum, lookupKey) = self.ipStrToIntAndKey(ipStr)
        if ipNum is None or lookupKey is None:
            raise ValueError("IP string is not a valid IP address: '%s'" % str(ipStr))
        while lookupKey > 0:
            try:
                ipRangeChain = self.ipToCountryDict[lookupKey]
                if ipRangeChain is None:
                    raise ValueError("IP string is not a valid IP address: '%s'" % str(ipStr))
                # Sometimes the correct entry is *lower* than
                # where the initial lookup key points:
                if ipRangeChain[0][0] > ipNum:
                    # Backtrack to an earlier key:
                    raise KeyError()
                break
            except KeyError:
                lookupKey = str(int(lookupKey) - 1).zfill(4)[0:4]
                continue
        for ipInfo in ipRangeChain:
            # Have (rangeStart,rangeEnd,country2Let,country3Let,county)
            # Sorted by rangeStart:
            if ipNum > ipInfo[IpCountryStateDict.END_IP_POS]:
                continue
            return(ipInfo[IpCountryStateDict.TWO_LETTER_POS], 
                   ipInfo[IpCountryStateDict.COUNTRY_POS],
                   ipInfo[IpCountryStateDict.STATE_POS],
                   ipInfo[IpCountryStateDict.CITY_POS],
                   )
        # If we get here, the IP is in a range in which
        # the IP-->Country table has a hole:
        return('ZZ','ZZZ','unknown')
        
        
            
    def ipStrToIntAndKey(self, ipStr):
        '''
        Given an IP string, return two-tuple: the numeric
        int, and a lookup key into self.ipToCountryDict.
         
        :param ipStr: ip string like '171.64.65.66'
        :type ipStr: string
        :return: two-tuple of ip int and the first four digits, i.e. a lookup key. Like (16793600, 1679). Returns (None,None) if IP was not a four-octed str.
        :rtype: (int,int)
        '''
        try:
            (oct0,oct1,oct2,oct3) = ipStr.split('.')
        except ValueError:
            # Given ip str does not contain four octets:
            return (None,None)
        ipNum = int(oct3) + (int(oct2) * 256) + (int(oct1) * 256 * 256) + (int(oct0) * 256 * 256 * 256)
        return (ipNum, str(ipNum).zfill(10)[0:4])


if __name__ == '__main__':
    import sys
    if len(sys.argv) < 2:
        raise ValueError("Usage: python ipToCountry.py [pathToIpCsv] <ipAddress>")
    elif len(sys.argv) == 3:
        dbPath = sys.argv[1]
        ipAddr = sys.argv[2]
    else:
        dbPath = 'data/IP2LOCATION-LITE-DB3.CSV'
        ipAddr = sys.argv[1]
    
    #lookup = IpCountryStateDict('ipToCountrySoftware77DotNet.csv')
    lookup = IpCountryStateDict(dbPath)
    (twoLetter,country,region,city) = lookup.lookupIP(ipAddr)
    print('%s; %s; %s; %s' % (twoLetter,country,region,city))
    
    #(ip,lookupKey) = lookup.ipStrToIntAndKey('171.64.64.64')
    #(twoLetter,threeLetter,country) = lookup.lookupIP('171.64.75.96')
    #*****lookup.assertEqual((twoLetter,threeLetter,country),('US','USA','United States'))
#     print('%s, %s, %s' % (twoLetter,threeLetter,country))
#     (twoLetter,threeLetter,country) = lookup.lookupIP('5.96.4.5')
#     print('%s, %s, %s' % (twoLetter,threeLetter,country)) 
#     (twoLetter,threeLetter,country) = lookup.lookupIP('91.96.4.5')
#     print('%s, %s, %s' % (twoLetter,threeLetter,country)) 
#     (twoLetter,threeLetter,country) = lookup.lookupIP('105.48.87.6')
#     print('%s, %s, %s' % (twoLetter,threeLetter,country)) 
    
    