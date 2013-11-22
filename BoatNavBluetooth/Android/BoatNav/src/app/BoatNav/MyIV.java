package app.BoatNav;

import java.io.File;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
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

import app.BoatNav.GPSClass;
import app.BoatNav.RangeClass;
import app.BoatNav.SonarClass;
import app.BoatNav.BoatNav;;

public class MyIV extends ImageView {

	public static final int MAPMAXBMP = 15;
	public static final int MAPMAXICON = 32;
	public static final int MAPMAXZOOM = 5;
	public static final int MAPTILESIZE = 512;
	public static final int MAPMAXLATARR = 65;
	public static final int MAPMAXTRAIL = 2048;
	public static int scrnwt;
	public static int scrnht;
	public static int mapwt = 0;
	public static int sonarwt = 0;
	public static float xofs = 0;
	public static float yofs = 0;

	public static int mode = 1;
	public static int viewmode = 2;
	public static boolean land = true;
	public static int zoom = 5;
	public static boolean locktogps = true;
	public static boolean showtrail = true;
	public static int tracksmoothing = 5;

	public static String path = Environment.getExternalStorageDirectory() + File.separator + "Map" + File.separator;
	public static int maxtilex[] = {0,5,10,20,40,80};
	public static int maxtiley[] = {0,4,8,16,32,64};
	private static Paint paint = new Paint(Paint.FAKE_BOLD_TEXT_FLAG);
	//MapRect=12.912960,66.533650,14.670640,65.967385
	public static final double left=12.912960d;
	private static final double top=66.533650d;
	public static final double right=14.670640d;
	private static final double bottom=65.967385d;
	private static final double latarray[]={66.533650d,66.524900d,66.516147d,66.507390d,66.498631d,
											66.489868d,66.481102d,66.472333d,66.463561d,66.454786d,
											66.446008d,66.437227d,66.428443d,66.419656d,66.410865d,
											66.402072d,66.393275d,66.384475d,66.375672d,66.366867d,
											66.358058d,66.349245d,66.340430d,66.331612d,66.322791d,
											66.313966d,66.305139d,66.296308d,66.287474d,66.278637d,
											66.269797d,66.260954d,66.252108d,66.243259d,66.234406d,
											66.225551d,66.216692d,66.207830d,66.198966d,66.190098d,
											66.181227d,66.172352d,66.163475d,66.154595d,66.145711d,
											66.136825d,66.127935d,66.119042d,66.110146d,66.101247d,
											66.092345d,66.083439d,66.074531d,66.065619d,66.056705d,
											66.047787d,66.038866d,66.029942d,66.021015d,66.012084d,
											66.003151d,65.994214d,65.985274d,65.976331d,65.967385d};
	private static int mpx;
	private static int mpy;
	private static int spx;
	private static int spy;
	public static int cpx=0;
	public static int cpy=0;
	public static double curlat = 66.317270d;
	public static double curlon = 14.196690d;
	public static double prvlat = 66.317270d;
	public static double prvlon = 14.196690d;
	public static double distance = 0;
	public static int curbearing = 0;
	public static int curspeed = 0;
	public static float curbatt = 12.6f;
	public static float curatemp = 17.2f;
	public static String curtime = "29.10.2013 11:45:04";
	public static int trailpoints = 0;
	public static int trailhead = 0;
	public static int trailtail = 0;
	public static int trail[] = new int[MAPMAXTRAIL * 3];
	public static int AirTempArray[] = {537,500,630,450,737,400,865,350,1015,300,1190,250,1390,200,1600,150,1846,105,2090,65,2510,0};

	public static final int MAXSONARBMP = 128;
	public static final int SONARTILEWIDTH = 32;
	public static final int SONARTILEHEIGHT = 512;
	public static final int SONARSIGNALGRAHWIDTH = 32;
	public static final int SONARRANGEBARWIDTH = SONARSIGNALGRAHWIDTH + 6;
	public static final int MAXSONARRANGE = 20;
	public static final int MAXFISH = 64;
	public static final int SMALLFISH = 96 * 4;
	public static final int BIGFISH = (96 + 64) * 4;
	public static final int SONARARRAYSIZE = 28 + 6 * 12 + 10 + 512;
	public static final int SONAROFFSET = 28 + 6 * 12 + 10;
	public static final SimpleDateFormat sdf = new SimpleDateFormat("dd.MM.yyyy HH:mm:ss");
	public static int sonarColor;

