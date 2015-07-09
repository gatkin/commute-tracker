

module CommuteTrackerUtil {

	const MPS_TO_MPH = 2.24;
	const METERS_TO_MILES = 0.0006213;

	function formatTime(hour, minute) {
		var meridian = "a";
		if( hour == 12 ) {
			meridian = "p";
		} else if ( hour > 12 && hour < 24 ) {
			meridian = "p";
			hour = hour % 12;
		} else if ( hour == 0 ) { // midnight
			hour = 12;
		}
		
		var minuteString = (minute < 10) ? ("0" + minute) : (minute.toString());
		return hour.toString() + ":" + minuteString + meridian;
	}
	
	
	function formatDuration(elapsedTime) {
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