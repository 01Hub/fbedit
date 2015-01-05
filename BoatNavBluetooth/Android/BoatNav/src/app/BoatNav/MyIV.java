package app.BoatNav;

import java.io.File;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Color;
import android.graphics.Paint.Style;
import android.graphics.Rect;
import android.os.Environment;
import android.widget.ImageView;
import android.util.*;
import android.graphics.Region;
import java.io.RandomAccessFile;
import java.text.SimpleDateFormat;
import java.util.TimeZone;
import app.BoatNav.GPSClass;
import app.BoatNav.RangeClass;
import app.BoatNav.SonarClass;

public class MyIV extends ImageView {

	public static final int MAPMAXBMP = 15;
	public static final int MAPMAXICON = 32;
	public static final int MAPMAXZOOM = 5;
	public static final int MAPTILESIZE = 512;
	public static final int MAPMAXLATARR = 65;
	public static final int MAPMAXTRAIL = 8192;
	public static int scrnwt;
	public static int scrnht;
	public static int mapwt = 0;
	public static int sonarwt = 0;
	public static int satelitewt = 0;
	public static float xofs = 0;
	public static float yofs = 0;

	public static int mode = 1;
	public static int viewmode;
	public static boolean land;
	public static int zoom;
	public static boolean locktogps;
	public static boolean showtrail;
	public static int tracksmoothing;

	public static String path = Environment.getExternalStorageDirectory() + File.separator + "Map" + File.separator;
	public static int maxtilex[] = new int[6];
	public static int maxtiley[] = new int[6];
	private static Paint paint = new Paint(Paint.FAKE_BOLD_TEXT_FLAG);
	// MapRect
	public static double left;
	public static double top;
	public static double right;
	public static double bottom;
	public static double latarray[] = new double[65];
	private static int mpx;
	private static int mpy;
	private static int spx;
	private static int spy;
	public static int cpx=0;
	public static int cpy=0;
	public static double curlat;
	public static double curlon;
	public static double prvlat;
	public static double prvlon;
	private static double distance = 0;
	private static int curbearing = 0;
	private static int curspeed = 0;
	private static int curfix = 0;
	private static float curbatt = 12.6f;
	private static float curatemp = 17.2f;
	private static String curtime = "29.10.2013 11:45:04";
	private static int trailpoints = 0;
	private static int trailhead = 0;
	private static int trailtail = 0;
	private static int trail[] = new int[MAPMAXTRAIL * 3];
	public static int AirTempArray[] = new int[22];
	public static final int MAXSONARBMP = 512;
	public static final int SONARTILEWIDTH = 32;
	public static final int SONARTILEHEIGHT = 512;
	public static final int SONARSIGNALGRAHWIDTH = 32;
	public static final int SONARRANGEBARWIDTH = SONARSIGNALGRAHWIDTH + 6;
	public static final int MAXSONARRANGE = 20;
	public static final int MAXFISH = 64;
	private static final int SMALLFISH = 96 * 4;
	private static final int BIGFISH = (96 + 64) * 4;
	public static final int SONARARRAYSIZE = 28 + 6 * 12 + 10 + 512;
	private static final int SONAROFFSET = 28 + 6 * 12 + 10;
	public static final SimpleDateFormat sdf = new SimpleDateFormat("dd.MM.yyyy HH:mm:ss");
	public static int sonarColor;
	public static int sonarColorArray[]=new int[256];

	public static int sonarpinginit;
	public static boolean sonarautoping;
	public static int sonargaininit;
	public static boolean sonarautogain;
	public static int sonarnoiselevel;
	public static int sonarnoisereject;
	public static int sonarfishdetect;
	public static boolean sonarfishalarm;
	public static boolean sonarfishdepth;
	public static boolean sonarfishicon;
	public static boolean sonarautorange;
	public static int sonarshallow = 0;
	public static int sonardeep = 0;
	public static int sonarrangeinx = 4;
	public static int sonarrangeset = -1;
	public static int sonarrangechange = 0;
	public static int sonarrangechangedir = 1;
	public static boolean sonarpause = false;

	private static Rect srcrect = new Rect(0,0,0,0);
	private static Rect dstrect =  new Rect(0,0,0,0);
	public static Bitmap[] sonarbmp = new Bitmap[MAXSONARBMP];
	public static Bitmap sonarsignalbmp;
	public static int[] sonarbmpwidth = new int[MAXSONARBMP];
	public static int[] sonarbmprange = new int[MAXSONARBMP];
	public static int[] sonarbmplat = new int[MAXSONARBMP];
	public static int[] sonarbmplon = new int[MAXSONARBMP];
	public static int sonarofs = 0;
	public static int cursonarrange = 10;
	private static int echoarrayinx = 0;
	private static int echoarraycount = 0;
	public static int sonarcount = 0;

	public static int rndpixdir = 0;
	public static int rndpixmov = 0;
	public static int rndpixdpt = 250;
	public static int rndfishdpt = 0;
	public static int rndfishcount = 0;
	
	private static Byte[][] echoarray = new Byte[4][SONARTILEHEIGHT];
	private static int fisharrayinx = 0;
	public static int[][] fisharray = new int[4][MAXFISH];
	public static float curdepth = 0;
	private static float curwtemp = 12.3f;
	public static boolean nodepth = true;
	public static boolean blink = false;
	private static int sonarbmpinx = 0;
	private static int sonarcurbmpinx = 0;
	private static String rngticks;
	public static boolean playfishalarm = false;
	public static boolean playshallowalarm = false;
	public static boolean shallowalarm = false;
	public static boolean playdeepalarm = false;
	public static boolean deepalarm = false;
	public static byte[] replayarray = new byte[SONARARRAYSIZE];
	public static SonarClass sc = new SonarClass();
	public static RangeClass[] range = RangeClass.RangeClassSet(MAXSONARRANGE);

//	SONARREPLAY struct (28 bytes)
//0		Version			BYTE ?								;201
//1		PingPulses		BYTE ?								;Number of pulses in a ping (0 to 128)
//2		GainSet			WORD ?								;Gain set level (0 to 4095)
//4		SoundSpeed		WORD ?								;Speed of sound in water
//6		ADCBattery		WORD ?								;Battery level
//8		ADCWaterTemp	WORD ?								;Water temperature
//10	ADCAirTemp		WORD ?								;Air temperature
//12	iTime			DWORD ?								;UTC Dos file time. 2 seconds resolution
//16	iLon			DWORD ?								;Longitude, integer
//20	iLat			DWORD ?								;Latitude, integer
//24	iSpeed			WORD ?								;Speed in kts
//26	iBear			WORD ?								;Degrees
//SONARREPLAY ends

//SATELITE struct (6*12 bytes = 72 bytes)
//	SatelliteID			BYTE ?								;Satellite ID
//	Elevation			BYTE ?								;Elevation in degrees (0-90)
//	Azimuth				WORD ?								;Azimuth in degrees (0-359)
//	SNR					BYTE ?								;Signal strength	(0-50, 0 not tracked) 
//	Fixed				BYTE ?								;TRUE if used in fix
//SATELITE ends

//ALTITUDE struct (10 bytes)
//	fixquality			BYTE ?								;Fix quality
//	nsat				BYTE ?								;Number of satellites tracked
//	hdop				WORD ?								;Horizontal dilution of position * 10
//	vdop				WORD ?								;Vertical dilution of position * 10
//	pdop				WORD ?								;Position dilution of position * 10
//	alt					WORD ?								;Altitude in meters
//ALTITUDE ends

