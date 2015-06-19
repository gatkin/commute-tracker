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
	
	class HistoryMenuDelegate extends Ui.MenuInputDelegate {
		function onMenuItem(item) {
			if( item == :current ) {
				Sys.println("Current");
			} else {
				Sys.println("Other");
			}
			var view = new CommuteHistoryView();
			Ui.pushView(view, view.getInputDelegate(), Ui.SLIDE_LEFT);
		}
	}
	
	
	class CommuteHistoryView extends Ui.View {
		hidden var inputDelegate = null;
		hidden var commuteHistory = null;
		
		function initialize() {
			inputDelegate = new CommuteHistoryInputDelegate();
			commuteHistory = loadCommuteHistory();
		}
	
		//! Load your resources here
	    function onLayout(dc) {
	        setLayout(Rez.Layouts.CommuteHistory(dc));
	    }
	
	    //! Restore the state of the app and prepare the view to be shown
	    function onShow() {
	    	
	    }
	
	    //! Update the view
	    function onUpdate(dc) {
	        dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_BLACK );
			dc.clear();
			dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
	        
	        var spacing = 100 / (60 / HISTORY_RESOLUTION);
	        var textY = 25;
	        var textX = 5;
	        var barHeight = 5;
	        var chartBaseX = 45;
	        var barWidth = 0;
	        
	        for(var i=0; i<commuteHistory.size(); i++) {
	    		Sys.println(commuteHistory[i][:timeLabel] + ": " + commuteHistory[i][:commuteEfficiency]);
	    		dc.drawText(textX, textY, Gfx.FONT_XTINY, commuteHistory[i][:timeLabel], Gfx.TEXT_JUSTIFY_LEFT);
	    		barWidth = commuteHistory[i][:commuteEfficiency] * 100;
	    		dc.fillRectangle(chartBaseX, textY + 8, barWidth, barHeight);
	    		textY += spacing;
	    	}
	    	
	    	// Draw the graph tickmarks
			dc.fillRectangle(chartBaseX-1, 30 , 1, textY - 28);
			dc.fillRectangle(chartBaseX-1, textY, 101, 1);
			dc.drawText(chartBaseX, textY + 2, Gfx.FONT_XTINY, "0", Gfx.TEXT_JUSTIFY_RIGHT);
			dc.drawText(chartBaseX + 50, textY + 2, Gfx.FONT_XTINY, "50", Gfx.TEXT_JUSTIFY_RIGHT);
			dc.drawText(chartBaseX + 100, textY + 2, Gfx.FONT_XTINY, "100", Gfx.TEXT_JUSTIFY_RIGHT);
			dc.drawText(100, 5, Gfx.FONT_XTINY, "Commute Efficiency", Gfx.TEXT_JUSTIFY_CENTER); // Title
	    }
	
	    //! Called when this View is removed from the screen. Save the
	    //! state of your app here.
	    function onHide() {
	    }
	
		function getInputDelegate() {
			return inputDelegate;
		}
	}
	
	
	class CommuteHistoryInputDelegate extends Ui.InputDelegate {
		function onKey(keyEvent) {
			var key = keyEvent.getKey();
			if(key == Ui.KEY_ESC ) {
				// Take them back to the previous page
				Ui.popView(Ui.SLIDE_RIGHT);
			} 
		}
	}
	
	function loadCommuteHistory() {
		var keyInfo = getHourMinuteForKey(Time.now());
		var minute = keyInfo[:minute];
		var hour = keyInfo[:hour];
		var minuteKey = (minute < 10) ? ("0" + minute) : (minute.toString());
		
		var app = App.getApp();
		var recordsPerHour = 60 / HISTORY_RESOLUTION;
		var commuteHistory = new [recordsPerHour];
		for(var i=0; i<recordsPerHour; i++) {
			var objectStoreKey = hour.toString() + minuteKey;
			Sys.println("objectStoreKey = " + objectStoreKey);
			var totalTime = app.getProperty(objectStoreKey + TOTAL_TIME_KEY_EXTN);
			var moveTime = app.getProperty(objectStoreKey + MOVE_TIME_KEY_EXTN);
			var commuteEfficiency = null; // moveTime / totalTime
			if( totalTime == null || moveTime == null || totalTime == 0 ) {
				// We don't have a record yet for this time slot.
				commuteEfficiency = 0;
			} else {
				commuteEfficiency = moveTime / totalTime;
			}
			var timeString = "";
			// Convert to 12 hour time
			var hourKey = hour % 12;
			if( hourKey == 0 ) {
				hourKey = 12;
			}
			
			timeString = hourKey.toString() + ":" + minuteKey;
			commuteHistory[i] = {:timeLabel => timeString, :commuteEfficiency => commuteEfficiency};
			
			minute += HISTORY_RESOLUTION;
			if( minute == 60 ) {
				hour = ( hour + 1 ) % 24;
				minute = 0;
			}
			minuteKey = (minute < 10) ? ("0" + minute) : (minute.toString());
		}
		return commuteHistory;
	}
	
	function saveCommute( commuteStartTime, timeMoving, timeStopped ) {
		// We will aggregate commute statistics based on time of day at HISTORY_RESOLUTION minute intervals.
		var keyInfo = getHourMinuteForKey(commuteStartTime);
		var minute = keyInfo[:minute];
		var hour = keyInfo[:hour];
		var minuteKey = (minute < 10) ? ("0" + minute) : (minute.toString());
		var hourKey = hour.toString();
		
		// Use the combination of the start minute and the starting hour as a key
		// into the object store of the stats
		var commuteTime = timeMoving + timeStopped;
		var app = App.getApp();
		var commuteStatsKey = hourKey + minuteKey;
		var totalTimeKey = commuteStatsKey + TOTAL_TIME_KEY_EXTN; // Represents total time spent commuting.
		var moveTimeKey = commuteStatsKey + MOVE_TIME_KEY_EXTN; // Represents time spent moving
		var totalTime = app.getProperty(totalTimeKey);
		var moveTime = app.getProperty(moveTimeKey);
		
		Sys.println("Key = " + commuteStatsKey);
		Sys.println("MoveTime = " + moveTime);
		Sys.println("totalTime = " + totalTime);
		
		if( totalTime == null || moveTime == null ) {
			// This is the first commute record for this time of day.
			totalTime = commuteTime;
			moveTime = timeMoving;
		} else {
			totalTime += commuteTime;
			moveTime += timeMoving;
		}
		
		app.setProperty(totalTimeKey, totalTime);
		app.setProperty(moveTimeKey, moveTime);
	}
	
	hidden function getHourMinuteForKey(timeMoment) {
		var timeInfo = Gregorian.info(timeMoment, Time.FORMAT_SHORT);
		// Find the closest HISTORY_RESOLUTION minute to the current time
		var minute = ((timeInfo.min + (HISTORY_RESOLUTION/2)) / HISTORY_RESOLUTION ) * HISTORY_RESOLUTION ; 
		var hour = timeInfo.hour;
		if(minute == 60) {
			minute = 0;
			hour++;
		}
		return {:hour => hour, :minute => minute};
	}
	
}