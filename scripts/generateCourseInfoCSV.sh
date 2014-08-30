#!/bin/bash

# Given a year and the name of a quarter ('fall', 'winter', etc.),
# write CSV to stdout that contains course name, year, quarter,
# start date, and end date of the course. One course per line.
# Without a -y argument, all years are exported; without a -q
# all quarters (of each requested year) are exported.
#
# Uses the modulestore MongoDB directly. Can be used from CL.
#
# Usable from CL, but also used by cronRefreshModulStore.sh.

USAGE="Usage: generateCourseInfoCSV.sh [-y yyyy] [-q {fall | winter | spring | summer}]"

YEAR=0
QUARTER='all'
DATA_SINCE=2012

# --------------------- Process Input Args -------------

# Keep track of number of optional args the user provided:
NEXT_ARG=0

while getopts ":q:y:" opt
do
  case $opt in
    q)
      QUARTER=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    y)
      YEAR=$OPTARG
      NEXT_ARG=$((NEXT_ARG + 2))
      ;;
    \?)
      # Illegal option; the getopts provided the error message
      echo $USAGE
      exit 1
      ;;
  esac
done

# Shift past all the optional parms:
shift ${NEXT_ARG}

#echo $YEAR,$QUARTER
#exit 0

if [[ ! $YEAR =~ ^-?[0-9]+$ ]]
then
    echo "Year must be of format yyyy"
    exit 1
fi

if [[ ! (($QUARTER == 'all') || \
	 ($QUARTER == 'fall') || \
         ($QUARTER == 'winter') || \
         ($QUARTER == 'spring') || \
         ($QUARTER == 'summer') \
         )]]
then
    echo $USAGE
    exit 1
fi

# ------------------------- Establish Quarter Sequence ----------

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
		           "metadata.start": {$gte: quarterStartDate, $lt: nextQuarterStartDate}},
	                  {"metadata.start": true, "metadata.end": true}
		         );
'


# Place a Java script into a tmp file for subsequent input into
# MongoDB: 

JAVASCRIPT_FILE=mktemp
echo   'var year = '$YEAR';
        var quarter = '\"$QUARTER\"';
	var quartersToCover;
	if (quarter == "all") {
	    quartersToCover = ["fall", "winter", "spring", "summer"];
            // Without the following print statement, Mongo ouputs
            // the above array to stdout...who knows why. Workaround:
            // Print an empty line, and remove it later  (see grep below):
            print('');
	} else {
	    quartersToCover = [quarter];
	    switch (quarter) {
	    case "fall":
	        quartersToCover.push("winter");
	        break;
	    case "winter":
	        quartersToCover.push("spring");
	        break;
	    case "spring":
	        quartersToCover.push("summer");
	        break;
	    case "summer":
	        quartersToCover.push("fall");
	        break;
	    }
            // Without the following print statement, Mongo ouputs
            // the number 2 to stdout, in spite of the --quiet option. 
            // Workaround: Print an empty line, and remove it later (see grep below):
            print('');
	}

	var quarterStartDate;
	var nextQuarterStartDate;
	var thisYear = parseInt(year);
        if (thisYear == 0) {
            thisYear = '$DATA_SINCE';
            // Same stupid need for an empty line
            // to keep MongoDB from printing the 
            // value of $DATA_SINCE:
            print('');
        }
	var moreYearsToDo = true;
	var currYear = new Date().getFullYear();
	var theQuarterIndx  = 0;
	var nextQuarterIndx = 1;

	print("course_display_name,year,quarter,start_date,end_date");

	while (moreYearsToDo) {

	    var fallQuarterStartDate   = thisYear     + "-09-10T07:59:00Z";
	    var winterQuarterStartDate = thisYear+1 + "-01-01T07:59:00Z";
	    var springQuarterStartDate = thisYear+1 + "-03-01T07:59:00Z";
	    var summerQuarterStartDate = thisYear+1 + "-06-15T07:59:00Z";
	    var summerQuarterEndDate   = thisYear+1 + "-09-10T07:59:00Z";

	    var currQuarter = quartersToCover[theQuarterIndx];
	    switch (currQuarter) {
	    case "fall":
	        quarterStartDate = fallQuarterStartDate;
	        nextQuarterStartDate = winterQuarterStartDate;
	        break;
	    case "winter":
	        quarterStartDate = winterQuarterStartDate;
	        nextQuarterStartDate = springQuarterStartDate;
	        break;
	    case "spring":
	        quarterStartDate = springQuarterStartDate;
	        nextQuarterStartDate = summerQuarterStartDate;
	        break;
	    case "summer":
	        quarterStartDate = summerQuarterStartDate;
	        nextQuarterStartDate = summerQuarterEndDate;
	        break;
	    }

	    //************************
	    //print("quarter: " + quarter);
	    //print("currQuarter: " + currQuarter);
            //print("quartersToCover:" + quartersToCover);
	    //print("quarterStartDate: " + quarterStartDate);
	    //print("nextQuarterStartDate: " + nextQuarterStartDate);
	    //print("currYear: " + currYear);
	    //print("thisYear: " + thisYear);
	    //print("year: " + year);
	    //print("theQuarterIndx: " + theQuarterIndx);
	    //print("nextQuarterIndx: " + nextQuarterIndx);
	    //************************
	    courseCursor = db.modulestore.find({"_id.category": "course",
	   	                                "metadata.start": {$gte: quarterStartDate, $lt: nextQuarterStartDate}
	                                       },
	                      	               {"metadata.start": true, "metadata.end": true}
					      );

	    while (true) {
	        doc = courseCursor.hasNext() ? courseCursor.next() : null;
	        if (doc === null) {
	            break;
	        }
	        print(doc._id.org +
	              "/" + doc._id.course +
	              "/" + doc._id.name +
	              "," + year +
	              "," + currQuarter +
	              "," + doc.metadata.start +
	              "," + doc.metadata.end);
	    }
	    // Done with one quarter

	    if (quarter != "all" && year > 0) {
	        moreYearsToDo = false;
	        continue;
	    }

	    // Doing multiple quarters. what is the next quarter?
	    theQuarterIndx += 1;
	    if (theQuarterIndx > quartersToCover.length - 1) {
	        // Did all quarters of current academic year:
	        theQuarterIndx = 0;
	        // Do just one year?
	        if (year > 0) {
	            // We are to do just one academic year:
	            moreYearsToDo = false;
	            continue;
	        }
	    }

	    if (currQuarter == "fall") {
	        // Spring quarter happens in second
	        // calendar year of the academic year:
	        thisYear += 1;
	        if (thisYear > currYear) {
	            moreYearsToDo = false;
	            continue;
	        }
	    }
            //*************
            //print("moreYearsToDo: " + moreYearsToDo);
            //print("currQuarter: " + currQuarter);
            //*************

	} // end while(moreYearsToDo)
	' > $JAVASCRIPT_FILE
#********************
#cat $JAVASCRIPT_FILE
#exit
#********************


# Run the JavaScript inside mongodb; output to stdout.
# When Mongo processes the above Javascript, it outputs
# two lines at the end: 'false', and 'bye', even with the 
# --quiet flag. We need to suppress these to obtain a clean
# .csv output.
#
# Additionally, to prevent Mongo from outputting the result of the first
# Javascript conditional we had to add a newline in that
# script (see above in the script). We need to suppress
# this empty line as well
# 
# The following pipe into grep does these suppressions:

mongo modulestore --quiet < $JAVASCRIPT_FILE | grep --invert-match "^false$\|^bye$\|^$"

rm $JAVASCRIPT_FILE