	public static int sonarnoiselevel = 4;
	public static int sonarnoisereject = 2;
	public static int sonarfishdetect = 1;
	public static boolean sonarfishsound = false;
	public static boolean sonarfishdepth = true;
	public static boolean sonarfishicon = true;
	public static int sonarrangeinx = 4;
	public static int sonarrangechange = 0;
	public static int sonarrangechangedir = 1;
	public static boolean sonarautorange = true;

	private static Rect srcrect = new Rect(0,0,0,0);
	private static Rect dstrect =  new Rect(0,0,0,0);
	public static Bitmap[] sonarbmp = new Bitmap[MAXSONARBMP];
	public static Bitmap sonarsignalbmp;
	public static int[] sonarbmpwidth = new int[MAXSONARBMP];
	public static int[] sonarbmprange = new int[MAXSONARBMP];
	public static int sonarofs = 0;
	public static int cursonarrange = 2;
	public static int echoarrayinx = 0;
	public static int echoarraycount = 0;
	public static int sonarcount = 0;

	public static int rndpixdir = 0;
	public static int rndpixmov = 0;
	public static int rndpixdpt = 250;
	public static int rndfishdpt = 0;
	public static int rndfishcount = 0;
	
	public static Byte[][] echoarray = new Byte[4][SONARTILEHEIGHT];
	public static int fisharrayinx = 0;
	public static int[][] fisharray = new int[4][MAXFISH];
	public static float curdepth = 0;
	public static float curwtemp = 12.3f;
	public static boolean nodepth = true;
	public static boolean blink = false;
	private static int sonarbmpinx = 0;
	private static String rngticks;
	public static boolean playfishalarm;
	public static byte[] replayarray = new byte[SONARARRAYSIZE];
	public static SonarClass sc = new SonarClass();
	public static RangeClass[] range = RangeClass.RangeClassSet(MAXSONARRANGE);
	public static String rangestr[] ={"2,60,150,2,0,2,4,6,8,10,13,15,17,19,21,23,25,27,29,31,33,0,8,0,,0.5,,1,,1.5,,2",
								   	  "4,30,150,4,0,4,8,13,17,21,25,29,33,38,42,46,50,54,59,63,67,0,8,0,,1,,2,,3,,4",
								      "6,25,150,6,0,6,13,19,25,31,38,44,50,56,63,69,75,82,88,94,100,0,12,0,,1,,2,,3,,4,,5,,6",
								      "8,20,150,8,0,8,17,25,33,42,50,59,67,75,84,92,100,109,117,125,134,0,16,0,,1,,2,,3,,4,,5,,6,,7,,8",
								      "10,16,150,10,0,10,21,31,42,52,63,73,84,94,105,115,125,136,146,157,167,0,10,0,,2,,4,,6,,8,,10",
								      "14,16,150,14,0,15,29,44,59,73,88,102,117,132,146,161,176,190,205,220,234,0,14,0,,2,,4,,6,,8,,10,,12,,14",
								      "20,16,150,16,0,21,42,63,84,105,125,146,167,188,209,230,251,272,293,314,334,0,8,0,,5,,10,,15,,20",
								      "30,16,150,24,0,31,63,94,125,157,188,220,251,282,314,345,376,408,439,470,502,0,12,0,,5,,10,,15,,20,,25,,30",
								      "40,16,150,32,0,42,84,125,167,209,251,293,334,376,418,460,502,544,585,627,669,0,8,0,,10,,20,,30,,40",
								      "50,16,150,36,0,52,105,157,209,261,314,366,418,470,523,575,627,679,732,784,836,0,10,0,,10,,20,,30,,40,,50",
								      "70,16,150,40,0,73,146,220,293,366,439,512,585,659,732,805,878,951,1024,1098,1171,0,14,0,,10,,20,,30,,40,,50,,60,,70",
								      "100,8,175,48,0,105,209,314,418,523,627,732,836,941,1045,1150,1254,1359,1463,1568,1673,0,10,0,,20,,40,,60,,80,,100",
								      "120,8,200,54,0,125,251,376,502,627,753,878,1004,1129,1254,1380,1505,1631,1756,1882,2007,0,12,0,,20,,40,,60,,80,,100,,120",
								      "150,8,250,60,0,157,314,470,627,784,941,1098,1254,1411,1568,1725,1882,2038,2195,2352,2509,0,15,0,,,30,,,60,,,90,,,120,,,150",
								      "200,8,300,64,0,209,418,627,836,1045,1254,1463,1673,1882,2091,2300,2509,2718,2927,3136,3345,0,10,0,20,40,60,80,100,120,140,160,180,200",
								      "250,8,350,64,0,261,523,784,1045,1307,1568,1829,2091,2352,2613,2875,3136,3345,3345,3345,3345,0,10,0,25,50,75,100,125,150,175,200,225,250",
								      "300,8,425,64,0,314,627,941,1254,1568,1882,2195,2509,2822,3136,3345,3345,3345,3345,3345,3345,0,12,0,,50,,100,,150,,200,,250,,300",
								      "350,8,500,64,0,366,732,1098,1463,1829,2195,2561,2927,3293,3345,3345,3345,3345,3345,3345,3345,0,14,0,,50,,100,,150,,200,,250,,300,,350",
								      "400,8,600,64,0,418,836,1254,1673,2091,2509,2927,3345,3345,3345,3345,3345,3345,3345,3345,3345,0,16,0,,50,,100,,150,,200,,250,,300,,350,,400",
								      "500,8,700,64,0,523,1045,1568,2091,2613,3136,3345,3345,3345,3345,3345,3345,3345,3345,3345,3345,0,20,0,,50,,100,,150,,200,,250,,300,,350,,400,,450,,500"};

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
//	SatelliteID		BYTE ?									;Satellite ID
//	Elevation		BYTE ?									;Elevation in degrees (0-90)
//	Azimuth			WORD ?									;Azimuth in degrees (0-359)
//	SNR				BYTE ?									;Signal strength	(0-50, 0 not tracked) 
//	Fixed			BYTE ?									;TRUE if used in fix
//SATELITE ends

//ALTITUDE struct (10 bytes)
//	fixquality		BYTE ?									;Fix quality
//	nsat			BYTE ?									;Number of satellites tracked
//	hdop			WORD ?									;Horizontal dilution of position * 10
//	vdop			WORD ?									;Vertical dilution of position * 10
//	pdop			WORD ?									;Position dilution of position * 10
//	alt				WORD ?									;Altitude in meters
//ALTITUDE ends

