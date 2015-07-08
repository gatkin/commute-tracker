

module CommuteTrackerUtil {

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


}