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


class CommuteActivityView extends Ui.View {

	hidden var inputDelegate = null;
	hidden var timer = null;
	hidden var statTracker = null;
	hidden var session = null;

	function initialize() {
		timer = new Timer.Timer();
    	statTracker = new CommuteStatTracker();
    	
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
    	timer.start(method(:updateActivity), 1000, true);
    }

    //! Update the view
    function onUpdate(dc) {
    	// Update the running time of this activity
    	var timeField1 = "00";
    	var timeField2 = "00";
    	var distanceField1 = "0";
    	var distanceField2 = "0";
    	
    	var activityInfo = Activity.getActivityInfo();
    	var elapsedTime = null;
    	var elapsedDistance = null;
    	
    	if( activityInfo != null ) {
			elapsedTime = activityInfo.elapsedTime; // In ms
		}
		
		if( elapsedTime != null) {
			var minutes = (elapsedTime / (1000 * 60)).toNumber();
			if(minutes >= 60) {
				// Show hours:minutes
				timeField1 = (minutes / 60).toNumber().toString(); // Convert to hours
				minutes %= 60;
				timeField2 = (minutes < 10) ? ("0" + minutes.toString()) : (minutes.toString());
			} else {
				// Show minutes:seconds
				timeField1 = (minutes < 10) ? ("0" + minutes.toString()) : (minutes.toString());
				var seconds = ((elapsedTime / 1000) % 60).toNumber();
				timeField2 = (seconds < 10) ? ("0" + seconds.toString()) : (seconds.toString());
			}
		}
		
	
		Sys.println(timeField1 + ":" + timeField2);
		dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_BLACK );
        dc.clear();
        
        // Draw the timer
        dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
        dc.drawText( (dc.getWidth()/2) - 30 , (dc.getHeight() / 2), Gfx.FONT_MEDIUM, timeField1, Gfx.TEXT_JUSTIFY_LEFT );
        dc.drawText( (dc.getWidth()/2), (dc.getHeight() / 2), Gfx.FONT_MEDIUM, ":", Gfx.TEXT_JUSTIFY_LEFT );
        dc.drawText( (dc.getWidth()/2) + 15, (dc.getHeight() / 2), Gfx.FONT_MEDIUM, timeField2, Gfx.TEXT_JUSTIFY_LEFT );
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {
    	timer.stop();
    }

	function endActivity() {
    	statTracker.saveStats();
    	session.discard();
    	session = null;
	}

	function updateActivity() {
		Ui.requestUpdate(); // Update the timer displayed on the screen
		statTracker.updateStats();
	}
	
	function getInputDelegate() {
		if( inputDelegate == null ) {
			inputDelegate = new CommuteActivityDelegate();
		}
		return inputDelegate;
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


class CommuteStatTracker {

	hidden var commuteStartTime = null; // Moment object
	hidden var isMoving = false;
	hidden var totalTimeSpentMoving = null; // Duration object
	hidden var lastTimeStopped = null; // Moment object
	hidden var lastTimeMoving = null; // Moment object

	function initialize() {
		commuteStartTime = Time.now();
	}

	function updateStats() {
		// Update the commute statistics
		var activityInfo = Activity.getActivityInfo();
		if(activityInfo != null && activityInfo.currentSpeed != null) { // Check that an activity is currently running
			if( isMoving && activityInfo.currentSpeed == 0 ) {
				// We have just come to a stop
				isMoving = false;
				lastTimeMoving = Time.now();
				
				if( lastTimeStopped != null ) {
					var timeSpentMoving = Time.now().subtract(lastTimeStopped);
					if( totalTimeSpentMoving == null ) {
						// This is the first time we have gone from moving to being stopped
						totalTimeSpentMoving = timeSpentMoving;
					} else {
						totalTimeSpentMoving.add(timeSpentMoving);
					}
				}
			} else if( !isMoving && activityInfo.currentSpeed > 0 ) {
				// We have just started moving after being stopped
				isMoving = true;
				lastTimeStopped = Time.now();
			}
		}
	}
	
	function saveStats() {
		if( totalTimeSpentMoving == null ) {
			// If totalTimeSpentMoving is never set, then that means
			// we were moving for the entire commute time and never came to a stop.
			var commuteTime = Time.now().subtract(commuteStartTime);
			totalTimeSpentMoving = commuteTime;
		}
		CommuteHistory.saveCommute( commuteStartTime, totalTimeSpentMoving );
	}
}
