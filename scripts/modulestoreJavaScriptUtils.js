                   /* ************* Class CourseInfoExtractor *************** */

/*
Two ways to run the unittests at the end:
   o Open file modulestoreJavaScriptUtilsTest.html in a browser
     and use the buttons, or
   o In the context of a Mongo shell:
     * comment both print() functions in the two unittests
       at the end of this file.
     * Enter mongo from a terminal and:
          load('/home/paepcke/EclipseWorkspaces/json_to_relation/scripts/modulestoreJavaScriptUtils.js');
	  realDateUnittests();
	  courseInfoExtractorUnittests();
*/

//------------------------------
// isTrueCourseName
//-----------------

// Function isTrueCourseName() returns true if the
// given OpenEdX course_display_name is most likely
// a legitimate course name, rather than a bogus
// name polluting the OpenEdX platform namespace.
//
// This is one of three places that must be kept up
// to date if new bogus names are introduced. The
// others are filterCourseNames.sh for the bash
// version, and stored function isTrueCourseName()
// in mysqlProcAndFuncBodies.sql.

isTrueCourseName = function(courseName) {
    re = new RegExp("^[0-9]+|^testtest|jbauU|jbau|janeu|sefu|davidu|caitlynx|josephtest|nickdupuniversity|nathanielu|gracelyou|monx/|sandbox|demo|sampleuniversity|joeu|grbuniversity|stanford_spcs/001/spcs_test_course1|stanford/exp1/experimental_assessment_test|on_campus_stanford_only_test_class|business/123/gsb-test|business/123/gsb-test|worldview/wvtest/worldview_testing|foundation/wtc01/wadhwani_test_course|gsb/af1/alfresco_testing|tocc/1/eqptest|internal/101/private_testing_course|testing_settings/for_non_display|nickdup|openedx/testeduc2000c/2013_sept|grb/101/grb_test_course|online/bulldog/summer2014|testing/testing123/evergreen|stanford/xxxx/yyyy|.*zzz.*|/test/")
    return !re.test(courseName.toLowerCase());
}

/* ************* Class CourseInfoExtractor *************** */

//Class definition/constructor:
function CourseInfoExtractor() {

    this.earliestAvailableDataYear = 2012;

    this.stanfordEnrollDomain = "shib:https://idp.stanford.edu/";

    this.allQuartersArr = ["fall", "winter", "spring", "summer"];
    // To change start month/day of quarter starts,
    // change the following four partial month-dayTtime strings:
    this.fallStartStr   = "-09-01T00:00:00Z";
    this.winterStartStr = "-12-01T00:00:00Z";
    this.springStartStr = "-03-01T00:00:00Z";
    this.summerStartStr = "-06-01T00:00:00Z";
    this.summerEndStr   = "-08-31T00:00:00Z";

    // Create start months from above partial date strings:
    thisYear = new Date().getFullYear();
    // See class RealDate below about need for this class:
    this.fallQuarterStartMonth   = new RealDate(this.getQuarterStartDate(thisYear, "fall")).getMonth();
    this.winterQuarterStartMonth = new RealDate(this.getQuarterStartDate(thisYear, "winter")).getMonth();
    this.springQuarterStartMonth = new RealDate(this.getQuarterStartDate(thisYear, "spring")).getMonth();
    this.summerQuarterStartMonth = new RealDate(this.getQuarterStartDate(thisYear, "summer")).getMonth();

    this.NO_TIME_OUTPUT = true;

}


/* ************* Methods for CourseInfoExtractor *************** */

//------------------------------
// getQuarterStartDate
//----------------

CourseInfoExtractor.prototype.getQuarterStartDate = function(theYear, quarter) {
    switch (quarter) {
    case "fall":
     	return(theYear     + this.fallStartStr);
     	break;
    case "winter":
     	return(theYear     + this.winterStartStr);
     	break;
    case "spring":
     	return((Number(theYear)+1) + this.springStartStr);
     	break;
    case "summer":
     	return((Number(theYear)+1) + this.summerStartStr);
     	break;
    }
}

//------------------------------
// getQuarterFromDate
//----------------

CourseInfoExtractor.prototype.getQuarterFromDate = function(dateStr) {

    var dateObj;
    try {
     	dateObj   = new RealDate(dateStr);
    } catch(err) {
     	return("unknown");
    }

    var dateMonth = dateObj.getMonth();
    if (dateMonth >= this.fallQuarterStartMonth && dateMonth < this.winterQuarterStartMonth) {
     	return "fall";
    } else if (dateMonth >= this.winterQuarterStartMonth || dateMonth < this.springQuarterStartMonth) {
     	return "winter";
    } else if (dateMonth >= this.springQuarterStartMonth && dateMonth < this.summerQuarterStartMonth) {
     	return "spring";
    } else return "summer";
}

