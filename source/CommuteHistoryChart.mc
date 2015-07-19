using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Graphics as Gfx;
using CommuteTrackerUtil as CommuteTrackerUtil;
using CommuteHistory as CommuteHistory;

class CommuteHistoryChartView extends Ui.View {

	hidden const TIMES_PER_PAGE = 6; // Show data for 6 commute times per page
	hidden const PAGE_TIME_STEP = 1800; // Each page has 30 minutes of commute times
	hidden var timeToShow = null; // For what time of day we display for the commute history
	
	function initialize( time ) {
		timeToShow = time;
	}

    function onLayout(dc) {
    	setLayout( Rez.Layouts.HistoryChartLayout( dc) );
     }

    //! Update the view
    function onUpdate(dc) {
        
        var commuteHistory = CommuteHistory.loadCommuteHistoryOverview( timeToShow, TIMES_PER_PAGE );
        
        // First draw all of the time labels and update the view layout
		var labelId = "bar_label_";
        for(var i=0; i<commuteHistory.size(); i++) {
			View.findDrawableById(labelId + i.toString()).setText( commuteHistory[i][:timeLabel] );
    	}
    	// Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        
        // Now that we have updated the layout with the labels, draw all of the bars
		var spacing = 17;
        var barY = 33;
        var barHeight = 5;
        var chartBaseX = 50;
        var maxBarWidth = 150;
        var barWidth = 0;
        var barColor = Gfx.COLOR_WHITE;
        for(var i=0; i<commuteHistory.size(); i++) {
        	// Set the width of the bar based on the efficiency
    		barWidth = commuteHistory[i][:commuteEfficiency] * maxBarWidth / 100.0;
    		
    		// If we have a record for this time, always show a tiny bar, even if the 
			// efficiency is zero to indicate that a record exists
			if( ( commuteHistory[i][:hasRecord] ) && ( 0 == commuteHistory[i][:commuteEfficiency] ) ) {
				barWidth = 2;
			} 
			
			// Choose the color for the bar based on the efficiency
			barColor = Gfx.COLOR_WHITE;
			if( commuteHistory[i][:commuteEfficiency] < 25 ) {
				barColor = Gfx.COLOR_RED;
			} else if ( commuteHistory[i][:commuteEfficiency] < 50 ) {
				barColor = Gfx.COLOR_ORANGE;
			} else if ( commuteHistory[i][:commuteEfficiency] < 75 ) {
				barColor = Gfx.COLOR_YELLOW;
			} else {
				barColor = Gfx.COLOR_GREEN;
			}
			
			// Draw the bar
			dc.setColor( barColor, Gfx.COLOR_TRANSPARENT );
    		dc.fillRectangle (chartBaseX, barY, barWidth, barHeight );
    		barY += spacing;
    	}
    }


	function showPreviousHistoryPage() {
		// Decrease the time to show by one half hour
		var durationDecrement = new Time.Duration(-PAGE_TIME_STEP);
		timeToShow = timeToShow.add(durationDecrement);
		Ui.requestUpdate();
	}
	
	function showNextHistoryPage() {
		// Increase the time to show by one half hour
		var durationIncrement = new Time.Duration(PAGE_TIME_STEP);
		timeToShow = timeToShow.add(durationIncrement);
		Ui.requestUpdate();
	}
	
	function getTimeToShow() {
		return timeToShow;
	}
}

hidden class CommuteHistoryChartDelegate extends Ui.BehaviorDelegate {
	
	hidden var historyChartView = null;
	
	function initialize( view ) {
		historyChartView = view;
	}
	
	function onKey(keyEvent) {
		var key = keyEvent.getKey();
		if( Ui.KEY_DOWN == key ) {
			historyChartView.showNextHistoryPage();
		} else if ( Ui.KEY_UP == key ) {
			historyChartView.showPreviousHistoryPage();
		} else if ( Ui.KEY_ESC == key ) {
			// Take them back to the main view
			Ui.switchToView( new MainView(), new MainViewDelegate(), Ui.SLIDE_LEFT );
		} else if ( Ui.KEY_ENTER ) {
			// Remove the current history chart view to show the history detail view
			CommuteHistory.getController().showHistoryDetail( historyChartView.getTimeToShow() );
		}
		
		return true;
	}
	
	///! Allows scrolling through chart pages on touch screen devices
	function onSwipe(swipeEvent) {
		var direction = swipeEvent.getDirection();
		if( Ui.SWIPE_LEFT == direction ) {
			historyChartView.showNextHistoryPage();
		} else if( Ui.SWIPE_RIGHT == direction ) {
			historyChartView.showPreviousHistoryPage();
		}
	}
}