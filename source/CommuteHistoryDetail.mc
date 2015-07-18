using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Graphics as Gfx;
using CommuteTrackerUtil as CommuteTrackerUtil;



class CommuteHistoryDetailView extends Ui.View {
	
		hidden var commuteStartTime = null; // Moment object

		function initialize( startTime ) {
			commuteStartTime = startTime;
		}
		
		function onLayout(dc) {
        	setLayout(Rez.Layouts.HistoryDetailLayout(dc));
    	}
		
		function onUpdate(dc) {
        	
	        
	        var historyData = CommuteHistory.loadCommuteHistoryDetail( commuteStartTime );
	        
	        var startTimeString = CommuteTrackerUtil.formatTime(historyData[:startTimeHour], historyData[:startTimeMinute]);
			
			var currentYPosn = 2;
			
			// Draw the title with the current time
			var startTime = View.findDrawableById("detail_start_time").setText( "Commute History " + startTimeString );
			
			
			// Draw a horizontal line
			//currentYPosn = 20;
			//dc.setColor( Gfx.COLOR_DK_BLUE, Gfx.COLOR_TRANSPARENT );
			//dc.fillRectangle(0, currentYPosn, dc.getWidth(), 5); // horizontal bar
			//dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT ); // Reset text color to black

			// Display history data, if we have it for this time of day
			if( historyData[:numRecords] > 0 ) {
				// Parameters for drawing the data fields
				var labelXPosn = dc.getWidth() / 16;
				var valueXPosn = 7 * dc.getWidth() / 8;
				var verticalSpacing = 15;
	
				// Display the average total time
				currentYPosn += 5;
				dc.drawText(labelXPosn, currentYPosn, Gfx.FONT_SMALL, "Commutes", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(valueXPosn, currentYPosn, Gfx.FONT_SMALL, historyData[:numRecords].toString(), Gfx.TEXT_JUSTIFY_RIGHT);
	
				// Display the average total time
				var totalTime = historyData[:stopTime]  + historyData[:moveTime];
				var avgTime = totalTime / historyData[:numRecords];
				currentYPosn += verticalSpacing;
				dc.drawText(labelXPosn, currentYPosn, Gfx.FONT_SMALL, "Avg Time", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(valueXPosn, currentYPosn, Gfx.FONT_SMALL, CommuteTrackerUtil.formatDuration(avgTime), Gfx.TEXT_JUSTIFY_RIGHT);
				
				// Display the average time moving
				var avgMoveTime = historyData[:moveTime] / historyData[:numRecords];
				currentYPosn += verticalSpacing;
				dc.drawText(labelXPosn, currentYPosn, Gfx.FONT_SMALL, "Avg Time Moving", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(valueXPosn, currentYPosn, Gfx.FONT_SMALL, CommuteTrackerUtil.formatDuration(avgMoveTime), Gfx.TEXT_JUSTIFY_RIGHT);
				
				// Display the average time stoped
				var avgStopTime = historyData[:stopTime] / historyData[:numRecords];
				currentYPosn += verticalSpacing;
				dc.drawText(labelXPosn, currentYPosn, Gfx.FONT_SMALL, "Avg Time Stopped", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(valueXPosn, currentYPosn, Gfx.FONT_SMALL, CommuteTrackerUtil.formatDuration(avgStopTime), Gfx.TEXT_JUSTIFY_RIGHT);
				
				// Display the avg distance travelled
				var avgDistance = historyData[:distance] / historyData[:numRecords] * CommuteTrackerUtil.METERS_TO_MILES;
				currentYPosn += verticalSpacing;
				var avgDistString = avgDistance.format("%.2f") + " mi";
				dc.drawText(labelXPosn, currentYPosn, Gfx.FONT_SMALL, "Avg Distance", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(valueXPosn, currentYPosn, Gfx.FONT_SMALL, avgDistString, Gfx.TEXT_JUSTIFY_RIGHT);
				
				// Display the max speed
				currentYPosn += verticalSpacing;
				dc.drawText(labelXPosn, currentYPosn, Gfx.FONT_SMALL, "Max Speed", Gfx.TEXT_JUSTIFY_LEFT);
				var speed = historyData[:maxSpeed]  * CommuteTrackerUtil.MPS_TO_MPH;
				var speedString = speed.format("%.1f") + " mph";
				dc.drawText(valueXPosn, currentYPosn, Gfx.FONT_SMALL, speedString, Gfx.TEXT_JUSTIFY_RIGHT);
				
				// Display the number of stops
				var avgNumStops = historyData[:numStops] / historyData[:numRecords];
				currentYPosn += verticalSpacing;
				dc.drawText(labelXPosn, currentYPosn, Gfx.FONT_SMALL, "Avg Stops", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(valueXPosn, currentYPosn, Gfx.FONT_SMALL, avgNumStops.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
				
				// Display the commute efficiency
				var efficiency = 0;
				// Check for divide by zero
				if( 0 != totalTime ) {
					efficiency = historyData[:moveTime] * 100 / totalTime;
				}
				currentYPosn += verticalSpacing;
				dc.drawText(labelXPosn, currentYPosn, Gfx.FONT_SMALL, "Efficiency", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(valueXPosn, currentYPosn, Gfx.FONT_SMALL, efficiency.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
				
			} else {
				// Display that there is no data
				//dc.drawText((dc.getWidth()/2), (dc.getHeight()/2), Gfx.FONT_LARGE, "No Data", Gfx.TEXT_JUSTIFY_CENTER);
			}
	        View.onUpdate(dc);
	     }
		
		
		function showPreviousHistoryDetail() {
			// Decrease the time to show by one HISTORY_RESOLUTION seconds
			var durationIncrement = new Time.Duration( -CommuteHistory.HISTORY_RESOLUTION * 60 );
			commuteStartTime = commuteStartTime.add( durationIncrement );
			Ui.requestUpdate();
		}
		
		function showNextHistoryDetail() {
			// Increase the time to show by one HISTORY_RESOLUTION seconds
			var durationIncrement = new Time.Duration( CommuteHistory.HISTORY_RESOLUTION * 60 );
			commuteStartTime = commuteStartTime.add( durationIncrement );
			Ui.requestUpdate();
		}
		
		function getCommuteStartTime() {
			return commuteStartTime;
		}
	
	}
	
	
	
	class CommuteHistoryDetailDelegate extends Ui.BehaviorDelegate {
		
		hidden var historyDetailView = null;
		
		function initialize( histDetailView ) {
			historyDetailView = histDetailView;
		}
		
		function onBack() {
			// Remove the current history detail view
			Ui.popView( Ui.SLIDE_LEFT );
			// Take them back to the chart view with the first time shown in the chart set to
			// the time they were last looking at in the history detail view
			CommuteHistory.getController().showHistoryChart( historyDetailView.getCommuteStartTime() );
			return true;
		}
		
		function onKey(keyEvent) {
			var key = keyEvent.getKey();
			if( Ui.KEY_DOWN == key ) {
				historyDetailView.showNextHistoryDetail();
			} else if ( Ui.KEY_UP == key ) {
				historyDetailView.showPreviousHistoryDetail();
			} else if ( Ui.KEY_ESC == key ) {
				onBack();
			} 
		}
		
		function onSwipe(swipeEvent) {
			var direction = swipeEvent.getDirection();
			if( Ui.SWIPE_LEFT == direction ) {
				historyDetailView.showNextHistoryDetail();
			} else if( Ui.SWIPE_RIGHT == direction ) {
				historyDetailView.showPreviousHistoryDetail();
			}
		}
	}