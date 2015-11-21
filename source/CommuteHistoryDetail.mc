using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Graphics as Gfx;
using CommuteTrackerUtil as CommuteTrackerUtil;


///! View that shows detailed commute stats for a single commute start time
class CommuteHistoryDetailView extends Ui.View {
	
	hidden var commuteStartTime = null; // Moment object
	hidden var hasHistoryData = false;

	///! Constructor, takes as input the commute start time for which
	///! to show detailed statistics
	function initialize( startTime ) {
		commuteStartTime = startTime;
	}
	
	function onLayout(dc) { }
	
	function onUpdate(dc) {
        
        var historyData = CommuteHistory.loadCommuteHistoryDetail( commuteStartTime );

		// Display history data, if we have it for this time of day
		if( historyData[:numRecords] > 0 ) {
			hasHistoryData = true;
			setLayout( Rez.Layouts.HistoryDetailLayout(dc) );

			// Display the number of commutes
			View.findDrawableById("num_commutes").setText( historyData[:numRecords].toString() );

			// Display the average total time
			var totalTime = historyData[:stopTime]  + historyData[:moveTime];
			var avgTime = totalTime / historyData[:numRecords];
			View.findDrawableById("avg_commute_time").setText( CommuteTrackerUtil.formatDuration( avgTime ) );
			
			// Display the average time moving
			var avgMoveTime = historyData[:moveTime] / historyData[:numRecords];
			View.findDrawableById("avg_move_time").setText( CommuteTrackerUtil.formatDuration( avgMoveTime ) );
			
			// Display the average time stoped
			var avgStopTime = historyData[:stopTime] / historyData[:numRecords];
			View.findDrawableById("avg_stop_time").setText( CommuteTrackerUtil.formatDuration( avgStopTime) );
			
			// Display the avg distance traveled
			var avgDistance = historyData[:distance] / historyData[:numRecords];
			var avgDistString = CommuteTrackerUtil.formatDistance( avgDistance );
			View.findDrawableById("avg_distance").setText( avgDistString );
			
			// Display the max speed
			var speedString = CommuteTrackerUtil.formatSpeed( historyData[:maxSpeed] );
			View.findDrawableById("max_speed").setText( speedString );
			
			// Display the avg number of stops
			var avgNumStops = historyData[:numStops].toFloat() / historyData[:numRecords];
			var avgNumStopsString = avgNumStops.format("%.1f");
			View.findDrawableById("avg_stops").setText( avgNumStopsString );
			
			// Display the commute efficiency
			var efficiency = 0;
			// Check for divide by zero
			if( 0 != totalTime ) {
				efficiency = historyData[:moveTime] * 100 / totalTime;
			}
			View.findDrawableById("avg_efficiency").setText( efficiency.toString() );
			
		} else {
			// Display that there is no data
			setLayout( Rez.Layouts.HistoryDetailNoDataLayout(dc) );
			hasHistoryData = false;
		}
		
		// Draw the title with the commute start time
		var startTimeString = CommuteTrackerUtil.formatTime( historyData[:startTimeHour], historyData[:startTimeMinute] );
	 	View.findDrawableById("commute_start_time").setText( "Commute History " + startTimeString );
		
		// Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
     }
	
	///! Advances the history detail view to the previous record
	function showPreviousHistoryDetailPage() {
		// Decrease the commtue start time to show by one HISTORY_RESOLUTION seconds
		var durationDecrement = new Time.Duration( -CommuteHistory.HISTORY_RESOLUTION * 60 );
		commuteStartTime = commuteStartTime.add( durationDecrement );
		Ui.requestUpdate();
	}
	
	///! Advances the history detail view to the next record
	function showNextHistoryDetailPage() {
		// Increase the commtue start time to show by one HISTORY_RESOLUTION seconds
		var durationIncrement = new Time.Duration( CommuteHistory.HISTORY_RESOLUTION * 60 );
		commuteStartTime = commuteStartTime.add( durationIncrement );
		Ui.requestUpdate();
	}
	
	///! Returns the commute start time that is currently being displayed
	function getCommuteStartTime() {
		return commuteStartTime;
	}

	///! Returns true if currently displaying commute history data, returns false if
	///! if there is no history for the commute time that is being displayed
	function isHistoryDataDisplayed() {
		return hasHistoryData;
	}

}


///! Input delegate that correspondents to the CommuteHistoryDetailView
class CommuteHistoryDetailDelegate extends Ui.BehaviorDelegate {
	
	hidden var historyDetailView = null;
	
	///! Constructor, takes as input the HistoryDetailView
	function initialize(histDetailView) {
		historyDetailView = histDetailView;
	}
	
	function onKey(keyEvent) {
		Sys.println(historyDetailView.isHistoryDataDisplayed());
		var key = keyEvent.getKey();
		if( Ui.KEY_DOWN == key ) {
			historyDetailView.showNextHistoryDetailPage();
		} else if ( Ui.KEY_UP == key ) {
			historyDetailView.showPreviousHistoryDetailPage();
		} else if ( Ui.KEY_ESC == key ) {
			// Take them back to the chart view with the first time shown in the chart set to
			// the time they were last looking at in the history detail view
			CommuteHistory.getController().showHistoryChart( historyDetailView.getCommuteStartTime() );
		} else if( Ui.KEY_MODE == key && historyDetailView.isHistoryDataDisplayed() ) {
			// See if they want to delete the history for this time
			var confirmationMessage = "Delete history for " + CommuteTrackerUtil.formatMoment( historyDetailView.getCommuteStartTime() ) + "?";
			Ui.pushView( new Confirmation( confirmationMessage ), new ConfirmDeleteRecordDelegate( historyDetailView.getCommuteStartTime() ), Ui.SLIDE_LEFT );
		}
		return true; 
	}
	
	///! Allows scrolling through summary pages on touch screen devices
	function onSwipe(swipeEvent) {
		var direction = swipeEvent.getDirection();
		if( Ui.SWIPE_LEFT == direction ) {
			historyDetailView.showNextHistoryDetailPage();
		} else if( Ui.SWIPE_RIGHT == direction ) {
			historyDetailView.showPreviousHistoryDetailPage();
		}
		return true;
	}
}


class ConfirmDeleteRecordDelegate extends Ui.ConfirmationDelegate {
	
	hidden var commuteStartTime = null; // Moment object
	
	function initialize(startTime) {
		commuteStartTime = startTime;
	}
	
	function onResponse(response) {
		if( Ui.CONFIRM_YES == response ) {
			CommuteHistory.deleteRecordForTime( commuteStartTime );
		}
	}
}