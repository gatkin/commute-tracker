using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Application as App;
using CommuteTrackerUtil as CommuteTrackerUtil;


module CommuteHistory {

	///! Commutes are saved and aggregated based on the time of day they
	///! begin. HISTORY_RESOLUTION indicates at what minute commutes are
	///! grouped when saved into the history. Currently commutes are grouped
	///! every 5 minutes
	const HISTORY_RESOLUTION = 5; // In minutes

	///! The object store key for each time of day that we save commute stats
	///! consists of two parts. The first part of the object store key is of
	///! the form hour_minute where hour and minute represent the start time
	///! of the commute in 24-hour time. This forms the base key to acces records
	///! for each time of day in the object store. To access the particular values
	///! for each time of day, a key extension for each record is applied to the
	///! base key for each particular value we want to save or access. The key
	///! extensions for each value saved are listed below.
	hidden const NUM_RECORDS_KEY_EXTN = "_NUM_RECORDS";
	hidden const MOVE_TIME_KEY_EXTN = "_MOVE_TIME"; 
	hidden const STOP_TIME_KEY_EXTN = "_STOP_TIME"; 
	hidden const TOTAL_DIST_KEY_EXTN = "_TOTAL_DIST";
	hidden const NUM_STOPS_KEY_EXTN = "_NUM_STOPS";
	hidden const MAX_SPEED_KEY_EXTN = "_MAX_SPEED";
	
	
	///! Returns a controller to manage the commute history views
	function getController() {
		return new CommuteHistoryController();
	}
	
	///! Controller that manages commute hisotry views
	hidden class CommuteHistoryController {
		
		///! Displays the commute history chart view. Takes as input a moment
		///! object that represents the time of day for which the first commute data
		///! will be displayed at the top of the chart
		function showHistoryChart( timeToShow ) {
			var historyChartView = new CommuteHistoryChartView( timeToShow );
			var historyChartDelegate = new CommuteHistoryChartDelegate( historyChartView );
			Ui.switchToView( historyChartView, historyChartDelegate, Ui.SLIDE_LEFT );
		}
		
		///! Displays the commute history detail view. Takes as input a moment
		///! object that represents what time of day to show the commute history
		///! details for.
		function showHistoryDetail( timeToShow ) {
			var historyDetailView = new CommuteHistoryDetailView( timeToShow );
			var historyDetailDelegate = new CommuteHistoryDetailDelegate( historyDetailView );
			Ui.switchToView( historyDetailView, historyDetailDelegate, Ui.SLIDE_LEFT );
		}
	}
	
	
	
	///! Persists the statistics from the given commute model into the object store
	function saveCommute( commuteModel ) {
		// Get the base key from the time of day the commute began
		var keyInfo = getKeyForMoment( commuteModel.getCommuteStartTime() );
		var objectStoreKey = keyInfo[:objectStoreKey];
		
		var stopTime = commuteModel.getTimeStopped();
		var	moveTime = commuteModel.getTimeMoving();
		var	numStops = commuteModel.getNumStops();
		var	maxSpeed = commuteModel.getMaxSpeed();
		var	distance = commuteModel.getTotalDistance();
		
		var app = App.getApp();
		var numRecords = app.getProperty(objectStoreKey + NUM_RECORDS_KEY_EXTN);
		if( null == numRecords || 0 == numRecords ) {
			// This is the first commute record for this time of day
			numRecords = 1;
		} else {
			// Add the stats for this commute to the history we have for all commutes at this time of day
			numRecords++;
			stopTime += app.getProperty( objectStoreKey + STOP_TIME_KEY_EXTN );
			moveTime += app.getProperty( objectStoreKey + MOVE_TIME_KEY_EXTN );
			numStops += app.getProperty( objectStoreKey + NUM_STOPS_KEY_EXTN );
			distance += app.getProperty( objectStoreKey + TOTAL_DIST_KEY_EXTN );
			
			var prevMaxSpeed = app.getProperty( objectStoreKey + MAX_SPEED_KEY_EXTN );
			if( prevMaxSpeed > maxSpeed ) {
				maxSpeed = prevMaxSpeed;
			}
		}
		
		// Save the stats into the object store
		app.setProperty( objectStoreKey + NUM_RECORDS_KEY_EXTN, numRecords );
		app.setProperty( objectStoreKey + STOP_TIME_KEY_EXTN, stopTime );
		app.setProperty( objectStoreKey + MOVE_TIME_KEY_EXTN, moveTime );
		app.setProperty( objectStoreKey + NUM_STOPS_KEY_EXTN, numStops );
		app.setProperty( objectStoreKey + TOTAL_DIST_KEY_EXTN, distance );
		app.setProperty( objectStoreKey + MAX_SPEED_KEY_EXTN, maxSpeed );
	}
	