//------------------------------
// getNumQuartersDuration
//----------------

// Given two date strings, return the number of quarters that
// lie between those dates. If either of the given date is a
// null date, or not a legal datetime string, return -1. The
// quarters in which the dates lie are included in the count.
// Example:
//   getNumQuartersDuration("2014-08-21", "2013-12-31") => 3
// winter, spring, and summer.

CourseInfoExtractor.prototype.getNumQuartersDuration = function(startCalDate, endCalDate) {

    try {
     	startDate = new RealDate(startCalDate);
	if (startDate.isNullDateObj(startDate))
	    return(-1);
    } catch(err) {
     	return(-1);
    }
    startYear = startDate.getFullYear();
    thisYear  = startYear;
    startQuarter = this.getQuarterFromDate(startCalDate);

    thisQuarter  = startQuarter;

    try {
     	endDate      = new RealDate(endCalDate);
	if (endDate.isNullDateObj(endDate))
	    return(-1);
    } catch(err) {
     	return(-1);
    }
    endQuarter   = this.getQuarterFromDate(endCalDate);
    endYear      = endDate.getFullYear();

    ///*********
    // print("Start quarter: " + startQuarter);
    // print("End quarter  : " + endQuarter);
    // print("Start year   : " + startYear);
    // print("End year     : " + endYear);
    // print("This quarter : " + thisQuarter);
    ///*********

    numQuarters = 1;
    while(true) {
     	nextQuarter = this.getNextQuarter(thisQuarter);

     	if (thisYear >= endYear && thisQuarter == endQuarter) {
     	    return numQuarters;
     	}

     	if (thisQuarter == "fall") {
     	    thisYear += 1;
     	}
     	thisQuarter = nextQuarter;
     	numQuarters += 1;

     	///*********
     	// print("thisYear   :  " + thisYear);
     	// print("thisQuarter:  " + thisQuarter);
     	// print("endYear    :  " + endYear);
     	// print("endQuarter :  " + endQuarter);
     	///*********

    }
}

//------------------------------
// getNextQuarter
//----------------

// Given a quarter string ('winter', 'spring,'...), return
// the name of the following academic quarter.

CourseInfoExtractor.prototype.getNextQuarter = function(thisQuarter) {
    thisQuarterIndx = this.allQuartersArr.indexOf(thisQuarter);
    if (thisQuarterIndx == this.allQuartersArr.length - 1) {
     	return this.allQuartersArr[0];
    }
    return(this.allQuartersArr[thisQuarterIndx + 1]);
}

//------------------------------
// createCourseCSV
//----------------