	public static void TraslateFromByteArray() {
		int i;
		sc.ADCBattery = (short)(((short)(replayarray[6]) & 0xFF) | ((short)(replayarray[7] << 8) & 0xFF00));
		sc.ADCWaterTemp = (short)(((short)(replayarray[8]) & 0xFF) | ((short)(replayarray[9] << 8) & 0xFF00));
		sc.ADCAirTemp = (short)(((short)(replayarray[10]) & 0xFF) | ((short)(replayarray[11] << 8) & 0xFF00));
		sc.iTime = (((int)replayarray[15] << 24) & 0xFF000000) | (((int)replayarray[14] << 16) & 0x00FF0000) | (((int)replayarray[13] << 8) & 0x0000FF00) | (((int)replayarray[12]) & 0x000000FF);
		sc.iLon = (((int)replayarray[19] << 24) & 0xFF000000) | (((int)replayarray[18] << 16) & 0x00FF0000) | (((int)replayarray[17] << 8) & 0x0000FF00) | (((int)replayarray[16]) & 0x000000FF);
		if (sc.iLon < 12912960) {
			sc.iLon = 12912960;
		} else if (sc.iLon > 14670640) {
			sc.iLon = 14670640;
		}
		sc.iLat = (((int)replayarray[23] << 24) & 0xFF000000) | (((int)replayarray[22] << 16) & 0x00FF0000) | (((int)replayarray[21] << 8) & 0x0000FF00) | (((int)replayarray[20]) & 0x000000FF);
		if (sc.iLat < 65967385) {
			sc.iLat = 65967385;
		} else if (sc.iLat > 66533650) {
			sc.iLat = 66533650;
		}
		sc.iSpeed = (short)(((short)(replayarray[24]) & 0xFF) | ((short)(replayarray[25] << 8) & 0xFF00));
		sc.iBear = (short)(((short)(replayarray[26]) & 0xFF) | ((short)(replayarray[27] << 8) & 0xFF00));
		sc.fixquality = replayarray[28 + 72];
		sc.nsat = replayarray[28 + 72 + 1];
		sc.hdop = (short)(((short)(replayarray[28 + 72 + 2]) & 0xFF) | ((short)(replayarray[28 + 72 + 3] << 8) & 0xFF00));
		sc.vdop = (short)(((short)(replayarray[28 + 72 + 4]) & 0xFF) | ((short)(replayarray[28 + 72 + 5] << 8) & 0xFF00));
		sc.pdop = (short)(((short)(replayarray[28 + 72 + 6]) & 0xFF) | ((short)(replayarray[28 + 72 + 7] << 8) & 0xFF00));
		sc.alt = (short)(((short)(replayarray[28 + 72 + 8]) & 0xFF) | ((short)(replayarray[28 + 72 + 9] << 8) & 0xFF00));
		i = 0;
		while (i < 12) {
			sc.sat[i].SatelliteID = replayarray[28 + i * 6];
			sc.sat[i].Elevation = replayarray[28 + i * 6 + 1];
			sc.sat[i].Azimuth = (short)(((short)(replayarray[28 + i * 6 + 2]) & 0xFF) | ((short)(replayarray[28 + i * 6 + 3] << 8) & 0xFF00));
			sc.sat[i].SNR = replayarray[28 + i * 6 + 4];
			sc.sat[i].Fixed = replayarray[28 + i * 6 + 5];
			i++;
		}
		i = 0;
		while (i < SONARTILEHEIGHT) {
			sc.sonar[i] = replayarray[i + SONAROFFSET];
			i++;
		}
	}

	public static void SonarShow() {
		int i, year, month, day, hh, mm, ss;
		year = (sc.iTime >> 25) + 2000;
		month = (sc.iTime >> 21) & 0x0F;
		day = (sc.iTime >> 16) & 0x1F;
		hh = (sc.iTime >> 11) & 0x1F;
		mm = (sc.iTime >> 5) & 0x3F;
		ss = (sc.iTime << 1) & 0x3F;
		curtime = ("0" + day).substring(("0" + day).length() - 2) + "." + ("0" + month).substring(("0" + month).length() - 2) + "." + year + " ";
		curtime += ("0" + hh).substring(("0" + hh).length() - 2) + ":" + ("0" + mm).substring(("0" + mm).length() - 2) + ":" + ("0" + ss).substring(("0" + ss).length() - 2);
		curbatt = (float)sc.ADCBattery / 174f;
		curwtemp = -(float)(sc.ADCWaterTemp - 2500) / 52.5f;
		i = 0;
		while (AirTempArray[i + 1] > 0) {
			if (sc.ADCAirTemp < AirTempArray[i]) {
				break;
			}
			i += 2;
		}
		if (i == 0) {
			curatemp = 0;
		} else {
			curatemp = ((float)(AirTempArray[i - 1]) - ((float)(AirTempArray[i - 1] - AirTempArray[i + 1]) / (float)(AirTempArray[i] - AirTempArray[i - 2])) * (float)(sc.ADCAirTemp - AirTempArray[i - 2])) / 10f;
		}
		curbearing = sc.iBear;
		curspeed = sc.iSpeed;
		curfix = sc.fixquality;
		GoTo((double)sc.iLat / 1000000d, (double)sc.iLon / 1000000d, locktogps);
		UpdateSonarBitmap();
		// Update trail
		i = trailhead;
		i--;
		i &= MAPMAXTRAIL - 1;
		if ((trail[i * 3 + 2] != sc.iBear && sc.iSpeed > tracksmoothing) || trailpoints < 2) {
			trail[trailhead * 3] = sc.iLat;
			trail[trailhead * 3 + 1] = sc.iLon;
			trail[trailhead * 3 + 2] = sc.iBear;
			trailhead++;
			trailhead &= MAPMAXTRAIL - 1;
			if (trailhead == trailtail) {
				trailtail++;
				trailtail &= MAPMAXTRAIL - 1;
			}
			trailpoints++;
		} else {
			trail[i * 3] = sc.iLat;
			trail[i * 3 + 1] = sc.iLon;
			trail[i * 3 + 2] = sc.iBear;
		}
		if (locktogps == false) {
			sonarofs++;
		}
//		Log.d("MYTAG", "Trailpoints: " + trailpoints);
	}

	public static void SonarReplay(RandomAccessFile replayfile) {
		int nBytes;
		try {
			nBytes = replayfile.read(replayarray);
			if (nBytes == SONARARRAYSIZE) {
				if (replayarray[SONAROFFSET] >= 0 && replayarray[SONAROFFSET] < MAXSONARRANGE) {
					TraslateFromByteArray();
					SonarShow();
				}
				BoatNav.replayfilepos += nBytes;
			} else {
				if (BoatNav.btconnected) {
					mode = 0;
				} else {
					mode = 1;
				}
				replayfile.close();
	        	ClearTrail();
			}
		} catch (Exception e) {
			try {
				mode = 1;
				replayfile.close();
	        	ClearTrail();
			} catch (Exception e1) {
			}
		}
	}

