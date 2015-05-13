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
import os
import unittest


class IpCountryDict(unittest.TestCase):
    '''
    Implements lookup mapping IP to country.
    '''
    START_IP_POS = 0
    END_IP_POS   = 1
    TWO_LETTER_POS = 2
    THREE_LETTER_POS = 3
    COUNTRY_POS = 4

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
        self.threeLetterKeyedDict = {}
        if ipTablePath is None:
            tableSubPath = os.path.join('data/', 'ipToCountrySoftware77DotNet.csv')
            ipTablePath = os.path.join(os.path.dirname(__file__), tableSubPath)
        with open(ipTablePath, 'r') as fd:
            for line in fd:
                if line[0] == '#':
                    continue
                (startIPStr,endIPStr,auth,assigned,twoLetterCountry,threeLetterCountry,country) = line.strip().split(',')  # @UnusedVariable
                # Use first four digits of start ip as hash key:
                hashKey = startIPStr.strip('"').zfill(10)[0:4]
                if hashKey != currKey:
                    self.ipToCountryDict[hashKey] = []
                    currKey = hashKey
                self.ipToCountryDict[hashKey].append((int(startIPStr.strip('"')), 
                                                       int(endIPStr.strip('"')), 
                                                       twoLetterCountry.strip('"'), 
                                                       threeLetterCountry.strip('"'), 
                                                       country.strip('"'))
                                                    )
                self.threeLetterKeyedDict[threeLetterCountry.strip('"')] = (twoLetterCountry.strip('"'), threeLetterCountry.strip('"'), country.strip('"'))

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
        return self.threeLetterKeyedDict[threeLetterCode]

    def lookupIP(self,ipStr):
        '''
        Top level lookup: pass an IP string, get a
        triplet: two-letter country code, three-letter country code,
        and full country.
        :param ipStr: string of an IP address
        :type ipStr: string
        :return: 2-letter country code, 3-letter country code, and country string
        :rtype: (str,str,str)
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
            if ipNum > ipInfo[IpCountryDict.END_IP_POS]:
                continue
            return(ipInfo[IpCountryDict.TWO_LETTER_POS], 
                   ipInfo[IpCountryDict.THREE_LETTER_POS],
                   ipInfo[IpCountryDict.COUNTRY_POS])
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
    #lookup = IpCountryDict('ipToCountrySoftware77DotNet.csv')
    lookup = IpCountryDict()
    #(ip,lookupKey) = lookup.ipStrToIntAndKey('171.64.64.64')
    (twoLetter,threeLetter,country) = lookup.lookupIP('171.64.75.96')
    #*****lookup.assertEqual((twoLetter,threeLetter,country),('US','USA','United States'))
    print('%s, %s, %s' % (twoLetter,threeLetter,country))
    (twoLetter,threeLetter,country) = lookup.lookupIP('5.96.4.5')
    print('%s, %s, %s' % (twoLetter,threeLetter,country)) 
    (twoLetter,threeLetter,country) = lookup.lookupIP('91.96.4.5')
    print('%s, %s, %s' % (twoLetter,threeLetter,country)) 
    (twoLetter,threeLetter,country) = lookup.lookupIP('105.48.87.6')
    print('%s, %s, %s' % (twoLetter,threeLetter,country)) 
    
    