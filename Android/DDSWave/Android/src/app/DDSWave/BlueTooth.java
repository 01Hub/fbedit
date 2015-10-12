package app.DDSWave;

import java.io.IOException;

public class BlueTooth {

	public static final int CMD_DONE = 0;
	public static final int CMD_LCMCAL = 1;
	public static final int CMD_LCMCAP = 2;
	public static final int CMD_LCMIND = 3;
	public static final int CMD_FRQCH1 = 4;
	public static final int CMD_FRQCH2 = 5;
	public static final int CMD_FRQCH3 = 6;
	public static final int CMD_SCPSET = 7;
	public static final int CMD_HSCSET = 8;
	public static final int CMD_DDSSET = 9;
	public static final int CMD_LGASET = 10;
	public static final int CMD_WAVEUPLOAD = 11;
	public static final int CMD_SCP2SET = 12;
	public static final int CMD_STARTUP = 99;

	public static byte[] btreadbuffer = new byte[64 * 1024];

    public static int btmode = CMD_DONE;
    public static boolean btbusy = false;
    private static double CCal = 1.015e-9;

    public static short BTToShort(int i) {
    	return (short)((btreadbuffer[i+1] & 0xFF) << 8 | (btreadbuffer[+0] & 0xFF));
    }

    public static int BTToInt(int i) {
    	return (btreadbuffer[i+3] & 0xFF) << 24 | (btreadbuffer[i+2] & 0xFF) << 16 | (btreadbuffer[i+1] & 0xFF) << 8 | (btreadbuffer[i+0] & 0xFF);
    }

    public static boolean BTPutByte(Byte b) {
    	try {
			DDSWave.mOutputStream.write(b);
        	return true;
		} catch (IOException e) {
        	return false;
		}
	}

	public static boolean BTPutShort(short i) {
		byte[] b = new byte[2];
    	try {
    		b[0] = (byte) i;
    		b[1] = (byte) (i >> 8);
			DDSWave.mOutputStream.write(b);
        	return true;
		} catch (IOException e) {
        	return false;
		}
	}

	public static boolean BTPutInt(int i) {
		byte[] b = new byte[4];
    	try {
    		b[0] = (byte) i;
    		b[1] = (byte) (i >> 8);
    		b[2] = (byte) (i >> 16);
    		b[3] = (byte) (i >> 24);
			DDSWave.mOutputStream.write(b);
        	return true;
		} catch (IOException e) {
        	return false;
		}
	}

	public static boolean BTGetBytes(int n) {
        try {
        	btbusy = true;
        	int bytes = 0;
        	while (bytes < n) {
               	bytes += DDSWave.mInputStream.read(btreadbuffer,bytes,n-bytes);
        	}
        	btbusy = false;
        	return true;
        } catch (IOException e) {
        	return false;
        }
	}
	
	public static void BTLcmCal() {
		btmode = CMD_LCMCAL;
		if (BTPutInt(CMD_LCMCAL)) {
			if (BTGetBytes(8)) {
				btmode = CMD_DONE;
				DDSWave.mode = DDSWave.tmpmode;
			}
		}
	}

	public static String BTLcmCap() {
		double D1, D2, D3, Cx;
		btmode = CMD_LCMCAP;
		if (BTPutInt(CMD_LCMCAP)) {
			if (BTGetBytes(16)) {
				D1 = (double)BTToInt(8);
				D2 = (double)BTToInt(12);
				D3 = (double)BTToInt(0);
				// Capacitance meter: Cx=((((F1/F3)^2)-1)/(((F1/F2)^2)-1))*Ccal
				Cx = ((((D1/D3)*(D1/D3))-1.0)/(((D1/D2)*(D1/D2))-1.0))*CCal;
				btmode = CMD_DONE;
				if (Cx >= 1e-6) {
					// uF
					Cx *= 1e6;
					return String.format("%.3f",((float)(Cx))) + "uF";
				} else if (Cx >= 1e-9) {
					// nF
					Cx *= 1e9;
					return String.format("%.3f",((float)(Cx))) + "nF";
				} else {
					// pF
					Cx *= 1e12;
					return String.format("%.3f",((float)(Cx))) + "pF";
				}
			} else {
				return "err";
			}
		} else {
			return "err";
		}
	}

	public static String BTLcmInd() {
		double D1, D2, D3, Lx;
		btmode = CMD_LCMIND;
		if (BTPutInt(CMD_LCMIND)) {
			if (BTGetBytes(16)) {
				D1 = (double)BTToInt(8);
				D2 = (double)BTToInt(12);
				D3 = (double)BTToInt(0);
				// Inductance meter: Lx=(((F1/F3)^2)-1)*(((F1/F2)^2)-1)*(1/Ccal)*(1/(2*PI*F1))^2
				Lx = ((((D1/D3)*(D1/D3))-1.0)/(((D1/D2)*(D1/D2))-1.0))*(1.0/CCal) * Math.pow((1.0/(2*Math.PI*D1)),2);
				btmode = CMD_DONE;
				if (Lx >= 1e3) {
					// H
					Lx = 0;
					return String.format("%.3f",((float)(Lx))) + "H";
				} else if (Lx >= 1) {
					// H
					return String.format("%.3f",((float)(Lx))) + "H";
				} else if (Lx >= 1e-3) {
					// mH
					Lx *= 1e3;
					return String.format("%.3f",((float)(Lx))) + "mH";
				} else if (Lx >= 1e-6) {
					// uH
					Lx *= 1e6;
					return String.format("%.3f",((float)(Lx))) + "uH";
				} else {
					// nH
					Lx *= 1e9;
					return String.format("%.3f",((float)(Lx))) + "nH";
				}
			} else {
				return "err";
			}
		} else {
			return "err";
		}
	}
	
	public static void BTHscSet(int set, int div) {
		btmode = CMD_HSCSET;
		if (BTPutInt(CMD_HSCSET)) {
			BTPutInt(set);
			BTPutInt(div);
			if (BTGetBytes(8)) {
				btmode = CMD_DONE;
			}
		}
	}

	public static String BTHscGet() {
		int f;
		if (BTPutInt(CMD_FRQCH1)) {
			if (BTGetBytes(8)) {
				f = BTToInt(0);
				if (f >= 1000000) {
					return String.format("%.3f",((double)(f / 1000000.0))) + "MHz";
				} else if (f >= 1000) {
					return String.format("%.3f",((double)(f / 1000.0))) + "KHz";
				} else {
					return "" + f + "Hz";
				}
			}
		}
		return "err";
	}

}
