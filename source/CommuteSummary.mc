using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Time.Gregorian as Gregorian;


class CommuteSummaryView extends Ui.View {
		
		hidden var commuteModel = null;
		hidden var currentPage = null; // Allows for scrolling though commute stats


		function initialize(activityModel) {
			commuteModel = activityModel;
			currentPage = :pageOne;
		}
		
	    function onLayout(dc) {
	    }
	
		
		
		function onUpdate(dc) {
		    dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_WHITE );
	        dc.clear();
	        dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT );
	        
	    	
	    	var startTimeInfo = Gregorian.info(commuteModel.getCommuteStartTime(), Time.FORMAT_SHORT);
	    	var startTimeString = CommuteTrackerUtil.formatTime(startTimeInfo.hour, startTimeInfo.min);
			
			var currentYPosn = 2;
			
			// Draw the title with the current time
			dc.drawText(( dc.getWidth()/2), currentYPosn, Gfx.FONT_LARGE, "Commute " + startTimeString, Gfx.TEXT_JUSTIFY_CENTER );
			
			
			// Draw a horizontal line
			currentYPosn = 30;
			dc.setColor( Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT );
			dc.fillRectangle(0, currentYPosn, dc.getWidth(), 5); // horizontal bar
			dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT ); // Reset text color to black

			// Parameters for drawing the data fields
			var labelXPosn = dc.getWidth() / 8;
			var valueXPosn = 7 * dc.getWidth() / 8;
			var verticalSpacing = 25;

			if( currentPage == :pageOne ) {
	
				// Display the total time
				currentYPosn += 15;
				dc.drawText(labelXPosn, currentYPosn, Gfx.FONT_SMALL, "Total Time", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(valueXPosn, currentYPosn, Gfx.FONT_SMALL, CommuteTrackerUtil.formatDuration(commuteModel.getTotalCommuteTime()), Gfx.TEXT_JUSTIFY_RIGHT);
				
				// Display the time moving
				currentYPosn += verticalSpacing;
				dc.drawText(labelXPosn, currentYPosn, Gfx.FONT_SMALL, "Time Moving", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(valueXPosn, currentYPosn, Gfx.FONT_SMALL, CommuteTrackerUtil.formatDuration(commuteModel.getTimeMoving()), Gfx.TEXT_JUSTIFY_RIGHT);
				
				// Display the time stoped
				currentYPosn += verticalSpacing;
				dc.drawText(labelXPosn, currentYPosn, Gfx.FONT_SMALL, "Time Stopped", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(valueXPosn, currentYPosn, Gfx.FONT_SMALL, CommuteTrackerUtil.formatDuration(commuteModel.getTimeStopped()), Gfx.TEXT_JUSTIFY_RIGHT);
				
				// Display the distance travelled
				currentYPosn += verticalSpacing;
				dc.drawText(labelXPosn, currentYPosn, Gfx.FONT_SMALL, "Distance", Gfx.TEXT_JUSTIFY_LEFT);
				var dist = commuteModel.getTotalDistance() * CommuteTrackerUtil.METERS_TO_MILES;
				var distString = dist.format("%.2f") +  " mi";
				dc.drawText(valueXPosn, currentYPosn, Gfx.FONT_SMALL, distString, Gfx.TEXT_JUSTIFY_RIGHT);
			
			} else { // page 2
				
				// Display the max speed
				currentYPosn += 15;
				dc.drawText(labelXPosn, currentYPosn, Gfx.FONT_SMALL, "Max Speed", Gfx.TEXT_JUSTIFY_LEFT);
				var speed = commuteModel.getMaxSpeed() * CommuteTrackerUtil.MPS_TO_MPH;
				var speedString = speed.format("%.2f") + " mph";
				dc.drawText(valueXPosn, currentYPosn, Gfx.FONT_SMALL, speedString, Gfx.TEXT_JUSTIFY_RIGHT);
				
				// Display the number of stops
				currentYPosn += verticalSpacing;
				dc.drawText(labelXPosn, currentYPosn, Gfx.FONT_SMALL, "Stops", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(valueXPosn, currentYPosn, Gfx.FONT_SMALL, commuteModel.getNumStops().toString(), Gfx.TEXT_JUSTIFY_RIGHT);
				
				// Display the commute efficiency
				currentYPosn += verticalSpacing;
				dc.drawText(labelXPosn, currentYPosn, Gfx.FONT_SMALL, "Efficiency", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(valueXPosn, currentYPosn, Gfx.FONT_SMALL, commuteModel.getCommuteEfficiency().toString(), Gfx.TEXT_JUSTIFY_RIGHT);
			}
	     }
	     
	     function nextPage() {
	       if( :pageOne == currentPage ) {
	       		currentPage = :pageTwo;
	       		Ui.requestUpdate();
	       }
	     }
	     
	     function previousPage() {
	     	if( :pageTwo == currentPage ) {
	     		currentPage = :pageOne;
	     		Ui.requestUpdate();
	     	}
	     }
	     
	}
	
	
class CommuteSummaryDelegate extends Ui.InputDelegate {

		hidden var summaryView = null;
		
		function initialize(view) {
			summaryView = view;
		}
	
		function onKey(keyEvent) {
			var key = keyEvent.getKey();
			if( key == Ui.KEY_ENTER || key == Ui.KEY_ESC ) {
				// Take them back to the main menu
				Ui.popView(Ui.SLIDE_RIGHT);
			} else if( Ui.KEY_DOWN == key ) {
				summaryView.nextPage();
			} else if( Ui.KEY_UP == key ) {
				summaryView.previousPage();
			}
		}
	}