using Toybox.System as Sys;
using Toybox.Time.Gregorian as Gregorian;

module CommuteTrackerUtil {

	///! Unit conversion constants
	hidden const MPS_TO_MPH = 2.24; // Meters per second to miles per hour
	hidden const MPS_TO_KPH = 3.6; // Meters per second to kilometers per hour
	hidden const METERS_TO_MILES = 0.0006213;
	
	// Unit labels
	hidden const KPH_LABEL = " kph";
	hidden const MPH_LABEL = " mph";
	hidden const KILOMETERS_LABEL = " km";
	hidden const MILES_LABEL = " mi"; 

	///! Takes as input two integers representing the hour and minute of the time
	///! in 24-hour military format. If the device settings use 12 hour time, this will 
	///! return a string representing the time in 12 hour format with the meridan included.
	///! Otherwise return a string in 24 hour time format
	function formatTime(hour, minute) {
		var timeString = "";
		// Pad the minute with a 0 if it is less than 10
		var minuteString = (minute < 10) ? ("0" + minute.toString()) : (minute.toString());
			
		var settings = Sys.getDeviceSettings();
		
		if( settings.is24Hour ) {
			// Pad the hour with a leading zero
			var hourString = (hour < 10) ? ("0" + hour.toString()) : (hour.toString());
			timeString = hourString + minuteString;
		} else {
			// Convert to 12 hour time format
			var meridian = "a";
			if( 12 == hour  ) { // noon
				meridian = "p";
			} else if ( hour > 12 && hour < 24 ) {
				meridian = "p";
				hour = hour % 12;
			} else if ( 0 == hour ) { // midnight
				hour = 12;
			}
			
			timeString = hour.toString() + ":" + minuteString + meridian;
		}
		
		return timeString;
	}
	
	function formatMoment(moment) {
		var timeInfo = Gregorian.info( moment, Gregorian.FORMAT_SHORT );
		return formatTime( timeInfo.hour, timeInfo.min );
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


	///! Takes as input a distance in meters and converts to a string with whatever distance units
	///! are used in the device settings and with the units appended to the end of the string
	function formatDistance(distanceMeters) {
		var distanceString = "";
		var settings = Sys.getDeviceSettings();
		
		if( Sys.UNIT_METRIC == settings.distanceUnits ) {
			// Use kilometers for distance
			var distanceKM = distanceMeters / 1000;
			distanceString = distanceKM.format( "%.1f" ) + KILOMETERS_LABEL;
		
		} else {
			// Use miles for distance
			var distanceMiles = distanceMeters * METERS_TO_MILES;
			distanceString = distanceMiles.format( "%.1f" ) + MILES_LABEL;
		}
		
		return distanceString;
	}
	
	
	///! Takes as input a speed in meters/sec and converts to a string with whatever speed units
	///! are used in the device settings and with the units appended to the end of the string
	function formatSpeed(speedMPS) {
		var speedString = "";
		var settings = Sys.getDeviceSettings();
		
		if( Sys.UNIT_METRIC == settings.distanceUnits ) {
			// Use kilometers per hour
			var speedKPH = speedMPS * MPS_TO_KPH;
			speedString = speedKPH.format( "%.1f" ) + KPH_LABEL;
		} else {
			// Use miles per hour
			var speedMPH = speedMPS * MPS_TO_MPH;
			speedString = speedMPH.format( "%.1f" ) + MPH_LABEL;
		}
		
		return speedString;
	}

}