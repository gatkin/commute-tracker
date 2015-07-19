using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Graphics as Gfx;
using CommuteTrackerUtil as CommuteTrackerUtil;
using CommuteHistory as CommuteHistory;


///! View that displays the commute history chart
class CommuteHistoryChartView extends Ui.View {

	hidden const TIMES_PER_PAGE = 6; // Show data for 6 commute times per page
	hidden const PAGE_TIME_STEP = 1800; // Each page has 30 minutes worth of commute times
	hidden var firstCommuteStartTime = null; // The first commute start time in the chart
	
	///! Constructor, takes as input the first commute start time to display at the
	///! top of the chart
	function initialize( time ) {
		firstCommuteStartTime = time;
	}

    function onLayout(dc) {
    	setLayout( Rez.Layouts.HistoryChartLayout( dc ) );
     }

    //! Update the view
    function onUpdate(dc) {
        
        var commuteHistory = CommuteHistory.loadCommuteHistoryOverview( firstCommuteStartTime, TIMES_PER_PAGE );
        
        // First draw all of the time labels and update the view layout
		var labelId = "bar_label_";
        for(var i=0; i<commuteHistory.size(); i++) {
			View.findDrawableById(labelId + i.toString()).setText( commuteHistory[i][:timeLabel] );
    	}
    	// Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        
        // Now that we have updated the layout with the labels, draw all of the bars
		// Note that these values need to match the coordinate values of the time labels
		// in the layout file. Need to find a way to define the bars in the layout file
		// and dynamically set the color and width of the bars.
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
    		dc.fillRectangle ( chartBaseX, barY, barWidth, barHeight );
    		barY += spacing;
    	}
    }

	///! Shows the previous set of commute histories in the chart
	function showPreviousHistoryPage() {
		// Decrease the first commute start time by one half hour
		var durationDecrement = new Time.Duration( -PAGE_TIME_STEP );
		firstCommuteStartTime = firstCommuteStartTime.add( durationDecrement );
		Ui.requestUpdate();
	}
	
	///! Shows the next set of commute histories in the chart
	function showNextHistoryPage() {
		// Increase the first commute start time by one half hour
		var durationIncrement = new Time.Duration( PAGE_TIME_STEP );
		firstCommuteStartTime = firstCommuteStartTime.add( durationIncrement) ;
		Ui.requestUpdate();
	}
	
	///! Returns the commute start time that is currently displayed first
	///! in the chart
	function getFirstCommuteStartTime() {
		return firstCommuteStartTime;
	}
}

///! Input delegate that corresponds to the CommuteHistoryView
hidden class CommuteHistoryChartDelegate extends Ui.BehaviorDelegate {
	
	hidden var historyChartView = null;
	
	///! Constructor, takes as input the CommuteHistoryChartView
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
			// Show the history detail view for the commute start time that is at the top of the chart
			CommuteHistory.getController().showHistoryDetail( historyChartView.getFirstCommuteStartTime() );
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
		
		return true;
	}
}