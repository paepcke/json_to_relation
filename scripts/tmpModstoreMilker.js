var year = '2013';
var quarter = 'fall';


var quartersToCover;
if (quarter == 'all') {
    quartersToCover = ["fall", "winter", "spring", "summer"];
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
}

// Current calendar year:
var currYear = new Date().getFullYear();
var quarterStartDate;
var nextQuarterStartDate;
var thisYear;
// If the year parameter above is a positive number,
// then init thisYear to that year (i.e. the year whose
// quarter(s) we are to work on). Else use the current
// calendar year. The if clause is likely overkill.
// But better safe...:
if (!isNaN(year) && parseInt(Number(year)) == year && parseInt(Number(year)) > 0) {
    // The -1 will be offset by the bump inside the while below:
    thisYear = String(parseInt(year)-1);
} else {
    thisYear = String(currYear);
}
var moreYearsToDo = true;
var theQuarterIndx  = 0;
var nextQuarterIndx = 1;

print("course_display_name,year,quarter,start_date,end_date");

while (moreYearsToDo) {
    var thisYear = String(parseInt(thisYear) + 1);
    var nextYear = String(parseInt(thisYear) + 1);
    var fallQuarterStartDate   = thisYear + "-09-10T07:59:00";
    var winterQuarterStartDate = nextYear + "-01-01T07:59:00";
    var springQuarterStartDate = nextYear + "-03-01T07:59:00";
    var summerQuarterStartDate = nextYear + "-06-15T07:59:00";

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
        quarterStartDate = fallQuarterStartDate;
        nextQuarterStartDate = winterQuarterStartDate;
        break;
    }

    //searchStartDate = ISODate(quarterStartDate);
    //searchEndDate   = ISODate(nextQuarterStartDate);
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

    if (quarter != "all") {
        moreYearsToDo = false;
        continue;
    }

    // Doing multiple quarters. what is the next quarter?
    theQuarterIndx += 1;
    if (theQuarterIndx > quartersToCover.length() - 1) {
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
}	  
