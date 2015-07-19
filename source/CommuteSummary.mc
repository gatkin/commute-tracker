using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Time.Gregorian as Gregorian;

///! CommuteSummaryView is shown after the user has ended a commute activity.
///! This view sill display summary stats for the activity that just ended.
class CommuteSummaryView extends Ui.View {
		
		hidden var commuteModel = null;
		hidden var currentPage = null; // Allows for scrolling though commute stats

		///! Constructor, takes as input a CommuteActivityModel
		function initialize(activityModel) {
			commuteModel = activityModel;
			currentPage = :pageOne;
		}
		
	    function onLayout(dc) { }
		
		
		function onUpdate(dc) {
	    	var startTimeInfo = Gregorian.info( commuteModel.getCommuteStartTime(), Time.FORMAT_SHORT );

			if( :pageOne == currentPage ) {
				setLayout(Rez.Layouts.CommuteSummaryPageOneLayout(dc));
			
				var timeMovingString = CommuteTrackerUtil.formatDuration( commuteModel.getTimeMoving() );
				View.findDrawableById("move_time").setText( timeMovingString );
				
				var timeStoppedString = CommuteTrackerUtil.formatDuration( commuteModel.getTimeStopped() );
				View.findDrawableById("stop_time").setText( timeStoppedString );
				
		    	var totalTimeString = CommuteTrackerUtil.formatDuration( commuteModel.getTotalCommuteTime() );
		        View.findDrawableById("total_commute_time").setText( totalTimeString );
				
				var dist = commuteModel.getTotalDistance() * CommuteTrackerUtil.METERS_TO_MILES;
				var distString = dist.format("%.1f") +  " mi";
				View.findDrawableById("distance").setText( distString );
			
			} else { // Summary Page 2
				setLayout(Rez.Layouts.CommuteSummaryPageTwoLayout(dc));
				
				var speed = commuteModel.getMaxSpeed() * CommuteTrackerUtil.MPS_TO_MPH;
				var speedString = speed.format("%.1f") + " mph";
				View.findDrawableById("max_speed").setText( speedString );
				
				View.findDrawableById("num_stops").setText( commuteModel.getNumStops().toString() );
				
				View.findDrawableById("efficiency").setText( commuteModel.getCommuteEfficiency().toString() );
			}
			
			// Draw the title with the current time
			var startTimeString = CommuteTrackerUtil.formatTime( startTimeInfo.hour, startTimeInfo.min );
			View.findDrawableById("commute_start_time").setText( "Commute " + startTimeString );
			
			// Call the parent onUpdate function to redraw the layout
			View.onUpdate( dc );
	     }
	     
	     ///! Displays the next page of commute summary statistics
	     function nextPage() {
	       if( :pageOne == currentPage ) {
	       		currentPage = :pageTwo;
	       		Ui.requestUpdate();
	       }
	     }
	     
	     ///! Displays the previous page of commute summary statistics
	     function previousPage() {
	     	if( :pageTwo == currentPage ) {
	     		currentPage = :pageOne;
	     		Ui.requestUpdate();
	     	}
	     }
	     
	}
	
///! Input delegate that goes with the CommuteSummaryView	
class CommuteSummaryDelegate extends Ui.InputDelegate {

		hidden var summaryView = null;
		
		///! Constructor, takes as input a CommuteSummaryView object
		function initialize(view) {
			summaryView = view;
		}
		
	
		function onKey(keyEvent) {
			var key = keyEvent.getKey();
			if( Ui.KEY_ENTER == key || Ui.KEY_ESC == key ) {
				// Take them back to the main menu
				Ui.switchToView( new MainView(), new MainViewDelegate(), Ui.SLIDE_LEFT );
			} else if( Ui.KEY_DOWN == key ) {
				summaryView.nextPage();
			} else if( Ui.KEY_UP == key ) {
				summaryView.previousPage();
			}
			
			return true;
		}
		
		///! Allows scrolling through summary pages on touch screen devices
		function onSwipe(swipeEvent) {
			var direction = swipeEvent.getDirection();
			if( Ui.SWIPE_LEFT == direction ) {
				summaryView.nextPage();
			} else if( Ui.SWIPE_RIGHT == direction ) {
				summaryView.previousPage();
			}
		}
	}