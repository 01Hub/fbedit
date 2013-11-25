package app.BoatNav;

import android.util.Log;

public class GPSClass {

	//  Distance between two points:
	//  Spherical law of cosines: d = acos(sin(lat1).sin(lat2)+cos(lat1).cos(lat2).cos(long2-long1)).R
	//  R = earth’s radius (mean radius = 6,371km)

	//  Distance in meters between two points
	//	theta = lon2 - lon1
	//	dist = acos(sin(lat1) × sin(lat2) + cos(lat1) × cos(lat2) × cos(theta))
	//	if (dist < 0) dist = dist + pi
	//	dist = dist × 6371200 
	public static double Distance(double lata, double lona, double latb, double lonb) {
		double dist;
		dist = Math.acos(Math.sin(Math.toRadians(lata)) * Math.sin(Math.toRadians(latb)) + Math.cos(Math.toRadians(lata)) * Math.cos(Math.toRadians(latb)) * Math.cos(Math.toRadians(lonb-lona)));
		if (dist < 0) {
			dist += Math.PI;
		}
		if (Double.isNaN(dist)) {
	    	Log.d("MYTAG", "Dist: " + dist);
	    	Log.d("MYTAG", "Distance lat: " + lata + " " + latb);
	    	Log.d("MYTAG", "Distance lon: " + lona + " " + lonb);
			dist = 0;
		}
		dist *= 6371200d;
		return dist;
	}
	
	//    LatLon.brngRhumb = function(lat1, lon1, lat2, lon2) { 
	//    var dLon = (lon2-lon1).toRad(); 
	//    var dPhi = Math.log(Math.tan(lat2.toRad()/2+Math.PI/4)/Math.tan(lat1.toRad()/2+Math.PI/4)); 
	//    if (Math.abs(dLon) > Math.PI) dLon = dLon>0 ? -(2*Math.PI-dLon) : (2*Math.PI+dLon); 
	//    return Math.atan2(dLon, dPhi).toBrng(); } 
	public static double Bearing(double lata, double lona, double latb, double lonb) {
		double dLon = Math.toRadians(lonb-lona);
		double dPhi = Math.log(Math.tan(Math.toRadians(latb)/2+Math.PI/4)/Math.tan(Math.toRadians(lata)/2+Math.PI/4));
		double bearing;
	    //if (Math.abs(dLon) > Math.PI) dLon = dLon>0 ? -(2*Math.PI-dLon) : (2*Math.PI+dLon); 
		bearing = Math.toDegrees(Math.atan2(dLon, dPhi));
		if (bearing > 0d && bearing < 180d) {
			bearing = bearing + 180;
		} else if (bearing < 0) {
			bearing = bearing + 180;
		}
		return bearing;
	}

}
