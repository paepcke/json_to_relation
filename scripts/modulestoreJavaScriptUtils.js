// ------------------  Class CourseInfoExtractor ----------------------

//Class definition/constructor:
function CourseInfoExtractor() {
    this.allQuartersArr = ["fall", "winter", "spring", "summer"];
}

CourseInfoExtractor.prototype.getQuarterStartDate = function(thisYear, quarter) {
    switch (quarter) {
    case "fall":
	return(thisYear     + "-09-10T07:59:00Z");
	break;
    case "winter":
	return((Number(thisYear)+1) + "-01-01T07:59:00Z");
	break;
    case "spring":
	return((Number(thisYear)+1) + "-03-01T07:59:00Z");
	break;
    case "summer":
	return((Number(thisYear)+1) + "-06-15T07:59:00Z");
	break;
    }
}

CourseInfoExtractor.prototype.getQuarterFromDate = function(dateStr) {
    
}

CourseInfoExtractor.prototype.getQuartersDuration = function(startCalDate, endCalDate) {
    startDate = new Date(startCalDate);
    endDate   = new Date(endCalDate);
    numQuarters = 0;
    
}

CourseInfoExtractor.prototype.getNextQuarter = function(thisQuarter) {
    thisQuarterIndx = this.allQuartersArr.indexOf(thisQuarter);
    if (thisQuarterIndx == this.allQuartersArr.length - 1) {
	return this.allQuartersArr[0];
    }
    return(this.allQuartersArr[thisQuarterIndx + 1])
}

CourseInfoExtractor.prototype.createCourseCSV = function(academicYear, quartersToDo) {
    // Create CSV with course info, and print to stdout.
    // If "year" is 0, include all years on record.
    // If "quarter" is "all", include all quarters.

    this.year = academicYear;
    this.quartersToDo  = quartersToDo;
    var quartersToCover = [];
    if (this.quartersToDo == 'all') {
	quartersToCover = ["fall", "winter", "spring", "summer"];
    } else {
	quartersToCover.push(this.quartersToDo);
    }

    var quarterStartDate;
    var nextQuarterStartDate;
    var moreYearsToDo = true;
    var thisAcademicYear = this.year;
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
	quarterStartDate = this.getQuarterStartDate(thisAcademicYear, currQuarter);
	nextQuarterStartDate = this.getQuarterStartDate(thisAcademicYear, this.getNextQuarter(currQuarter));

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
	    if (this.year > 0) {
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
	if (currQuarter == "fall" || this.year == 0) {
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