CourseInfoExtractor.prototype.createCourseCSV = function(academicYear, quartersToDo, splitMongo) {
    // Main, workhorse method.
    // Create CSV with course info, and print to stdout.
    // If "year" is 0, include all years on record.
    // If "quarter" is "all", include all quarters.
    // If "splitMongo" is true, handle split case instead
    var split = (typeof split !== 'undefined') ? splitMongo : false;
    this.year = Number(academicYear);
    this.quartersToDo  = quartersToDo;
    var quartersToCover = [];
    if (this.quartersToDo == 'all') {
     	quartersToCover = ["fall", "winter", "spring", "summer"];
    } else {
     	quartersToCover.push(quartersToDo);
    }

    var quarterStartDate;
    var nextQuarterStartDate;
    var moreYearsToDo = true;
    var thisAcademicYear = this.year;
    var currYear = Number(new Date().getFullYear());
    var theQuarterIndx  = 0;
    var nextQuarterIndx = 1;

    // If doing all years, set year to start
    // year of recorded history. OK to set it
    // earlier than true first recorded courses:
    if (thisAcademicYear == 0) {
     	thisAcademicYear = this.earliestAvailableDataYear;
    }
    // Distinguish between academic and calendar year:
    thisCalYear = thisAcademicYear;

    ///**********
    // print("thisAcademicYear: " + thisAcademicYear);
    // print("thisCalYear: " + thisCalYear);
    // print("thisYear: " + thisYear);
    // print("quartersToCover: " + quartersToCover);
    ///**********
    print("course_display_name,course_catalog_name,academic_year,quarter,num_quarters,is_internal,enrollment_start,start_date,end_date");

    while (moreYearsToDo) {
	var fallQuarterStartDate   = thisAcademicYear   + this.fallStartStr;
	var winterQuarterStartDate = thisAcademicYear   + this.winterStartStr;
	var springQuarterStartDate = thisAcademicYear+1 + this.springStartStr;
	var summerQuarterStartDate = thisAcademicYear+1 + this.summerStartStr;
	var summerQuarterEndDate   = thisAcademicYear+1 + this.summerEndStr;

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

     	//**********
     	//print("Quarter start     : " + quarterStartDate);
     	//print("Next Quarter start: " + nextQuarterStartDate);
     	//**********

     	// Get get course info for courses in
     	// one academic year, one particular quarter:

      if (split) {
        var courseCursor = db.modulestore.active_versions.find({},
           {"versions.published-branch": true, "org": true, "course": true, "run": true});

        while (true) {
          // Iterate through each course
          // We need the ms.active_version entry as well as the course structure from ms.structures
          var doc = courseCursor.hasNext() ? courseCursor.next() : null;
          if (doc === null) { break; }
          var def = db.modulestore.structures.find({"_id": doc.versions["published-branch"]},
             {"blocks": {$elemMatch: {"block_type": "course"}}})[0]["blocks"][0]["fields"];

          // Parse CDN and reject if test course
          var course_display_name = doc.org + "/" + doc.course + "/" + doc.run;
          if (!isTrueCourseName(course_display_name)) { continue; }

          // Parse course start and end dates
          startDate = def["start"];
          startDate = new RealDate(startDate).getMySqlDateStr(this.NO_TIME_OUTPUT);
          endDate = def["end"];
          endDate = new RealDate(endDate).getMySqlDateStr(this.NO_TIME_OUTPUT);

          // Reject if startDate not within bounds
          if (startDate < quarterStartDate || startDate >= nextQuarterStartDate ) { continue; }

          // Recover if endDate not defined
          if (endDate === undefined) {
            endDate = RealDate.prototype.getNullDateStr();
          }

          // Get number of quarters
          numQuarters = this.getNumQuartersDuration(def["start"], def["end"]);

          // Get enrollment start date and internal indicator for sharing
          enrollmentStartDate = def["enrollment_start"];
          enrollmentStartDate = new RealDate(enrollmentStartDate).getMySqlDateStr(this.NO_TIME_OUTPUT);
          enrollmentDomain = def["enrollment_domain"];
          isInternal == (isInternal == this.stanfordEnrollDomain || doc.org == "ohsx" || doc.org == "ohs") ? 1 : 0;

          // Parse platform display name
          display_name = def["display_name"];

          // Print result
          print(course_display_name +
     		  ",\"" + display_name + "\"" +
     		  "," + thisAcademicYear +
     		  "," + currQuarter +
     		  "," + numQuarters +
     		  "," + isInternal +
     		  "," + enrollmentStartDate +
     		  "," + startDate +
     		  "," + endDate);
        }
      }

     	courseCursor = db.modulestore.find({"_id.category": "course",
        				    "metadata.start": {$gte: quarterStartDate, $lt: nextQuarterStartDate}
     					   },
                 {"metadata.start": true,
     					    "metadata.end": true,
     					    "metadata.enrollment_domain":true,
     					    "metadata.enrollment_start":true,
     					    "metadata.display_name":true
                 }
     					  );

     	while (true) {
     	    doc = courseCursor.hasNext() ? courseCursor.next() : null;
     	    if (doc === null) {
     		break;
     	    }

      // Filter out courses injected for testing by platform staff:
	    course_display_name = doc._id.org + "/" + doc._id.course + "/" + doc._id.name;
	    if (! isTrueCourseName(course_display_name)) {
		continue;
	    }

     	    // Compute how many quarters course runs:
     	    numQuarters = this.getNumQuartersDuration(doc.metadata.start, doc.metadata.end);

     	    // Some records don't have class start or end
     	    // dates. Use zero-dates for those:
     	    startDate = doc.metadata.start;
     	    startDate = new RealDate(startDate).getMySqlDateStr(this.NO_TIME_OUTPUT);

     	    endDate = doc.metadata.end;
     	    endDate = new RealDate(endDate).getMySqlDateStr(this.NO_TIME_OUTPUT);

     	    enrollmentStartDate = doc.metadata.enrollment_start;
     	    enrollmentStartDate = new RealDate(enrollmentStartDate).getMySqlDateStr(this.NO_TIME_OUTPUT);

     	    isInternal = doc.metadata.enrollment_domain;
     	    if (isInternal == this.stanfordEnrollDomain || doc._id.org == "ohsx" || doc._id.org == "ohs") {
     		isInternal = 1;
     	    } else {
     		isInternal = 0;
     	    }

     	    if (endDate === undefined) {
     		// '.prototype' to use getNullDateStr as a class method:
     		endDate = RealDate.prototype.getNullDateStr();
     	    }
     	    print(course_display_name +
     		  ",\"" + doc.metadata.display_name + "\"" +
     		  "," + thisAcademicYear +
     		  "," + currQuarter +
     		  "," + numQuarters +
     		  "," + isInternal +
     		  "," + enrollmentStartDate +
     		  "," + startDate +
     		  "," + endDate);
     	}

     	// Done with one quarter
	if (currQuarter != "all" && this.year > 0) {
	    moreYearsToDo = false;
	    continue;
	}

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
     	    }
     	    // Do next year with same series of
     	    // quarters we just did for this year:
	    //**************************
	    //print('*********thisAcademicYear: ' + thisAcademicYear);
	    //print('*********thisCalYear: ' + thisCalYear);
	    //print('*********quartersToCover[theQuarterIndx]: ' + quartersToCover[theQuarterIndx]);
	    //**************************
     	    continue;
     	}
     	// Still have quarters to do in current academic year.
     	// Calendar date increments, if switching from
        // Fall quarter to winter:
     	if (currQuarter == "fall") {
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
	//**************************
	//print('*********thisAcademicYear: ' + thisAcademicYear);
	//print('*********thisCalYear: ' + thisCalYear);
	//print('*********quartersToCover[theQuarterIndx]: ' + quartersToCover[theQuarterIndx]);
	//**************************
    }
}

