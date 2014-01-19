#!/usr/bin/env python

import sys

if __name__ == '__main__':
  if len(sys.argv) > 1:
    sys.stdout.write(sys.argv[1])
    sys.stdout.flush()
