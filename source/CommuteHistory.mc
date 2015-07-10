using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using CommuteTrackerUtil as CommuteTrackerUtil;


module CommuteHistory {

	//!  We group commutes that start in blocks of HISTORY_RESOLUTION minutes to store in history
	const HISTORY_RESOLUTION = 5; // In minutes
	hidden const NUM_RECORDS_KEY_EXTN = "_NUM_RECORDS";
	hidden const MOVE_TIME_KEY_EXTN = "_MOVE_TIME"; 
	hidden const STOP_TIME_KEY_EXTN = "_STOP_TIME"; 
	hidden const TOTAL_DIST_KEY_EXTN = "_TOTAL_DIST";
	hidden const NUM_STOPS_KEY_EXTN = "_NUM_STOPS";
	hidden const MAX_SPEED_KEY_EXTN = "_MAX_SPEED";
	
	
	class CommuteHistoryController extends Ui.BehaviorDelegate {
		
		hidden var historyChartView = null;
		
		function initialize() {
			historyChartView = new CommuteHistoryChartView();
		}
		
		function getView() {
			return historyChartView;
		}
		
		function onBack() {
			Ui.popView(Ui.SLIDE_RIGHT);
			return true;
		}
		
		function onKey(keyEvent) {
			var key = keyEvent.getKey();
			if( Ui.KEY_DOWN == key ) {
				historyChartView.showNextHistoryPage();
			} else if ( Ui.KEY_UP == key ) {
				historyChartView.showPreviousHistoryPage();
			} else if ( Ui.KEY_ESC == key ) {
				Ui.popView(Ui.SLIDE_RIGHT);
			} else if ( Ui.KEY_ENTER ) {
				showHistoryDetail();
			}
		}
		
