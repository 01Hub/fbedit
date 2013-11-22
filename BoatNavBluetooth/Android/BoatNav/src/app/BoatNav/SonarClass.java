package app.BoatNav;

//SONARREPLAY struct
//Version		BYTE ?									;201
//PingPulses	BYTE ?									;Number of pulses in a ping (0 to 128)
//GainSet		WORD ?									;Gain set level (0 to 4095)
//SoundSpeed	WORD ?									;Speed of sound in water
//ADCBattery	WORD ?									;Battery level
//ADCWaterTemp	WORD ?									;Water temperature
//ADCAirTemp	WORD ?									;Air temperature
//iTime			DWORD ?									;UTC Dos file time. 2 seconds resolution
//iLon			DWORD ?									;Longitude, integer
//iLat			DWORD ?									;Lattitude, integer
//iSpeed		WORD ?									;Speed in kts
//iBear			WORD ?									;Degrees
//SONARREPLAY ends

//SATELITE struct
//SatelliteID	BYTE ?									;Satellite ID
//Elevation		BYTE ?									;Elevation in degrees (0-90)
//Azimuth		WORD ?									;Azimuth in degrees (0-359)
//SNR			BYTE ?									;Signal strength	(0-50, 0 not tracked) 
//Fixed			BYTE ?									;TRUE if used in fix
//SATELITE ends

//ALTITUDE struct
//fixquality	BYTE ?									;Fix quality
//nsat			BYTE ?									;Number of satellites tracked
//hdop			WORD ?									;Horizontal dilution of position * 10
//vdop			WORD ?									;Vertical dilution of position * 10
//pdop			WORD ?									;Position dilution of position * 10
//alt			WORD ?									;Altitude in meters
//ALTITUDE ends

public class SonarClass {
	public Byte Version = (byte)0xC9; // 201
	public Byte PingPulses = 0;
	public Short GainSet = 0;
	public Short SoundSpeed = 0;
	public Short ADCBattery = 0;
	public Short ADCWaterTemp = 0;
	public Short ADCAirTemp = 0;
	public int iTime = 0;
	public int iLon = 0;
	public int iLat = 0;
	public Short iSpeed = 0;
	public Short iBear = 0;
	public SateliteClass[] sat = SateliteClass.SateliteClassSet(12);
	public Byte fixquality = 0;
	public Byte nsat = 0;
	public Short hdop = 0;
	public Short vdop = 0;
	public Short pdop = 0;
	public Short alt = 0;
	public Byte[] sonar = new Byte[512];
}
