package app.BoatNav;

import android.app.Activity;
import android.app.AlertDialog;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.MediaPlayer.OnCompletionListener;
import android.media.SoundPool;
import android.os.Bundle;
import android.os.Environment;
import android.view.Menu;
import android.view.MotionEvent;
import android.view.MenuInflater;
import android.view.SubMenu;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.util.*;
import android.app.Dialog;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.view.View.OnClickListener;
import android.view.View;
import android.widget.*;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.SeekBar.OnSeekBarChangeListener;
import java.io.File;
import android.view.MenuItem;
import java.io.BufferedInputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.RandomAccessFile;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.lang.reflect.Method;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Comparator;
import java.util.Random;
import java.util.Set;
import java.util.TimeZone;
import java.util.Timer;
import java.util.TimerTask;
import app.BoatNav.BmpClass;
import app.BoatNav.MyIV;
import app.BoatNav.R;

public class BoatNav extends Activity {
	private static MyIV mIV;
	private static float xd, yd, xs, ys, sxs;
	public static Bitmap mGrayBitmap;
	public static Bitmap mIcons;
	public static BmpClass[] bmp = BmpClass.BmpClassSet(MyIV.MAPMAXBMP + MyIV.MAPMAXICON);
	private static boolean rginuse = false;
	
	public static String config[][] = new String[50][2];
	public static int placeState[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	public static String placeTitle[] = {"","","","","","","","","","","","","","","",""};
	public static int placeIcon[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	public static double placeLat[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	public static double placeLon[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	private static int mplaceinx = 0;
	private static String buffer;
	private static String line;
	private final static int REQUEST_ENABLE_BT = 1;
	private Timer tmr = new Timer();
	private static Random rnd = new Random();
	private static RandomAccessFile  replayfile;
	private static boolean recording = false;
	public static int blinkrate = 0;
	private static int soundplaying = 0;
	private static ArrayAdapter<String> btadapter;
	private static ArrayList<String> btlistItems = new ArrayList<String>();
	private static String btdeviceaddr;
	private static boolean btautoconnect = false;
    protected BluetoothAdapter mBluetoothAdapter = null;//BluetoothAdapter.getDefaultAdapter();
    BluetoothDevice mBluetoothDevice = null;
    protected BluetoothSocket mBluetoothSocket = null;
    private OutputStream mOutputStream = null;
    private InputStream mInputStream = null;
    private static BTClass btSend = new BTClass();
    private static byte[] btwritebuffer = new byte[42];
    private static byte[] btreadbuffer = new byte[MyIV.SONARARRAYSIZE];
    private static boolean btstart = false;
    public static boolean btconnected = false;
    public static String btlogg = "";

    @Override
	public void onCreate(Bundle icicle) {
		super.onCreate(icicle);
		int i;

		if (mGrayBitmap == null) {
			i = 0;
			while (i < MyIV.SONARTILEHEIGHT) {
				MyIV.sc.sonar[i] = 0;
				i++;
			}
			mGrayBitmap = BitmapFactory.decodeFile(Environment.getExternalStorageDirectory() + File.separator + "Map" + File.separator + "Gray.jpg");
			mIcons = BitmapFactory.decodeResource(getResources(), R.drawable.cur);
			MakeTransparent();
			MakeIcons();
			GetConfig();
			GetPlaces();
			MyIV.sonarColor = 0xFF000000 | 108 << 16 | 189 << 8 | 244;
			MyIV.sonarsignalbmp = Bitmap.createBitmap(MyIV.SONARSIGNALGRAHWIDTH, MyIV.SONARTILEHEIGHT, Bitmap.Config.ARGB_8888);
			MyIV.sonarsignalbmp.eraseColor(MyIV.sonarColor);
			MyIV.SonarClear();
			if (btautoconnect) {
				BTConnect();
			}
			tmr.schedule(new TimerTask() {
				@Override
				public void run() {
					TimerMethod();
				}
			}, 1000, 100);

	    	Runnable runnable = new Runnable() {
		        public void run() {
                	while (true) {
                		if (btstart) {
        					Boolean err = false;
        			        int ri = MyIV.sonarrangeinx;
        			        
        					if (MyIV.sonarautorange) {
        						// Check range change
        						if (MyIV.nodepth) {
        							if (MyIV.sonarrangechange > 5) {
        								if ((ri == 0 && MyIV.sonarrangechangedir < 0) || (ri == MyIV.MAXSONARRANGE - 1 && MyIV.sonarrangechangedir > 0)) {
        									MyIV.sonarrangechangedir = -MyIV.sonarrangechangedir;
        								}
        								ri += MyIV.sonarrangechangedir;
        								MyIV.sonarrangechange = 0;
        							}
        						} else if (MyIV.sonarrangechange > 5) {
        							float d = (float)MyIV.range[ri].range;
        							if (((float)MyIV.curdepth > (d - d / 5f)) && ri < 19) {
        								MyIV.rndpixdpt = (MyIV.rndpixdpt * MyIV.range[ri].range) / MyIV.range[ri + 1].range;
        								ri++;
        								MyIV.sonarrangechange = 0;
        							} else if (((float)MyIV.curdepth < (d / 5f)) && ri > 0) {
        								MyIV.rndpixdpt = (MyIV.rndpixdpt * MyIV.range[ri].range) / MyIV.range[ri - 1].range;
        								ri--;
        								MyIV.sonarrangechange = 0;
        							}
        						}
        					} else if (MyIV.sonarrangeset >= 0) {
       							ri = MyIV.sonarrangeset;
       							MyIV.sonarrangeset = -1;
        					}
        					MyIV.sonarrangechange++;

        			        btSend.Start = 1;
        			        if (MyIV.sonarautoping) {
            			        btSend.PingPulses = (byte)(MyIV.sonarpinginit + MyIV.range[ri].pingadd);
        			        } else {
            			        btSend.PingPulses = (byte)(MyIV.sonarpinginit);
        			        }
        			        btSend.PingTimer = (40000000 / 200000 / 2)-1;
        			        btSend.RangeInx = (byte)ri;
        			        btSend.PixelTimer = (short) MyIV.range[MyIV.sonarrangeinx].pixeltimer;
        			        btSend.GainInit[0] = (short)MyIV.sonargaininit;
        			        int i = 0;
        			        if (MyIV.sonarautogain == true) {
            			        while (i < 17) {
            			        	btSend.GainInit[i + 1] = (short)MyIV.range[ri].gain[i];
            			        	i++;
            			        }
        			        } else {
            			        while (i < 17) {
            			        	btSend.GainInit[i + 1] = 0;
            			        	i++;
            			        }
        			        }
        			        btwritebuffer[0] = btSend.Start;
        			        btwritebuffer[1] = btSend.PingPulses;
        			        btwritebuffer[2] = btSend.PingTimer;
        			        btwritebuffer[3] = btSend.RangeInx;
        			        btwritebuffer[4] = (byte)(btSend.PixelTimer & 0xFF);
        			        btwritebuffer[5] = (byte)(btSend.PixelTimer / 256);
        			        i = 0;
        			        while (i < 18) {
        			        	btwritebuffer[i * 2 + 6] = (byte)(btSend.GainInit[i] & 0xFF);
        			        	btwritebuffer[i * 2 + 7] = (byte)(btSend.GainInit[i] >> 8);
        			        	i++;
        			        }
        			        try {
        			        	mOutputStream.write(btwritebuffer);
        			            try {
        			            	int bytes = 0;
        			            	while (bytes < MyIV.SONARARRAYSIZE) {
        				               	bytes += mInputStream.read(btreadbuffer,bytes,MyIV.SONARARRAYSIZE-bytes);
        			            	}
        			               	if (bytes == MyIV.SONARARRAYSIZE) {
        			               		if (((int)btreadbuffer[0] & 0xFF) == 201) {
        			               			if (recording == true) {
        			               				try {
            			               				replayfile.write(btreadbuffer);
        			               				} catch (Exception e) {
        			               				}
        			               			}
        				               		bytes = 0;
        				               		while (bytes < MyIV.SONARARRAYSIZE) {
        				               			MyIV.replayarray[bytes] = btreadbuffer[bytes];
        				               			bytes++;
        				               		}
        			               		}
        			               	}
        			            } catch (IOException e) {
        				        	err = true;
        			            }
        			        } catch (IOException e) {
        			        	err = true;
        			    	}
        			        if (err) {
        			        	btconnected = BTDisConnect();
		               			if (recording == true) {
		               				try {
			               				replayfile.close();
		               				} catch (Exception e) {
		               				}
		               				recording = false;
		               			}
		               			MyIV.SonarClear();
        			        	MyIV.ClearTrail();
        			        	MyIV.mode = 1;
                			}
                			btstart = false;
                		} else {
                    		try {
    							Thread.sleep(50);
    						} catch (InterruptedException e) {
    						}
                		}
                	}
		        }
	    	};
	    	Thread mythread = new Thread(runnable);
	    	mythread.start();
		}
        mIV = new MyIV(this);
		setContentView(mIV);
		mIV.invalidate();
	}

    @Override
    public void onStop()
    {
        super.onStop();
        //msgbox("Stop","Stop");
        //SaveConfig();
    }

    @Override
    public void onDestroy()
    {
        super.onDestroy();
        SaveConfig();
        if (isFinishing()) {
    		if (recording) {
    			recording = false;
    			try {
    				replayfile.close();
    			} catch (IOException e) {
    			}
    		}
    		if (btconnected) {
    			btconnected = BTDisConnect();
    		}
        } else { 
        }
    }

    private void TimerMethod()
	{
		this.runOnUiThread(Timer_Tick);
		if (MyIV.sonarfishsound == true && MyIV.playfishalarm == true && soundplaying == 0) {
			MyIV.playfishalarm = false;
			playFishAlarm();
		} else if (soundplaying > 0) {
			soundplaying--;
		}
	}

	private void NormalMode() {
		if (btstart == false) {
       		if (((int)btreadbuffer[0] & 0xFF) == 201) {
           		MyIV.TraslateFromByteArray();
           		MyIV.SonarShow();
       		}
			btstart = true;
		}
   		mIV.invalidate();
	}

	private void DemoMode() {
		int i, j, x, pix, dd, mm, yy, hh, mn, ss, ri;
		String datetime;
		MyIV.sc.ADCBattery = 2234;
		MyIV.sc.ADCWaterTemp = 1900;
		MyIV.sc.ADCAirTemp = 1500;
		Calendar c = Calendar.getInstance();
		MyIV.sdf.setTimeZone(TimeZone.getTimeZone("UTC"));
		datetime=MyIV.sdf.format(c.getTime());
		// 29.10.2013 11:45:04
		dd = Integer.valueOf(datetime.substring(0, 2));
		mm = Integer.valueOf(datetime.substring(3, 5));
		yy = Integer.valueOf(datetime.substring(8, 10));
		hh = Integer.valueOf(datetime.substring(11, 13));
		mn = Integer.valueOf(datetime.substring(14, 16));
		ss = Integer.valueOf(datetime.substring(17, 19));
		//	YYYYYYYMMMMDDDDDHHHHHMMMMMMSSSSS
		MyIV.sc.iTime = yy << 25 | mm << 21 | dd << 16 | hh << 11 | mn << 5 | ss >> 1;
   		MyIV.sc.iLon = 14196690;
   		MyIV.sc.iLat = 66317270;
		MyIV.sc.iSpeed = 0;
		MyIV.sc.iBear = 0;
		MyIV.sc.fixquality = 0;

		if (MyIV.sonarrangeinx >= MyIV.MAXSONARRANGE) {
			MyIV.sonarrangeinx = MyIV.MAXSONARRANGE - 1;
		}
		ri = MyIV.sonarrangeinx;
		if (MyIV.sonarautorange) {
			// Check range change
			if (MyIV.nodepth) {
				if (MyIV.sonarrangechange > 5) {
					ri += MyIV.sonarrangechangedir;
					if (ri == 0 || ri == MyIV.MAXSONARRANGE - 1) {
						MyIV.sonarrangechangedir = -MyIV.sonarrangechangedir;
					}
					MyIV.sonarrangechange = 0;
				}
			} else if (MyIV.sonarrangechange > 5) {
				float d = (float)MyIV.range[ri].range;
				if (((float)MyIV.curdepth > (d - d / 5f)) && ri < 19) {
					MyIV.rndpixdpt = (MyIV.rndpixdpt * MyIV.range[ri].range) / MyIV.range[ri + 1].range;
					ri++;
					MyIV.sonarrangechange = 0;
				} else if (((float)MyIV.curdepth < (d / 5f)) && ri > 0) {
					MyIV.rndpixdpt = (MyIV.rndpixdpt * MyIV.range[ri].range) / MyIV.range[ri - 1].range;
					ri--;
					MyIV.sonarrangechange = 0;
				} else if (ri == 0 || ri == 19) {
					MyIV.sonarrangechange = 0;
				}
			}
		} else if (MyIV.sonarrangeset >= 0) {
			ri = MyIV.sonarrangeset;
			MyIV.sonarrangeset = -1;
		}
		MyIV.sc.sonar[0] = (byte)(ri);
		MyIV.sonarrangechange++;
		// Clear echo
   		i = 1;
   		while (i < MyIV.SONARTILEHEIGHT) {
   			MyIV.sc.sonar[i] = 0;
   			i++;
   		}
		// Show ping
		i = 100 / (MyIV.range[ri].pixeltimer / MyIV.range[0].pixeltimer);
		if (i < 3) {
			i = 3;
		}
		x = i;
		j = 1;
		while (j < i) {
			pix = rnd.nextInt(50) + 255 - 50;
			MyIV.sc.sonar[j] = (byte)pix;
			j++;
		}
		x = i;
		// Show surface clutter
		i += rnd.nextInt(i / 2);
		while (j < i) {
			pix = 50 + rnd.nextInt(200);
			MyIV.sc.sonar[j] = (byte)pix;
			j++;
		}
		if ((MyIV.sonarcount & 63) == 0) {
			MyIV.rndpixdir = rnd.nextInt(6);
		}
		if ((MyIV.sonarcount & 7) == 0) {
			MyIV.rndpixmov = rnd.nextInt(3);
		}
		if (MyIV.rndpixdir <= 1 && MyIV.rndpixdpt > 50) {
			// Up
			MyIV.rndpixdpt -= MyIV.rndpixmov;
			MyIV.rndfishcount = 0;
		} else if (MyIV.rndpixdir >= 3 && MyIV.rndpixdpt < 500) {
			// Down
			MyIV.rndpixdpt += MyIV.rndpixmov;
			MyIV.rndfishcount = 0;
		}
		// Random bottom vegetation
		i = MyIV.rndpixdpt - rnd.nextInt(x / 2);
		if (i <= x) {
			i = x + 1;
		}
		while (i < MyIV.rndpixdpt && i < MyIV.SONARTILEHEIGHT) {
			pix = rnd.nextInt(64);
			MyIV.sc.sonar[i] = (byte)pix;
			i++;
		}
		// Random bottom echo
		i = MyIV.rndpixdpt;
		j =  MyIV.rndpixdpt + x * 2;
		while (i < j && i < MyIV.SONARTILEHEIGHT) {
			pix = rnd.nextInt(50) + 255 - 50;
			MyIV.sc.sonar[i] = (byte)pix;
			i++;
		}
		// Random bottom weak echo
		j += rnd.nextInt(x * 2) + 12;
		while (i < j && i < MyIV.SONARTILEHEIGHT) {
			pix = rnd.nextInt(64) + 64;
			MyIV.sc.sonar[i] = (byte)pix;
			i++;
		}
		// Random fish
		if (MyIV.rndfishcount == 0) {
			if (rnd.nextInt(100) > 95) {
				MyIV.rndfishdpt = rnd.nextInt(MyIV.rndpixdpt - 5);
				if (MyIV.rndfishdpt < 10) {
					MyIV.rndfishdpt = 10;
				}
				MyIV.rndfishcount = 5;
			}
		} else {
			i = MyIV.rndfishdpt;
			while (i < MyIV.rndfishdpt + 5 && i < MyIV.SONARTILEHEIGHT) {
				pix = 50 + rnd.nextInt(200);
				MyIV.sc.sonar[i] = (byte)pix;
				i++;
			}
			MyIV.rndfishcount--;
		}
		MyIV.SonarShow();
		mIV.invalidate();
	}

	private void ReplayMode() {
		MyIV.SonarReplay(replayfile);
		mIV.invalidate();
	}

	private Runnable Timer_Tick = new Runnable() {
		public void run() {
			switch (MyIV.mode) {
			case 0:
				NormalMode();
				break;
			case 1:
				DemoMode();
				break;
			case 2:
				ReplayMode();
				break;
			}
			blinkrate++;
			if ((blinkrate & 3) == 0) {
				MyIV.blink = !MyIV.blink;
			}
			
		}
	};
	
	/*
	range			Range in meters
	mindepth		Index where to start depth search
	interval		Update rate (ms)
	pingadd			Number of pulses to add to initial ping pulses (0 to 127). Used when autoping is on
	gain			Gain levels for every 32 pixels. Used when auto gain is on
	nticks			Number of ticks on rane bar
	scale			Text to draw on range bar
	*/
	private void ParseRange(int i) {
		int j = 0;
		GetLine();
		MyIV.range[i].range = Integer.valueOf(GetItem());
		MyIV.range[i].mindepth = Integer.valueOf(GetItem());
		MyIV.range[i].interval = Integer.valueOf(GetItem());
		MyIV.range[i].pingadd = Integer.valueOf(GetItem());
        MyIV.range[i].pixeltimer = (int)((((double)MyIV.range[i].range / (double)MyIV.SONARTILEHEIGHT) / (1450d / 2d)) * 40000000d);
		while (j<17) {
			MyIV.range[i].gain[j] =  Integer.valueOf(GetItem());
			j++;
		}
		MyIV.range[i].nticks = Integer.valueOf(GetItem());
		MyIV.range[i].scale = line;
	}

	private void GetLine() {
		int x;
		try {
			while (true) {
				x = buffer.indexOf(0x0a);
				line = buffer.substring(0,x-1);
				buffer = buffer.substring(x+1);
				if (!line.startsWith("//")) {
					break;
				}
			}
		} catch (Exception e) {
	        Log.e("MYTAG", "Line error: " + e.toString());
		}
	}
	
	private void GetComment() {
		int x;
		try {
			x = buffer.indexOf(0x0a);
			line = buffer.substring(0,x-1);
			buffer = buffer.substring(x+1);
		} catch (Exception e) {
	        Log.e("MYTAG", "Line error: " + e.toString());
		}
	}
	
	private String GetItem() {
		String item = "";
		int x;
		try {
			if (line.startsWith(Character.toString((char)0x22))) {
				x = line.indexOf(0x22,1);
				item = line.substring(1,x);
				line = line.substring(x+2);
			} else {
				x = line.indexOf(0x2c);
				if (x >= 0) {
					item = line.substring(0,x);
					line = line.substring(x+1);
				} else {
					item = line;
					line = "";
				}
			}
		} catch (Exception e) {
	        Log.e("MYTAG", "Item error: " + e.toString());
		}
		return item;
	}

	private void AddItem(String item) {
		if (line.length() != 0) {
			line = line + ",";
		}
		line = line + item;
	}

	private void AddItemString(String item) {
		if (line.length() != 0) {
			line = line + ",";
		}
		line = line + Character.toString((char)0x22) + item + Character.toString((char)0x22);
	}

	private int FindConfig(String section) {
		int i = 0;
		while (config[i][0].length() > 0 && config[i][0].contentEquals(section) == false) {
			i++;
		}
		buffer = config[i][1];
		return i;
	}

	private void GetConfig() {
		buffer = readFileAsString("config.txt");
		int i = -1;
		while (buffer.length() != 0) {
			GetLine();
			if (line.startsWith("#")) {
				i++;
				config[i][0] = line;
				config[i][1] = "";
			} else {
				config[i][1] += line + "\r\n";
			}
		}
		i++;
		config[i][0] = "";
		config[i][1] = "";
		buffer = "";
		FindConfig("#btaddress");
		GetLine();
		btdeviceaddr = line;
		FindConfig("#btautoconnect");
		GetLine();
		btautoconnect = Integer.valueOf(GetItem()) == 1;
		FindConfig("#maxtilex");
		GetLine();
		MyIV.maxtilex[0] = 0;
		i = 1;
		while (line.length() > 0) {
			MyIV.maxtilex[i] = Integer.valueOf(GetItem());
			i++;
		}
		FindConfig("#maxtiley");
		GetLine();
		MyIV.maxtiley[0] = 0;
		i = 1;
		while (line.length() > 0) {
			MyIV.maxtiley[i] = Integer.valueOf(GetItem());
			i++;
		}
		FindConfig("#maprect");
		GetLine();
		MyIV.left = Double.valueOf(GetItem());
		MyIV.top = Double.valueOf(GetItem());
		MyIV.right = Double.valueOf(GetItem());
		MyIV.bottom = Double.valueOf(GetItem());
		FindConfig("#latarray");
		GetLine();
		i = 0;
		while (i < 65) {
			MyIV.latarray[i] = Double.valueOf(GetItem());
			i++;
		}
		FindConfig("#curpos");
		GetLine();
		MyIV.curlat = Double.valueOf(GetItem());
		MyIV.prvlat = MyIV.curlat;
		MyIV.curlon = Double.valueOf(GetItem());
		MyIV.prvlon = MyIV.curlon;
		FindConfig("#map");
		GetLine();
		MyIV.viewmode = Integer.valueOf(GetItem());
		MyIV.land = Integer.valueOf(GetItem()) == 1;
		MyIV.zoom = Integer.valueOf(GetItem());
		MyIV.locktogps = Integer.valueOf(GetItem()) == 1;
		MyIV.showtrail = Integer.valueOf(GetItem()) == 1;
		MyIV.tracksmoothing = Integer.valueOf(GetItem());
		FindConfig("#sonar");
		GetLine();
		MyIV.sonarpinginit = Integer.valueOf(GetItem());
		MyIV.sonarautoping = Integer.valueOf(GetItem()) == 1;
		MyIV.sonargaininit = Integer.valueOf(GetItem());
		MyIV.sonarautogain = Integer.valueOf(GetItem()) == 1;
		MyIV.sonarnoiselevel = Integer.valueOf(GetItem());
		MyIV.sonarnoisereject = Integer.valueOf(GetItem());
		MyIV.sonarfishdetect = Integer.valueOf(GetItem());
		MyIV.sonarfishsound = Integer.valueOf(GetItem()) == 1;
		MyIV.sonarfishdepth = Integer.valueOf(GetItem()) == 1;
		MyIV.sonarfishicon = Integer.valueOf(GetItem()) == 1;
		MyIV.sonarautorange = Integer.valueOf(GetItem()) == 1;
		FindConfig("#sonarrange");
		i=0;
		while (buffer.length() > 0) {
			ParseRange(i);
			i++;
		}

//    	Log.e("MYTAG", buffer);
	}
	
	private int GetBoolean(boolean b) {
		if (b) {
			return 1;
		} else {
			return 0;
		}
	}

	private void SaveConfig() {
		int i;
		i = FindConfig("#btautoconnect");
		config[i][1] = "";
		while (buffer.startsWith("//")) {
			GetComment();
			config[i][1] += line + "\r\n";
		}
		line = "";
		AddItem(Integer.toString(GetBoolean(btautoconnect)));
		config[i][1] += line + "\r\n";
		i = FindConfig("#curpos");
		config[i][1] = "";
		while (buffer.startsWith("//")) {
			GetComment();
			config[i][1] += line + "\r\n";
		}
		// latitude,longitude
		line = "";
		AddItem(Double.toString(MyIV.curlat));
		AddItem(Double.toString(MyIV.curlon));
		config[i][1] += line + "\r\n";
		i = FindConfig("#map");
		config[i][1] = "";
		while (buffer.startsWith("//")) {
			GetComment();
			config[i][1] += line + "\r\n";
		}
		// viewmode,land,zoom,locktogps,showtrail,tracksmoothing
		line = "";
		AddItem(Integer.toString(MyIV.viewmode));
		AddItem(Integer.toString(GetBoolean(MyIV.land)));
		AddItem(Integer.toString(MyIV.zoom));
		AddItem(Integer.toString(GetBoolean(MyIV.locktogps)));
		AddItem(Integer.toString(GetBoolean(MyIV.showtrail)));
		AddItem(Integer.toString(MyIV.tracksmoothing));
		config[i][1] += line + "\r\n";
		i = FindConfig("#sonar");
		config[i][1] = "";
		while (buffer.startsWith("//")) {
			GetComment();
			config[i][1] += line + "\r\n";
		}
		// sonarpinginit,sonarautoping,sonargaininit,sonarautogain,sonarnoiselevel,sonarnoisereject,sonarfishdetect,sonarfishsound,sonarfishdepth,sonarfishicon,sonarautorange
		line = "";
		AddItem(Integer.toString(MyIV.sonarpinginit));
		AddItem(Integer.toString(GetBoolean(MyIV.sonarautoping)));
		AddItem(Integer.toString(MyIV.sonargaininit));
		AddItem(Integer.toString(GetBoolean(MyIV.sonarautogain)));
		AddItem(Integer.toString(MyIV.sonarnoiselevel));
		AddItem(Integer.toString(MyIV.sonarnoisereject));
		AddItem(Integer.toString(MyIV.sonarfishdetect));
		AddItem(Integer.toString(GetBoolean(MyIV.sonarfishsound)));
		AddItem(Integer.toString(GetBoolean(MyIV.sonarfishdepth)));
		AddItem(Integer.toString(GetBoolean(MyIV.sonarfishicon)));
		AddItem(Integer.toString(GetBoolean(MyIV.sonarautorange)));
		config[i][1] += line + "\r\n";
		buffer = "";
		i = 0;
		while (config[i][0].length() > 0) {
			buffer += config[i][0] + "\r\n";
			buffer += config[i][1];
			i++;
		}
		writeStringToFile("config.txt", buffer);
	}

	private void GetPlaces() {
		int i = 0;
		String item;
		buffer = readFileAsString("places.txt");
		while (i < 16 && buffer.length() != 0) {
			GetLine();
			item = GetItem();
			placeState[i] = Integer.valueOf(item);
			item = GetItem();
			placeTitle[i] = item;
			item = GetItem();
			placeIcon[i] = Integer.valueOf(item);
			item = GetItem();
			placeLat[i] = Double.valueOf(item);
			item = GetItem();
			placeLon[i] = Double.valueOf(item);
			i++;
		}
	}

	private void SavePlaces() {
		int i = 0;
		buffer = "";
		while (i < 16) {
			if (placeState[i] != 0) {
				line = "";
				AddItem(Integer.toString(placeState[i]));
				AddItemString(placeTitle[i]);
				AddItem(Integer.toString(placeIcon[i]));
				AddItem(Double.toString(placeLat[i]));
				AddItem(Double.toString(placeLon[i]));
				buffer = buffer + line + "\r\n";
			}
			i++;
		}
		writeStringToFile("places.txt", buffer);
	}
	
	@Override
    public boolean onCreateOptionsMenu(Menu menu) {
        super.onCreateOptionsMenu(menu);
        // Inflate the menu; this adds items to the action bar if it is present.
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.main, menu);
        return true;
    }
	
	private boolean BTDisConnect() {
        if (mOutputStream != null) {
        	try {
        		mOutputStream.close();
        		mOutputStream = null;
			} catch (IOException e1) {
			}
        }
        if (mInputStream != null) {
        	try {
				mInputStream.close();
				mInputStream = null;
			} catch (IOException e1) {
			}
        }
        if (mBluetoothSocket != null) {
        	try {
				mBluetoothSocket.close();
				mBluetoothSocket = null;
			} catch (IOException e) {
			}
        }
		return false;
	}

	@Override 
	 protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		if (requestCode == REQUEST_ENABLE_BT) {
			if (resultCode == RESULT_OK){
				Toast.makeText(getApplicationContext(), "BlueTooth is now enabled", Toast.LENGTH_LONG).show();
            	ShowBluetoothDialog();
			}
			if (resultCode == RESULT_CANCELED) {
				Toast.makeText(getApplicationContext(), "Error occured while enabling BlueTooth.", Toast.LENGTH_LONG).show();
			}
		 }
	 }

	private boolean BTConnect() {
    	Boolean err = false;
    	btconnected = BTDisConnect();
        try {
        	BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        	if (mBluetoothAdapter == null) {
	        	err = true;
        	} else {
            	// Set up a pointer to the remote node using it's address.
            	mBluetoothDevice = mBluetoothAdapter.getRemoteDevice(btdeviceaddr);
            	Method m = mBluetoothDevice.getClass().getMethod("createInsecureRfcommSocket", new Class[] { int.class }); 
            	mBluetoothSocket = (BluetoothSocket) m.invoke(mBluetoothDevice,Integer.valueOf(1));
                // Discovery is resource intensive.  Make sure it isn't going on
                // when you attempt to connect and pass your message.
                mBluetoothAdapter.cancelDiscovery();
                // Establish the connection.  This will block until it connects.
                try {
                	mBluetoothSocket.connect();
    	            // Create data streams so we can talk to server.
    	            try {
    	            	mOutputStream = mBluetoothSocket.getOutputStream();
    		            try {
    		            	mInputStream = mBluetoothSocket.getInputStream();
    		            	// Done, set the mode
    						MyIV.SonarClear();
    	                	MyIV.mode = 0;
    	                	btconnected = true;
    		            } catch (IOException e) {
    			        	msgbox("BT", "getInputStream " + e.getMessage());
    			        	err = true;
    		            }
    	            } catch (IOException e) {
    		        	msgbox("BT", "getOutputStream " + e.getMessage());
    		        	err = true;
    	            }
                } catch (IOException e) {
    	        	msgbox("BT", "connect " + e.getMessage());
    	        	err = true;
                }
        	}
		} catch (Exception e) {
        	msgbox("BT", "getRemoteDevice " + e.getMessage());
        	err = true;
		}
        if (err == true) {
        	btconnected = BTDisConnect();
        }
        return err;
	}

	private void ShowBluetoothDialog() {
 	   final Context context = this;
 	   final Dialog dialog = new Dialog(context);
 	   dialog.setContentView(R.layout.dialogbluetooth);
 	   dialog.setTitle("Bluetooth");

 	   	BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
		ListView lv = (ListView) dialog.findViewById(R.id.lvPaired);

	    btadapter=new ArrayAdapter<String>(this, android.R.layout.simple_list_item_1, btlistItems);
	    btadapter.clear();
        lv.setAdapter(btadapter);
        lv.layout(0, 0, 400, 300);
		Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
		if (mBluetoothAdapter != null) {
			if (!mBluetoothAdapter.isEnabled()) {
				startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
				dialog.dismiss();
			} else {
	         	btlistItems.add(mBluetoothAdapter.getName() + "\n" + mBluetoothAdapter.getAddress());
				Set<BluetoothDevice> pairedDevices = mBluetoothAdapter.getBondedDevices();
				// If there are paired devices
				if (pairedDevices.size() > 0) {
					// Loop through paired devices
					for (BluetoothDevice device : pairedDevices) {
						// Add the name and address to the ListView
			         	btlistItems.add(device.getName() + "\n" + device.getAddress());
					}
				}
		        btadapter.notifyDataSetChanged();
			}
		} else {
         	btlistItems.add("No bluetooth adapter found");
	        btadapter.notifyDataSetChanged();
		}

		CheckBox chkAutoConnect;
		chkAutoConnect = (CheckBox) dialog.findViewById(R.id.chkAutoConnect);
		chkAutoConnect.setChecked(btautoconnect);
		chkAutoConnect.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				btautoconnect = ((CheckBox) v).isChecked();
			}
		});

