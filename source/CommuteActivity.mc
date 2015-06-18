using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Position as Position;
using Toybox.System as Sys;
using Toybox.Timer as Timer;
using Toybox.Activity as Activity;
using Toybox.Math as Math;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.ActivityRecording as Record;
using Toybox.Application as App;
using CommuteHistory as CommuteHistory;


module CommuteActivity {


	class CommuteActivityView extends Ui.View {
		hidden const UPDATE_PERIOD_SEC = 1; // seconds
		hidden var inputDelegate = null;
		hidden var timer = null;
		hidden var session = null;
		hidden var timeMoving = null; // in seconds
		hidden var timeStopped = null; // in seconds
		hidden var commuteStartTime = null; // Moment object
		hidden var isMoving = false;
	
		function initialize() {
			timer = new Timer.Timer();
	    	timeMoving = 0;
	    	timeStopped = 0;
	    	commuteStartTime = Time.now();
	    	
	    	// Start the current session
	    	if( session == null || !session.isRecording() ) {
	    		session = Record.createSession({:name => "Commute"});
	    		session.start();
	    		Sys.println("Started Session");
	          }
		}
	
	    //! Load your resources here
	    function onLayout(dc) {
	        setLayout(Rez.Layouts.ActivityLayout(dc));
	    }
	
	    //! Restore the state of the app and prepare the view to be shown
	    function onShow() {
	    	timer.start(method(:updateActivity), UPDATE_PERIOD_SEC * 1000, true);
	    }
	
	    //! Update the view
	    function onUpdate(dc) {
	    	// Update the running time of this activity
	    	var timeMovingString = formatDuration(timeMoving);
	    	var timeStoppedString = formatDuration(timeStopped);
	    	var totalTimeString = formatDuration(timeMoving + timeStopped);
			
			Sys.println(totalTimeString);
			dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_BLACK );
	        dc.clear();
	        
	        // Draw the timer
	        dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
	        dc.drawText(( dc.getWidth()/4), (dc.getHeight() / 4), Gfx.FONT_MEDIUM, timeMovingString, Gfx.TEXT_JUSTIFY_CENTER );
	        dc.drawText(( 3*dc.getWidth()/4), (dc.getHeight() / 4), Gfx.FONT_MEDIUM, timeStoppedString, Gfx.TEXT_JUSTIFY_CENTER );
	        dc.drawText(( dc.getWidth()/2), (3*dc.getHeight() / 4), Gfx.FONT_MEDIUM, totalTimeString, Gfx.TEXT_JUSTIFY_CENTER );
	    }
	
	    //! Called when this View is removed from the screen. Save the
	    //! state of your app here.
	    function onHide() {
	    	timer.stop();
	    }
	
		function endActivity() {
	    	CommuteHistory.saveCommute(commuteStartTime, timeMoving, timeStopped);
	    	session.discard();
	    	session = null;
		}
	
		function updateActivity() {
			var activityInfo = Activity.getActivityInfo();
			if(activityInfo != null && activityInfo.currentSpeed != null) { // Check that an activity is currently running
				if( isMoving && activityInfo.currentSpeed == 0 ) {
					// We have just come to a stop
					isMoving = false;
				} else if( !isMoving && activityInfo.currentSpeed > 0 ) {
					// We have just started moving after being stopped
					isMoving = true;
				}
				
				if( isMoving ) {
					timeMoving += UPDATE_PERIOD_SEC; 
				} else {
					timeStopped += UPDATTE_PERIOD_SEC;
				}
			}
			Ui.requestUpdate(); // Update the timer displayed on the screen
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