	public static void SonarClear() {
		int i=0;
		while (i < MyIV.MAXSONARBMP) {
			if (MyIV.sonarbmp[i] != null) {
				MyIV.sonarbmp[i].recycle();
				MyIV.sonarbmp[i] = null;
			}
			MyIV.sonarbmp[i] =  Bitmap.createBitmap(MyIV.SONARTILEWIDTH, MyIV.SONARTILEHEIGHT, Bitmap.Config.ARGB_8888);
			MyIV.sonarbmp[i].eraseColor(MyIV.sonarColor);
			MyIV.sonarbmpwidth[i] = MyIV.SONARTILEWIDTH;
			MyIV.sonarbmprange[i] = 0;
			MyIV.sonarbmplat[i] = 0;
			MyIV.sonarbmplon[i] = 0;
			i++;
		}
		i = 0;
		while (i < MyIV.MAXFISH) {
			MyIV.fisharray[0][i] = 0;
			MyIV.fisharray[1][i] = 0;
			MyIV.fisharray[2][i] = 0;
			MyIV.fisharray[3][i] = 0;
			i++;
		}
    }

	private static void ScrollFish() {
		int inx = 0;
		while (inx < MAXFISH) {
			fisharray[1][inx]++;
			inx++;
		}
	}

	private static void AddFish (int depthinx, int size) {
		int dist = 300;
		if (fisharray[0][fisharrayinx] != 0) {
			// Should be adjusted according to range
			dist = Math.abs(depthinx - fisharray[2][fisharrayinx]); // y
			dist += fisharray[1][fisharrayinx];	// x
		}
		if (dist > 60) {
			fisharrayinx++;
			fisharrayinx &= MAXFISH - 1;
			fisharray[0][fisharrayinx] = size;
			fisharray[1][fisharrayinx] = 0;
			fisharray[2][fisharrayinx] = depthinx;
			fisharray[3][fisharrayinx] = sonarrangeinx;
			playfishalarm = true;
		}
	}

	private static void FindFish(int depthstartinx, int depthinx) {
		int y, ymax;
		int sum = 0;
		y = depthinx;
		// Skip bottom vegetation
		while (y > depthstartinx) {
			sum =((int)echoarray[0][y]) & 0xFF;
			sum +=((int)echoarray[1][y]) & 0xFF;
			sum +=((int)echoarray[2][y]) & 0xFF;
			sum +=((int)echoarray[3][y]) & 0xFF;
			if (sum < sonarnoiselevel * 4) {
				break;
			}
			y--;
		}
		ymax = y;
		y = depthstartinx;
		while (y < ymax) {
			if ((((int)echoarray[0][y]) & 0xFF) > sonarnoiselevel + 96) {
				switch (sonarfishdetect) {
				case 1:
					// Hard 3 x 4
					sum =((int)echoarray[0][y]) & 0xFF;
					sum +=((int)echoarray[1][y]) & 0xFF;
					sum +=((int)echoarray[2][y]) & 0xFF;
					sum +=((int)echoarray[3][y]) & 0xFF;
					sum +=((int)echoarray[0][y+1]) & 0xFF;
					sum +=((int)echoarray[1][y+1]) & 0xFF;
					sum +=((int)echoarray[2][y+1]) & 0xFF;
					sum +=((int)echoarray[3][y+1]) & 0xFF;
					sum +=((int)echoarray[0][y+2]) & 0xFF;
					sum +=((int)echoarray[1][y+2]) & 0xFF;
					sum +=((int)echoarray[2][y+2]) & 0xFF;
					sum +=((int)echoarray[3][y+2]) & 0xFF;
					if (sum > BIGFISH * 3) {
						AddFish(y, 2);
					} else if (sum > SMALLFISH * 3) {
						AddFish(y, 1);
					}
			    	break;
				case 2:
					// Medium 2 x 4
					sum =((int)echoarray[0][y]) & 0xFF;
					sum +=((int)echoarray[1][y]) & 0xFF;
					sum +=((int)echoarray[2][y]) & 0xFF;
					sum +=((int)echoarray[3][y]) & 0xFF;
					sum +=((int)echoarray[0][y+1]) & 0xFF;
					sum +=((int)echoarray[1][y+1]) & 0xFF;
					sum +=((int)echoarray[2][y+1]) & 0xFF;
					sum +=((int)echoarray[3][y+1]) & 0xFF;
					if (sum > BIGFISH * 2) {
						AddFish(y, 2);
					} else if (sum > SMALLFISH * 2) {
						AddFish(y, 1);
					}
			    	break;
				case 3:
					// Easy 1 x 4
					sum =((int)echoarray[0][y]) & 0xFF;
					sum +=((int)echoarray[1][y]) & 0xFF;
					sum +=((int)echoarray[2][y]) & 0xFF;
					sum +=((int)echoarray[3][y]) & 0xFF;
					if (sum > BIGFISH * 1) {
						AddFish(y, 2);
					} else if (sum > SMALLFISH * 1) {
						AddFish(y, 1);
					}
			    	break;
				}
			}
			y++;
		}
	}

	private static void FindDepth() {
		int y, depthstartinx, depthinx, maxsum, sum;
		if (echoarraycount >= 4) {
			y = range[sonarrangeinx].mindepth;
			while (y < 256) {
				sum =((int)echoarray[0][y]) & 0xFF;
				sum +=((int)echoarray[1][y]) & 0xFF;
				sum +=((int)echoarray[2][y]) & 0xFF;
				sum +=((int)echoarray[3][y]) & 0xFF;

				sum +=((int)echoarray[0][y+1]) & 0xFF;
				sum +=((int)echoarray[1][y+1]) & 0xFF;
				sum +=((int)echoarray[2][y+1]) & 0xFF;
				sum +=((int)echoarray[3][y+1]) & 0xFF;

				sum +=((int)echoarray[0][y+2]) & 0xFF;
				sum +=((int)echoarray[1][y+2]) & 0xFF;
				sum +=((int)echoarray[2][y+2]) & 0xFF;
				sum +=((int)echoarray[3][y+2]) & 0xFF;

				sum +=((int)echoarray[0][y+3]) & 0xFF;
				sum +=((int)echoarray[1][y+3]) & 0xFF;
				sum +=((int)echoarray[2][y+3]) & 0xFF;
				sum +=((int)echoarray[3][y+3]) & 0xFF;
				if (sum < 256) {
					y += 4;
					break;
				}
				y++;
			}
			depthstartinx = y;
			maxsum = 0;
			depthinx = 0;
			if (y < 256) {
				while (y < 508) {
					// sum 4x4 echoes
					sum =((int)echoarray[0][y]) & 0xFF;
					sum +=((int)echoarray[1][y]) & 0xFF;
					sum +=((int)echoarray[2][y]) & 0xFF;
					sum +=((int)echoarray[3][y]) & 0xFF;

					sum +=((int)echoarray[0][y+1]) & 0xFF;
					sum +=((int)echoarray[1][y+1]) & 0xFF;
					sum +=((int)echoarray[2][y+1]) & 0xFF;
					sum +=((int)echoarray[3][y+1]) & 0xFF;

					sum +=((int)echoarray[0][y+2]) & 0xFF;
					sum +=((int)echoarray[1][y+2]) & 0xFF;
					sum +=((int)echoarray[2][y+2]) & 0xFF;
					sum +=((int)echoarray[3][y+2]) & 0xFF;

					sum +=((int)echoarray[0][y+3]) & 0xFF;
					sum +=((int)echoarray[1][y+3]) & 0xFF;
					sum +=((int)echoarray[2][y+3]) & 0xFF;
					sum +=((int)echoarray[3][y+3]) & 0xFF;
					
					if (sum > maxsum + 512) {
						maxsum = sum;
						depthinx = y;
					}

					y++;
				}
			}
			if (depthinx != 0) {
				nodepth = false;
				curdepth = (float)((float)depthinx / 512f * (float)cursonarrange);
				if (sonarfishdetect != 0) {
					// Find fish
					FindFish(depthstartinx, depthinx);
				}
				if ((int)(curdepth * 10) <= sonarshallow) {
					playshallowalarm = true;
				} else {
					playshallowalarm = false;
					shallowalarm = false;
				}
				if ((int)(curdepth) >= sonardeep) {
					playdeepalarm = true;
				} else {
					playdeepalarm = false;
					deepalarm = false;
				}
			} else {
				nodepth = true;
			}
		}
	}

