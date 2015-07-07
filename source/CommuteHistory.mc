using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;


module CommuteHistory {

	//!  We group commutes that start in blocks of HISTORY_RESOLUTION minutes to store in history
	hidden const HISTORY_RESOLUTION = 10; // In minutes
	hidden const TOTAL_TIME_KEY_EXTN = "_TOTAL_TIME"; // Extension on the key to retrieve the total time for a history entry
	hidden const MOVE_TIME_KEY_EXTN = "_MOVE_TIME"; // Extension on the key to retrieve the move time for a history entry
	
	
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
	        var textY = 25;
	        var textX = 5;
	        var barHeight = 5;
	        var chartBaseX = 45;
	        var maxBarWidth = 150;
	        var barWidth = 0;
	        
	        var commuteHistory = loadCommuteHistory(timeToShow);
	        for(var i=0; i<commuteHistory.size(); i++) {
	        	// Draw the time label
	    		dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT );
	    		dc.drawText(textX, textY, Gfx.FONT_XTINY, commuteHistory[i][:timeLabel], Gfx.TEXT_JUSTIFY_LEFT);
	    		barWidth = commuteHistory[i][:commuteEfficiency] * maxBarWidth;
	    		
	    		// If we have a record for this time, always show a tiny bar, even if the 
				// efficiency is zero to indicate that a record exists
				if( commuteHistory[i][:hasRecord] && 0 == commuteHistory[i][:commuteEfficiency] ) {
					barWidth = 2;
				} 
				
				// Choose the color for the bar based on the efficiency
				var barColor = Gfx.COLOR_WHITE;
				if( commuteHistory[i][:commuteEfficiency] < 0.25 ) {
					barColor = Gfx.COLOR_RED;
				} else if ( commuteHistory[i][:commuteEfficiency] < 0.50 ) {
					barColor = Gfx.COLOR_ORANGE;
				} else if ( commuteHistory[i][:commuteEfficiency] < 0.75 ) {
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
			dc.drawText(115, 5, Gfx.FONT_XTINY, "Commute Efficiency", Gfx.TEXT_JUSTIFY_CENTER); 
	    }
	
	
		function showPreviousHistoryPage() {
			// Decrease the time to show by one half hour
			var durationDecrement = new Time.Duration(-1800);
			timeToShow = timeToShow.add(durationDecrement);
			Ui.requestUpdate();
		}
		
		function showNextHistoryPage() {
			// Decrease the time to show by one half hour
			var durationIncrement = new Time.Duration(1800);
			timeToShow = timeToShow.add(durationIncrement);
			Ui.requestUpdate();
		}
	}
	
	
	
	function saveCommute( commuteStartTime, timeMoving, timeStopped ) {
		// We will aggregate commute statistics based on time of day at HISTORY_RESOLUTION minute intervals.
		// Use the combination of the start minute and the starting hour as a key
		// into the object store of the stats
		var keyInfo = getHourMinuteForKey(commuteStartTime);
		var minute = keyInfo[:minute];
		var hour = keyInfo[:hour];
		var minuteKey = (minute < 10) ? ("0" + minute) : (minute.toString());
		var hourKey = hour.toString();
		
		var commuteStatsKey = hourKey + minuteKey;
		var totalTimeKey = commuteStatsKey + TOTAL_TIME_KEY_EXTN; // Represents total time spent commuting.
		var moveTimeKey = commuteStatsKey + MOVE_TIME_KEY_EXTN; // Represents time spent moving

		var app = App.getApp();
		var totalTimeHistory = app.getProperty(totalTimeKey);
		var moveTimeHistory = app.getProperty(moveTimeKey);
		var commuteTime = timeMoving + timeStopped;
		
		if( totalTime == null || moveTime == null ) {
			// This is the first commute record for this time of day.
			totalTimeHistory = commuteTime;
			moveTimeHistory = timeMoving;
		} else {
			totalTimeHistory += commuteTime;
			moveTimeHistory += timeMoving;
		}
		
		// Save the history in the object store
		app.setProperty(totalTimeKey, totalTimeHistory);
		app.setProperty(moveTimeKey, moveTimeHistory);
	}
	
	
	
	hidden function loadCommuteHistory(timeToShow) {
		var keyInfo = getHourMinuteForKey(timeToShow);
		var minute = keyInfo[:minute];
		var hour = keyInfo[:hour];
		var minuteKey = (minute < 10) ? ("0" + minute) : (minute.toString());
		
		var app = App.getApp();
		var recordsPerHour = 60 / HISTORY_RESOLUTION;
		var commuteHistory = new [recordsPerHour];
		for(var i=0; i<recordsPerHour; i++) {
			var objectStoreKey = hour.toString() + minuteKey;
			var totalTime = app.getProperty(objectStoreKey + TOTAL_TIME_KEY_EXTN);
			var moveTime = app.getProperty(objectStoreKey + MOVE_TIME_KEY_EXTN);
			var commuteEfficiency = null; // moveTime / totalTime
			var hasRecord = false;
			if( totalTime == null || moveTime == null ) {
				// We don't have a record yet for this time slot.
				hasRecord = false;
				commuteEfficiency = 0;
			} else {
				// Check for divide by zero
				if ( 0 != totalTime ) {
					commuteEfficiency = moveTime / totalTime;
				} else {
					commuteEfficiency = 0;
				}
				hasRecord = true;
			}
			
			
			// Convert to 12 hour time
			var hourKey = hour;
			var meridian = "a";
			if( hour == 12 ) {
				meridian = "p";
			} else if ( hour > 12 && hour < 24 ) {
				meridian = "p";
				hourKey = hour % 12;
			} else if ( hour == 0 ) { // midnight
				hourKey = 12;
			}
			
			var timeString = hourKey.toString() + ":" + minuteKey + meridian;
			commuteHistory[i] = {:timeLabel => timeString, :commuteEfficiency => commuteEfficiency, :hasRecord => hasRecord};
			
			minute += HISTORY_RESOLUTION;
			if( minute == 60 ) {
				hour = ( hour + 1 ) % 24;
				minute = 0;
			}
			minuteKey = (minute < 10) ? ("0" + minute) : (minute.toString());
		}
		return commuteHistory;
	}
	
	hidden function getHourMinuteForKey(timeMoment) {
		var timeInfo = Gregorian.info(timeMoment, Time.FORMAT_SHORT);
		// Find the closest HISTORY_RESOLUTION minute to the current time
		var minute = ((timeInfo.min + (HISTORY_RESOLUTION/2)) / HISTORY_RESOLUTION ) * HISTORY_RESOLUTION ; 
		var hour = timeInfo.hour;
		if(minute == 60) {
			minute = 0;
			hour = (hour + 1) % 24;
		}
		return {:hour => hour, :minute => minute};
	}
	
}