/* ************* Class RealDate *************** */

// Date class that fixes a seeming bug in MongoDB's
// JavaScript implementation. Its new ISODate("2014-01-01T07:00:00Z")
// returns 11 instead of 1 (or even 0 for zero-based month scheme.).
// My understanding is that 'Z' is local time.
// Note: this class only handles local time. It's all we need here.

function RealDate(isoDateStr) {
    if (!this.isISOStr(isoDateStr)) {
	this.theDate = this.getNullDateStr();
	this.dateComponents = [];
    } else {
	this.theDate = isoDateStr;
	this.dateComponents = isoDateStr.split('-');
    }
}

/* ************* Methods for RealDate *************** */


//------------------------------
// toDateObj
//----------------

// Return an ISO date string.

RealDate.prototype.toDateObj = function() {
    try {
        return(new ISODate(this.theDate));
    } catch(ReferenceError) {
	return(new Date(this.theDate));
    }
}

//------------------------------
// getYear
//----------------

RealDate.prototype.getYear = function() {
    if (this.dateComponents.length > 0) {
    	return(Number(this.dateComponents[0]));
    } else {
    	return(0);
    }
}

//------------------------------
// getFullYear
//----------------

RealDate.prototype.getFullYear = function() {
    // Synonym to getYear()
    if (this.dateComponents.length > 0) {
    	return(Number(this.dateComponents[0]));
    } else {
    	return(0);
    }
}

//------------------------------
// getMonth
//----------------

RealDate.prototype.getMonth = function() {
    if (this.dateComponents.length > 1) {
    	return(Number(this.dateComponents[1]));
    } else {
    	return(0);
    }
}

//------------------------------
// getDay
//----------------

RealDate.prototype.getDay = function() {
    if (this.dateComponents.length > 2) {
    	dayPlusTPlusTime = this.dateComponents[2];
    	dayPlusTime = dayPlusTPlusTime.split('T');
    	return(Number(dayPlusTime[0]));
    } else {
    	return(0);
    }
}

//------------------------------
// getTimeWithTimezone
//----------------

RealDate.prototype.getTimeWithTimezone = function() {
    if (this.dateComponents.length > 2) {
    	dayPlusTPlusTime = this.dateComponents[2];
    	dayPlusTime = dayPlusTPlusTime.split('T');
    	return(dayPlusTime[1]);
    } else {
    	return("00:00:00:Z");
    }}

//------------------------------
// getTimeNoTimezone
//----------------