	private static void UpdateSonarBitmap() {
		int x, y, z, col, signal;
		int[] bmparray;

		sonarsignalbmp.eraseColor(sonarColor);
        Canvas canvas = new Canvas(sonarsignalbmp);
        paint.setColor(0xFF000080);
        paint.setStrokeWidth(1);
        canvas.drawBitmap(sonarsignalbmp, 0, 0, paint);
        if (sonarrangeinx != (int)sc.sonar[0]) {
        	// Clear echo array
        	z = 0;
        	while (z < 4) {
        		y = 0;
        		while (y < SONARTILEHEIGHT) {
        			echoarray[z][y] = 0;
        			y++;
        		}
        		z++;
        	}
        	echoarraycount = 0;
        }
        sonarrangeinx = (int)sc.sonar[0];
		cursonarrange = range[sonarrangeinx].range;
	    bmparray = new int[SONARTILEWIDTH*SONARTILEHEIGHT];
	    if (sonarbmpwidth[sonarbmpinx] == SONARTILEWIDTH || cursonarrange != sonarbmprange[sonarbmpinx]) {
	    	sonarbmpinx++;
	    	if (sonarbmpinx == MAXSONARBMP) {
	    		sonarbmpinx = 0;
	    	}
	    	sonarbmpwidth[sonarbmpinx] = 0;
	    	sonarbmprange[sonarbmpinx] = cursonarrange;
	    }
    	sonarbmplat[sonarbmpinx] = sc.iLat;
    	sonarbmplon[sonarbmpinx] = sc.iLon;
	    sonarbmp[sonarbmpinx].getPixels(bmparray,0,SONARTILEWIDTH,0,0,SONARTILEWIDTH,SONARTILEHEIGHT);
	    x = sonarbmpwidth[sonarbmpinx];
	    echoarrayinx++;
	    echoarrayinx &= 3;
	    echoarraycount++;
	    y = 0;
	    while (y < SONARTILEHEIGHT) {
	    	if (echoarraycount == 1) {
		    	echoarray[0][y] = sc.sonar[y];
		    	echoarray[1][y] = sc.sonar[y];
		    	echoarray[2][y] = sc.sonar[y];
		    	echoarray[3][y] = sc.sonar[y];
	    	} else {
		    	echoarray[echoarrayinx][y] = sc.sonar[y];
	    	}
		    signal = ((int)sc.sonar[y]) & 0xFF;
		    if (signal >= 8) {
		    	/* Signal bar */
		        canvas.drawLine(0, y, signal / 8, y, paint);
		    }
		    col = sonarColor;
		    if (y > 3) {
			    switch (sonarnoisereject) {
			    case 1:
			    	z = (echoarrayinx - 1) & 3;
			    	if (((int)echoarray[z][y] & 0xFF) <= sonarnoiselevel) {
			    		signal = 0;
			    	}
			    	break;
			    case 2:
			    	z = (echoarrayinx - 1) & 3;
			    	if (((int)echoarray[z][y] & 0xFF) <= sonarnoiselevel) {
			    		signal = 0;
			    	}
			    	z = (echoarrayinx - 2) & 3;
			    	if (((int)echoarray[z][y] & 0xFF) <= sonarnoiselevel) {
			    		signal = 0;
			    	}
			    	break;
			    case 3:
			    	z = (echoarrayinx - 1) & 3;
			    	if (((int)echoarray[z][y] & 0xFF) <= sonarnoiselevel) {
			    		signal = 0;
			    	}
			    	z = (echoarrayinx - 2) & 3;
			    	if (((int)echoarray[z][y] & 0xFF) <= sonarnoiselevel) {
			    		signal = 0;
			    	}
			    	z = (echoarrayinx - 3) & 3;
			    	if (((int)echoarray[z][y] & 0xFF) <= sonarnoiselevel) {
			    		signal = 0;
			    	}
			    	break;
			    }
		    }
		    if (signal > sonarnoiselevel) {
		    	col = sonarColorArray[signal];
		    }
		    z = (y * SONARTILEWIDTH) + x;
	    	bmparray[z] = col;
	    	y++;
	    }
	    sonarbmp[sonarbmpinx].setPixels(bmparray, 0, SONARTILEWIDTH, 0, 0, SONARTILEWIDTH, SONARTILEHEIGHT);
	    sonarbmpwidth[sonarbmpinx]++;
	    ScrollFish();
	    FindDepth();
	    sonarcount++;
	}

	// Convert latitude and longitude to a position on the max zoomed map
	public static void GpsPosToMapPos(double lat, double lon) {
		double fmpx, fmpy;
		int i;
		// Get the map y position
		fmpy=0;
		i=0;
		while (lat<=latarray[i] && i < MAPTILESIZE) {
			i = i + 1;
			fmpy = fmpy + MAPTILESIZE;
		}
		fmpy = (latarray[i-1] - lat)  * MAPTILESIZE / (latarray[i-1] - latarray[i]) + fmpy - MAPTILESIZE;
		mpy = (int)fmpy;
		// Get the map x position
		fmpx = ((maxtilex[MAPMAXZOOM] * MAPTILESIZE) / (right - left))*(lon - left);
		mpx = (int)fmpx;
	}
	
	// Converts map pos to screen pos using current zoom
	public static void MapPosToScrnPos() {
		spy = mpy / (int)Math.pow(2, MAPMAXZOOM-zoom);
		spx = mpx / (int)Math.pow(2, MAPMAXZOOM-zoom);
	}

	// Converts screen pos to cursor pos using current offset
	public static void ScrnPosToCurPos() {
		cpx = (int)(spx + xofs);
		cpy = (int)(spy + yofs);
	}

	public static void GoTo(double lat, double lon, boolean lock) {
		prvlat = curlat;
		prvlon = curlon;
		curlat = lat;
		curlon = lon;
		// Update distance
		if ((trailpoints >= 2) && (prvlat != curlat || prvlon != curlon)) {
			distance += GPSClass.Distance(prvlat, prvlon, curlat, curlon);
		}
		GpsPosToMapPos(lat, lon);
		MapPosToScrnPos();
		if (lock) {
			yofs = -spy + scrnht/2;
			xofs = -spx + mapwt/2;
		}
	}

