using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Position as Position;
using Toybox.System as Sys;
using Toybox.Timer as Timer;
using Toybox.Math as Math;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using CommuteHistory as CommuteHistory;
using Toybox.Position as Position;
using CommuteTrackerUtil as CommuteTrackerUtil;


module CommuteActivity {

	hidden const UPDATE_PERIOD_SEC = 1; // [seconds], how often we update the model

	///! The activityController variable is kept in singleton scope.
	///! An Unexpected Type Error gets thrown when a module variable is 
	///! explicitely initialized to null, so we have to leave this variable 
	///! unitialized, though it does end up getting implicitly initialized to null
	hidden var activityController;

	///! The activityController module variable will have a reference to
	///! the current active commute activity model. This controller will also
	///! control how the various activity views are managed and will pass
	///! the current commute activity model around to the views as needed.
	///! Therefore, all access to the commute activity controller needs to
	///! be to the same object. The getController() function enforces the
	///! fact that the activityController is a singleton object.
	function getController() {
		if( null == activityController ) {
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
		
		///! Stops updates to the activity and view if there currently is an active activity
		function pauseActivity() {
			if( hasActiveActivity ) {
				modelUpdateTimer.stop();
	    		Position.enableLocationEvents( Position.LOCATION_DISABLE, method( :onPositionCallback ) );
			}
		}
		
		///! Resumes updates to the activity and view if there currently is an active activity
		function resumeActivity() {
			if( hasActiveActivity ) {
				modelUpdateTimer.start( method( :updateActivity ), UPDATE_PERIOD_SEC * 1000, true );
	    		Position.enableLocationEvents( Position.LOCATION_CONTINUOUS, method( :onPositionCallback ) );
			}
		}
		
		///! If there is an active commute activity, persist the activity
		///! and show the commute summary view
		function saveActivity() {
			if( hasActiveActivity ) {
				// Remove the CommuteActivityMenu view that is currently on top of the page stack
				Ui.popView( Ui.SLIDE_LEFT );
				
				// Stop the timer and position updates
				pauseActivity(); 
				
	    		CommuteHistory.saveCommute( activityModel );
            
	            // Show the activity summary
	            var summaryView = new CommuteSummaryView( activityModel );
		        Ui.switchToView( summaryView, new CommuteSummaryDelegate( summaryView ), Ui.SLIDE_LEFT );
	        }
	        dispose();
		}
		
		///! If there is an active commute activity, discard the activity without saving it,
		///! and show the main view
		function discardActivity() {
			if( hasActiveActivity ) {
				// Remove the CommuteActivityMenu view that is currently on top of the page stack
				Ui.popView( Ui.SLIDE_LEFT );
				
				// Stop the timer and position updates
				pauseActivity();
			
				// Remove the activity view without saving any data, take them back to the main view
				Ui.switchToView( new MainView(), new MainViewDelegate(), Ui.SLIDE_LEFT );
			}
			dispose();
		}
		
		///! Callback function for when new positioning updates are ready
		function onPositionCallback( positionInfo ) {
			activityModel.updatePositioning( positionInfo );
		}
		
		///! Function that runs once a second. Updates both the model and the view
		function updateActivity() {
			activityModel.updateState();
			Ui.requestUpdate(); // Update the timers displayed on the screen
		}
		
		///! Cleans up the resources used by the CommuteActivityController.
		///! To be called when after an active commute activiy has ended.
		hidden function dispose() {
			activityModel = null;
			hasActiveActivity = false;
			modelUpdateTimer = null;
		}
		
	}
	
	
	///! Represents a commute activity
	hidden class CommuteActivityModel {
		hidden const MIN_MOVING_SPEED = 4.5; // [m/s] ~ 10mph

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
		///! It updates the state of the commute activity provided a GPS fix has
		///! been acquired
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
		///! it takes as input a Position.Info object
		function updatePositioning( info ) {
			// Check that we have a good enough GPS fix
			if( Position.QUALITY_NOT_AVAILABLE != info.accuracy ) {
				isValidGPS = true;
				currentSpeed = info.speed;
				
				if( currentSpeed > MIN_MOVING_SPEED ) {
					isMoving = true;
					
					// Check if we have acheived a new maximum speed
					if( currentSpeed > maxSpeed ) {
						maxSpeed = currentSpeed;
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
		
		///! Returns the total distance traveled in meters
		function getTotalDistance() {
			return totalDistance;
		}
		
		function getNumStops() {
			return numStops;
		}
		
		///! Returns a value between 0 and 100 that indicates
		///! hoe efficient the commute is
		function getCommuteEfficiency() {
			var efficiency = 0;
			var totalTime = timeMoving + timeStopped;
			// Check for divide by zero
			if( 0 != totalTime ) {
				efficiency = (timeMoving * 100) / totalTime;
			}
			return efficiency;
		}
		
		///! Returns a moment object that represents
		///! the time the commute activity began
		function getCommuteStartTime() {
			return commuteStartTime;
		}
		
		///! Returns the time moving in seconds
		function getTimeMoving() {
			return timeMoving;
		}
		
		///! Returns the time stopped in seconds
		function getTimeStopped() {
			return timeStopped;
		}
		
		///! Returns the total commute time in seconds
		function getTotalCommuteTime() {
			return timeMoving + timeStopped;
		}
		
		///! Returns the maximum speed reached during the commmute
		///! in units of meters per second
		function getMaxSpeed() {
			return maxSpeed;
		}
	}


	///! This is the view shown during the commute activity
	hidden class CommuteActivityView extends Ui.View {
	
		hidden const EFFICIENCY_BAR_Y = Ui.loadResource( Rez.Strings.efficiency_bar_y ).toNumber();
		hidden const EFFICIENCY_BAR_HEIGHT = Ui.loadResource( Rez.Strings.efficiency_bar_height ).toNumber();
	
		hidden var commuteModel = null;
	
		///! Constructor
		function initialize(model) {
			commuteModel = model;
		}
	
	    //! Load resources
	    function onLayout(dc) {
	    	setLayout( Rez.Layouts.CommuteActivityLayout( dc ) );
	     }
	
	    //! Restore the state of the app and prepare the view to be shown
	    function onShow() {
	    	getController().resumeActivity();
	    }
	    
	    //! Called when this View is removed from the screen. 
	    function onHide() {
	    	getController().pauseActivity();
	    }
	
	    //! Update the view
	    function onUpdate(dc) {
	    	if( commuteModel.hasGPSFix() ) {
	    		// Clear the bad GPS message
	    		View.findDrawableById("wait_for_gps").setText( "" );
	    	
	    		// Update the timers on the screen
				var timeMovingString = CommuteTrackerUtil.formatDuration( commuteModel.getTimeMoving() );
				View.findDrawableById("move_time").setText( timeMovingString );
				
				var timeStoppedString = CommuteTrackerUtil.formatDuration( commuteModel.getTimeStopped() );
				View.findDrawableById("stop_time").setText( timeStoppedString );
				
		    	var totalTimeString = CommuteTrackerUtil.formatDuration( commuteModel.getTotalCommuteTime() );
		        View.findDrawableById("total_time").setText( totalTimeString );
		        
		        // Call the parent onUpdate to redraw the layout with the new string values
		        View.onUpdate( dc );
		        
		        // Draw a bar along the bottom to represent the current commute efficiency.
				// Both the width and color of the bar will represent the current efficiency
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
		        dc.setColor( barColor, Gfx.COLOR_TRANSPARENT ); 
		        dc.fillRectangle( 0, EFFICIENCY_BAR_Y, barWidth, EFFICIENCY_BAR_HEIGHT ); //218
	        } else {
	        	// If we don't have a GPS fix, dash out the times and display a message
				View.findDrawableById("move_time").setText( "--:--" );
				View.findDrawableById("stop_time").setText( "--:--" );
		        View.findDrawableById("total_time").setText( "--:--" );
	        	View.findDrawableById("wait_for_gps").setText( "Wait for GPS..." );
	        	View.onUpdate( dc );
	        }
	    }
	}
	
	///! Input delegate that goes with the CommuteActivityView
	hidden class CommuteActivityDelegate extends Ui.InputDelegate {
	
		function onKey(keyEvent) {
			var key = keyEvent.getKey();
			if( Ui.KEY_ENTER == key || Ui.KEY_ESC == key ) {
				// The user may want to exit the activity, bring up the menu
				Ui.pushView( new Rez.Menus.CommuteActivityMenu(), new CommuteActivityMenuDelegate(), Ui.SLIDE_LEFT );
			}
			return true; 
		}
	
	}
	
	
	///! Input delegate for the menu that is shown when the user tries to exit the commute activity
	hidden class CommuteActivityMenuDelegate extends Ui.MenuInputDelegate {

	    function onMenuItem(item) {
	        if ( :resume == item ) {
	        	// Do nothing, return to the activity
	        } else if ( :save == item ) {
	            getController().saveActivity();
	        } else if ( :discard == item ) {
				getController().discardActivity();
	        }
	    }
	}
}