RealDate.prototype.getTimeNoTimezone = function() {
    if (this.dateComponents.length > 2) {
    	dayPlusTPlusTime = this.dateComponents[2];
    	dayPlusTime = dayPlusTPlusTime.split('T');
    	timeWithTimeZone = dayPlusTime[1];
    	timeZoneSeparate = timeWithTimeZone.split('Z');
    	return(timeZoneSeparate[0]);
    } else {
    	return("00:00:00");
    }
}


//------------------------------
// getMySqlDateStr
//----------------

// Get either date+time, or just date
// from the RealDate object. Example output
// for a RealDate instance created using
// "2014-08-21T04:20:02", getMySqlDataStr()
// returns 2014-08-21 04:20:02, while
// getMySqlDataStr(true) returns just 2014-08-21.
// That is, notTimeOption is an optional arg.

RealDate.prototype.getMySqlDateStr = function(noTimeOption) {
    // Return a MySQL datetime-legal string.
    year = this.getYear();
    if (year == 0)
    	year = "0000";

    month = this.getMonth();
    if (month == 0)
    	month = "00";
    else if (month < 10)
    	month = "0" + month;

    day = this.getDay();
    if (day == 0)
    	day = "00";
    else if (day < 10)
    	day = "0" + day;

    mySqlDateStr = [year, month, day].join("-");
    if (noTimeOption) {
	mySqlStr = mySqlDateStr;
    } else {
	mySqlStr = mySqlDateStr + ' ' + this.getTimeNoTimezone();
    }
    return mySqlStr;
}

//------------------------------
// getNullDateStr
//----------------

RealDate.prototype.getNullDateStr = function() {
    // Return a MongoDB legal zero ISO date.
    // Note: Not legal in MySQL, b/c of the
    // 'T' and the timezone.
    return("0000-00-00T00:00:00.000Z");
}


//------------------------------
// isNullDateObj
//----------------

// Return true if given RealDate *instance* is a null date,
// else return false

RealDate.prototype.isNullDateObj = function(realDateObj) {
    return(realDateObj.theDate == '0000-00-00T00:00:00.000Z' ||
	   realDateObj.theDate == '0000-00-00T00:00:00.Z' ||
	   realDateObj.theDate == '0000-00-00T00:00:00' ||
	   realDateObj.theDate == '0000-00-00' ||
	   realDateObj.theDate == '00:00:00' ||
	   realDateObj.theDate == '00:00:00Z')
}

//------------------------------
// isNullDateStr
//----------------

// Return true if given string is a null date,
// else return false

RealDate.prototype.isNullDateStr = function(readDateStr) {
    return(readDateStr == '0000-00-00T00:00:00.000Z' ||
	   readDateStr == '0000-00-00T00:00:00Z' ||
	   readDateStr == '0000-00-00T00:00:00' ||
	   realDateObj.theDate == '0000-00-00' ||
	   realDateObj.theDate == '00:00:00' ||
	   realDateObj.theDate == '00:00:00Z')
}

//------------------------------
// isISOStr
//---------

// Return true/false if given maybeISODateStr is
// a string conforming to ISO. Example: "2014-08-21T04:20:02"
// returns true, while "2014-08-21 04:20:02" returns false.
// Value of null returns null. Just a date, like 2014-08-21
// returns true.

RealDate.prototype.isISOStr = function(maybeISODateStr) {
    if (maybeISODateStr === null || maybeISODateStr === undefined || maybeISODateStr === "null") {
	return false;
    }
    dateTimeRegExpPattern = new RegExp("[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}");
    dateTimeMatch = maybeISODateStr.match(dateTimeRegExpPattern);
    if (dateTimeMatch != null) {
	return dateTimeMatch;
    }
    dateOnlyRegExpPattern = new RegExp("[0-9]{4}-[0-9]{2}-[0-9]{2}");
    dateOnlyMatch = maybeISODateStr.match(dateOnlyRegExpPattern);
    return dateOnlyMatch != null;
}

/* ************* Unit Tests *************** */

function dualEnvPrint(txt) {
// Print function that works both within a Mongo shell
// and in the Web browser test environment (see comment
// at top of file.)

    try {
	txtArea = document.getElementById('outTxt');
	txtArea.value += txt + '\n';
    }  catch(ReferenceError) {
	print(txt);
    }
}