	public  static void MapPosToGpsPos() {
		int i;
		double dlat, dlon;
		if (mpx < 0) {
			mpx = 0;
		}
		if (mpx >= maxtilex[MAPMAXZOOM] * MAPTILESIZE) {
			mpx = maxtilex[MAPMAXZOOM] * MAPTILESIZE -1;
		}
		if (mpy < 0) {
			mpy = 0;
		}
		if (mpy >= maxtiley[MAPMAXZOOM] * MAPTILESIZE) {
			mpy = maxtiley[MAPMAXZOOM] * MAPTILESIZE -1;
		}
		// Longitude
		dlon = (right - left) / (maxtilex[MAPMAXZOOM] * MAPTILESIZE);
		curlon = left + dlon * mpx;
		// Latitude
		i = mpy / MAPTILESIZE;
		dlat = (latarray[i+1] - latarray[i]) / MAPTILESIZE;
		curlat = latarray[i] + dlat  * (mpy - i * MAPTILESIZE);
	}

	public static void ScrnPosToMapPos() {
		mpx = spx * (int)Math.pow(2, MAPMAXZOOM-zoom);
		mpy = spy * (int)Math.pow(2, MAPMAXZOOM-zoom);
	}

	public static void CurPosToScrnPos() {
		spx = cpx - (int)xofs;
		spy = cpy - (int)yofs;
	}

	public static boolean Zoom(int zoomadd) {
		int z, i;
		z = zoom + zoomadd;
		if (z > 0 && z <= MAPMAXZOOM) {
			zoom=z;
			for(i = 0; i < MAPMAXBMP; i = i + 1) {
				BoatNav.bmp[i].inuse=0;
				BoatNav.bmp[i].tilex=-1;
				BoatNav.bmp[i].tiley=-1;
			}
			if (zoomadd == 1) {
				xofs = xofs * 2f - scrnwt / 2f;
				yofs = yofs * 2f - scrnht / 2f;
			} else if (zoomadd == -1) {
				xofs = xofs / 2f + scrnwt / 4f;
				yofs = yofs / 2f + scrnht / 4f;
			}
			return true;
		}
		return false;
	}

	private String GetFileName(int tilex, int tiley) {
		String filename = "";
		if (tilex >= 0 && tilex < maxtilex[zoom] && tiley >= 0 && tiley < maxtiley[zoom]) {
			if (land == true) {
				filename = "LandX" + zoom + File.separator + "Land";
			} else {
				filename = "SeaX" + zoom + File.separator + "Sea";
			}
			filename = path + filename + String.format("%02X", 0xFF & tiley) + String.format("%02X", 0xFF & tilex) + ".jpg";
		}
		return filename;
	}

	private void ClearInUse(int lefttile, int toptile) {
		int i;
		for(i = 0; i < MAPMAXBMP; i++) {
			if (BoatNav.bmp[i].tilex < lefttile || BoatNav.bmp[i].tilex >= lefttile + 3 || BoatNav.bmp[i].tiley < toptile || BoatNav.bmp[i].tiley >= toptile + 3) {
				BoatNav.bmp[i].inuse=0;
			}
		}
	}

	private int FindFreeBmp() {
		int i;
		for(i = 0; i < MAPMAXBMP; i = i + 1) {
			if (BoatNav.bmp[i].inuse == 0 && BoatNav.bmp[i].tilex == -1) {
				return i;
			}
		}
		for(i = 0; i < MAPMAXBMP; i = i + 1) {
			if (BoatNav.bmp[i].inuse == 0) {
				return i;
			}
		}
		return -1;
	}

	private int FindBmp(int tilex, int tiley) {
		int i;
		for(i = 0; i < MAPMAXBMP; i = i + 1) {
			if (BoatNav.bmp[i].tilex == tilex && BoatNav.bmp[i].tiley == tiley) {
				return i;
			}
		}
		return -1;
	}

	private Bitmap GetBitmap(int tilex, int tiley) {
		String filename;
		Bitmap bm = null;
		int i;
		
		i=FindBmp(tilex, tiley);
		if (i>=0) {
			BoatNav.bmp[i].inuse = 1;
			bm = BoatNav.bmp[i].bm;
		} else {
			filename = GetFileName(tilex, tiley);
			if (filename != "") {
				bm = BitmapFactory.decodeFile(filename);
				i=FindFreeBmp();
				if (i>=0) {
					if (BoatNav.bmp[i].tilex != -1) {
						BoatNav.bmp[i].bm.recycle();
					}
					BoatNav.bmp[i].inuse = 1;
					BoatNav.bmp[i].tilex = tilex;
					BoatNav.bmp[i].tiley = tiley;
					BoatNav.bmp[i].bm = bm;
				}
			} else {
				bm = BoatNav.mGrayBitmap;
			}
		}
		return bm;
	}

	public static void ClearTrail() {
		trailhead = 0;
		trailtail = 0;
		trailpoints = 0;
		distance = 0;
	}

	private void DrawTrail(Canvas canvas) {
		if (showtrail) {
			int i = trailtail;
			int iLat, iLon, x, y;
			if (i != trailhead) {
				paint.setColor(Color.DKGRAY);
				paint.setStrokeWidth(2);
				iLat = trail[i * 3];
				iLon = trail[i * 3 +1];
				GpsPosToMapPos((double)((double)iLat / 1000000), (double)((double)iLon / 1000000));
				MapPosToScrnPos();
				ScrnPosToCurPos();
				x = cpx;
				y = cpy;
				while (i != trailhead) {
					i++;
					i &= MAPMAXTRAIL - 1;
					if (i != trailhead) {
						iLat = trail[i * 3];
						iLon = trail[i * 3 + 1];
						GpsPosToMapPos((double)((double)iLat / 1000000), (double)((double)iLon / 1000000));
						MapPosToScrnPos();
						ScrnPosToCurPos();
				        canvas.drawLine(x, y, cpx, cpy, paint);
						x = cpx;
						y = cpy;
					}
				}
			}
		}
	}

	private void DrawText(int x, int y, int size, String text, Canvas canvas) {
		
		paint.setTextSize(size);
		paint.setColor(Color.WHITE);
		canvas.drawText(text, x-2, y-2, paint);
		canvas.drawText(text, x-1, y-2, paint);
		canvas.drawText(text, x+1, y-2, paint);
		canvas.drawText(text, x+2, y-2, paint);
		canvas.drawText(text, x-2, y+2, paint);
		canvas.drawText(text, x-1, y+2, paint);
		canvas.drawText(text, x+1, y+2, paint);
		canvas.drawText(text, x+2, y+2, paint);
		paint.setColor(Color.BLACK);
		canvas.drawText(text, x, y, paint);
	}

	private String GetItem() {
		String item = "";
		int x;
		try {
			x = rngticks.indexOf(0x2c);
			if (x >= 0) {
				item = rngticks.substring(0,x);
				rngticks = rngticks.substring(x+1);
			} else {
				item = rngticks;
				rngticks = "";
			}
		} catch (Exception e) {
	        Log.e("MYTAG", "Item error: " + e.toString());
		}
		return item;
	}

	private void DrawSonarRangeBarTick(int y, int width, Canvas canvas) {
        canvas.drawLine(mapwt + sonarwt - SONARRANGEBARWIDTH + 3 - width / 2, y, mapwt + sonarwt - SONARRANGEBARWIDTH+3 + width / 2, y, paint);
	}
	
