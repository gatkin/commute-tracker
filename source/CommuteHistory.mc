using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;


module CommuteHistory {
	
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
	        dc.clear();
	        var textY = 25;
	        var textX = 5;
	        var font = Gfx.FONT_XTINY;
	        var barHeight = 5;
	        var chartBaseX = 45;
	        var barWidth = 0;
	        for(var i=0; i<commuteHistory.size(); i++) {
	    		Sys.println(commuteHistory[i][:timeLabel] + ": " + commuteHistory[i][:commuteEfficiency]);
	    		dc.drawText(textX, textY, font, commuteHistory[i][:timeLabel], Gfx.TEXT_JUSTIFY_LEFT);
	    		barWidth = commuteHistory[i][:commuteEfficiency] * 100;
	    		dc.drawRectangle(chartBaseX, textY + 8, barWidth, barHeight);
	    		textY += 25;
	    	}
	    	
	    	// Draw the graph tickmarks
			dc.drawText(chartBaseX, textY, font, "0", Gfx.TEXT_JUSTIFY_LEFT);
			dc.drawText(chartBaseX + 50, textY, font, "50", Gfx.TEXT_JUSTIFY_LEFT);
			dc.drawText(chartBaseX + 100, textY, font, "100", Gfx.TEXT_JUSTIFY_LEFT);
			dc.drawText(100, 5, font, "Commute Efficiency", Gfx.TEXT_JUSTIFY_CENTER); // Title
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
			if( key == Ui.KEY_ENTER || key == Ui.KEY_ESC ) {
				// Take them back to the previous page
				Ui.popView(Ui.SLIDE_RIGHT);
			} 
		}
	}
	
	function loadCommuteHistory() {
		var currentTime = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
		var minute = (((currentTime.min + 7) / 15) * 15); // Find the closest 15 minute mark
		var hour = currentTime.hour;
		if(minute == 60) {
			minute = 0;
			hour++;
		}
		var minuteKey = (minute < 10) ? ("0" + minute) : (minute.toString());
		
		var app = App.getApp();
		var commuteHistory = new [4];
		for(var i=0; i<4; i++) {
			var objectStoreKey = hour.toString() + minuteKey;
			Sys.println("objectStoreKey = " + objectStoreKey);
			var totalTime = app.getProperty(objectStoreKey + "_TOTAL_TIME");
			var moveTime = app.getProperty(objectStoreKey + "_MOVE_TIME");
			var commuteEfficiency = null; // moveTime / totalTime
			if(totalTime == null || moveTime == null) {
				// We don't have a record yet for this time slot.
				commuteEfficiency = 0;
			} else {
				commuteEfficiency = moveTime / totalTime;
			}
			var timeString = hour.toString() + ":" + minuteKey;
			commuteHistory[i] = {:timeLabel => timeString, :commuteEfficiency => commuteEfficiency};
			
			minute += 15;
			if( minute == 60 ) {
				hour = ( hour + 1 ) % 24;
				minute = 0;
			}
			minuteKey = (minute < 10) ? ("0" + minute) : (minute.toString());
		}
		return commuteHistory;
	}
	
	function saveCommute( commuteStartTime, totalTimeSpentMoving ) {
		Sys.println("Saving commute stats.");
		var commuteTime = Time.now().subtract(commuteStartTime);
		// We will aggregate commute statistics based on time of day at 15 minute intervals.
		// Later we can see about aggregate commute stats for each day of the week or for shorter intervals.
		var startTimeInfo = Gregorian.info(commuteStartTime, Time.FORMAT_SHORT);
		var minute = ((startTimeInfo.min + 7) / 15) * 15; // Find the closest 15 minute mark
		var minuteKey = (minute < 10) ? ("0" + minute) : (minute.toString());
		
		// Use the combination of the start minute and the starting hour as a key
		// into the object store of the stats
		var app = App.getApp();
		var commuteStatsKey = startTimeInfo.hour.toString() + minuteKey;
		var totalTimeKey = commuteStatsKey + "_TOTAL_TIME"; // Represents total time spent commuting.
		var moveTimeKey = commuteStatsKey + "_MOVE_TIME"; // Represents time spent moving
		var totalTime = app.getProperty(totalTimeKey);
		var moveTime = app.getProperty(moveTimeKey);
		
		Sys.println("Key = " + commuteStatsKey);
		Sys.println("MoveTime = " + moveTime);
		Sys.println("totalTime = " + totalTime);
		
		if( totalTime == null || moveTime == null ) {
			// This is the first commute record for this time of day.
			totalTime = commuteTime.value();
			moveTime = totalTimeSpentMoving.value();
		} else {
			totalTime += commuteTime.value();
			moveTime += totalTimeSpentMoving.value();
		}
		
		app.setProperty(totalTimeKey, totalTime);
		app.setProperty(moveTimeKey, moveTime);
	}
	
}