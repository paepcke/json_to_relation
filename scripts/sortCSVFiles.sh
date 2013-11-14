#!/bin/bash

time sort -t',' --key=1 --buffer-size=1G /tmp/tracking.log-20131001.gz.2013-11-10T22_38_33.272564_15192_Account.csv  > AccountSorted.csv
