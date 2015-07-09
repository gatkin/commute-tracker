using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using CommuteTrackerUtil as CommuteTrackerUtil;


module CommuteHistory {

	//!  We group commutes that start in blocks of HISTORY_RESOLUTION minutes to store in history
	hidden const HISTORY_RESOLUTION = 10; // In minutes
	hidden const NUM_RECORDS_KEY_EXTN = "_NUM_RECORDS";
	hidden const MOVE_TIME_KEY_EXTN = "_MOVE_TIME"; 
	hidden const STOP_TIME_KEY_EXTN = "_STOP_TIME"; 
	hidden const TOTAL_DIST_KEY_EXTN = "_TOTAL_DIST";
	hidden const NUM_STOPS_KEY_EXTN = "_NUM_STOPS";
	hidden const MAX_SPEED_KEY_EXTN = "_MAX_SPEED";
	
	
	class CommuteHistoryController extends Ui.BehaviorDelegate {
		
		hidden var historyView = null;
		
		function initialize() {
			historyView = new CommuteHistoryView();
		}
		
		function getView() {
			return historyView;
		}
		
		function onBack() {
			Ui.popView(Ui.SLIDE_RIGHT);
			return true;
		}
		
		function onKey(keyEvent) {
			var key = keyEvent.getKey();
			if( Ui.KEY_DOWN == key ) {
				historyView.showNextHistoryPage();
			} else if ( Ui.KEY_UP == key ) {
				historyView.showPreviousHistoryPage();
			} else if ( Ui.KEY_ESC == key ) {
				Ui.popView(Ui.SLIDE_RIGHT);
			}
		}
	}
	
	
	hidden class CommuteHistoryView extends Ui.View {
		hidden var timeToShow = null; // For what time of day we display for the commute history
		
		function initialize() {
			timeToShow = Time.now();
		}
	
	    function onLayout(dc) {
	        setLayout(Rez.Layouts.CommuteHistory(dc));
	    }
	
	    //! Update the view
	    function onUpdate(dc) {
	        dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_WHITE );
	        dc.clear();
	        dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT );
	        
	        var spacing = 100 / (60 / HISTORY_RESOLUTION);
	        var textY = 30;
	        var textX = 5;
	        var barHeight = 5;
	        var chartBaseX = 45;
	        var maxBarWidth = 150;
	        var barWidth = 0;
	        
	        var commuteHistory = loadCommuteHistoryOverview(timeToShow);
	        for(var i=0; i<commuteHistory.size(); i++) {
	        	// Draw the time label
	    		dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT );
	    		dc.drawText(textX, textY, Gfx.FONT_XTINY, commuteHistory[i][:timeLabel], Gfx.TEXT_JUSTIFY_LEFT);
	    		barWidth = commuteHistory[i][:commuteEfficiency] * maxBarWidth / 100.0;
	    		
	    		// If we have a record for this time, always show a tiny bar, even if the 
				// efficiency is zero to indicate that a record exists
				if( commuteHistory[i][:hasRecord] && 0 == commuteHistory[i][:commuteEfficiency] ) {
					barWidth = 2;
				} 
				
				// Choose the color for the bar based on the efficiency
				var barColor = Gfx.COLOR_WHITE;
				if( commuteHistory[i][:commuteEfficiency] < 25 ) {
					barColor = Gfx.COLOR_RED;
				} else if ( commuteHistory[i][:commuteEfficiency] < 50 ) {
					barColor = Gfx.COLOR_ORANGE;
				} else if ( commuteHistory[i][:commuteEfficiency] < 75 ) {
					barColor = Gfx.COLOR_YELLOW;
				} else {
					barColor = Gfx.COLOR_GREEN;
				}
				
				dc.setColor(barColor, Gfx.COLOR_TRANSPARENT);
	    		dc.fillRectangle(chartBaseX, textY + 8, barWidth, barHeight);
	    		textY += spacing;
	    	}
	    	
	    	// Draw the graph tickmarks
			dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT );
			dc.fillRectangle(chartBaseX-1, 30 , 1, textY - 28);
			dc.fillRectangle(chartBaseX-1, textY, maxBarWidth, 1);
			dc.drawText(chartBaseX, textY + 2, Gfx.FONT_XTINY, "0", Gfx.TEXT_JUSTIFY_RIGHT);
			dc.drawText(chartBaseX + maxBarWidth/2, textY + 2, Gfx.FONT_XTINY, "50", Gfx.TEXT_JUSTIFY_RIGHT);
			dc.drawText(chartBaseX + maxBarWidth, textY + 2, Gfx.FONT_XTINY, "100", Gfx.TEXT_JUSTIFY_RIGHT);
			
			// Title
			dc.drawText(115, 3, Gfx.FONT_SMALL, "Commute Efficiency", Gfx.TEXT_JUSTIFY_CENTER); 
	    }
	
	
		function showPreviousHistoryPage() {
			// Decrease the time to show by one half hour
			var durationDecrement = new Time.Duration(-1800);
			timeToShow = timeToShow.add(durationDecrement);
			Ui.requestUpdate();
		}
		
		function showNextHistoryPage() {
			// Increase the time to show by one half hour
			var durationIncrement = new Time.Duration(1800);
			timeToShow = timeToShow.add(durationIncrement);
			Ui.requestUpdate();
		}
	}
	
	
	class CommuteHistoryDetailView extends Ui.View {
	
		hidden var commuteStartTime = null; // Moment object

		function intialize( startTime ) {
			commuteStartTime = startTime;
		}
		
		function onUpdate(dc) {
	        dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_WHITE );
	        dc.clear();
	        dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT );
	        
	        historyData = loadCommuteHistoryDetail( commuteStartTime );
	     }
		
		
		function showPreviousHistoryDetail() {
			// Decrease the time to show by one half hour
			commuteStartTime = commuteStartTime.add( -HISTORY_RESOLUTION );
			Ui.requestUpdate();
		}
		
		function showNextHistoryDetail() {
			// Decrease the time to show by one half hour
			commuteStartTime = commuteStartTime.add(durationIncrement);
			Ui.requestUpdate();
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
	
	
	hidden function loadCommuteHistoryDetail( commuteStartTime ) {
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
				:maxSpeed => 0
			};

		} else {
			// Load the rest of the history data
			historyData = { 
				:numRecords => numRecords, 
				:stopTime => app.getProperty(objectStoreKey + STOP_TIME_KEY_EXTN),
				:moveTime => app.getProperty(objectStoreKey + MOVE_TIME_KEY_EXTN),
				:numStops => app.getProperty(objectStoreKey + NUM_STOPS_KEY_EXTN),
				:distance => app.getProperty(objectStoreKey + TOTAL_DIST_KEY_EXTN),
				:maxSpeed => app.getProperty(objectStoreKey + MAX_SPEED_KEY_EXTN)
			};
		}
		return historyData;
	}
	
	
	hidden function loadCommuteHistoryOverview( commuteStartTime ) {
		var keyInfo = getKeyForMoment( commuteStartTime );
		var minute = keyInfo[:minute];
		var hour = keyInfo[:hour];
		
		var app = App.getApp();
		var recordsPerHour = 60 / HISTORY_RESOLUTION;
		var commuteHistory = new [recordsPerHour];
		for(var i=0; i<recordsPerHour; i++) {
		
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