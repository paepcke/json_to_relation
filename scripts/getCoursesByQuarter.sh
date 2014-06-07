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

QUERY='courseCursor = db.modulestore.find({"_id.category": "course",
		           "metadata.start": {$gte: theQuarter, $lt: nextQuarter}},
	                  {"metadata.start": true, "metadata.end": true}
		         );
'


SCRIPT='var year = '$YEAR';
        var fallQuarterStart   = year     + "-09-10T07:59:00Z";
        var winterQuarterStart = (year+1) + "-01-01T07:59:00Z";
        var springQuarterStart = (year+1) + "-03-01T07:59:00Z";
        var summerQuarterStart = (year+1) + "-06-15T07:59:00Z";
	var theQuarter  = '${QUARTER}'QuarterStart;
	var nextQuarter = '${NEXT_QUARTER}'QuarterStart;
       '$QUERY'

       while (true) {
          doc = courseCursor.hasNext() ? courseCursor.next() : null;
          if (doc == null)
             break;
          print(doc._id.org +
                "/" + doc._id.course + 
                "/" + doc._id.name + 
                "," + doc.metadata.start +
                "," + doc.metadata.end
                );
       }
'
#echo $SCRIPT
cmd="mongo modulestore --quiet --eval '$SCRIPT'"
#echo $cmd
eval $cmd