	public static void TraslateFromByteArray() {
		int i;
		sc.ADCBattery = (short)(((short)(replayarray[6]) & 0xFF) | ((short)(replayarray[7] << 8) & 0xFF00));
		sc.ADCWaterTemp = (short)(((short)(replayarray[8]) & 0xFF) | ((short)(replayarray[9] << 8) & 0xFF00));
		sc.ADCAirTemp = (short)(((short)(replayarray[10]) & 0xFF) | ((short)(replayarray[11] << 8) & 0xFF00));
		sc.iTime = (((int)replayarray[15] << 24) & 0xFF000000) | (((int)replayarray[14] << 16) & 0x00FF0000) | (((int)replayarray[13] << 8) & 0x0000FF00) | (((int)replayarray[12]) & 0x000000FF);
		sc.iLon = (((int)replayarray[19] << 24) & 0xFF000000) | (((int)replayarray[18] << 16) & 0x00FF0000) | (((int)replayarray[17] << 8) & 0x0000FF00) | (((int)replayarray[16]) & 0x000000FF);
		sc.iLat = (((int)replayarray[23] << 24) & 0xFF000000) | (((int)replayarray[22] << 16) & 0x00FF0000) | (((int)replayarray[21] << 8) & 0x0000FF00) | (((int)replayarray[20]) & 0x000000FF);
		sc.iSpeed = (short)(((short)(replayarray[24]) & 0xFF) | ((short)(replayarray[25] << 8) & 0xFF00));
		sc.iBear = (short)(((short)(replayarray[26]) & 0xFF) | ((short)(replayarray[27] << 8) & 0xFF00));
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
		curatemp = ((float)(AirTempArray[i - 1]) - ((float)(AirTempArray[i - 1] - AirTempArray[i + 1]) / (float)(AirTempArray[i] - AirTempArray[i - 2])) * (float)(sc.ADCAirTemp - AirTempArray[i - 2])) / 10f;
		curbearing = sc.iBear;
		curspeed = sc.iSpeed;
		GoTo((double)sc.iLat / 1000000d, (double)sc.iLon / 1000000d, locktogps);
		UpdateSonarBitmap();
		// Update trail
		i = trailhead;
		i--;
		i &= MAPMAXTRAIL - 1;
		if ((trail[i * 3 + 2] != sc.iBear && sc.iSpeed >= tracksmoothing) || trailpoints < 2) {
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
		}
		else {
			trail[i * 3] = sc.iLat;
			trail[i * 3 + 1] = sc.iLon;
			trail[i * 3 + 2] = sc.iBear;
		}
		if (locktogps == false)
		{
			sonarofs++;
		}
//		Log.d("MYTAG", "Trailpoints: " + trailpoints);
	}

