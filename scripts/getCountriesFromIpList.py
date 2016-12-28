#!/usr/bin/env python

import sys
from ipToCountry import IpCountryDict 

class CountryListGetter(object):
    
    def __init__(self, ip_list_file):
        
        countryDict = IpCountryDict()
        with open(ip_list_file, 'r') as fd:
            for ip in fd:
                ip = ip.strip()
                if len(ip) == 0:
                    print('%s\t%s' % ('<empty>','n/a'))
                    continue
                 
                if ip == '127.0.0.1':
                    print('%s\t%s\t' % (ip,'localhost'))
                    continue
                # If there are multiple, comma-separated ips, do them all:
                ips = ip.split(',')
                try:
                    for the_ip in ips:
                        country = countryDict.get(the_ip.strip(), 'n/a')
                        sys.stdout.write('%s\t%s' % (the_ip,country))
                except ValueError as e:
                    print('%s\t%s' % (ip,'n/a'))
                    continue
                sys.stdout.write('\n')
if __name__ == '__main__':
    
    if len(sys.argv) != 2:
        print('Usage: %s <ipListFile>' % sys.argv[0])
    CountryListGetter(sys.argv[1])
