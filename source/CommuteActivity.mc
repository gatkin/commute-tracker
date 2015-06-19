using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Position as Position;
using Toybox.System as Sys;
using Toybox.Timer as Timer;
using Toybox.Math as Math;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.ActivityRecording as Record;
using Toybox.Application as App;
using CommuteHistory as CommuteHistory;
using Toybox.Position as Position;


module CommuteActivity {


	class CommuteActivityView extends Ui.View {
	
		hidden const UPDATE_PERIOD_SEC = 1; // seconds
		hidden const MIN_MOVING_SPEED = 1; // m/s

		hidden var inputDelegate = null;
		hidden var timer = null;
		hidden var timeMoving = null; // in seconds
		hidden var timeStopped = null; // in seconds
		hidden var commuteStartTime = null; // Moment object
		hidden var isMoving = false;
		hidden var isValidGPS = false;
	
		function initialize() {
			timer = new Timer.Timer();
	    	timeMoving = 0;
	    	timeStopped = 0;
	    	commuteStartTime = Time.now();
		}
	
	    //! Load resources
	    function onLayout(dc) {
	    }
	
	    //! Restore the state of the app and prepare the view to be shown
	    function onShow() {
	    	timer.start(method(:updateActivity), UPDATE_PERIOD_SEC * 1000, true);
	    	Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
	    }
	
	    //! Update the view
	    function onUpdate(dc) {
		    dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_BLACK );
	        dc.clear();
	        dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
	    	if( isValidGPS ) {
		    	// Update the running time of this activity
		    	var timeMovingString = formatDuration(timeMoving);
		    	var timeStoppedString = formatDuration(timeStopped);
		    	var totalTimeString = formatDuration(timeMoving + timeStopped);
				
		        // Draw the timer
				dc.drawText(( dc.getWidth()/4), 0, Gfx.FONT_TINY, "Move Time", Gfx.TEXT_JUSTIFY_CENTER );
		        dc.drawText(( dc.getWidth()/4), (dc.getHeight() / 6), Gfx.FONT_NUMBER_MILD, timeMovingString, Gfx.TEXT_JUSTIFY_CENTER );
		        dc.drawRectangle((dc.getWidth()/2), 0, 2, dc.getHeight()/2);
		        
		        dc.drawText(( 3*dc.getWidth()/4), 0, Gfx.FONT_TINY, "Stop Time", Gfx.TEXT_JUSTIFY_CENTER );
		        dc.drawText(( 3*dc.getWidth()/4), (dc.getHeight() / 6), Gfx.FONT_NUMBER_MILD, timeStoppedString, Gfx.TEXT_JUSTIFY_CENTER );
		        
		        dc.drawRectangle(0,(dc.getHeight()/2), dc.getWidth(), 2);
		        dc.drawText( (dc.getWidth()/2), (dc.getHeight()/2), Gfx.FONT_SMALL, "Total Time", Gfx.TEXT_JUSTIFY_CENTER);
		        dc.drawText(( dc.getWidth()/2), (2*dc.getHeight() / 3), Gfx.FONT_NUMBER_MEDIUM, totalTimeString, Gfx.TEXT_JUSTIFY_CENTER );
	        } else {
	        	dc.drawText((dc.getWidth()/2), (dc.getHeight()/2), Gfx.FONT_LARGE, "Wait for GPS", Gfx.TEXT_JUSTIFY_CENTER);
	        }
	    }
	
	    //! Called when this View is removed from the screen. 
	    function onHide() {
	    	timer.stop();
	    	Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
	    }
	
		function endActivity() {
	    	CommuteHistory.saveCommute(commuteStartTime, timeMoving, timeStopped);
		}
	
		///! This function runs once every 1 second. It updates the stopped and moving times
		function updateActivity() {
			if( isValidGPS ) {
				if( isMoving ) {
					timeMoving += UPDATE_PERIOD_SEC; 
				} else {
					timeStopped += UPDATE_PERIOD_SEC;
				}
			}
			Ui.requestUpdate(); // Update the timer displayed on the screen
		}
		
		function onPosition(info) {
			// Check that we have a good enough GPS fix
			if( info.accuracy == Position.QUALITY_GOOD || info.accuracy == Position.QUALITY_USABLE ) {
				isValidGPS = true;
				if( info.speed < MIN_MOVING_SPEED ) {
					isMoving = false;
				} else {
					isMoving = true;
				}
			} else {
				// Don't update the state because the GPS fix is not good enough
				isValidGPS = false;
			}
		}
		
		function getInputDelegate() {
			if( inputDelegate == null ) {
				inputDelegate = new CommuteActivityDelegate();
			}
			return inputDelegate;
		}
		
		
		hidden function formatDuration(elapsedTime) {
			var timeField1 = "00";
	    	var timeField2 = "00";
			var minutes = (elapsedTime / 60).toNumber();
			if(minutes >= 60) {
				// Show hours:minutes
				timeField1 = (minutes / 60).toNumber().toString(); // Convert to hours
				minutes %= 60;
				timeField2 = (minutes < 10) ? ("0" + minutes.toString()) : (minutes.toString());
			} else {
				// Show minutes:seconds
				timeField1 = (minutes < 10) ? ("0" + minutes.toString()) : (minutes.toString());
				var seconds = (elapsedTime % 60).toNumber();
				timeField2 = (seconds < 10) ? ("0" + seconds.toString()) : (seconds.toString());
			}
			return timeField1 + ":" + timeField2;
		}
	}
	
	class CommuteActivityDelegate extends Ui.InputDelegate {
	
		function onKey(keyEvent) {
			var key = keyEvent.getKey();
			if( key == Ui.KEY_ENTER || key == Ui.KEY_ESC ) {
				// The user may want to exit the activity.
				Ui.pushView(new Ui.Confirmation("End commute?"), new ActivityConfirmationDelegate(), Ui.SLIDE_IMMEDIATE);
			} 
		}
	
	}
	
	
	class ActivityConfirmationDelegate extends Ui.ConfirmationDelegate {
		function onResponse(response) {
			if (response == CONFIRM_YES) {
				// They want to end this activity
				Ui.popView(Ui.SLIDE_RIGHT);
				getCommuteActivityView().endActivity();
			}
		}
	}
}
