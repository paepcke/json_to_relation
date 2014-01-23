/*
  Loaded by exportClass.html. Function startProgressStream()
  is called when the Export Class button is pressed. The function
  causes:
  dbadmin:datastage:Code/json_to_relation/json_to_relation/cgi_bin/exportClass.py
  to run on datastage. That remote execution is started via
  an EventSource, so that server-send messages from datastage
  can be displayed on the browser below the export class form.
*/

function ExportClass() {

    var screenContent = "";
    var source = null;
    var ws = null;

    this.construct = function() {
	ws =  new WebSocket("ws://localhost:8080/exportClass");
	ws.onopen = function() {};

	ws.onmessage = function(evt) {
	    // Separate "<action>:<args>":
	    // e.g. "courseList:['course1','course2']"
	    try {
		var attrVal = evt.data.split(":");
		var action  = attrVal[0]; // e.g. 'courseList'
		var args    = eval(attrVal)[1]; // e.g. JS str array
	    } catch(err) {
		alert('Bad action request from server: ' + evt.data);
	    }
	    handleActionRequest(action,args);
	}
    }();

    var handleActionRequest = function(action,args) {
	switch (action) {
	case 'courseList':
	    listCourseNames(args);
	    break;
	default:
	    alert('Unknown action request from server: ' + action);
	    break;
	}
    }

    var listCourseNames = function(courseNameArr) {
	clrProgressDiv();
	var len = courseNameArr.length
	for (var i=0; i<len; ++i) {
	    var crsNm = courseNameArr[i];
	    document.getElementById("progress").innerHTML += 
	    '<input type="radio" id="courseID" value="' + crsNm + '">' + crsNm + '<br>';
	}
    }

    this.progressUpdate = function() {
	// One-second timer showing date/time on screen while
	// no output is coming from server, b/c some entity
	// is buffering:
	var currDate = new Date();
	document.getElementById("progress").innerHTML = screenContent + 
	    currDate.toLocaleDateString() + 
	    " " +
	    currDate.toLocaleTimeString();
    }

    this.queryCourseIDResolution = function(courseQuery) {
	ws.send("courseNameQ:" + courseQuery);
    }

    this.handleCourseListRes = function(courseListStr) {
    }

    this.startProgressStream = function() {
	//****************************
	//this.getCourseIDResolution(encodeURI(document.getElementById("courseID").value));
	this.queryCourseIDResolution(document.getElementById("courseID").value);
	return;
	//****************************
	/*Start the event stream, and install the required
	  event listeners on the EventSource
	*/
	var xmlHttp = null;
	// The 'encodeURI() is needed such that "%EE222%" is
	// not read as 'ee' being a hex char Unicode:
	var courseID   = encodeURI(document.getElementById("courseID").value);
	var fileAction = document.getElementById("fileAction").checked;

	var theURL = window.location.origin + "/code/exportClass.py";

	theURL += "?courseID="+courseID+"&fileAction="+fileAction;

	if(typeof(EventSource) == "undefined") {
	    // Browser doesn't support server-send events.
	    // Just start the export without giving on-the-fly
	    // feedback:
	    window.location = theURL;
	    return;
	}

	// Start the progress timer; remember the existing
	// screen content in the 'progress' div so that
	// the timer func can append to that:
	
	screenContent = document.getElementById("progress").innerHTML = "<h2>Data Export Progress</h2>\n\n"
	timer = window.setInterval(progressUpdate,1000);

	// Start exportClass.py at the server, listening
	// for an event stream from that program:
	source = new EventSource(theURL);

	// Listener for all strings from server that start with 'data: ':
	source.addEventListener('message', function(event) {
	    /*Called when server sends a string that starts with
	      'data: '
	    */
	    // Add the string to the bottom of the screen:
	    document.getElementById("progress").innerHTML += event.data + "<br>";
	    // If 'clear progress info' button is not visible, make it
	    // visible:
	    if (!clrProgressButtonVisible()) {
		exposeClearProgressButton();
	    }

	}, false);

	// Listener for exportClass.py saying that it's done:
	source.addEventListener('allDone', function(event) {
	    /*Called when server sends a string that starts
	      with 'event: allDone'
	    */
	    //console.log("Got 'allDone'") //********8
	    source.close();
	    clearInterval(timer);
	}, false);
    }

    var clrProgressDiv = function() {
	/* Clear the progress information section on screen */
	document.getElementById("progress").innerHTML = "";
	hideClearProgressButton();
    }

    var exposeClearProgressButton = function() {
	/* Show the Clear Progress Info button */
	document.getElementById("clrProgBtn").style.visibility="visible";
    }

    var hideClearProgressButton = function() {
	/* Hide the Clear Progress Info button */
	document.getElementById("clrProgBtn").style.visibility="hidden";
    }

    var clrProgressButtonVisible = function() {
	/* Return true if the Clear Progress Info button is visible, else false*/
	return document.getElementById("clrProgBtn").style.visibility == "visible";
    }

    var cancelProcess = function() {
	source.close();
	clearInterval(timer);
	clrProgressDiv();
    }
}
var classExporter = new ExportClass();
