#!/usr/bin/env python

import sys
import os

source_dir = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "../json_to_relation/")]
source_dir.extend(sys.path)
sys.path = source_dir

from json_to_relation import JSONToRelation
from output_disposition import OutputPipe, OutputDisposition
from input_source import InPipe

if __name__ == "__main__":
        
    mongoConverter = JSONToRelation(InPipe(),
                                    OutputPipe(),
                                    outputFormat = OutputDisposition.OutputFormat.CSV,
                                    schemaHints = {}
                                    )
    mongoConverter.convert(prependColHeader=True)