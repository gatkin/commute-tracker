

module CommuteTrackerUtil {

	///! Unit conversion constants
	const MPS_TO_MPH = 2.24;
	const METERS_TO_MILES = 0.0006213;

	///! Takes as input two integers representing the hour and minute of the time
	///! in 24-hour military format. Returns a string representing the time in 12
	///! hour format with the meridan included
	function formatTime(hour, minute) {
		var meridian = "a";
		if( 12 == hour  ) { // noon
			meridian = "p";
		} else if ( hour > 12 && hour < 24 ) {
			meridian = "p";
			hour = hour % 12;
		} else if ( 0 == hour ) { // midnight
			hour = 12;
		}
		
		// Pad the minute with a 0 if it is less than 10
		var minuteString = (minute < 10) ? ("0" + minute) : (minute.toString());
		
		return hour.toString() + ":" + minuteString + meridian;
	}
	
	///! Takes as input an integer representing a duration in seconds, and returns a 
	///! string representing the duration in the form MM:SS if the given duration is 
	///! less than an hour or HH:MM if the given duration is more than an hour
	function formatDuration(elapsedTime) {
		var timeField1 = "00";
    	var timeField2 = "00";
		var minutes = (elapsedTime / 60).toNumber();
		
		if( minutes >= 60 ) {
			// Show hours:minutes
			timeField1 = (minutes / 60).toNumber().toString(); // Convert to hours
			minutes %= 60;
			
			// Pad with a leading 0 if less than 10
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