		function showHistoryDetail() {
			var histDetailView = new CommuteHistoryDetailView( historyChartView.getTimeToShow() );
			var histDetailDelegate = new CommuteHistoryDetailDelegate( histDetailView );
			Ui.pushView( histDetailView, histDetailDelegate, Ui.SLIDE_LEFT );
		}
	}
	
	
	
	
	function saveCommute( commuteModel ) {
		// We will aggregate commute statistics based on time of day at HISTORY_RESOLUTION minute intervals.
		// Use the combination of the start minute and the starting hour as a key
		// into the object store of the stats
		var keyInfo = getKeyForMoment(commuteModel.getCommuteStartTime());
		var objectStoreKey = keyInfo[:objectStoreKey];
		
		var stopTime = commuteModel.getTimeStopped();
		var	moveTime = commuteModel.getTimeMoving();
		var	numStops = commuteModel.getNumStops();
		var	maxSpeed = commuteModel.getMaxSpeed();
		var	distance = commuteModel.getTotalDistance();
		
		var app = App.getApp();
		var numRecords = app.getProperty(objectStoreKey + NUM_RECORDS_KEY_EXTN);
		if( null == numRecords || 0 == numRecords ) {
			// This is the first commute record for this time of day.
			numRecords = 1;
		} else {
			// Add the stats for this commute to the history we have for all commutes at this time of day
			numRecords++;
			stopTime += app.getProperty(objectStoreKey + STOP_TIME_KEY_EXTN);
			moveTime += app.getProperty(objectStoreKey + MOVE_TIME_KEY_EXTN);
			numStops += app.getProperty(objectStoreKey + NUM_STOPS_KEY_EXTN);
			distance += app.getProperty(objectStoreKey + TOTAL_DIST_KEY_EXTN);
			
			var prevMaxSpeed = app.getProperty(objectStoreKey + MAX_SPEED_KEY_EXTN);
			if( prevMaxSpeed > maxSpeed ) {
				maxSpeed = prevMaxSpeed;
			}
		}
		
		// Save the history in the object store
		app.setProperty(objectStoreKey + NUM_RECORDS_KEY_EXTN, numRecords);
		app.setProperty(objectStoreKey + STOP_TIME_KEY_EXTN, stopTime);
		app.setProperty(objectStoreKey + MOVE_TIME_KEY_EXTN, moveTime);
		app.setProperty(objectStoreKey + NUM_STOPS_KEY_EXTN, numStops);
		app.setProperty(objectStoreKey + TOTAL_DIST_KEY_EXTN, distance);
		app.setProperty(objectStoreKey + MAX_SPEED_KEY_EXTN, maxSpeed);
	}
	
	
	function loadCommuteHistoryDetail( commuteStartTime ) {
		var keyInfo = getKeyForMoment( commuteStartTime );
		var objectStoreKey = keyInfo[:objectStoreKey];
		
		var app = App.getApp();
		var historyData = null;
		var numRecords = app.getProperty(objectStoreKey + NUM_RECORDS_KEY_EXTN);
		if( null == numRecords || 0 == numRecords ) {
			// There are no records for this time of day
			historyData = { 
				:numRecords => 0, 
				:stopTime => 0,
				:moveTime => 0,
				:numStops => 0,
				:distance => 0,
				:maxSpeed => 0,
				:startTimeHour => keyInfo[:hour],
				:startTimeMinute => keyInfo[:minute]
			};

		} else {
			// Load the rest of the history data
			historyData = { 
				:numRecords => numRecords, 
				:stopTime => app.getProperty(objectStoreKey + STOP_TIME_KEY_EXTN),
				:moveTime => app.getProperty(objectStoreKey + MOVE_TIME_KEY_EXTN),
				:numStops => app.getProperty(objectStoreKey + NUM_STOPS_KEY_EXTN),
				:distance => app.getProperty(objectStoreKey + TOTAL_DIST_KEY_EXTN),
				:maxSpeed => app.getProperty(objectStoreKey + MAX_SPEED_KEY_EXTN),
				:startTimeHour => keyInfo[:hour],
				:startTimeMinute => keyInfo[:minute]
			};
		}
		return historyData;
	}
	
	
	function loadCommuteHistoryOverview( commuteStartTime, numRecordsToLoad ) {
		var keyInfo = getKeyForMoment( commuteStartTime );
		var minute = keyInfo[:minute];
		var hour = keyInfo[:hour];
		
		var app = App.getApp();
		var commuteHistory = new [numRecordsToLoad];
		for(var i=0; i<numRecordsToLoad; i++) {
		
			// Retrive the values from the object store
			var objectStoreKey = getKeyForHourMinute(hour, minute);
			var stopTime = app.getProperty(objectStoreKey + STOP_TIME_KEY_EXTN);
			var moveTime = app.getProperty(objectStoreKey + MOVE_TIME_KEY_EXTN);
			
			var commuteEfficiency = 0; 
			var hasRecord = false;
			if( stopTime == null || moveTime == null ) {
				// We don't have a record yet for this time slot.
				hasRecord = false;
			} else {
				// Check for divide by zero
				var totalTime = moveTime + stopTime;
				if ( 0 != totalTime ) {
					commuteEfficiency = (moveTime * 100) / totalTime;
				} 
				hasRecord = true;
			}
			
			var timeLabel = CommuteTrackerUtil.formatTime(hour, minute);
			commuteHistory[i] = {:timeLabel => timeLabel, :commuteEfficiency => commuteEfficiency, :hasRecord => hasRecord};
			
			minute += HISTORY_RESOLUTION;
			if( minute == 60 ) {
				hour = ( hour + 1 ) % 24;
				minute = 0;
			}
		}
		return commuteHistory;
	}
	
	///! Returns the hour, minute, and objectStoreKey for the given moment
    ///! to be used to save and access data in the object store
	hidden function getKeyForMoment(timeMoment) {
		var timeInfo = Gregorian.info(timeMoment, Time.FORMAT_SHORT);
		// Find the closest HISTORY_RESOLUTION minute to the current time
		var minute = ((timeInfo.min + (HISTORY_RESOLUTION/2)) / HISTORY_RESOLUTION ) * HISTORY_RESOLUTION ; 
		var hour = timeInfo.hour;
		if(minute == 60) {
			minute = 0;
			hour = (hour + 1) % 24;
		}
		var objectStoreKey = getKeyForHourMinute(hour, minute);
		return {:hour => hour, :minute => minute, :objectStoreKey => objectStoreKey};
	}
	
	///! Returns a string representing the object store key used to access data in the object store
    ///! The key is unique for each hour/minute combination
	hidden function getKeyForHourMinute(hour, minute) {
		return hour.toString() + "_" + minute.toString();
	}
	
}