	///! Loads all commute statistics for the given time of day. Takes
	///! as input a moment object representing the time of day for which
	///! to load all commute statistics. Returns a dictionary with the fields
	///! {:numRecords, :stopTime, :moveTime, :numStops, :distance, :maxSpeed,
	///! :startTimeHour, :startTimeMinute}
	function loadCommuteHistoryDetail( commuteStartTime ) {
		// Get the base key for the given time of day
		var keyInfo = getKeyForMoment( commuteStartTime );
		var objectStoreKey = keyInfo[:objectStoreKey];
		
		var app = App.getApp();
		var historyData = null;
		var numRecords = app.getProperty( objectStoreKey + NUM_RECORDS_KEY_EXTN );
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
				:stopTime => app.getProperty( objectStoreKey + STOP_TIME_KEY_EXTN ),
				:moveTime => app.getProperty( objectStoreKey + MOVE_TIME_KEY_EXTN ),
				:numStops => app.getProperty( objectStoreKey + NUM_STOPS_KEY_EXTN ),
				:distance => app.getProperty( objectStoreKey + TOTAL_DIST_KEY_EXTN ),
				:maxSpeed => app.getProperty( objectStoreKey + MAX_SPEED_KEY_EXTN ),
				:startTimeHour => keyInfo[:hour],
				:startTimeMinute => keyInfo[:minute]
			};
		}
		return historyData;
	}
	
	///! Loads a given number of consecutive commute records starting at the record for
	///! commuteStartTime. commuteStatTime is a moment object representing the time of
	///! day of the first record to load, and numRecordsToLoad is an integer.
	///! Returns an array of length numRecordsToLoad. Each entry in the returned
	///! array is a dictionary of the form:
	///!	{ 
	///!      :timeLabel => string label for the commute time, 
	///!	  :commuteEfficiency => integer between 0 and 100,
	///! 	  :hasRecord => boolean, whether there are any records for this time of day
	///!    }
	function loadCommuteHistoryOverview( commuteStartTime, numRecordsToLoad ) {
		// Get the hour and minute for the first record to load
		var keyInfo = getKeyForMoment( commuteStartTime );
		var minute = keyInfo[:minute];
		var hour = keyInfo[:hour];
		
		var app = App.getApp();
		var commuteHistory = new [numRecordsToLoad];
		for(var i=0; i<numRecordsToLoad; i++) {
			// Get the base key for the current hour and minute values
			var objectStoreKey = getKeyForHourMinute( hour, minute );
			
			// Retreive the values
			var stopTime = app.getProperty( objectStoreKey + STOP_TIME_KEY_EXTN );
			var moveTime = app.getProperty( objectStoreKey + MOVE_TIME_KEY_EXTN );
			
			// Compute the commute efficiency for this time of day
			var commuteEfficiency = 0; 
			var hasRecord = false;
			if( null == stopTime || null == moveTime ) {
				// We don't have any records yet for this time of day.
				hasRecord = false;
			} else {
				var totalTime = moveTime + stopTime;
				// Check for divide by zero
				if ( 0 != totalTime ) {
					commuteEfficiency = (moveTime * 100) / totalTime;
				} 
				hasRecord = true;
			}
			
			var timeLabel = CommuteTrackerUtil.formatTime( hour, minute );
			commuteHistory[i] = {:timeLabel => timeLabel, :commuteEfficiency => commuteEfficiency, :hasRecord => hasRecord};
			
			// Advance the hour and minute to point to the next record in the object store
			minute += HISTORY_RESOLUTION;
			if( 60 == minute ) {
				hour = ( hour + 1 ) % 24;
				minute = 0;
			}
		}
		return commuteHistory;
	}
	
	function deleteAllHistory() {
		App.getApp().clearProperties();
	}
	
	function deleteRecordForTime(commuteStartTime) {
		var objectStoreKey = getKeyForMoment( commuteStartTime )[:objectStoreKey];
		var app = App.getApp();
		
		app.deleteProperty( objectStoreKey + NUM_RECORDS_KEY_EXTN );
		app.deleteProperty( objectStoreKey + STOP_TIME_KEY_EXTN );
		app.deleteProperty( objectStoreKey + MOVE_TIME_KEY_EXTN );
		app.deleteProperty( objectStoreKey + NUM_STOPS_KEY_EXTN );
		app.deleteProperty( objectStoreKey + TOTAL_DIST_KEY_EXTN );
		app.deleteProperty( objectStoreKey + MAX_SPEED_KEY_EXTN );
	}
	
	///! Takes as input a moment object representing the time of day to
	///! retrieve the object store key. Returns a dictionary of the form
	///! {
	///!   :objectStoreKey => string representing the base object store key for the given time of day
	///!   :hour => integer representing the hour portion of the base object store key
	///!   :minute => integer representing the minute portion of the base object store key
	///!  }
	hidden function getKeyForMoment(timeMoment) {
		var timeInfo = Gregorian.info( timeMoment, Time.FORMAT_SHORT );
		
		// Round the minute to the closest HISTORY_RESOLUTION minute
		var minute = ((timeInfo.min + (HISTORY_RESOLUTION/2)) / HISTORY_RESOLUTION ) * HISTORY_RESOLUTION ; 
		var hour = timeInfo.hour;
		
		// Check for wraparound
		if( 60 == minute ) {
			minute = 0;
			hour = (hour + 1) % 24;
		}
		var objectStoreKey = getKeyForHourMinute( hour, minute );
		return {:hour => hour, :minute => minute, :objectStoreKey => objectStoreKey};
	}
	
	///! Returns a string representing the object store key used to access data in the object store
    ///! The key is unique for each hour/minute combination
	hidden function getKeyForHourMinute(hour, minute) {
		return hour.toString() + "_" + minute.toString();
	}
	
}