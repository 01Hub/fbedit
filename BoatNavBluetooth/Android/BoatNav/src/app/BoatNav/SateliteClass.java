package app.BoatNav;

public class SateliteClass {

	public Byte SatelliteID = 0;
	public Byte Elevation = 0;
	public Short Azimuth = 0;
	public Byte SNR = 0;
	public Byte Fixed = 0;

    public static SateliteClass[] SateliteClassSet(int size) {
    	SateliteClass[] p= new SateliteClass[size];
        for(int i=0; i<size; i++)
            p[i] = new SateliteClass();
        return p;
    }
}
