using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Graphics as Gfx;
using CommuteTrackerUtil as CommuteTrackerUtil;

class CommuteHistoryChartView extends Ui.View {
		hidden var timeToShow = null; // For what time of day we display for the commute history
		
		function initialize() {
			timeToShow = Time.now();
		}
	
	    function onLayout(dc) {
	    }
	
	    //! Update the view
	    function onUpdate(dc) {
	        dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_BLACK );
	        dc.clear();
	        dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
	        
	        var spacing = 17;
	        var textY = 25;
	        var textX = 5;
	        var barHeight = 5;
	        var chartBaseX = 45;
	        var maxBarWidth = 150;
	        var barWidth = 0;
	        
	        var commuteHistory = CommuteHistory.loadCommuteHistoryOverview(timeToShow, 6);
	        for(var i=0; i<commuteHistory.size(); i++) {
	        	// Draw the time label
	    		dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
	    		dc.drawText(textX, textY, Gfx.FONT_XTINY, commuteHistory[i][:timeLabel], Gfx.TEXT_JUSTIFY_LEFT);
	    		barWidth = commuteHistory[i][:commuteEfficiency] * maxBarWidth / 100.0;
	    		
	    		// If we have a record for this time, always show a tiny bar, even if the 
				// efficiency is zero to indicate that a record exists
				if( commuteHistory[i][:hasRecord] && 0 == commuteHistory[i][:commuteEfficiency] ) {
					barWidth = 2;
				} 
				
				// Choose the color for the bar based on the efficiency
				var barColor = Gfx.COLOR_WHITE;
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
				dc.setColor(barColor, Gfx.COLOR_TRANSPARENT);
	    		dc.fillRectangle(chartBaseX, textY + 8, barWidth, barHeight);
	    		textY += spacing;
	    	}
	    	
	    	// Draw the graph tickmarks
			dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
			dc.fillRectangle(chartBaseX-1, 30 , 2, textY - 28);
			dc.fillRectangle(chartBaseX-1, textY, maxBarWidth, 2);
			dc.drawText(chartBaseX, textY + 2, Gfx.FONT_XTINY, "0", Gfx.TEXT_JUSTIFY_RIGHT);
			dc.drawText(chartBaseX + maxBarWidth/2, textY + 2, Gfx.FONT_XTINY, "50", Gfx.TEXT_JUSTIFY_RIGHT);
			dc.drawText(chartBaseX + maxBarWidth, textY + 2, Gfx.FONT_XTINY, "100", Gfx.TEXT_JUSTIFY_RIGHT);
			
			// Title
			dc.drawText(120, 5, Gfx.FONT_SMALL, "Commute Efficiency", Gfx.TEXT_JUSTIFY_CENTER); 
	    }
	
	
		function showPreviousHistoryPage() {
			// Decrease the time to show by one half hour
			var durationDecrement = new Time.Duration(-1800);
			timeToShow = timeToShow.add(durationDecrement);
			Ui.requestUpdate();
		}
		
		function showNextHistoryPage() {
			// Increase the time to show by one half hour
			var durationIncrement = new Time.Duration(1800);
			timeToShow = timeToShow.add(durationIncrement);
			Ui.requestUpdate();
		}
		
		function getTimeToShow() {
			return timeToShow;
		}
	}