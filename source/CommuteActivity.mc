using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Position as Position;
using Toybox.System as Sys;
using Toybox.Timer as Timer;
using Toybox.Math as Math;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.ActivityRecording as Record;
using CommuteHistory as CommuteHistory;
using Toybox.Position as Position;
using Toybox.Activity as Activity;
using CommuteTrackerUtil as CommuteTrackerUtil;


module CommuteActivity {

	hidden const UPDATE_PERIOD_SEC = 1; // [seconds]
	hidden const MIN_MOVING_SPEED = 4.5; // [m/s] ~ 10mph
	hidden var activityController;

	///! The activityController module variable will have a reference to
	///! the current active commute activity model. This controller will
	///! control how the various activity views are managed and will pass
	///! the current commute activity model around to the views as needed.
	///! Therefore, all access to the commute activity controller needs to
	///! be to the same object. The getController() function enforces the
	///! fact that the activityController is a singleton object.
	function getController() {
		if( activityController == null ) {
			activityController = new CommuteActivityController();
		} 
		return activityController;
	}
	

	///! Making the CommuteActivityController a hidden class within the
	///! CommuteActivity module helps enforce its singleton scope
	hidden class CommuteActivityController {
	
		///! Represents the current active commute
		hidden var activityModel = null;
		
		///! Whether the controller currently has an active commute activity
		hidden var hasActiveActivity = false;
		
		///! Timer object that controls updates to the commute activity model
		hidden var modelUpdateTimer = null;
		
		///! Begins a new commute activity and shows the activity view
		function startCommuteActivity() {
			hasActiveActivity = true;
			activityModel = new CommuteActivityModel();
			var activityView = new CommuteActivityView( activityModel );
			Ui.switchToView( activityView, new CommuteActivityDelegate(), Ui.SLIDE_LEFT );
			
			modelUpdateTimer = new Timer.Timer();
			
		}
		
		///! Stops updates to the activity and view
		function pauseActivity() {
			if( hasActivityActivity ) {
				modelUpdateTimer.stop();
	    		Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPositionCallback));
			}
		}
		
		///! Resumes updates to the activity and view
		function resumeActivity() {
			if( hasActivityActivity ) {
				modelUpdateTimer.start(method(:updateModel), UPDATE_PERIOD_SEC * 1000, true);
	    		Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPositionCallback));
			}
		}
		
		///! If there is an active commute activity, persist the activity
		///! and show the commute summary view
		function saveActivity() {
			if( hasActiveActivity ) {
				// Remove the CommuteActivityMenu view that is currently on top of the page stack
				Ui.popView( Ui.SLIDE_LEFT );
				
				// Stop the timer and position updates
				activityModel.pauseActivity(); 
				
	    		CommuteHistory.saveCommute(activityModel);
            
	            // Show the activity summary
	            var summaryView = new CommuteSummaryView( activityModel );
		        Ui.switchToView(summaryView, new CommuteSummaryDelegate( summaryView ), Ui.SLIDE_LEFT );
	        }
	        dispose();
		}
		
		///! If there is an active commute activity, discard the activity,
		///! and show the main view
		function discardActivity() {
			if( hasActiveActivity ) {
				// Remove the CommuteActivityMenu view that is currently on top of the page stack
				Ui.popView( Ui.SLIDE_LEFT );
				
				// Stop the timer and position updates
				activityModel.pauseActivity();
			
				// Remove the activity view without saving any data, take them back to the main view
				Ui.switchToView( new MainView(), new MainViewDelegate(), Ui.SLIDE_LEFT );
			}
			dispose();
		}
		
		///! Callback function for when new positioning updates are ready
		hidden function onPositionCallback( positionInfo ) {
			activityModel.updatePositioning( positionInfo );
		}
		
		///! Function that runs once a second. Updates both the model and the state
		hidden function updateModel() {
			activityModel.updateState();
			Ui.requestUpdate(); // Update the timer displayed on the screen
		}
		
		///! Cleans up the resources used by the CommuteActivityController.
		///! To be called when after an active commute activiy has ended.
		hidden function dispose() {
			activityModel = null;
			hasActiveActivity = false;
		}
		
	}
	
	
	hidden class CommuteActivityModel {
	
		hidden var totalDistance = null; // in meters
		hidden var timeMoving = null; // in seconds
		hidden var timeStopped = null; // in seconds
		hidden var commuteStartTime = null; // moment object
		hidden var numStops = null; // integer
		hidden var maxSpeed = null; // meters per second
		hidden var currentSpeed = null; // meters per second
		hidden var isMoving = false;
		hidden var isValidGPS = false;
		
		///! Constructor
		function initialize() {
			totalDistance = 0.0;
			timeMoving = 0;
			timeStopped = 0;
			commuteStartTime = Time.now();
			numStops = 0;
			maxSpeed = 0;
			currentSpeed = 0;
		}
		
		///! This function should be called once ever UPDATE_PERIOD_SEC seconds.
		///! It updates the stopped and moving times of the activity
		function updateState() {
			if( isValidGPS ) {
				// Update the total distance travelled by integrating the speed over time
				totalDistance += currentSpeed * UPDATE_PERIOD_SEC;
				
				if( isMoving ) {
					timeMoving += UPDATE_PERIOD_SEC; 
				} else {
					timeStopped += UPDATE_PERIOD_SEC;
				}
			}
		}
		
		///! This function should be called once new positioning updates become avaliable
		///! it takes as input a Positioning.Info object
		function updatePositioning( info ) {
			// Check that we have a good enough GPS fix
			if( info.accuracy != Position.QUALITY_NOT_AVAILABLE ) {
				isValidGPS = true;
				
				currentSpeed = info.speed;
				
				if( currentSpeed > MIN_MOVING_SPEED ) {
					isMoving = true;
					
					// Check if we have acheived a new maximum speed
					if( info.speed > maxSpeed ) {
						maxSpeed = info.speed;
					}
					
				} else {
					// Check if we have just come to a stop
					if( isMoving ) {
						numStops++;
					}
					isMoving = false;
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
		
		function getTotalDistance() {
			return totalDistance;
		}
		
		function getNumStops() {
			return numStops;
		}
		
		function getCommuteEfficiency() {
			var efficiency = 0;
			var totalTime = timeMoving + timeStopped;
			// Check for divide by zero
			if( 0 != totalTime ) {
				efficiency = (timeMoving * 100) / totalTime;
			}
			return efficiency;
		}
		
		function getCommuteStartTime() {
			return commuteStartTime;
		}
		
		function getTimeMoving() {
			return timeMoving;
		}
		
		function getTimeStopped() {
			return timeStopped;
		}
		
		function getTotalCommuteTime() {
			return timeMoving + timeStopped;
		}
		
		function getMaxSpeed() {
			return maxSpeed;
		}
	}


	hidden class CommuteActivityView extends Ui.View {
	
		hidden var commuteModel = null;
	
		function initialize(model) {
			commuteModel = model;
		}
	
	    //! Load resources
	    function onLayout(dc) {
	    	setLayout(Rez.Layouts.CommuteActivityLayout(dc));
	     }
	
	    //! Restore the state of the app and prepare the view to be shown
	    function onShow() {
	    	getController().resumeActivity();
	    }
	
	    //! Update the view
	    function onUpdate(dc) {
	    	if( commuteModel.hasGPSFix() ) {
	    		// Clear the bad GPS message
	    		View.findDrawableById("wait_for_gps").setText( "" );
	    	
				var timeMovingString = CommuteTrackerUtil.formatDuration( commuteModel.getTimeMoving() );
				View.findDrawableById("move_time").setText( timeMovingString );
				
				var timeStoppedString = CommuteTrackerUtil.formatDuration( commuteModel.getTimeStopped() );
				View.findDrawableById("stop_time").setText( timeStoppedString );
				
		    	var totalTimeString = CommuteTrackerUtil.formatDuration( commuteModel.getTotalCommuteTime() );
		        View.findDrawableById("total_time").setText( totalTimeString );
		        
		        // Call the parent onUpdate to redraw the layout with the new string values
		        View.onUpdate(dc);
		        
		        // Draw a bar along the bottom to represent commute efficiency
				var efficiency = commuteModel.getCommuteEfficiency();
		        var barColor = Gfx.COLOR_WHITE;
		        var barWidth = dc.getWidth() * efficiency / 100.0;
		        
		        // Choose what color the bar will be based on how good the commute efficiency is
		        if( efficiency < 25 ) {
		        	barColor = Gfx.COLOR_RED;
		        } else if( efficiency < 50 ) {
		        	barColor = Gfx.COLOR_ORANGE;
		        } else if( efficiency < 75 ) {
		        	barColor = Gfx.COLOR_YELLOW;
		        } else {
		        	barColor = Gfx.COLOR_GREEN;
		        }
		        
		        dc.setColor(barColor, Gfx.COLOR_TRANSPARENT);
		        dc.fillRectangle(0, dc.getHeight() - 10, barWidth, 10);
	        } else {
	        	// If we don't have a GPS fix, dash out the times and display a message
				View.findDrawableById("move_time").setText( "--:--" );
				View.findDrawableById("stop_time").setText( "--:--" );
		        View.findDrawableById("total_time").setText( "--:--" );
	        	View.findDrawableById("wait_for_gps").setText( "Wait for GPS..." );
	        	View.onUpdate(dc);
	        }
	    }
	
	    //! Called when this View is removed from the screen. 
	    function onHide() {
	    	getController().pauseActivity();
	    }
		
	}
	
	
	hidden class CommuteActivityDelegate extends Ui.InputDelegate {
	
		function onKey(keyEvent) {
			var key = keyEvent.getKey();
			if( key == Ui.KEY_ENTER || key == Ui.KEY_ESC ) {
				// The user may want to exit the activity.
				Ui.pushView( new Rez.Menus.CommuteActivityMenu(), new CommuteActivityMenuDelegate(), Ui.SLIDE_UP );
			}
			return true; 
		}
	
	}
	
	
	
	hidden class CommuteActivityMenuDelegate extends Ui.MenuInputDelegate {

	    function onMenuItem(item) {
	        if (item == :resume) {
	        	// Do nothing, return to the activity
	        } else if (item == :save) {
	            getController().saveActivity();
	        } else if ( item == :discard ) {
				getController().discardActivity();
	        }
	    }
	}
}