	public static void SonarReplay(RandomAccessFile replayfile) {
		int nBytes;
		try {
			nBytes = replayfile.read(replayarray);
			if (nBytes == SONARARRAYSIZE) {
				TraslateFromByteArray();
				SonarShow();
			}
			else {
				mode = 1;
				replayfile.close();
	        	ClearTrail();
			}
		}
		catch (Exception e) {
			try {
				mode = 1;
				replayfile.close();
	        	ClearTrail();
			}
			catch (Exception e1) {

			}
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
					}
					else if (sum > SMALLFISH * 3) {
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
					}
					else if (sum > SMALLFISH * 2) {
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
					}
					else if (sum > SMALLFISH * 1) {
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
			y = 16;
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
			}
			else {
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
        		while (y < 512) {
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
	    	sonarbmpinx &= MAXSONARBMP-1;
	    	sonarbmpwidth[sonarbmpinx] = 0;
	    	sonarbmprange[sonarbmpinx] = cursonarrange;
	    }
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
	    	}
	    	else {
		    	echoarray[echoarrayinx][y] = sc.sonar[y];
	    	}
		    signal = ((int)sc.sonar[y]) & 0xFF;
		    if (signal >= 8) {
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
		    	col = 0xFF000000 | (signal << 16) | (signal << 8) | signal;
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
			}
			else if (zoomadd == -1) {
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
			}
			else {
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
		}
		else {
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
			}
			else
			{
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
			}
			else {
				item = rngticks;
				rngticks = "";
			}
		}
		catch (Exception e) {
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
        tickdist = (float)scrnht / (float)nticks;
        if (color == Color.WHITE) {
            DrawSonarRangeBarTick(1, 12, canvas);
            i = 1;
            while (i <= nticks) {
                DrawSonarRangeBarTick((int)(tickdist * (float)i), 12, canvas);
            	i++;
            }
        }
        else {
            DrawSonarRangeBarTick(1, 10, canvas);
            i = 0;
            while (i <= nticks) {
                DrawSonarRangeBarTick((int)(tickdist * (float)i), 10, canvas);
                item = GetItem();
                if (i == 0) {
                    DrawText(mapwt + sonarwt - SONARRANGEBARWIDTH + 3, 20, 15, item, canvas);
                }
                else {
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
				fishdepth = (float)((float)fisharray[2][inx] / 512f * (float)range[fisharray[3][inx]].range);
				y = (int)((fishdepth / (float)cursonarrange) * (float)scrnht);
				// Draw fish icon
				if (sonarfishicon) {
					canvas.drawBitmap(BoatNav.bmp[MAPMAXBMP + 16 + 8 + fisharray[0][inx]].bm, x - 8, y - 8, null);
					y -= 10;
				}
				if (sonarfishdepth) {
					paint.setTextAlign(Paint.Align.CENTER);
					DrawText(x, y, 10, String.format("%.0f",fishdepth), canvas);
				}
			}
			inx++;
		}
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
		}
		else {
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
			    	}
			    	else {
						canvas.drawBitmap(GetBitmap(tilex, tiley), x, y, null);
			    	}
			    }
			    catch(Exception e) {
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
		// Draw speed
		DrawText(10, 50, 50, String.format("%.1f",((float)curspeed/10)), canvas);
		// Draw battery
		DrawText(10, scrnht - 15, 25, String.format("%.1f",(curbatt)) + "V", canvas);
		// Draw air temperature
		paint.setTextAlign(Paint.Align.RIGHT);
		DrawText(mapwt - 10, 30, 25, String.format("%.1f",(curatemp)) + "C", canvas);
		// Draw time
		DrawText(mapwt - 10, scrnht - 15, 10, curtime, canvas);
		// Draw distance
		paint.setTextAlign(Paint.Align.CENTER);
		DrawText(mapwt / 2, 15, 15, String.format("%.0f", distance) + "m", canvas);
		// Draw cursor
		index = (int)((double)curbearing / 22.5d) & 15;
		GpsPosToMapPos(curlat, curlon);
		MapPosToScrnPos();
		ScrnPosToCurPos();
		canvas.drawBitmap(BoatNav.bmp[MAPMAXBMP + index].bm, cpx-8, cpy-8, null);
	}

