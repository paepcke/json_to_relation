getQuarterStartDate = function(thisYear, quarter) {
    switch (quarter) {
    case "fall":
	return(thisYear     + "-09-10T07:59:00Z");
	break;
    case "winter":
	return((thisYear+1) + "-01-01T07:59:00Z");
	break;
    case "spring":
	return((thisYear+1) + "-03-01T07:59:00Z");
	break;
    case "summer":
	return((thisYear+1) + "-06-15T07:59:00Z");
	break;
    }
}

getQuarterFromDate = function(dateStr) {
    
}

getQuartersDuration = function(startCalDate, endCalDate) {
    startDate = new Date(startCalDate);
    endDate   = new Date(endCalDate);
    numQuarters = 0;
    
}

getNextQuarter = function(thisQuarter) {
    // Relies on thisQuarter being one of 
    // "fall", "winter", "spring", or "summer".
    // No error check
    // Fake a static, local variable:
    if ( typeof getNextQuarter.allQuartersArr == 'undefined' ) {
        // allQuartersArr has not been defined yet:
        getNextQuarter.allQuartersArr = ["fall", "winter", "spring", "summer"];
    }
    quartersArr = getNextQuarter.allQuartersArr;
    thisQuarterIndx = quartersArr.indexOf(thisQuarter);
    if (thisQuarterIndx == quartersArr.length - 1) {
	return quartersArr[0];
    }
    return(quartersArr[thisQuarterIndx + 1])
}

createCourseCSV = function(year, quarterToDo) {
    // Create CSV with course info, and print to stdout.
    // If "year" is 0, include all years on record.
    // If "quarter" is "all", include all quarters.

    var quartersToCover = [];
    if (quarterToDo == 'all') {
	quartersToCover = ["fall", "winter", "spring", "summer"];
    } else {
	quartersToCover.push(quarterToDo);
    }

    var quarterStartDate;
    var nextQuarterStartDate;
    var moreYearsToDo = true;
    var thisAcademicYear = year;
    var currYear = new Date().getFullYear();
    var theQuarterIndx  = 0;
    var nextQuarterIndx = 1;

    // If doing all years, set year to start
    // year of recorded history. OK to set it
    // earlier than true first recorded courses:
    if (thisAcademicYear == 0) {
	thisAcademicYear = 2010;
    }
    // Distinguish between academic and calendar year:
    thisCalYear = thisAcademicYear;

    //***********
    //print(thisAcademicYear);
    //print(thisCalYear);
    //print(quartersToCover);
    //***********
    print("course_display_name,academic_year,quarter,start_date,end_date");

    while (moreYearsToDo) {
	var currQuarter = quartersToCover[theQuarterIndx];
	quarterStartDate = getQuarterStartDate(thisAcademicYear, currQuarter);
	nextQuarterStartDate = getQuarterStartDate(thisAcademicYear, getNextQuarter(currQuarter));

	//***********
	//print("Quarter start     : " + quarterStartDate);
	//print("Next Quarter start: " + nextQuarterStartDate);
	//***********

	// Get get course info for courses in
	// one academic year, one particular quarter:
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
	    // Compute how many quarters course runs:
	    //******
	    print(doc._id.org +
		  "/" + doc._id.course +
		  "/" + doc._id.name +
		  "," + thisAcademicYear +
		  "," + currQuarter +
		  "," + doc.metadata.start +
		  "," + doc.metadata.end);
	}
	// Done with one quarter

	// What is the next quarter
	// of the quarters we are supposed to cover?
	theQuarterIndx += 1;
	if (theQuarterIndx > quartersToCover.length - 1) {
	    // Did all wanted quarters for current academic year:
	    theQuarterIndx = 0;
	    // Do just one year?
	    if (year > 0) {
		// We are to do just one academic year:
		moreYearsToDo = false;
		continue;
	    } else {
		// Want same quarters for multiple years.
		thisAcademicYear += 1;

		// Adjust calendar year:
		if (quartersToCover[theQuarterIndx] == "fall") {
		    thisCalYear = thisAcademicYear;
		} else {
		    thisCalYear = thisAcademicYear + 1;
		}

		// Did all recorded years?
		if (thisAcademicYear > currYear) {
		    moreYearsToDo = false;
		    continue;
		}
		// Do next year with same series of 
		// quarters we just did for this year:
		continue;
	    }
	}
	// Still have quarters to do in current academic year.
	// Calendar date increments, if switching from
        // Fall quarter to winter:
	if (currQuarter == "fall" || year == 0) {
	    // Just did fall quarter, or want all years for one 
	    // Spring quarter happens in second
	    // calendar year of the academic year:
	    thisCalYear += 1;
	    // Did all recorded years up to today's year plus 1?
	    if (thisCalYear > currYear + 1) {
		moreYearsToDo = false;
		continue;
	    }
	}
    }
}
