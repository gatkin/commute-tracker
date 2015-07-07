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

	hidden const UPDATE_PERIOD_SEC = 1; // seconds
	hidden const MIN_MOVING_SPEED = 4.5; // m/s ~ 10mph
	hidden var activityController;

	function getCommuteActivityController() {
		if( activityController == null ) {
			activityController = new CommuteActivityController();
		}
		return activityController;
	}


	hidden class CommuteActivityController {
	
		hidden var activityView = null;
		hidden var activityModel = null;
		hidden var hasActiveActivity = false;
		
		function getActivityView() {
			activityModel = new CommuteActivityModel();
			activityView = new CommuteActivityView(activityModel);
			hasActiveActivity = true;
			return activityView;
		}
		
		function getActivityDelegate() {
			return new CommuteActivityDelegate();
		}
		
		
		function saveActivity() {
			if( hasActiveActivity ) {
				// Remove the activity view
	            Ui.popView(Ui.SLIDE_RIGHT);
			
				activityModel.endActivity();
            
	            // Show the activity summary
	            var summaryView = new CommuteSummaryView(activityModel.getTimeMoving(), activityModel.getTimeStopped());
		        Ui.pushView(summaryView, new CommuteSummaryDelegate(), Ui.SLIDE_LEFT);
	        }
		}
		
		function discardActivity() {
			if( hasActiveActivity ) {
				// Remove the activity view without saving any data
				Ui.popView(Ui.SLIDE_RIGHT);
			}
		
			activityModel = null;
			activityView = null;
			hasActiveActivity = false;
		}
		
	}
	
	
	hidden class CommuteActivityModel {
	
		hidden var timeMoving = null; // in seconds
		hidden var timeStopped = null; // in seconds
		hidden var commuteStartTime = null; // Moment object
		hidden var isMoving = false;
		hidden var isValidGPS = false;
		hidden var timer = null;
		
		
		function initialize() {
			timeMoving = 0;
			timeStopped = 0;
			timer = new Timer.Timer();
			commuteStartTime = Time.now();
		}
		
		function pauseActivity() {
			timer.stop();
	    	Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
		}
		
		function resumeActivity() {
			timer.start(method(:updateActivity), UPDATE_PERIOD_SEC * 1000, true);
	    	Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
		}
		
		function endActivity() {
			pauseActivity();
			if( timeMoving > 0 || timeStopped > 0 ) {
	    		CommuteHistory.saveCommute(commuteStartTime, timeMoving, timeStopped);
    		}
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
		
		function isMoving() {
			return isMoving;
		}
		
		function hasGPSFix() {
			return isValidGPS;
		}
		
		function getTimeMoving() {
			return timeMoving;
		}
		
		function getTimeStopped() {
			return timeStopped;
		}
		
		function getCommuteEfficiency() {
			var efficiency = 0;
			var totalTime = timeMoving + timeStopped;
			if( 0 != totalTime ) {
				efficiency = (timeMoving * 100) / totalTime;
			}
			return efficiency;
		}
		
	}


	hidden class CommuteActivityView extends Ui.View {
	
		hidden var commuteModel = null;
	
		function initialize(model) {
			commuteModel = model;
		}
	
	    //! Load resources
	    function onLayout(dc) {
	    }
	
	    //! Restore the state of the app and prepare the view to be shown
	    function onShow() {
	    	commuteModel.resumeActivity();
	    }
	
	    //! Update the view
	    function onUpdate(dc) {
		    dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_WHITE );
	        dc.clear();
	        dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT );
	    	if( commuteModel.hasGPSFix() ) {
		    	// Update the running time of this activity
				var timeMoving = commuteModel.getTimeMoving();
				var timeStopped = commuteModel.getTimeStopped();
		    	var timeMovingString = formatDuration(timeMoving);
		    	var timeStoppedString = formatDuration(timeStopped);
		    	var totalTimeString = formatDuration(timeMoving + timeStopped);
				

				// Display the moving time
				dc.drawText(( dc.getWidth()/4), 5, Gfx.FONT_SMALL, "Move Time", Gfx.TEXT_JUSTIFY_CENTER );
		        dc.drawText(( dc.getWidth()/4), (dc.getHeight() / 6), Gfx.FONT_NUMBER_MEDIUM, timeMovingString, Gfx.TEXT_JUSTIFY_CENTER );
		        
		        // Display the time stopped
		        dc.drawText(( 3*dc.getWidth()/4), 5, Gfx.FONT_SMALL, "Stop Time", Gfx.TEXT_JUSTIFY_CENTER );
		        dc.drawText(( 3*dc.getWidth()/4), (dc.getHeight() / 6), Gfx.FONT_NUMBER_MEDIUM, timeStoppedString, Gfx.TEXT_JUSTIFY_CENTER );
		        
		        // Display the total time
		        dc.drawText( (dc.getWidth()/2), (dc.getHeight()/2) + 5, Gfx.FONT_SMALL, "Total Time", Gfx.TEXT_JUSTIFY_CENTER);
		        dc.drawText(( dc.getWidth()/2), (2*dc.getHeight() / 3), Gfx.FONT_NUMBER_HOT, totalTimeString, Gfx.TEXT_JUSTIFY_CENTER );
		        
		        // Draw the dividing bars
				dc.setColor( Gfx.COLOR_DK_BLUE, Gfx.COLOR_TRANSPARENT );
				dc.fillRectangle((dc.getWidth()/2), 0, 5, dc.getHeight()/2); // Vertical bar
				dc.fillRectangle(0,(dc.getHeight()/2), dc.getWidth(), 5); // horizontal bar

		        
		        // Draw a bar along the bottom to represent commute efficiency
		        var efficiency = commuteModel.getCommuteEfficiency();
		        var barColor = Gfx.COLOR_WHITE;
		        var barWidth = 0;
		        if( efficiency < 25 ) {
		        	barColor = Gfx.COLOR_RED;
		        	barWidth = 0.25;
		        } else if( efficiency < 50 ) {
		        	barColor = Gfx.COLOR_ORANGE;
		        	barWidth = 0.50;
		        } else if( efficiency < 75 ) {
		        	barColor = Gfx.COLOR_YELLOW;
		        	barWidth = 0.75;
		        } else {
		        	barColor = Gfx.COLOR_GREEN;
		        	barWidth = 1.0;
		        }
		        
		        dc.setColor(barColor, Gfx.COLOR_TRANSPARENT);
		        dc.fillRectangle(0, dc.getHeight() - 5, dc.getWidth() * barWidth, 5);
		        
		        
	        } else {
	        	dc.drawText((dc.getWidth()/2), (dc.getHeight()/2), Gfx.FONT_LARGE, "Wait for GPS", Gfx.TEXT_JUSTIFY_CENTER);
	        }
	    }
	
	    //! Called when this View is removed from the screen. 
	    function onHide() {
	    	commuteModel.pauseActivity();
	    }
		
	}
	
	
	hidden class CommuteActivityDelegate extends Ui.InputDelegate {
	
		function onKey(keyEvent) {
			var key = keyEvent.getKey();
			if( key == Ui.KEY_ENTER || key == Ui.KEY_ESC ) {
				// The user may want to exit the activity.
				Ui.pushView(new Rez.Menus.CommuteActivityMenu(), new CommuteActivityMenuDelegate(), Ui.SLIDE_IMMEDIATE);
			} 
		}
	
	}
	
	
	
	hidden class CommuteActivityMenuDelegate extends Ui.MenuInputDelegate {

	    function onMenuItem(item) {
	        if (item == :resume) {
	        	// Do nothing, return to the activity
	        } else if (item == :save) {
	            getCommuteActivityController().saveActivity();
	        } else if ( item == :discard ) {
				getCommuteActivityController().discardActivity();
	        }
	    }
	}
	
	
	hidden class CommuteSummaryView extends Ui.View {
		
		hidden var timeMoving = null; // in seconds
		hidden var timeStopped = null; // in seconds
		hidden var commuteEfficiency = 0;


		function initialize(moveTime, stoppedTime) {
			timeMoving = moveTime;
			timeStopped = stoppedTime;
			
			// Compute commute efficiency. Check for divide by zero.
			if( timeMoving > 0 || timeStopped > 0 ) {
				commuteEfficiency = (timeMoving / (timeMoving + timeStopped)) * 100;
			} else {
				commuteEfficiency = 0;
			}
		}
		
		//! Load resources
	    function onLayout(dc) {
	    }
	
		
		
		function onUpdate(dc) {
		    dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_WHITE );
	        dc.clear();
	        dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT );
	        
	        var timeMovingString = formatDuration(timeMoving);
	    	var timeStoppedString = formatDuration(timeStopped);
			
			dc.drawText(( dc.getWidth()/4), 5, Gfx.FONT_SMALL, "Move Time", Gfx.TEXT_JUSTIFY_CENTER );
	        dc.drawText(( dc.getWidth()/4), (dc.getHeight() / 6), Gfx.FONT_NUMBER_MEDIUM, timeMovingString, Gfx.TEXT_JUSTIFY_CENTER );
	        
	        dc.drawText(( 3*dc.getWidth()/4), 5, Gfx.FONT_SMALL, "Stop Time", Gfx.TEXT_JUSTIFY_CENTER );
	        dc.drawText(( 3*dc.getWidth()/4), (dc.getHeight() / 6), Gfx.FONT_NUMBER_MEDIUM, timeStoppedString, Gfx.TEXT_JUSTIFY_CENTER );
	        
	        dc.drawText( (dc.getWidth()/2), (dc.getHeight()/2)+2, Gfx.FONT_SMALL, "Efficiency", Gfx.TEXT_JUSTIFY_CENTER);
	        dc.drawText(( dc.getWidth()/2), (2*dc.getHeight() / 3), Gfx.FONT_NUMBER_HOT, commuteEfficiency.toString(), Gfx.TEXT_JUSTIFY_CENTER );
	        
	        // Draw the dividing bars
			dc.setColor( Gfx.COLOR_DK_BLUE, Gfx.COLOR_TRANSPARENT );
			dc.fillRectangle((dc.getWidth()/2), 0, 5, dc.getHeight()/2); // Vertical bar
			dc.fillRectangle(0,(dc.getHeight()/2), dc.getWidth(), 5); // horizontal bar
	      }
	}
	
	
	hidden class CommuteSummaryDelegate extends Ui.InputDelegate {
	
		function onKey(keyEvent) {
			var key = keyEvent.getKey();
			if( key == Ui.KEY_ENTER || key == Ui.KEY_ESC ) {
				// Take them back to the main menu
				Ui.popView(Ui.SLIDE_RIGHT);
			} 
		}
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