		Button btnConnect = (Button) dialog.findViewById(R.id.btnConnect);
		if (btconnected) {
			btnConnect.setText("Disconnect");
		}
        btnConnect.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
		    	Boolean err = false;
				if (btconnected) {
					btconnected = BTDisConnect();
				} else {
			    	err = BTConnect();
				}
		    	if (err) {
		    		
		    	} else {
					SaveConfig();
					dialog.dismiss();
		    	}
			}
		});

        Button btnOK = (Button) dialog.findViewById(R.id.btnOK);
		btnOK.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				SaveConfig();
				dialog.dismiss();
			}
		});

		dialog.show();
	}

	private void ShowReplayDialog() {
		int i;
		ArrayList<String> listItems=new ArrayList<String>();
		ArrayAdapter<String> adapter;

    	final Context context = this;
		final Dialog dialog = new Dialog(context);
		dialog.setContentView(R.layout.dialogreplay);
		dialog.setTitle("Replay");

	    ListView lv = (ListView) dialog.findViewById(R.id.lvFiles);

        adapter=new ArrayAdapter<String>(this, android.R.layout.simple_list_item_1, listItems);
        lv.setAdapter(adapter);
        lv.layout(0, 0, 400, 400);

        File f = new File(Environment.getExternalStorageDirectory() + File.separator + "Map" + File.separator + "Sonar");
        File[] files = f.listFiles();

        if (files.length != 0) {
            Arrays.sort(files, new Comparator<File>() {
            	public int compare(File f1, File f2) {
            		return f1.getName().compareTo(f2.getName());
                }
            });
            for(i=0; i < files.length; i++) {
            	File file = files[i];
             	listItems.add(file.getName());
            }
            adapter.notifyDataSetChanged();
        }

        lv.setOnItemClickListener(new OnItemClickListener() {
			@Override
			public void onItemClick(AdapterView<?> parent, View viev, int pos, long id) {
		    	String s;
				s = (String) parent.getItemAtPosition(pos);
            	try {
            		String FileName = Environment.getExternalStorageDirectory() + File.separator + "Map" + File.separator + "Sonar" + File.separator + s;
                	replayfile = new RandomAccessFile(FileName,"r");
                	// Clear trail and distance
                	MyIV.ClearTrail();
                	MyIV.SonarClear();
                	// Set replay mode
                	MyIV.mode = 2;
    				dialog.dismiss();
	        	} catch (Exception e) {
	        	}
			}
        });

        Button btnRecord = (Button) dialog.findViewById(R.id.btnRecord);
        if (MyIV.mode != 0) {
        	btnRecord.setVisibility(4);
        }
        if (recording) {
        	btnRecord.setText("Stop Recording");
        }
		btnRecord.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (recording) {
					recording = false;
					try {
						replayfile.close();
					} catch (IOException e) {
					}
				} else {
					SimpleDateFormat msdf = new SimpleDateFormat("yyyyMMdd_HHmm");
					Calendar c = Calendar.getInstance();
					String s = "Sonar" + msdf.format(c.getTime()) + ".snr";
            		String FileName = Environment.getExternalStorageDirectory() + File.separator + "Map" + File.separator + "Sonar" + File.separator + s;
            		msgbox("Recording",FileName);
                    try {
						replayfile = new RandomAccessFile(FileName, "rw");
						recording = true;
					} catch (FileNotFoundException e) {
					}
				}
				dialog.dismiss();
			}
		});

		Button btnCancel = (Button) dialog.findViewById(R.id.btnCancel);
		btnCancel.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				dialog.dismiss();
			}
		});

		dialog.show();
    }

    private void ShowGPSSetupDialog() {
    	final Context context = this;
		final Dialog dialog = new Dialog(context);
		dialog.setContentView(R.layout.dialoggpssetup);
    	
		dialog.setTitle("GPS Setup");
		final TextView tvTrackSmoothing;
		tvTrackSmoothing = (TextView) dialog.findViewById(R.id.textView1);
		tvTrackSmoothing.setText("Track Smoothing: " +  String.format("%.1f",((float)MyIV.tracksmoothing / 10)));
		SeekBar sbTrackSmoothing;
		sbTrackSmoothing = (SeekBar) dialog.findViewById(R.id.sbTrackSmoothing);
		sbTrackSmoothing.setProgress(MyIV.tracksmoothing);
		sbTrackSmoothing.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		MyIV.tracksmoothing = progress;
        		tvTrackSmoothing.setText("Track Smoothing: " +  String.format("%.1f",((float)MyIV.tracksmoothing / 10)));
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });

		CheckBox chkShowTrail;
		chkShowTrail = (CheckBox) dialog.findViewById(R.id.chkShowTrail);
		chkShowTrail.setChecked(MyIV.showtrail);
		chkShowTrail.setOnClickListener(new OnClickListener() {
			
			@Override
			public void onClick(View v) {
				MyIV.showtrail = ((CheckBox) v).isChecked();
			}
		});

		Button btnOK = (Button) dialog.findViewById(R.id.btnOK);
		// if button is clicked, close the custom dialog
		btnOK.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				SaveConfig();
				dialog.dismiss();
			}
		});

		Button btnClear = (Button) dialog.findViewById(R.id.btnClear);
		// if button is clicked, clear the trail
		btnClear.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				MyIV.ClearTrail();
			}
		});

		dialog.show();
    }

    private void ShowSonarSetupDialog() {
    	final Context context = this;
		final Dialog dialog = new Dialog(context);
		dialog.setContentView(R.layout.dialogsonarsetup);

		dialog.setTitle("Sonar Setup");

		final TextView tvInitialPing;
		tvInitialPing = (TextView) dialog.findViewById(R.id.textView5);
		tvInitialPing.setText("Initial Ping: " + MyIV.sonarpinginit);
		SeekBar sbInitialPing;
		sbInitialPing = (SeekBar) dialog.findViewById(R.id.sbInitialPing);
		sbInitialPing.setProgress(MyIV.sonarpinginit);
		sbInitialPing.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		MyIV.sonarpinginit = progress;
        		tvInitialPing.setText("Initial Ping: " + MyIV.sonarpinginit);
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });

		CheckBox chkAutoPing;
		chkAutoPing = (CheckBox) dialog.findViewById(R.id.chkAutoPing);
		chkAutoPing.setChecked(MyIV.sonarautoping);
		chkAutoPing.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				MyIV.sonarautoping = ((CheckBox) v).isChecked();
			}
		});

		final TextView tvInitialGain;
		tvInitialGain = (TextView) dialog.findViewById(R.id.textView6);
		tvInitialGain.setText("Initial Gain: " + MyIV.sonargaininit);
		SeekBar sbInitialGain;
		sbInitialGain = (SeekBar) dialog.findViewById(R.id.sbInitialGain);
		sbInitialGain.setProgress((MyIV.sonargaininit - 600) / 10);
		sbInitialGain.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		MyIV.sonargaininit = 600 + progress * 10;
        		tvInitialGain.setText("Initial Gain: " + MyIV.sonargaininit);
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });

		CheckBox chkAutoGain;
		chkAutoGain = (CheckBox) dialog.findViewById(R.id.chkAutoGain);
		chkAutoGain.setChecked(MyIV.sonarautogain);
		chkAutoGain.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				MyIV.sonarautogain = ((CheckBox) v).isChecked();
			}
		});

		final TextView tvNoiseLevel;
		tvNoiseLevel = (TextView) dialog.findViewById(R.id.textView1);
		tvNoiseLevel.setText("Noise Level: " + MyIV.sonarnoiselevel);
		SeekBar sbNoiseLevel;
		sbNoiseLevel = (SeekBar) dialog.findViewById(R.id.sbNoiseLevel);
		sbNoiseLevel.setProgress(MyIV.sonarnoiselevel);
		sbNoiseLevel.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		MyIV.sonarnoiselevel = progress;
        		tvNoiseLevel.setText("Noise Level: " + MyIV.sonarnoiselevel);
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });

		final TextView tvNoiseReject;
		tvNoiseReject = (TextView) dialog.findViewById(R.id.textView2);
		tvNoiseReject.setText("Noise Reject: " + MyIV.sonarnoisereject);
		SeekBar sbNoiseReject;
		sbNoiseReject = (SeekBar) dialog.findViewById(R.id.sbNoiseReject);
		sbNoiseReject.setProgress(MyIV.sonarnoisereject);
		sbNoiseReject.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		MyIV.sonarnoisereject = progress;
        		tvNoiseReject.setText("Noise Reject: " + MyIV.sonarnoisereject);
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });

		final TextView tvFishDetect;
		tvFishDetect = (TextView) dialog.findViewById(R.id.textView3);
		tvFishDetect.setText("Fish Detect: " + MyIV.sonarfishdetect);
		SeekBar sbFishDetect;
		sbFishDetect = (SeekBar) dialog.findViewById(R.id.sbFishDetect);
		sbFishDetect.setProgress(MyIV.sonarfishdetect);
		sbFishDetect.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		MyIV.sonarfishdetect = progress;
        		tvFishDetect.setText("Fish Detect: " + MyIV.sonarfishdetect);
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });

		CheckBox chkFishSound;
		chkFishSound = (CheckBox) dialog.findViewById(R.id.chkFishSound);
		chkFishSound.setChecked(MyIV.sonarfishsound);
		chkFishSound.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				MyIV.sonarfishsound = ((CheckBox) v).isChecked();
			}
		});

		CheckBox chkFishDepth;
		chkFishDepth = (CheckBox) dialog.findViewById(R.id.chkFishDepth);
		chkFishDepth.setChecked(MyIV.sonarfishdepth);
		chkFishDepth.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				MyIV.sonarfishdepth = ((CheckBox) v).isChecked();
			}
		});

		CheckBox chkFishIcon;
		chkFishIcon = (CheckBox) dialog.findViewById(R.id.chkFishIcon);
		chkFishIcon.setChecked(MyIV.sonarfishicon);
		chkFishIcon.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				MyIV.sonarfishicon = ((CheckBox) v).isChecked();
			}
		});

		final TextView tvRange;
		tvRange = (TextView) dialog.findViewById(R.id.textView4);
		tvRange.setText("Range: " + MyIV.range[MyIV.sonarrangeinx].range);
		SeekBar sbRange;
		sbRange = (SeekBar) dialog.findViewById(R.id.sbRange);
		sbRange.setProgress(MyIV.sonarrangeinx);
		sbRange.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		MyIV.sonarrangeset = progress;
        		tvRange.setText("Range: " + MyIV.range[MyIV.sonarrangeset].range);
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });

		CheckBox chkAutoRange;
		chkAutoRange = (CheckBox) dialog.findViewById(R.id.chkAutoRange);
		chkAutoRange.setChecked(MyIV.sonarautorange);
		chkAutoRange.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				MyIV.sonarautorange = ((CheckBox) v).isChecked();
			}
		});

		Button btnClear = (Button) dialog.findViewById(R.id.btnClearSonar);
		btnClear.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				MyIV.SonarClear();
			}
		});

		Button btnOK = (Button) dialog.findViewById(R.id.btnOK);
		btnOK.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				SaveConfig();
				dialog.dismiss();
			}
		});
        dialog.show();
    }

    private void SetAddEditPlaceDialog(Dialog dialog, int placeinx) {
    	RadioGroup rg1 = (RadioGroup) dialog.findViewById(R.id.rgIcons1);
    	RadioGroup rg2 = (RadioGroup) dialog.findViewById(R.id.rgIcons2);
		EditText mEditLat = (EditText)dialog.findViewById(R.id.editLat);
		EditText mEditLon = (EditText)dialog.findViewById(R.id.editLon);
		EditText mEditTitle = (EditText)dialog.findViewById(R.id.editTitle);
		Button mNext = (Button)dialog.findViewById(R.id.btnNext);
		Button mDelete = (Button)dialog.findViewById(R.id.btnDelete);
		CheckBox mChkMenu =  (CheckBox)dialog.findViewById(R.id.chkMenu);
		CheckBox mChkMap =  (CheckBox)dialog.findViewById(R.id.chkMap);
		// Set text values
		mEditLat.setText(Double.toString(placeLat[placeinx]));
		mEditLon.setText(Double.toString(placeLon[placeinx]));
		mEditTitle.setText(placeTitle[placeinx]);
		// Set check boxes
		mChkMap.setChecked(((BoatNav.placeState[placeinx]) & 2) != 0);
		mChkMenu.setChecked(((BoatNav.placeState[placeinx]) & 4) != 0);
		rg1.clearCheck();
		rg2.clearCheck();
		// Set radio button
		switch (placeIcon[placeinx]) {
        case 0:
        	// None R.id.rbn1
        	rg1.check(R.id.rbn1);
        	break;
        case 22:
        	// Building R.id.rbn2
        	rg1.check(R.id.rbn2);
        	break;
        case 21:
        	// House R.id.rbn3
        	rg1.check(R.id.rbn3);
        	break;
        case 24:
        	// Shallow R.id.rbn4
        	rg1.check(R.id.rbn4);
        	break;
        }
        switch (placeIcon[placeinx]) {
        case 26:
        	// Big fish
        	rg2.check(R.id.rbn5);
        	break;
        case 25:
        	// Small fish
        	rg2.check(R.id.rbn6);
        	break;
        case 19:
        	// Cross
        	rg2.check(R.id.rbn7);
        	break;
        case 20:
        	// City
        	rg2.check(R.id.rbn8);
        	break;
        }
        // Show buttons
		mNext.setVisibility(View.VISIBLE);
		mDelete.setVisibility(View.VISIBLE);
    }

    private void ShowAddEditPlaceDialog(boolean edit, int placeinx) {
    	final Context context = this;
		final Dialog dialog = new Dialog(context);
		dialog.setContentView(R.layout.dialogaddplace);
    	final RadioGroup rg1 = (RadioGroup) dialog.findViewById(R.id.rgIcons1);
    	final RadioGroup rg2 = (RadioGroup) dialog.findViewById(R.id.rgIcons2);
    	final boolean medit = edit;
    	mplaceinx = placeinx;
    	if (edit) {
			dialog.setTitle("Edit Place");
			SetAddEditPlaceDialog(dialog, mplaceinx);
		} else {
			dialog.setTitle("Add Place");
			EditText mEditLat = (EditText)dialog.findViewById(R.id.editLat);
			EditText mEditLon = (EditText)dialog.findViewById(R.id.editLon);
			mEditLat.setText("" + MyIV.curlat);
			mEditLon.setText("" + MyIV.curlon);
		}

		Button btnOK = (Button) dialog.findViewById(R.id.btnOK);
		btnOK.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				int i = mplaceinx;

				EditText mEditTitle = (EditText)dialog.findViewById(R.id.editTitle);
				EditText mEditLat = (EditText)dialog.findViewById(R.id.editLat);
				EditText mEditLon = (EditText)dialog.findViewById(R.id.editLon);
				CheckBox mChkMenu =  (CheckBox)dialog.findViewById(R.id.chkMenu);
				CheckBox mChkMap =  (CheckBox)dialog.findViewById(R.id.chkMap);
				// Returns an integer which represents the selected radio button's ID
				int rbnsel1 = rg1.getCheckedRadioButtonId();
				int rbnsel2 = rg2.getCheckedRadioButtonId();

				placeState[i] = 1;
				if (mChkMap.isChecked()) {
					placeState[i] |= 2;
				}
				if (mChkMenu.isChecked()) {
					placeState[i] |= 4;
				}

	        	switch (rbnsel1) {
	            case R.id.rbn1:
	            	// None
					placeIcon[i] = 0;
	            	break;
	            case R.id.rbn2:
	            	// Building
					placeIcon[i] = 22;
	            	break;
	            case R.id.rbn3:
	            	// House
					placeIcon[i] = 21;
	            	break;
	            case R.id.rbn4:
	            	// Shallow
					placeIcon[i] = 24;
	            	break;
	            }
	            switch (rbnsel2) {
	            case R.id.rbn5:
	            	// Big fish
					placeIcon[i] = 26;
	            	break;
	            case R.id.rbn6:
	            	// Small fish
					placeIcon[i] = 25;
	            	break;
	            case R.id.rbn7:
	            	// Cross
					placeIcon[i] = 19;
	            	break;
	            case R.id.rbn8:
	            	// City
					placeIcon[i] = 20;
	            	break;
	            }
	        	
	        	placeTitle[i] = mEditTitle.getText().toString();
				try {
					placeLat[i] = Double.valueOf(mEditLat.getText().toString());
					placeLon[i] = Double.valueOf(mEditLon.getText().toString());
        			mIV.invalidate();
    				dialog.dismiss();
    				SavePlaces();
				} catch (Exception e) {
					// Lat or Lon not valid
					if (!medit) {
						DeletePlace(i);
					}
				}
			}
		});

		Button btnCancel = (Button) dialog.findViewById(R.id.btnCancel);
		btnCancel.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				dialog.dismiss();
			}
		});

		Button btnNext = (Button) dialog.findViewById(R.id.btnNext);
		btnNext.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				mplaceinx = FindNonFreePlace(mplaceinx+1);
				if (mplaceinx >= 16) {
					mplaceinx = FindNonFreePlace(0);
				}
				SetAddEditPlaceDialog(dialog, mplaceinx);
			}
		});

		Button btnDelete = (Button) dialog.findViewById(R.id.btnDelete);
		btnDelete.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				DeletePlace(mplaceinx);
				dialog.dismiss();
			}
		});

        rg1.setOnCheckedChangeListener(new  RadioGroup.OnCheckedChangeListener() {
	        public void onCheckedChanged(RadioGroup group,int checkedId) {
	        	if (!rginuse) {
	        		rginuse = true;
		    		rg2.clearCheck();
	        		rginuse = false;
	        	}
	        }
       	});
        	
        rg2.setOnCheckedChangeListener(new  RadioGroup.OnCheckedChangeListener() {
	        public void onCheckedChanged(RadioGroup group,int checkedId) {
	        	if (!rginuse) {
	        		rginuse = true;
		    		rg1.clearCheck();
	        		rginuse = false;
	        	}
	        }
       	});
		btnCancel.requestFocus();
        dialog.show();
    }

	@Override
	public boolean onPrepareOptionsMenu(Menu menu) {
		MenuItem menuitem = menu.findItem(R.id.item5);
    	SubMenu submenu = menuitem.getSubMenu();
    	// Remove sub menu items
		int i=0;
		while (i<16) {
			menuitem = submenu.findItem(i);
			if (menuitem != null) {
				submenu.removeItem(i);
			}
			i++;
		}
		// Add sub menu items
		i=0;
		while (i<16) {
			if (((placeState[i]) & 4) != 0 && placeTitle[i] != "") {
				menuitem = submenu.add(Menu.NONE, i, 0, placeTitle[i]);
			}
			i++;
		}
    	return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle item selection
    	int i = item.getItemId();
    	if (i >= 0 && i < 16) {
        	// Goto place
        	MyIV.GoTo(placeLat[i], placeLon[i], true);
        	mIV.invalidate();
            return true;
    	} else {
            switch (i) {
            case R.id.action_lock:
            	MyIV.locktogps = !MyIV.locktogps;
            	if (MyIV.locktogps) {
            		item.setIcon(R.drawable.lock);
            		MyIV.sonarofs = 0;
            	} else {
            		item.setIcon(R.drawable.unlock);
            	}
                return true;
            case R.id.action_zoomin:
            	// Zoom In
            	if (MyIV.Zoom(1)) {
        			mIV.invalidate();
            	}
                return true;
            case R.id.action_zoomout:
            	// Zoom Out
            	if (MyIV.Zoom(-1)) {
        			mIV.invalidate();
            	}
                return true;
            case R.id.action_mode:
            	// Switch mode
            	if (MyIV.viewmode == 3) {
            		MyIV.viewmode = 0;
            	} else {
            		MyIV.viewmode++;
            	}
            	switch (MyIV.viewmode) {
        		case 0:
        			MyIV.mapwt = MyIV.scrnwt;
        			MyIV.sonarwt = 0;
        			MyIV.satelitewt = 0;
        			break;
        		case 1:
        			MyIV.mapwt = 0;
        			MyIV.satelitewt = 0;
        			MyIV.sonarwt = MyIV.scrnwt;
        			break;
        		case 2:
        			MyIV.mapwt = MyIV.scrnwt / 2;
        			MyIV.satelitewt = 0;
        			MyIV.sonarwt = MyIV.scrnwt / 2;
        			break;
        		case 3:
        			MyIV.satelitewt = MyIV.scrnwt / 2;
        			MyIV.mapwt = MyIV.scrnwt / 2;
        			MyIV.sonarwt = MyIV.scrnwt / 2;
        			break;
            	}
       			mIV.invalidate();
                return true;
            case R.id.item3:
            	// Land / Sea Map
               	MyIV.land = !MyIV.land;
               	MyIV.Zoom(0);
               	mIV.invalidate();
                return true;
            case R.id.item5:
            	// Goto
                return true;
            case R.id.item6:
				i = FindFreePlace();
				if (i < 16) {
	            	// Add new place, show custom dialog
	            	ShowAddEditPlaceDialog(false, i);
	            	return true;
				}
            	return false;
            case R.id.item7:
            	i = FindNonFreePlace(0);
				if (i < 16) {
	            	// Edit place, show custom dialog
	            	ShowAddEditPlaceDialog(true, i);
	            	return true;
				}
            	return false;
            case R.id.item8:
            	try {
            		if (MyIV.mode == 2) {
        				if (BoatNav.btconnected) {
        					MyIV.mode = 0;
        				} else {
        					MyIV.mode = 1;
        				}
            			replayfile.close();
                    	MyIV.ClearTrail();
            		} else {
                    	ShowReplayDialog();
            		}
                	return true;
            	} catch (Exception e) {
            	}
            	return false;
            case R.id.item12:
            	ShowBluetoothDialog();
            	return true;
            case R.id.item10:
            	ShowGPSSetupDialog();
            	return true;
            case R.id.item11:
            	ShowSonarSetupDialog();
            	return true;
            }
    	}
        return super.onOptionsItemSelected(item);
    }
    
	private void MakeTransparent() {
		int[] pix = new int[MyIV.MAPMAXICON * 16 * 16];
		mIcons.getPixels(pix, 0, MyIV.MAPMAXICON * 16, 0, 0, MyIV.MAPMAXICON * 16, 16);
		int index;
		
		for (int y = 0; y < 16; y++) {	    
			for (int x = 0; x < MyIV.MAPMAXICON * 16; x++) {	    	    	
				index = y * MyIV.MAPMAXICON * 16 + x;
				if (pix[index] == Color.MAGENTA) {
					pix[index] = Color.TRANSPARENT;
				}
			}
		}
		Bitmap bm = Bitmap.createBitmap(MyIV.MAPMAXICON * 16, 16, Bitmap.Config.ARGB_8888);
		bm.setPixels(pix, 0, MyIV.MAPMAXICON * 16, 0, 0, MyIV.MAPMAXICON * 16, 16); 	
		mIcons.recycle();
		mIcons = bm;
		pix = null;
	}

	private void MakeIcons() {
		int x=0, i;
		for (i = 0; i < MyIV.MAPMAXICON; i++) {
			bmp[i + MyIV.MAPMAXBMP].bm = Bitmap.createBitmap(mIcons, x, 0, 16, 16);
			x = x + 16;
		}
	}

	private int FindFreePlace() {
		int i = 0;
		while (i < 16) {
			if (placeState[i] == 0) {
				break;
			}
			i++;
		}
		return i;
	}
	
	private int FindNonFreePlace(int search) {
		int i = search;
		while (i < 16) {
			if (placeState[i] != 0) {
				break;
			}
			i++;
		}
		return i;
	}
	
	private void DeletePlace(int index) {
		placeState[index] = 0;
		placeIcon[index] = 0;
		placeTitle[index] = "";
		placeLat[index] = 0;
		placeLon[index] = 0;
	}
	
	private int GetTopBarHeight() {
		int sbarHeight = 0;
		int actionBarHeight = 0;
		int resourceId = getResources().getIdentifier("status_bar_height", "dimen", "android");
		if (resourceId > 0) {
			sbarHeight = getResources().getDimensionPixelSize(resourceId);
		}
        // Calculate ActionBar height
        TypedValue tv = new TypedValue();
        if (getTheme().resolveAttribute(android.R.attr.actionBarSize, tv, true)) {
            actionBarHeight = TypedValue.complexToDimensionPixelSize(tv.data,getResources().getDisplayMetrics());
        }
        return actionBarHeight + sbarHeight;
	}

	// ZOOM
	// http://www.androidhub4you.com/2013/05/zoom-image-demo-in-android-zoom-image.html
	@Override
	public boolean onTouchEvent(MotionEvent event) {
		switch (event.getAction()) {
		case MotionEvent.ACTION_UP:
			return (true);
		case MotionEvent.ACTION_POINTER_UP:
			return (true);
		case MotionEvent.ACTION_DOWN:
			xs = MyIV.xofs;
			ys = MyIV.yofs;
			sxs = MyIV.sonarofs;
			xd = event.getAxisValue(0);
			yd = event.getAxisValue(1);
			MyIV.cpx = (int)xd;
			MyIV.cpy = (int)yd - GetTopBarHeight();
			mIV.invalidate();
			return (true);
		case MotionEvent.ACTION_POINTER_DOWN:
			return (true);
		case MotionEvent.ACTION_MOVE:
			if (!MyIV.locktogps) {
				if (xd < MyIV.mapwt) {
					MyIV.xofs = xs - (xd - event.getAxisValue(0, event.getPointerCount() - 1));
					MyIV.yofs = ys - (yd - event.getAxisValue(1, event.getPointerCount() - 1));
					mIV.invalidate();
				} else if (xd > MyIV.mapwt) {
					MyIV.sonarofs = (int)(sxs - (xd - event.getAxisValue(0, event.getPointerCount() - 1)));
					if (MyIV.sonarofs < 0) {
						MyIV.sonarofs = 0;
					}
					mIV.invalidate();
				}
			}
			return (true);
		}
		return super.onTouchEvent(event);
	}

	private static String readFileAsString(String filename) {
		String file = Environment.getExternalStorageDirectory() + File.separator + "Map" + File.separator + filename;

		byte[] bytes = new byte[(int) new File(file).length()];
	    BufferedInputStream stream;
		try {
			stream = new BufferedInputStream(new FileInputStream(file));
		    try {
				stream.read(bytes);
			} catch (Exception e) {
		         Log.e("MYTAG", "File err" + e.toString());
			}
			stream.close();
		} catch (Exception e) {
          Log.e("MYTAG", "File err" + e.toString());
		}
	    return new String(bytes);
	}

	private static boolean writeStringToFile(String filename, String filedata) {
		File sdCard = Environment.getExternalStorageDirectory();
		File directory = new File (sdCard.getAbsolutePath() + "/Map");
		File file = new File(directory, filename);
		try {
			FileOutputStream fOut = new FileOutputStream(file);
			OutputStreamWriter osw = new OutputStreamWriter(fOut);
			osw.write(filedata);
			osw.flush();
			osw.close();
			return true;
		} catch (Exception e) {
	          Log.e("MYTAG", "File write err" + e.toString());
		}
		return false;
	}

	private void playFishAlarm() {
		soundplaying = 10;
		SoundPool sp = new SoundPool(5, AudioManager.STREAM_MUSIC, 0);
		int iTmp = sp.load(getBaseContext(), R.raw.fish, 1);
		sp.play(iTmp, 1, 1, 0, 0, 1);
		MediaPlayer mPlayer = MediaPlayer.create(getBaseContext(), R.raw.fish);
		mPlayer.start();
//	    MediaPlayer mp = MediaPlayer.create(this, R.raw.fish);
//	    mp.start();
//	    mp.setOnCompletionListener(new OnCompletionListener() {
//	        @Override
//	        public void onCompletion(MediaPlayer mp) {
//	            mp.release();
//				soundplaying = 0;
//	        }
//	    });
	}

	public void msgbox(String title,String message) {
	    AlertDialog.Builder dlgAlert  = new AlertDialog.Builder(this);                      
	    dlgAlert.setTitle(title); 
	    dlgAlert.setMessage(message); 
	    dlgAlert.setPositiveButton("OK",new DialogInterface.OnClickListener() {
	        public void onClick(DialogInterface dialog, int whichButton) {
	        }
	    });
	    dlgAlert.setCancelable(true);
	    dlgAlert.create().show();
	}

}
