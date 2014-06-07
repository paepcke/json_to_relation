#!/bin/bash

# Given a year and the name of a quarter ('fall', 'winter', etc.),
# write CSV to stdout that contains course name, year, quarter,
# start date, and end date of the course. One course per line.

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

# Create a JavaScript that will be run within a Mongo shell
# further down. The scripts queries Mongo for all courses
# within the given quarter's start/end dates. Catching the
# resulting db cursor, the JavaScript writes to stdout one
# CSV line after another: <courseName>,<year>,<quarter>,<startDate>,<endDate>

QUERY='courseCursor = db.modulestore.find({"_id.category": "course",
		           "metadata.start": {$gte: theQuarter, $lt: nextQuarter}},
	                  {"metadata.start": true, "metadata.end": true}
		         );
'


SCRIPT='var year = '$YEAR';
        var quarter = '\"$QUARTER\"';
        var fallQuarterStart   = year     + "-09-10T07:59:00Z";
        var winterQuarterStart = (year+1) + "-01-01T07:59:00Z";
        var springQuarterStart = (year+1) + "-03-01T07:59:00Z";
        var summerQuarterStart = (year+1) + "-06-15T07:59:00Z";
	var theQuarter  = '${QUARTER}'QuarterStart;
	var nextQuarter = '${NEXT_QUARTER}'QuarterStart;
       '$QUERY'

       print("course_display_name,year,quarter,start_date,end_date");
       while (true) {
          doc = courseCursor.hasNext() ? courseCursor.next() : null;
          if (doc == null)
             break;
          print(doc._id.org +
                "/" + doc._id.course + 
                "/" + doc._id.name +
                "," + year +
                "," + quarter +
                "," + doc.metadata.start +
                "," + doc.metadata.end
                );
       }
'
#echo $SCRIPT

# Create a bash command that invokes the Mongo shell
# with the JavaScript as the command to run:
cmd="mongo modulestore --quiet --eval '$SCRIPT'"

#echo $cmd

# Run the command:
eval $cmd