	private void DrawSonarRangeBar(int size, int color, Canvas canvas) {
		String item;
		int nticks, i;
		float tickdist;
		paint.setColor(color);
		paint.setStrokeWidth(size);
		paint.setTextAlign(Paint.Align.CENTER);
        canvas.drawLine(mapwt + sonarwt - SONARRANGEBARWIDTH + 3, 0, mapwt + sonarwt - SONARRANGEBARWIDTH + 3, scrnht, paint);

        rngticks = range[sonarrangeinx].scale;
        nticks= range[sonarrangeinx].nticks;
        tickdist = (float)scrnht / (float)(nticks - 1);
        if (color == Color.WHITE) {
            DrawSonarRangeBarTick(1, 12, canvas);
            i = 1;
            while (i < nticks) {
                DrawSonarRangeBarTick((int)(tickdist * (float)i), 12, canvas);
            	i++;
            }
        } else {
            DrawSonarRangeBarTick(1, 10, canvas);
            i = 0;
            while (i < nticks) {
                DrawSonarRangeBarTick((int)(tickdist * (float)i), 10, canvas);
                item = GetItem();
                if (i == 0) {
                    DrawText(mapwt + sonarwt - SONARRANGEBARWIDTH + 3, 20, 15, item, canvas);
                } else {
                    DrawText(mapwt + sonarwt - SONARRANGEBARWIDTH + 3, (int)(tickdist * (float)i) - 8, 15, item, canvas);
                }
            	i++;
            }
        }
	}

	private void DrawSonarFish(Canvas canvas) {
		int inx = 0;
		int x, y;
		float fishdepth;
		while (inx < MAXFISH) {
			if (fisharray[0][inx] != 0) {
				x = scrnwt - SONARRANGEBARWIDTH - fisharray[1][inx] + sonarofs;
		    	if (x > mapwt -10) {
					fishdepth = (float)((float)fisharray[2][inx] / 512f * (float)range[fisharray[3][inx]].range);
					y = (int)((fishdepth / (float)cursonarrange) * (float)scrnht);
			    	if (y < scrnht + 10) {
						// Draw fish icon
						if (sonarfishicon) {
							canvas.drawBitmap(BoatNav.bmp[MAPMAXBMP + 1 + 8 + fisharray[0][inx]].bm, x - 8, y - 8, null);
							y -= 10;
						}
						if (sonarfishdepth) {
							paint.setTextAlign(Paint.Align.CENTER);
							DrawText(x, y, 10, String.format("%.0f",fishdepth), canvas);
						}
			    	}
		    	}
			}
			inx++;
		}
	}

	private void DrawCursor(Canvas canvas, int x, int y, int angle) {
		Matrix matrix = new Matrix();
		matrix.postRotate(angle);
		Bitmap rotated = Bitmap.createBitmap(BoatNav.bmp[MAPMAXBMP].bm,0,0,16,16,matrix,true);
		canvas.drawBitmap(rotated, x-(rotated.getWidth()/2), y-(rotated.getHeight()/2), null);
	}

	private void DrawMap(Canvas canvas) {
		int tilex, tiley, index;
		float x, y;
		int lefttile = (int)(((-xofs)) / MAPTILESIZE);
		int toptile = (int)(((-yofs)) / MAPTILESIZE);
		
		if (xofs > 0) {
			lefttile--;
		}
		if (yofs > 0) {
			toptile--;
		}
		if (sonarwt !=0) {
			canvas.clipRect(0, 0, mapwt-1, scrnht);
		} else {
			canvas.clipRect(0, 0, mapwt, scrnht);
		}
		ClearInUse(lefttile, toptile);
		y = yofs + toptile * MAPTILESIZE;
		tiley = toptile;
		while (y < scrnht) {
			x = xofs + lefttile * MAPTILESIZE;
			tilex = lefttile;
			while (x < mapwt) {
			    try {
			    	if (tilex < 0 || tiley < 0) {
						canvas.drawBitmap(BoatNav.mGrayBitmap, x, y, null);
			    	} else {
						canvas.drawBitmap(GetBitmap(tilex, tiley), x, y, null);
			    	}
			    } catch(Exception e) {
			    	Log.e("MYTAG", "drawBitmap:");
			    	Log.e("MYTAG", "lefttile: " + lefttile);
			    	Log.e("MYTAG", "toptile: " + toptile);
			    	Log.e("MYTAG", "tilex: " + tilex);
			    	Log.e("MYTAG", "tiley: " + tiley);
			    }
				x += MAPTILESIZE;
				tilex++;
			}
			y += MAPTILESIZE;
			tiley++;
		}
		paint.setTextAlign(Paint.Align.LEFT);
		// Draw places
		paint.setColor(Color.DKGRAY);
		paint.setTextSize(15);
		index = 0;
		while (index < 16 ) {
			if (BoatNav.placeState[index] != 0) {
				GpsPosToMapPos(BoatNav.placeLat[index], BoatNav.placeLon[index]);
				MapPosToScrnPos();
				ScrnPosToCurPos();
				if (BoatNav.placeIcon[index] != 0) {
					// Draw icon
					canvas.drawBitmap(BoatNav.bmp[MAPMAXBMP + BoatNav.placeIcon[index]].bm, cpx - 8, cpy - 8, null);
					cpx += 10;
				}
				if (((BoatNav.placeState[index]) & 2) != 0 && BoatNav.placeTitle[index] != "") {
					// Draw text
					canvas.drawText(BoatNav.placeTitle[index], cpx, cpy + 4, paint);
				}
			}
			index++;
		}
		DrawTrail(canvas);
		// Draw battery
		DrawText(10, scrnht - 15, 25, String.format("%.1f",(curbatt)) + "V", canvas);
		// Draw air temperature
		paint.setTextAlign(Paint.Align.RIGHT);
		DrawText(mapwt - 10, 30, 25, String.format("%.1f",(curatemp)) + "C", canvas);
		// Draw time
		try {
			sdf.setTimeZone(TimeZone.getTimeZone("UTC"));
		    java.util.Date date = sdf.parse(curtime);
		    sdf.setTimeZone(TimeZone.getDefault());
			DrawText(mapwt - 10, scrnht - 15, 15, sdf.format(date), canvas);
		} catch (java.text.ParseException e) {
			DrawText(mapwt - 10, scrnht - 15, 10, "ERR", canvas);
		}
		// Draw distance
		paint.setTextAlign(Paint.Align.CENTER);
		DrawText(mapwt / 2, 15, 15, String.format("%.0f", distance) + "m", canvas);
		if (!locktogps) {
			if (sonarcurbmpinx >= 0) {
				if (sonarbmplat[sonarcurbmpinx] != 0) {
					GpsPosToMapPos((double)sonarbmplat[sonarcurbmpinx] / 1000000d, (double)sonarbmplon[sonarcurbmpinx] / 1000000d);
					MapPosToScrnPos();
					ScrnPosToCurPos();
					canvas.drawBitmap(BoatNav.bmp[MAPMAXBMP + 13].bm, cpx-8, cpy-8, null);
				}
			}
		}
		// Draw speed and cursor
		if (blink || curfix > 1) {
			GpsPosToMapPos(curlat, curlon);
			MapPosToScrnPos();
			ScrnPosToCurPos();
			paint.setTextAlign(Paint.Align.LEFT);
			// Draw speed and cursor
			DrawText(10, 50, 50, String.format("%.1f",((float)curspeed/10)), canvas);
			DrawCursor(canvas,cpx,cpy,curbearing);
		}
	}

