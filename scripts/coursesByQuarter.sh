#!/bin/bash

USAGE="Usage: coursesByQuarter.sh yyyy {fall | winter | spring | summer}"

if [ $# != 2 ]
then
    echo $USAGE
    exit 1
fi

YEAR=$1

if [[ ! $YEAR =~ ^-?[0-9]+$ ]]
then
    echo "Year must be of format yyyy"
fi

QUARTER=$2

if [[ ! (($QUARTER == 'fall') || \
         ($QUARTER == 'winter') || \
         ($QUARTER == 'spring') || \
         ($QUARTER == 'summer') \
         )]]
then
    echo $USAGE
fi

if [[ $QUARTER == 'fall' ]]
then
    NEXT_QUARTER='winter'
elif [[ $QUARTER == 'winter' ]]
then
    NEXT_QUARTER='spring'
elif [[ $QUARTER == 'spring' ]]
then
    NEXT_QUARTER='summer'
elif [[ $QUARTER == 'summer' ]]
then
    NEXT_QUARTER='fall'
fi



# ----------------------- Create JavaScript --------------

QUERY='courseCursor = db.modulestore.find({"_id.category": "course",\n
		           "metadata.start": {$gte: theQuarter, $lt: nextQuarter}},\n
	                  {"metadata.start": true, "metadata.end": true}\n
		         );
'


SCRIPT='var year = '$YEAR';\n
        var fallQuarterStart   = year     + "-09-10T07:59:00Z";\n
        var winterQuarterStart = (year+1) + "-01-01T07:59:00Z";\n
        var springQuarterStart = (year+1) + "-03-01T07:59:00Z";\n
        var summerQuarterStart = (year+1) + "-06-15T07:59:00Z";\n
	var theQuarter  = '${QUARTER}'QuarterStart;\n
	var nextQuarter = '${NEXT_QUARTER}'QuarterStart;\n
       '$QUERY'\n

       while (true) {\n
          doc = courseCursor.hasNext() ? courseCursor.next() : null;\n
          if (doc == null)\n
             break;\n
          print(doc._id.org +\n
                "/" + doc._id.course +\n 
                "/" + doc._id.name +\n 
                "," + doc.metadata.start +\n
                "," + doc.metadata.end\n
                );\n
       }          
'
echo $SCRIPT
mongo modulestore --eval $SCRIPT