function realDateUnittests() {

    dualEnvPrint('Tests for class RealDate...');

    rd = new RealDate('2014-01-02T10:11:12Z');

    // Jan 2 instead of Jan1 because of conversion GMT->PST
    if (String(rd.toDateObj()) !== 'Thu Jan 02 2014 02:11:12 GMT-0800 (PST)')
	dualEnvPrint("Conversion to ISO date failed.");
    else
	dualEnvPrint('toDateObj() OK.');

    if (rd.getYear() !== 2014)
	dualEnvPrint("getYear() failed.");
    else
	dualEnvPrint('getYear() OK.');

    if (rd.getFullYear() !== 2014)
	dualEnvPrint("getFullYear() failed.");
    else
	dualEnvPrint('getFullYear() OK.');

    if (rd.getMonth() !== 1)
	dualEnvPrint("getMonth() failed.");
    else
	dualEnvPrint('getMonth() OK.');

    if (rd.getDay() !== 2)
	dualEnvPrint("getDay() failed.");
    else
	dualEnvPrint('getDay() OK.');

    if (rd.getTimeWithTimezone() !== '10:11:12Z')
	dualEnvPrint("getTimeWithTimezone() failed.");
    else
	dualEnvPrint('getTimeWithTimezone() OK.');

    if (rd.getTimeNoTimezone() !== '10:11:12')
	dualEnvPrint("getTimeNoTimezone() failed.");
    else
	dualEnvPrint('getTimeNoTimezone() OK.');

    if (rd.getMySqlDateStr() !== '2014-01-02 10:11:12')
	dualEnvPrint("getMySqlDateStr() failed.");
    else
	dualEnvPrint('getMySqlDateStr() OK.');

    if (rd.isNullDateObj(rd))
	dualEnvPrint("isNullDateObj() failed.");
    else
	dualEnvPrint('isNullDatObj() OK.');

    if (! rd.isNullDateStr('0000-00-00T00:00:00Z'))
	dualEnvPrint("isNullDataStr() failed.");
    else
	dualEnvPrint('isNullDateStr() OK.');

    dualEnvPrint('Class RealDate OK.');
}


function courseInfoExtractorUnittests() {

    dualEnvPrint('Tests for class CourseInfoExtractor...');

    ce = new CourseInfoExtractor(2013, 'winter');

    if (ce.getQuarterStartDate(2013, 'summer') !== '2014-06-01T00:00:00Z')
	dualEnvPrint('(1) getQuarterStartDate() failed (OK if in browser context).');
    else
	dualEnvPrint('(1) getQuarterStartDate() OK.');

    if (ce.getQuarterFromDate('2014-03-02') !== 'spring')
	dualEnvPrint('(2) getQuarterFromDate() failed: computes ' + ce.getQuarterFromDate('2014-03-02') + ' should be spring');
    else
	dualEnvPrint('(2) getQuarterFromDate() OK.');

    if (ce.getQuarterFromDate('2014-02-30') !== 'winter')
	dualEnvPrint('(3) getQuarterFromDate() failed: computes ' + ce.getQuarterFromDate('2014-02-30') + ' should be winter');
    else
	dualEnvPrint('(3) getQuarterFromDate() OK.');

    if (ce.getQuarterFromDate('2014-06-30') !== 'summer')
	dualEnvPrint('(4) getQuarterFromDate() failed: computes ' + ce.getQuarterFromDate('2014-02-30') + ' should be summer');
    else
	dualEnvPrint('(4) getQuarterFromDate() OK.');

    if (ce.getNumQuartersDuration('2013-01-02', '2013-01-02') != 1)
	dualEnvPrint('getNumQuartersDuration() failed.');
    else
	dualEnvPrint('getNumQuartersDuration() OK.');

    if (ce.getNumQuartersDuration('2013-01-02', '2014-01-02') != 5)
	dualEnvPrint('getNumQuartersDuration() failed.');
    else
	dualEnvPrint('getNumQuartersDuration() OK.');

    if (ce.getNumQuartersDuration('2013-01-02', '0000-00-00') != -1)
	dualEnvPrint('getNumQuartersDuration() failed.');
    else
	dualEnvPrint('getNumQuartersDuration() OK.');

    if (ce.getNumQuartersDuration('10:30:11', '00:00:00') != -1)
	dualEnvPrint('getNumQuartersDuration() failed.');
    else
	dualEnvPrint('getNumQuartersDuration() OK.');

    if (ce.getNextQuarter('winter') != 'spring')
	dualEnvPrint('getNextQuarter() failed.');
    else
	dualEnvPrint('getNextQuarter() OK.');

    if (ce.getNextQuarter('summer') != 'fall')
	dualEnvPrint('getNextQuarter() failed.');
    else
	dualEnvPrint('getNextQuarter() OK.');
}