	private void DrawSonar(Canvas canvas) {
		int i;
		int r;
		// Draw sonar range bar
		if (mapwt != 0) {
			canvas.clipRect(mapwt+1, 0, mapwt + sonarwt, scrnht, Region.Op.REPLACE);
		} else {
			canvas.clipRect(0, 0, sonarwt, scrnht, Region.Op.REPLACE);
		}
		// Draw sonar signal strength graph
		srcrect.left = 0;
        srcrect.top =0 ;
        srcrect.right = SONARSIGNALGRAHWIDTH;
        srcrect.bottom = SONARTILEHEIGHT;
        dstrect.left = mapwt + sonarwt - SONARSIGNALGRAHWIDTH;
        dstrect.top = 0;
        dstrect.right = mapwt + sonarwt;
        dstrect.bottom = scrnht;
		canvas.drawBitmap(sonarsignalbmp, srcrect, dstrect, null);
		// Draw sonar data
		if (mapwt != 0) {
			canvas.clipRect(mapwt+1, 0, mapwt + sonarwt - SONARSIGNALGRAHWIDTH, scrnht, Region.Op.REPLACE);
		} else {
			canvas.clipRect(0, 0, sonarwt - SONARSIGNALGRAHWIDTH, scrnht, Region.Op.REPLACE);
		}
		i = sonarbmpinx;
		r = mapwt + sonarwt - SONARRANGEBARWIDTH + sonarofs;
		sonarcurbmpinx = -1;
		while (true) {
			dstrect.right = r;
	        r -= sonarbmpwidth[i];
	        if (r < scrnwt - SONARRANGEBARWIDTH) {
	        	if (sonarcurbmpinx == -1) {
	        		sonarcurbmpinx = i;
	        	}
		        dstrect.left = r;
		        dstrect.top = 0;
		        srcrect.left = 0;
		        srcrect.top =0 ;
		        srcrect.right = sonarbmpwidth[i];
			    if (cursonarrange == sonarbmprange[i]) {
			        dstrect.bottom = scrnht;
			        srcrect.bottom = SONARTILEHEIGHT;
					canvas.drawBitmap(sonarbmp[i], srcrect, dstrect, null);
			    } else if (cursonarrange > sonarbmprange[i]) {
			        dstrect.bottom = scrnht * sonarbmprange[i] / cursonarrange;
			        srcrect.bottom = SONARTILEHEIGHT;
					canvas.drawBitmap(sonarbmp[i], srcrect, dstrect, null);
					dstrect.top = dstrect.bottom;
					dstrect.bottom = scrnht;
			        paint.setColor(sonarColor);
			        paint.setStyle(Style.FILL);
			        canvas.drawRect(dstrect, paint);   
			    } else if (cursonarrange < sonarbmprange[i]) {
			        dstrect.bottom = scrnht;
			        srcrect.bottom = SONARTILEHEIGHT * cursonarrange / sonarbmprange[i];
					canvas.drawBitmap(sonarbmp[i], srcrect, dstrect, null);
			    }
	        }
			i--;
			if (i < 0) {
				i = MAXSONARBMP - 1;
			}
			if (i == sonarbmpinx || r < mapwt) {
				break;
			}
		}
        DrawSonarFish(canvas);
		if (mapwt != 0) {
			canvas.clipRect(mapwt+1, 0, mapwt + sonarwt, scrnht, Region.Op.REPLACE);
		} else {
			canvas.clipRect(0, 0, sonarwt, scrnht, Region.Op.REPLACE);
		}
        DrawSonarRangeBar(6, Color.WHITE,canvas);
        DrawSonarRangeBar(3, Color.BLACK,canvas);
		// Draw sonar range
		paint.setTextAlign(Paint.Align.LEFT);
		DrawText(mapwt + 10, scrnht - 20, 30, String.valueOf(cursonarrange), canvas);
		// Draw depth
		if (nodepth) {
			if (blink) {
				if (curdepth >= 100) {
					DrawText(mapwt + 10, 50, 50, String.format("%.0f",curdepth), canvas);
				} else {
					DrawText(mapwt + 10, 50, 50, String.format("%.1f",curdepth), canvas);
				}
			}
		} else {
			if (curdepth >= 100) {
				DrawText(mapwt + 10, 50, 50, String.format("%.0f",curdepth), canvas);
			} else {
				DrawText(mapwt + 10, 50, 50, String.format("%.1f",curdepth), canvas);
			}
		}
		// Draw water temperature
		DrawText(mapwt + 15, 85, 25, String.format("%.1f",curwtemp) + "C", canvas);
		if (mode == 2)
		{
			// Draw replay progress bar
			i = (int)((float)sonarwt * ((float)BoatNav.replayfilepos / (float)BoatNav.replayfilesize));
			paint.setStrokeWidth(5);
			paint.setColor(Color.WHITE);
	        canvas.drawLine(mapwt, scrnht - 3, scrnwt, scrnht - 3, paint);
			paint.setColor(Color.RED);
	        canvas.drawLine(mapwt, scrnht - 3, mapwt + i, scrnht - 3, paint);
		}
	}

