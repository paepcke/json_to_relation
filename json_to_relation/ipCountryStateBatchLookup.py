#!/usr/bin/env python
'''
Created on Jun 24, 2017

@author: paepcke
'''
import argparse
from csv import reader
import os
import sys

from ipToCountryState import IpCountryStateDict
                            

class IpCountryStateBatchLookup(object):
    '''
    Given a CSV file in which one column contains IP addresses,
    append three columns at the end that contain the country of that
    IP address, the region (e.g. US State), and the city
     
    The resulting CSV is written to standard out. 
    
    An arbitrary number of lines at the start of the IP file
    may be transferred to the destination
    without processing: used for headers. The string 'country,region,city' is 
    added to each of these rows.
    '''


    def __init__(self, input_file, ip_position, output_file=None, ignore_lines=0):
        '''
        Runs processing from beginning to end.
        
        @param input_file: path to CSV file containing the IP address column 
        @type input_file: str
        @param ip_position: zero-origin index of column that contains the IP address.
        @type ip_position: int
        @param output_file: optional output file for the result CSV
        @type output_file: {str | None|
        @param ignore_lines: number of lines to copy to destination unprocessed. Used for headers.
        @type ignore_lines: {int}
        '''
        
        if not os.access(input_file, os.R_OK):
            print("Input file %s not found or not readable." % input_file)
            sys.exit(1)
            
        self.country_dict = IpCountryStateDict()
        
        # Get lines to pass through, and array of row-arrays:
        (headers, rows) = self.read_csvlines(input_file, ignore_lines)
        self.write_country_state_city(headers, rows, ip_position, output_file)
    
    def read_csvlines(self, input_file, ignore_lines):
        '''
        Read all of the CSV file into memory, and return
        a tuple: the pass-through rows with 'country' appended
        to each, and the array of rows. Returns a 2-tuple: an
        array of array with pass-through lines, and an array of array
        of rows.
        
        @param input_file: path to file with CSV input
        @type input_file: str
        @param ignore_lines: how many lines to pass through
        @type ignore_lines: int
        @return: a possibly empty array of rows to pass through ('country' attached)
        @rtype: ([[str]], [[str]])
        '''
        headers = []
        with open(input_file, 'r') as csvfile:
            csv_reader = reader(csvfile)
            try:
                # Get each header line, add 'country',
                # and add to the 'headers' result:
                for _ in range(ignore_lines):
                    row = csv_reader.next()
                    headers.append(row + ['country'])
            except StopIteration:
                # Fewer lines in file than supposed
                # header lines:
                return []
            # Read the row-arrays, enclosing them
            # all as an array: [[col1,1, col1,2], [col2,1, col2,2]]:
            rows = [row for row in csv_reader]
            return (headers, rows)
            
    def write_country_state_city(self, header_rows, rows, ip_position, output_file):
        '''
        The actual lookup:
        
        @param header_rows: possibly empty row of header lines
        @type header_rows: [[str]]
        @param rows: rows containing IP addresses to resolve to countries
        @type rows: [[str]]
        @param ip_position: zero-origin index to IP-containing column in each rows.
        @type ip_position: int
        @param output_file: output file; if None, write to stdout.
        @type output_file: {str | None}
        '''

        # Ensure the_output_file variable holds
        # an open file descriptor:
        
        if output_file is None:
            the_output_file = sys.stdout
        elif type(output_file) == str:
            the_output_file = open(output_file, 'w')
        else:
            the_output_file = output_file
    
        # Ignore header rows: just copy them to the output:
        for header_row in header_rows:
            the_output_file.write(','.join(header_row) + '\n')

        # The actual work:        
        for row in rows:
            try:
                (twoLetter,country,region,city) = \
                    self.country_dict.lookupIP(row[ip_position]) #@UnusedVariable
            except ValueError:
                country = 'Bad ip %s' % row[ip_position]
            row.extend([twoLetter,country,region,city])
            the_output_file.write(','.join(row) + '\n')
        
        # If output_file parameter was a string, we
        # opened a file:
        if type(output_file) == str:
            the_output_file.close() 
                
if __name__ == '__main__':
    
    parser = argparse.ArgumentParser(description='Look up countries from many IP addresses in bulk.')
    parser.add_argument('--passthrough_lines', 
                        type=int,
                        default=0,
                    help="Number of header lines to copy to output without looking for an IP address. " +
                          "String 'country,region,city' will be added to each line. Default is 0.")
    parser.add_argument('infile', type=str,
                    help='CSV file path with rows that include an IP addresss column')
    parser.add_argument('ipPos', type=int,
                    help='Index of column with IP address (0-origin)')

#****    args = parser.parse_args()
#****    resolver = IpCountryStateDict(args.infile, args.ipPos, ignore_lines=args.passthrough_lines)
    resolver = IpCountryStateBatchLookup('allIPsApril_23_2018.txt', 0, ignore_lines=1)
        

    
            