	private void DrawSonar(Canvas canvas) {
		int i;
		int r;
		// Draw sonar range bar
		if (mapwt != 0) {
			canvas.clipRect(mapwt+1, 0, mapwt + sonarwt, scrnht, Region.Op.REPLACE);
		}
		else {
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
		}
		else {
			canvas.clipRect(0, 0, sonarwt - SONARSIGNALGRAHWIDTH, scrnht, Region.Op.REPLACE);
		}
		i = sonarbmpinx;
		r = mapwt + sonarwt - SONARRANGEBARWIDTH + sonarofs;
		while (true) {
			dstrect.right = r;
	        r -= sonarbmpwidth[i];
	        dstrect.left = r;
	        dstrect.top = 0;
	        srcrect.left = 0;
	        srcrect.top =0 ;
	        srcrect.right = sonarbmpwidth[i];
		    if (cursonarrange == sonarbmprange[i]) {
		        dstrect.bottom = scrnht;
		        srcrect.bottom = SONARTILEHEIGHT;
				canvas.drawBitmap(sonarbmp[i], srcrect, dstrect, null);
		    }
		    else if (cursonarrange > sonarbmprange[i]) {
		        dstrect.bottom = scrnht * sonarbmprange[i] / cursonarrange;
		        srcrect.bottom = SONARTILEHEIGHT;
				canvas.drawBitmap(sonarbmp[i], srcrect, dstrect, null);
				dstrect.top = dstrect.bottom;
				dstrect.bottom = scrnht;
		        paint.setColor(sonarColor);
		        paint.setStyle(Style.FILL);
		        canvas.drawRect(dstrect, paint);   
		    }
		    else if (cursonarrange < sonarbmprange[i]) {
		        dstrect.bottom = scrnht;
		        srcrect.bottom = SONARTILEHEIGHT * cursonarrange / sonarbmprange[i];
				canvas.drawBitmap(sonarbmp[i], srcrect, dstrect, null);
		    }
			i--;
			i &= MAXSONARBMP - 1;
			if (i == sonarbmpinx || r < mapwt) {
				break;
			}
		}
        DrawSonarFish(canvas);
		if (mapwt != 0) {
			canvas.clipRect(mapwt+1, 0, mapwt + sonarwt, scrnht, Region.Op.REPLACE);
		}
		else {
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
				}
				else {
					DrawText(mapwt + 10, 50, 50, String.format("%.1f",curdepth), canvas);
				}
			}
		}
		else {
			if (curdepth >= 100) {
				DrawText(mapwt + 10, 50, 50, String.format("%.0f",curdepth), canvas);
			}
			else {
				DrawText(mapwt + 10, 50, 50, String.format("%.1f",curdepth), canvas);
			}
		}
		// Draw water temperature
		DrawText(mapwt + 15, 85, 25, String.format("%.1f",curwtemp) + "C", canvas);
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
			mapwt = w;
			sonarwt = 0;
			break;
		case 1:
			mapwt = 0;
			sonarwt = w;
			break;
		case 2:
			mapwt = w / 2;
			sonarwt = w / 2;
			break;
		}
	}                	      
	
	@Override
	protected void onDraw(Canvas canvas) {
		if (mapwt != 0) {
			DrawMap(canvas);
		}
		if (sonarwt != 0) {
			DrawSonar(canvas);
		}

// Debug
		canvas.clipRect(0, 0, scrnwt, scrnht, Region.Op.REPLACE);
		paint.setColor(Color.BLACK);
		paint.setTextSize(20);
//		String sText;
//		paint.setTextAlign(Paint.Align.LEFT);
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