	private void DrawSatelite(Canvas canvas) {
		Bitmap bm = Bitmap.createBitmap(8, 8, Bitmap.Config.ARGB_8888);
		int cx, cy, r, nsat, x, y, s;
		double tmp1, tmp2;
		// Set background
		bm.eraseColor(MyIV.sonarColor);
		canvas.clipRect(0, 0, satelitewt-1, scrnht);
		srcrect.left = 0;
        srcrect.top = 0 ;
		srcrect.right = 8;
        srcrect.bottom = 8;
		dstrect.left = 0;
        dstrect.top = 0 ;
		dstrect.right = satelitewt-1;
        dstrect.bottom = scrnht;
		canvas.drawBitmap(bm, srcrect, dstrect, null);
		// Calculate circle center and radius
		cx = satelitewt / 2;
		if (scrnwt > scrnht) {
			cy = cx - 70;
			r = satelitewt / 2 - 100;
		} else {
			cy = cx + 30;
			r = satelitewt / 2 - 10;
		}
		// Draw circles and cross hair
		paint.setColor(Color.BLACK);
		paint.setStrokeWidth(1);
		paint.setStyle(Paint.Style.STROKE);
		canvas.drawCircle(cx, cy, r, paint);
		canvas.drawCircle(cx, cy, r / 2, paint);
		canvas.drawLine(cx - r, cy, cx + r, cy, paint);
		canvas.drawLine(cx, cy - r, cx, cy + r, paint);
		canvas.drawBitmap(BoatNav.bmp[MAPMAXBMP + 13].bm, cx-8, cy-8, null);
		// Draw speed and cursor
		paint.setTextAlign(Paint.Align.LEFT);
		paint.setStyle(Paint.Style.FILL);
		if (blink || curfix > 1) {
			// Draw speed and cursor
			DrawText(10, 50, 50, String.format("%.1f",((float)curspeed/10)), canvas);
			DrawCursor(canvas,cx,cy,curbearing);
		}
		// Draw air temperature
		paint.setTextAlign(Paint.Align.RIGHT);
		DrawText(mapwt - 10, 30, 25, String.format("%.1f",(curatemp)) + "C", canvas);
		// Draw some info
		paint.setTextAlign(Paint.Align.LEFT);
		paint.setTextSize(15);
		y = scrnht - 115;
		if (sc.fixquality == 2) {
			canvas.drawText("Fix: 2D", 10, y, paint);
		} else if (sc.fixquality == 3) {
			canvas.drawText("Fix: 3D", 10, y, paint);
		} else {
			canvas.drawText("Fix: No fix", 10, y, paint);
		}
		canvas.drawText("Sat: " + sc.nsat, 10, y + 17, paint);

		canvas.drawText("HDOP: " + String.format("%.1f",((float)sc.hdop/10)), 90, y, paint);
		canvas.drawText("VDOP: " + String.format("%.1f",((float)sc.vdop/10)), 90, y + 17, paint);
		canvas.drawText("PDOP: " + String.format("%.1f",((float)sc.pdop/10)), 180, y, paint);
		canvas.drawText("Alt: " + sc.alt, 180, y + 17, paint);
		// Draw satellite signal strength and position
		nsat = 0;
		while (nsat < 12) {
			if (sc.sat[nsat].SatelliteID > 0) {

				paint.setStrokeWidth(1);
				paint.setStyle(Paint.Style.STROKE);
				paint.setColor(Color.WHITE);
				canvas.drawRect(10 + nsat * 24, scrnht - 92, 30 + nsat * 24, scrnht - 40, paint);
				paint.setStyle(Paint.Style.FILL);
				s = 15; // Red
				if (sc.sat[nsat].SNR > 0) {
					if (sc.sat[nsat].Fixed == 1) {
						s = 14; // Green
						paint.setColor(0xFF008200);
					} else {
						s = 16; // Blue
						paint.setColor(Color.BLUE);
					}
					canvas.drawRect(11 + nsat * 24, scrnht - 41 - sc.sat[nsat].SNR, 30 + nsat * 24, scrnht - 41, paint);
				}
				paint.setColor(Color.BLACK);
				paint.setTextAlign(Paint.Align.CENTER);
				paint.setTextSize(15);
				canvas.drawText("" + sc.sat[nsat].SatelliteID, 16 + nsat * 24, scrnht - 20, paint);

				// Get point on circle
				tmp1 = ((90d - (double)sc.sat[nsat].Elevation) * (double)r) / 90d;	// Radius
				tmp2 = Math.toRadians((double)sc.sat[nsat].Azimuth - 90d);			// Angle
				x = cx + (int)(Math.cos(tmp2) * tmp1);
				y = cy + (int)(Math.sin(tmp2) * tmp1);
				paint.setStyle(Paint.Style.FILL);
				canvas.drawBitmap(BoatNav.bmp[MAPMAXBMP + s].bm, x - 8, y - 8, null);
				paint.setColor(Color.WHITE);
				paint.setTextSize(10);
				canvas.drawText("" + sc.sat[nsat].SatelliteID, x, y + 4,paint);
			}
			nsat++;
		}
		// Draw time
		try {
			paint.setTextAlign(Paint.Align.RIGHT);
			sdf.setTimeZone(TimeZone.getTimeZone("UTC"));
		    java.util.Date date = sdf.parse(curtime);
		    sdf.setTimeZone(TimeZone.getDefault());
			DrawText(mapwt - 10, scrnht - 15, 15, sdf.format(date), canvas);
		} catch (java.text.ParseException e) {
			DrawText(mapwt - 10, scrnht - 15, 10, "ERR", canvas);
		}
	}

	public MyIV(Context c) {
		super(c);                                     
	}   

	@Override
	protected void onSizeChanged(int w, int h, int oldw, int oldh) {
		scrnwt = w;
		scrnht = h;
    	switch (viewmode) {
		case 0:
			mapwt = scrnwt;
			sonarwt = 0;
			satelitewt = 0;
			break;
		case 1:
			mapwt = 0;
			satelitewt = 0;
			sonarwt = scrnwt;
			break;
		case 2:
			mapwt = scrnwt / 2;
			satelitewt = 0;
			sonarwt = scrnwt / 2;
			break;
		case 3:
			satelitewt = scrnwt / 2;
			mapwt = scrnwt / 2;
			sonarwt = scrnwt / 2;
			break;
    	}
	}                	      
	
	@Override
	protected void onDraw(Canvas canvas) {
		if (mapwt != 0) {
			if (satelitewt != 0){
				DrawSatelite(canvas);
			} else {
				DrawMap(canvas);
			}
		}
		if (sonarwt != 0) {
			DrawSonar(canvas);
		}
		if (sonarpause) {
			// Pause
			canvas.clipRect(0, 0, scrnwt, scrnht, Region.Op.REPLACE);
			canvas.drawBitmap(BoatNav.bmppause, scrnwt / 2 - 24, scrnht / 2 - 24, paint);
		}
		if (BoatNav.recording && blink) {
			// Recording
			canvas.clipRect(0, 0, scrnwt, scrnht, Region.Op.REPLACE);
			canvas.drawBitmap(BoatNav.bmp[MAPMAXBMP + 13].bm, scrnwt - 24, scrnht - 24, paint);
		}

// Debug
//		canvas.clipRect(0, 0, scrnwt, scrnht, Region.Op.REPLACE);
//		paint.setColor(Color.BLACK);
//		paint.setTextSize(20);
//		paint.setTextAlign(Paint.Align.LEFT);
//		canvas.drawText("Total mem: " + BoatNav.mtot / 1024 + "Kb", 10, 165, paint);
//		canvas.drawText("Free mem:  " + BoatNav.mfree / 1024 + "Kb", 10, 185, paint);
//		canvas.drawText(sTextWait, 10, 185, paint);
//		canvas.drawText(TutorialOnImages.sbtdeviceaddr, 10, 125, paint);
//		sText="Latitude: " + String.format("%.6f",curlat);
//		canvas.drawText(sText, 10, 125, paint);
//		sText="Longitude: " + String.format("%.6f",curlon);
//		canvas.drawText(sText, 10, 145, paint);
//		sText="Bearing: " + curbearing;
//		canvas.drawText(sText, 10, 165, paint);
//		sText="Distance " + GPSClass.Distance(66.317270d,14.196690d,66.268048d,13.724513d);
//		canvas.drawText(sText, 10, 25, paint);
//		sText="Bearing " + bearing;
//		canvas.drawText(sText, 10, 45, paint);
//		sText="Bearing right " + GPSClass.Bearing(66.317270d,14.196690d,66.317270d,13.724513d);
//		canvas.drawText(sText, 10, 65, paint);
//		sText="Bearing down " + GPSClass.Bearing(66.317270d,14.196690d,66.268048d,14.196690d);
//		canvas.drawText(sText, 10, 85, paint);
//		sText="Bearing left " + GPSClass.Bearing(66.317270d,13.724513d,66.317270d,14.196690d);
//		canvas.drawText(sText, 10, 105, paint);
//		sText="Bearing up " + GPSClass.Bearing(66.268048d,14.196690d,66.317270d,14.196690d);
//		canvas.drawText(sText, 10, 125, paint);
//		sText="xofs " + xofs;
//		canvas.drawText(sText, 10, 145, paint);
//		sText="yofs " + yofs;
//		canvas.drawText(sText, 10, 165, paint);
//		sText="mpx " + mpx;
//		canvas.drawText(sText, 10, 185, paint);
//		sText="mpy " + mpy;
//		canvas.drawText(sText, 10, 205, paint);

	}

}
