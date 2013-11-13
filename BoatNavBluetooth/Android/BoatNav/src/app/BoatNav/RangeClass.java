package app.BoatNav;

//RANGE struct
//range			DWORD ?									;Range in meters
//mindepth		DWORD ?									;Min index for depth search
//interval		DWORD ?									;Update rate
//pixeltimer		DWORD ?									;Pixel timer value
//pingadd			DWORD ?									;Number of pulses to add to the initial ping (0 to 128). Used when autoping is on
//nticks			DWORD ?									;Number of ticks on the range scale
//scale			BYTE 64 dup(?)							;Zero terminated strings of depths on range scale
//gain			DWORD 17 dup(?)							;Gain increment levels read from ini file
//RANGE ends

public class RangeClass {
	public int range;
	public int mindepth;
	public int interval;
	public int pixeltimer;
	public int pingadd;
	public int[] gain = new int[17];
	public int nticks;
	public String scale;

	public static RangeClass[] RangeClassSet(int size) {
		RangeClass[] p= new RangeClass[size];
	    for(int i=0; i<size; i++)
	        p[i] = new RangeClass();
	    return p;
	}
}
