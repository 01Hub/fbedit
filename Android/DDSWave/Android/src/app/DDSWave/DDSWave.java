package app.DDSWave;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.Method;
import java.util.Timer;
import java.util.TimerTask;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Canvas;
import android.graphics.Region.Op;
import android.graphics.drawable.BitmapDrawable;
import android.os.Bundle;
import android.util.Log;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.view.View.OnClickListener;
import android.view.WindowManager.LayoutParams;
import android.view.inputmethod.EditorInfo;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;
import android.widget.Toast;
import android.widget.SeekBar.OnSeekBarChangeListener;
import app.DDSWave.R;

public class DDSWave extends Activity {
	
	private static final int STM32_CLOCK = 200000000;
	private static ImageView mIV;
	private static Bitmap bmpwave;
	private static Paint paint = new Paint(Paint.FAKE_BOLD_TEXT_FLAG);
	private static Canvas canvas;
	private boolean StartUp = true;
	private final static int REQUEST_ENABLE_BT = 1;
    protected BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
    BluetoothDevice mBluetoothDevice = null;
    protected BluetoothSocket mBluetoothSocket = null;
	private static String btdeviceaddr = "98:D3:31:B2:0D:40";
    public static OutputStream mOutputStream = null;
    public static InputStream mInputStream = null;
    public static boolean btconnected = false;
    public static boolean nobt = false;
	private Timer tmr = new Timer();
	private int tmrcnt = 0;
	private int wt;
	private int ht;
	public static int mode = 4;
	public static int tmpmode;
	public static final int WAVEGRID = 50;
	public static final int WAVEGRIDX = 10;
	private static final int WAVEGRIDY = 8;
	private int WAVEGRIDXOFS = 0;
	private int WAVEGRIDYOFS = 0;
	private String wavestr[] = new String[9];

	// DDS
	private static final short DDS_PHASESET = 1;
	private static final short DDS_WAVESET = 2;
	private static final short DDS_SWEEPSET = 3;
    private static STM32_DDS dds = new STM32_DDS();
    private static boolean ddssend = false;
	private static final int DDSSIZE = 2048;
	private short ddsWave[] = new short[DDSSIZE];
	private int ddsfrqhz = 0;
	private int ddsfrqkhz = 5;
	private boolean ddsfrqhzsel = false;
	private int ddsamp = 100;
	private int ddsdcofs = 300;
	private int ddswave=0;

	// Scope
	public static final int SCPXSIZE = (WAVEGRID * WAVEGRIDX);
	public static final int SCPYSIZE = (WAVEGRID * WAVEGRIDY);
    private static STM32_SCP scp = new STM32_SCP();
    public static short scpWave[] = new short[SCPXSIZE];
	private int scpsr = 67;
	private int scptd = 10;
	private int scpvd = 8;
	private int scpvp = (150 + 13);
	private int scptl = 150;
	private byte scptr = 1;
	private String scpfrq = "";
	private boolean scpsample = false;
	private boolean scpsampledone = false;
	private boolean scphold = false;

	// LGA
	public static final int LGASIZE = 32 * 1024;
	private static final int LGAWIDTH = 10;
	private int lgasr  = 0;
	private String lgasrstr[] = {"1KHz","2KHz","5KHz","10KHz","20KHz","50KHz","100KHz","200KHz","500KHz","1MHz","2MHz","5MHz","10MHz","20MHz","40MHz"};
	private int lgasrint[] = {199999,99999,39999,19999,9999,3999,1999,999,399,199,99,39,19,9,4};
	private int lgabuff  = 0;
	private byte lgatrg = (byte)0x00;
	private byte lgamask = (byte)0x00;
    private static STM32_LGA lga = new STM32_LGA();
	private float xd,xs, lgaxofs;
	private int lgatrgpos = 100;

    // HSC
    private static boolean hscsend = false;
	private int hscset = 2;
	private int hscfrq = 1000;
	private int hscarr = 1;
	private int hscclk = 49999;
	private int hscres;

	@Override
	public void onCreate(Bundle icicle) {
		super.onCreate(icicle);

		int i;
		requestWindowFeature(Window.FEATURE_NO_TITLE);
		requestWindowFeature(Window.FEATURE_ACTION_BAR_OVERLAY);
		getWindow().setFlags(
		WindowManager.LayoutParams.FLAG_FULLSCREEN,  
		WindowManager.LayoutParams.FLAG_FULLSCREEN);
		setContentView(R.layout.main);
		mIV=(ImageView) this.findViewById(R.id.ImageView1);

		final Button btnDDS = (Button) this.findViewById(R.id.btnDDS);
		final Button btnSCOPE = (Button) this.findViewById(R.id.btnSCOPE);
		final Button btnLGA = (Button) this.findViewById(R.id.btnLGA);
		final Button btnHSC = (Button) this.findViewById(R.id.btnHSC);
		final Button btnLCM_C = (Button) this.findViewById(R.id.btnLCM_C);
		final Button btnLCM_L = (Button) this.findViewById(R.id.btnLCM_L);
		final Button btnSETUP = (Button) this.findViewById(R.id.btnSETUP);
		final TextView tvText = (TextView) this.findViewById(R.id.tvText);

		btnDDS.setBackgroundColor(Color.DKGRAY);
		btnSCOPE.setBackgroundColor(Color.DKGRAY);
		btnLGA.setBackgroundColor(Color.DKGRAY);
		btnHSC.setBackgroundColor(Color.DKGRAY);
		btnLCM_C.setBackgroundColor(Color.GRAY);
		btnLCM_L.setBackgroundColor(Color.DKGRAY);
		btnSETUP.setBackgroundColor(Color.DKGRAY);
		for (i = 0;i<9;i++) {
			wavestr[i] = "";//"Test 12345";
		}
		ddsSineWave();
		GenSCPWave();
		for (i = 0;i<LGASIZE;i++) {
			BlueTooth.btreadbuffer[i] = (byte)(i & 255);
		}
		btnDDS.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				btnSETUP.setText("Setup");
				mode = 0;
				btnSCOPE.setBackgroundColor(Color.DKGRAY);
				btnLGA.setBackgroundColor(Color.DKGRAY);
				btnHSC.setBackgroundColor(Color.DKGRAY);
				btnLCM_C.setBackgroundColor(Color.DKGRAY);
				btnLCM_L.setBackgroundColor(Color.DKGRAY);
				btnDDS.setBackgroundColor(Color.GRAY);
				DrawDDSWave();
			}
		});
		btnSCOPE.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				btnSETUP.setText("Setup");
				mode = 1;
				btnDDS.setBackgroundColor(Color.DKGRAY);
				btnHSC.setBackgroundColor(Color.DKGRAY);
				btnLGA.setBackgroundColor(Color.DKGRAY);
				btnLCM_C.setBackgroundColor(Color.DKGRAY);
				btnLCM_L.setBackgroundColor(Color.DKGRAY);
				btnSCOPE.setBackgroundColor(Color.GRAY);
				DrawScopeWave();
			}
		});
		btnLGA.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				btnSETUP.setText("Setup");
				mode = 2;
				btnDDS.setBackgroundColor(Color.DKGRAY);
				btnSCOPE.setBackgroundColor(Color.DKGRAY);
				btnHSC.setBackgroundColor(Color.DKGRAY);
				btnLCM_C.setBackgroundColor(Color.DKGRAY);
				btnLCM_L.setBackgroundColor(Color.DKGRAY);
				btnLGA.setBackgroundColor(Color.GRAY);
				DrawLGAWave();
			}
		});
		btnHSC.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				btnSETUP.setText("Setup");
				mode = 3;
				btnDDS.setBackgroundColor(Color.DKGRAY);
				btnSCOPE.setBackgroundColor(Color.DKGRAY);
				btnLGA.setBackgroundColor(Color.DKGRAY);
				btnLCM_C.setBackgroundColor(Color.DKGRAY);
				btnLCM_L.setBackgroundColor(Color.DKGRAY);
				btnHSC.setBackgroundColor(Color.GRAY);
				DrawHSCWave();
			}
		});
		btnLCM_C.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				btnSETUP.setText("Calibrate");
				mode = 4;
				btnDDS.setBackgroundColor(Color.DKGRAY);
				btnSCOPE.setBackgroundColor(Color.DKGRAY);
				btnLGA.setBackgroundColor(Color.DKGRAY);
				btnHSC.setBackgroundColor(Color.DKGRAY);
				btnLCM_L.setBackgroundColor(Color.DKGRAY);
				btnLCM_C.setBackgroundColor(Color.GRAY);
			}
		});
		btnLCM_L.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				btnSETUP.setText("Calibrate");
				mode = 5;
				btnDDS.setBackgroundColor(Color.DKGRAY);
				btnSCOPE.setBackgroundColor(Color.DKGRAY);
				btnLGA.setBackgroundColor(Color.DKGRAY);
				btnHSC.setBackgroundColor(Color.DKGRAY);
				btnLCM_C.setBackgroundColor(Color.DKGRAY);
				btnLCM_L.setBackgroundColor(Color.GRAY);
			}
		});
		btnSETUP.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (btconnected || nobt) {
					//Log.d("MYTAG", "Setup");
					if (mode == 0) {
						ShowDDSSetupDialog();
					} else if (mode == 1) {
						ShowSCPSetupDialog();
					} else if (mode == 2) {
						ShowLGASetupDialog();
					} else if (mode == 3) {
						ShowHSCSetupDialog();
					} else if (mode == 4 || mode == 5) {
						tmpmode = mode;
						mode = 6;
	    				tvText.setText("Calibrate");
					}
				} else {
    				tvText.setText("Connecting");
					BTConnect();
					btnSETUP.setText("Calibrate");
				}
			}
		});

		tmr.schedule(new TimerTask() {
			@Override
			public void run() {
				TimerMethod(tvText);
			}
		}, 1000, 10);

    	Runnable runnable = new Runnable() {
	        public void run() {
	        	while (true) {
	    			if (nobt == false) {
	    				if (mode == 1) {
	    					if (scphold == false && scpsample == false) {
	    						scpsample = true;
	    						scpsampledone = false;
			    				scpfrq = scp.SendSCP();
	    						scpsampledone = true;
	    					}
	    				}
	    			}
	        	}
	        }
    	};
    	Thread mythread = new Thread(runnable);
    	mythread.start();
	}
	
    private void TimerMethod(final TextView tvText)
	{
    	runOnUiThread(new Runnable() {
    	    public void run() {
    			DrawBTStatus();
				if ((btconnected == true || nobt == true) && BlueTooth.btmode == BlueTooth.CMD_DONE && (tmrcnt & 31) == 0 && BlueTooth.btbusy == false) {
	    			String s;
	    			if (nobt == false) {
		    			switch (mode) {
		    			case 0:
		    				// DDS Wave
		    				if (ddssend) {
		    					ddssend = false;
		    					dds.SendDDS();
		    					//Toast.makeText(getApplicationContext(), "DDS Updated", Toast.LENGTH_LONG).show();
		    				}
		    				break;
		    			case 1:
		    				// Scope
		    				if (scphold == false) {
		    					if (scpsampledone == true) {
				    				tvText.setText(scpfrq);
				    				DrawScopeWave();
		    						scpsample = false;
		    						scpsampledone = false;
		    					} else {
		    						
		    					}
		    				}
		    				break;
		    			case 2:
		    				// LGA
		    				break;
		    			case 3:
		    				// HSC
		    				if (hscsend) {
		    					hscsend = false;
		    					BlueTooth.BTHscSet(hscarr, hscclk);
		    					//Toast.makeText(getApplicationContext(), "HSC Updated arr: " + hscarr + " div: " + hscclk, Toast.LENGTH_LONG).show();
		    				} else {
		    					s = BlueTooth.BTHscGet();
			    				tvText.setText(s);
		    				}
		    				break;
		    			case 4:
		    				// Capacitor
		    				s = BlueTooth.BTLcmCap();
		    				tvText.setText(s);
		    				break;
		    			case 5:
		    				// Inductor
		    				s = BlueTooth.BTLcmInd();
		    				tvText.setText(s);
		    				break;
		    			case 6:
		    				// Calibrate LCM
		    				BlueTooth.BTLcmCal();
		    				break;
		    			}
	    			}
				}
				tmrcnt++;
    	    }
    	});
	}

    private void ddsSineWave() {
		double y;
		for (int x = 0;x < DDSSIZE;x++) {
			y=(float)Math.sin((float)(2*Math.PI) * (float)x / 2048.0D) * 2047.0;
			ddsWave[x] = (short)(2048 - (int)y);
		}
	}

	private void ddsTriangleWave() {
		short y = 2048;
		short dir=4;
		for (int x = 0;x < DDSSIZE;x++) {
			ddsWave[x] = y;
			y+=dir;
			if (y>4095) {
				dir = -4;
				y+=dir;
			} else if (y<0) {
				dir=4;
				y+=dir;
			}
		}
	}

	private void ddsSquareWave() {
		short y = 4095;
		ddsWave[0] = 2048;
		ddsWave[2047] = 2048;
		for (int x = 1;x < DDSSIZE - 1;x++) {
			if (x == 1024) {
				y=0;
			}
			ddsWave[x] = y;
		}
	}

	private void GenSCPWave() {
		double y;
		for (int x = 0;x < SCPXSIZE;x++) {
			y=(float)Math.sin((float)(2*Math.PI) * (float)x / (float)SCPYSIZE) * 2047.0;
			scpWave[x] = (short)(2048 - (int)y);
		}
	}

	private void DrawBTStatus() {
		if (btconnected == true) {
			if (BlueTooth.btbusy) {
		        paint.setColor(Color.RED);
			} else {
		        paint.setColor(Color.GREEN);
			}
		} else {
	        paint.setColor(Color.GRAY);
		}
		canvas.drawCircle(500, 10, 8, paint);
		mIV.setImageDrawable(new BitmapDrawable(getResources(), bmpwave));
	}

	private void DrawGrid() {
		int x=WAVEGRIDXOFS;
		int y=WAVEGRIDYOFS;
		int i=0;
		bmpwave.eraseColor(Color.BLUE);
		paint.setStrokeWidth(1);
        paint.setColor(Color.DKGRAY);
		while (i <= WAVEGRIDY) {
	        canvas.drawLine(WAVEGRIDXOFS, y, WAVEGRID*10+WAVEGRIDXOFS, y, paint);
	        y += WAVEGRID;
	        i++;
		}
		i=0;
		while (i <= WAVEGRIDX) {
	        canvas.drawLine(x, WAVEGRIDYOFS, x, WAVEGRID*WAVEGRIDY+WAVEGRIDYOFS, paint);
	        x+=WAVEGRID;
	        i++;
		}
		paint.setTextSize(18);
        paint.setColor(Color.WHITE);
		canvas.drawText(wavestr[0], WAVEGRIDYOFS, y, paint);
		canvas.drawText(wavestr[1], WAVEGRIDYOFS + 166, y, paint);
		canvas.drawText(wavestr[2], WAVEGRIDYOFS + 332, y, paint);
        y += WAVEGRID / 2;
		canvas.drawText(wavestr[3], WAVEGRIDYOFS, y, paint);
		canvas.drawText(wavestr[4], WAVEGRIDYOFS + 166, y, paint);
		canvas.drawText(wavestr[5], WAVEGRIDYOFS + 332, y, paint);
        y += WAVEGRID / 2;
		canvas.drawText(wavestr[6], WAVEGRIDYOFS, y, paint);
		canvas.drawText(wavestr[7], WAVEGRIDYOFS + 166, y, paint);
		canvas.drawText(wavestr[8], WAVEGRIDYOFS + 332, y, paint);
		DrawBTStatus();
	}

	private void DrawDDSWave() {
		int frq, xp, yp;
		int x = WAVEGRIDXOFS;
		int y = WAVEGRIDYOFS;
		int i;
		double per;
		
		for (i = 0;i<9;i++) {
			wavestr[i] = "";
		}
		frq = ddsfrqkhz * 1000 + ddsfrqhz;
		wavestr[0] = "Frq: " + frq + "Hz";
		per = 1000000000.0 / (double)frq;
		wavestr[1] = "Per: " + String.format("%.1f",per) + "ns";
		wavestr[3] = "Vpp: " + ddsamp * 10 + "mV";
		wavestr[4] = "Vmin: " + (((ddsdcofs - 300) * 10) - ddsamp * 5) + "mV";
		wavestr[5] = "Vmax: " + (((ddsdcofs - 300) * 10) + ddsamp * 5) + "mV";
		DrawGrid();
		canvas.clipRect(WAVEGRIDXOFS,WAVEGRIDYOFS,WAVEGRID * WAVEGRIDX + WAVEGRIDXOFS + 1,WAVEGRID * WAVEGRIDY + WAVEGRIDYOFS + 1, Op.REPLACE);
		paint.setStrokeWidth(2);
        paint.setColor(Color.YELLOW);
        i = 0;
		xp = ((i / 8) * WAVEGRID * WAVEGRIDX) / 256;
		yp = (((2048 - ddsWave[i]) / 16) * WAVEGRID * 6) / 256;
		yp = WAVEGRID * 4  + ((yp * ddsamp) / 300 - (ddsdcofs - 300)) / 2;
		i++;
		while (i < DDSSIZE) {
			x = ((i / 8) * WAVEGRID * WAVEGRIDX) / 256;
			y = (((2048 - ddsWave[i]) / 16) * WAVEGRID * 6) / 256;
			y = WAVEGRID * 4 + ((y * ddsamp) / 300 - (ddsdcofs - 300)) / 2;
	        canvas.drawLine(xp + WAVEGRIDXOFS, yp + WAVEGRIDYOFS, x + WAVEGRIDXOFS, y + WAVEGRIDYOFS, paint);
			xp = x;
			yp = y;
			i++;
		}
		mIV.setImageDrawable(new BitmapDrawable(getResources(), bmpwave));
		canvas.clipRect(0,0,wt,ht, Op.REPLACE);
	}

	private void DrawScopeWave() {
		int xp, yp;
		int x=WAVEGRIDXOFS;
		int y=WAVEGRIDYOFS;
		int i;
		double per;
		for (i = 0;i<9;i++) {
			wavestr[i] = "";
		}
		wavestr[0] = "Frq: " + scp.scpfrq + "Hz";
		per = 1000000000.0 / (double)scp.scpfrq;
		wavestr[1] = "Per: " + String.format("%.1f",per) + "ns";
		wavestr[3] = scp.scptdstr[scptd] + " / Div";
		wavestr[6] = scp.scpvdstr[scpvd] + " / Div";
		DrawGrid();
		canvas.clipRect(WAVEGRIDXOFS,WAVEGRIDYOFS,WAVEGRID * WAVEGRIDX + WAVEGRIDXOFS + 1,WAVEGRID * WAVEGRIDY + WAVEGRIDYOFS + 1, Op.REPLACE);
		paint.setStrokeWidth(2);
        paint.setColor(Color.YELLOW);
		xp = 0;
		i = 0;
		// Invert
		yp = 4095 - scpWave[i];
		// Scale to grid
		yp = (yp * SCPYSIZE) / 4095;
		i++;
		while (i < SCPXSIZE) {
			x = i;
			// Invert
			y = 4095 - scpWave[i];
			// Scale to grid
			y = (y * SCPYSIZE) / 4095;
	        canvas.drawLine(xp + WAVEGRIDXOFS, yp + WAVEGRIDYOFS, x + WAVEGRIDXOFS, y + WAVEGRIDYOFS, paint);
			xp = x;
			yp = y;
			i++;
		}
		if (scptr != 2) {
			
		}
		paint.setStrokeWidth(1);
        paint.setColor(Color.RED);
        yp = WAVEGRID * (WAVEGRIDY / 2);
        yp += 150 - scptl;
        canvas.drawLine(WAVEGRIDXOFS, WAVEGRIDYOFS + yp, WAVEGRIDXOFS + WAVEGRID * WAVEGRIDX, WAVEGRIDYOFS + yp, paint);
		mIV.setImageDrawable(new BitmapDrawable(getResources(), bmpwave));
		canvas.clipRect(0,0,wt,ht, Op.REPLACE);
	}

	private void DrawLGAWave() {
		int x, z, i, ofs;
		int y = WAVEGRIDYOFS + WAVEGRID / 3;
		byte bit,prv;
		for (i = 0;i<9;i++) {
			wavestr[i] = "";
		}
		DrawGrid();
		canvas.clipRect(WAVEGRIDXOFS,WAVEGRIDYOFS,WAVEGRID * WAVEGRIDX + WAVEGRIDXOFS + 1,WAVEGRID * WAVEGRIDY + WAVEGRIDYOFS + 1, Op.REPLACE);
		paint.setTextSize(15);
		paint.setColor(Color.WHITE);
		i = 0;
		while (i < 8) {
			if ((i & 1) != 0) {
		        paint.setColor(Color.YELLOW);
			} else {
		        paint.setColor(Color.WHITE);
			}
			canvas.drawText("D" + i, WAVEGRIDXOFS + 2, y, paint);
			y += WAVEGRID;
			i++;
		}
		paint.setStrokeWidth(2);
		ofs = (int)lgaxofs / (WAVEGRID / LGAWIDTH);
		if (lgatrgpos >= ofs && lgatrgpos <= (ofs + (WAVEGRID * WAVEGRIDX)) / (WAVEGRID / LGAWIDTH)) {
			paint.setColor(Color.RED);
	        canvas.drawLine(WAVEGRIDXOFS - ofs * (WAVEGRID / LGAWIDTH) + lgatrgpos*5, WAVEGRIDYOFS, WAVEGRIDXOFS - ofs * (WAVEGRID / LGAWIDTH) + lgatrgpos*5, WAVEGRIDYOFS + WAVEGRID * WAVEGRIDX, paint);
		}
		y = WAVEGRIDYOFS + WAVEGRID;
		bit = 1;
		z = 0;
		while (bit != 0) {
			if ((z & 1) != 0) {
		        paint.setColor(Color.YELLOW);
			} else {
		        paint.setColor(Color.WHITE);
			}
			i = (int)lgaxofs / (WAVEGRID / LGAWIDTH);
			x = WAVEGRIDXOFS;
			prv = BlueTooth.btreadbuffer[i];
			while (i < LGASIZE) {
				/* Draw L or H */
				if ((BlueTooth.btreadbuffer[i] & bit) == 0) {
					/* Low */
			        canvas.drawLine(x, y, x + WAVEGRID / LGAWIDTH, y, paint);
				} else {
					/* High */
			        canvas.drawLine(x, y - WAVEGRID / 2, x + WAVEGRID / LGAWIDTH, y - WAVEGRID / 2, paint);
				}
				if ((prv & bit) != (BlueTooth.btreadbuffer[i] & bit)) {
					/* Draw transition */
			        canvas.drawLine(x, y, x, y - WAVEGRID / 2, paint);
				}
				x += WAVEGRID / LGAWIDTH;
				if (x - WAVEGRIDXOFS >= WAVEGRID * WAVEGRIDX) {
					break;
				}
				prv = BlueTooth.btreadbuffer[i];
				i++;
			}
			bit <<=1;
			y += WAVEGRID;
			z++;
		}
		mIV.setImageDrawable(new BitmapDrawable(getResources(), bmpwave));
		canvas.clipRect(0,0,wt,ht, Op.REPLACE);
	}

	private void DrawHSCWave() {
		int i, xp, yp;
		int x = WAVEGRIDXOFS;
		int y = WAVEGRIDYOFS;
		double dut, per;
		for (i = 0;i<9;i++) {
			wavestr[i] = "";
		}
		wavestr[0] = "Frq: " + hscfrq + "Hz";
		per = 1000000000.0 / (double)hscfrq;
		wavestr[1] = "Per: " + String.format("%.1f",per) + "ns";
		dut = ((double)((hscarr + 1) >> 1) / ((double)hscarr + 1.0));
		wavestr[2] = "Dut: " + String.format("%.1f",100.0 * dut) + "%";
		DrawGrid();
		canvas.clipRect(WAVEGRIDXOFS,WAVEGRIDYOFS,WAVEGRID * WAVEGRIDX + WAVEGRIDXOFS + 1,WAVEGRID * WAVEGRIDY + WAVEGRIDYOFS + 1, Op.REPLACE);
		paint.setStrokeWidth(2);
        paint.setColor(Color.YELLOW);
        // Draw l to h
        x = 1;
        xp = 1;
        y = WAVEGRID * 7;
        yp = WAVEGRID * 1;
        canvas.drawLine(xp + WAVEGRIDXOFS, yp + WAVEGRIDYOFS, x + WAVEGRIDXOFS, y + WAVEGRIDYOFS, paint);
        // Draw h
        xp = (int)(WAVEGRID * WAVEGRIDX * dut);
        y = yp;
        canvas.drawLine(xp + WAVEGRIDXOFS, yp + WAVEGRIDYOFS, x + WAVEGRIDXOFS, y + WAVEGRIDYOFS, paint);
        //Draw h to l
        x = xp;
        y = WAVEGRID * 7;
        canvas.drawLine(xp + WAVEGRIDXOFS, yp + WAVEGRIDYOFS, x + WAVEGRIDXOFS, y + WAVEGRIDYOFS, paint);
        // Draw l
        yp = y;
        xp = WAVEGRID * 10 - 0;
        canvas.drawLine(xp + WAVEGRIDXOFS, yp + WAVEGRIDYOFS, x + WAVEGRIDXOFS, y + WAVEGRIDYOFS, paint);
        // Draw l to h
        x = xp;
        yp = WAVEGRID * 1;
        canvas.drawLine(xp + WAVEGRIDXOFS, yp + WAVEGRIDYOFS, x + WAVEGRIDXOFS, y + WAVEGRIDYOFS, paint);
		mIV.setImageDrawable(new BitmapDrawable(getResources(), bmpwave));
		canvas.clipRect(0,0,wt,ht, Op.REPLACE);
	}

	@Override
	public void onWindowFocusChanged (boolean hasFocus)
	{
		if (StartUp) {
		    super.onWindowFocusChanged(hasFocus);
	        ImageView imageView = (ImageView) findViewById(R.id.ImageView1);
	        wt = imageView.getWidth();
	        ht = imageView.getHeight();
			bmpwave = Bitmap.createBitmap(wt, ht, Bitmap.Config.ARGB_8888);
			canvas = new Canvas(bmpwave);
			WAVEGRIDXOFS = (wt - WAVEGRID * WAVEGRIDX) / 2;
			WAVEGRIDYOFS = (ht - WAVEGRID * WAVEGRIDX) / 2;
			DrawDDSWave();
			StartUp = false;
		}
	}

	@Override
	public void onConfigurationChanged(Configuration newConfig) {
	    super.onConfigurationChanged(newConfig);
	    // Checks the orientation of the screen
	    if (newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE) {
	    } else if (newConfig.orientation == Configuration.ORIENTATION_PORTRAIT){
	    }
		Log.d("MYTAG", "onConfigurationChanged");
	}

	private void SetSTM32_DDS(short cmd) {
		double pa;
		dds.DDS_Cmd = cmd;
		dds.DDS_Wave = (short) ddswave;
		pa = ((double)(ddsfrqkhz * 1000 + ddsfrqhz) * (double)0x1000000 * (double)0x100 * 8.0) / (double)STM32_CLOCK;
		dds.DDS__PhaseAdd = (int)pa;
		dds.DDS_Amplitude = (int)((float)ddsamp * 13.69);
		dds.DDS_DCOffset = (int)((float)ddsdcofs * 13.69);
		ddssend = true;
	}

	private void ShowDDSSetupDialog() {
    	final Context context = this;
		final Dialog dialog = new Dialog(context);
		dialog.setContentView(R.layout.dlgdds);
		dialog.getWindow().setGravity(Gravity.RIGHT | Gravity.TOP);
		LayoutParams params = dialog.getWindow().getAttributes();
		params.width = 512;
		params.y=0;
		dialog.getWindow().setAttributes(params);
		RadioButton rbn;
    	final RadioGroup rgwave = (RadioGroup) dialog.findViewById(R.id.rgwave);
		if (ddswave == 0) {
			rbn=(RadioButton) dialog.findViewById(R.id.rbnsine);
			rbn.setChecked(true);
		} else if (ddswave == 1) {
			rbn=(RadioButton) dialog.findViewById(R.id.rbntriangle);
			rbn.setChecked(true);
		} else if (ddswave == 2) {
			rbn=(RadioButton) dialog.findViewById(R.id.rbnsquare);
			rbn.setChecked(true);
		}

		final TextView tvfrequency = (TextView) dialog.findViewById(R.id.tvddsfrq);
    	final RadioGroup rgdds = (RadioGroup) dialog.findViewById(R.id.rgfrq);
		Button btnddsfrqdn = (Button) dialog.findViewById(R.id.btnddsfrqdn);
		final SeekBar sbfrequency = (SeekBar) dialog.findViewById(R.id.sbfrequency);
		Button btnddsfrqup = (Button) dialog.findViewById(R.id.btnddsfrqup);

		final TextView tvamplitude = (TextView) dialog.findViewById(R.id.tvddsamp);
		Button btnddsampdn = (Button) dialog.findViewById(R.id.btnddsampdn);
		final SeekBar sbamplitude = (SeekBar) dialog.findViewById(R.id.sbamplitude);
		Button btnddsampup = (Button) dialog.findViewById(R.id.btnddsampup);
		
		final TextView tvddsdcofs = (TextView) dialog.findViewById(R.id.tvddsdcofs);
		Button btnddsdcofsdn = (Button) dialog.findViewById(R.id.btnddsdcofsdn);
		final SeekBar sbdcoffset = (SeekBar) dialog.findViewById(R.id.sbdcoffset);
		Button btnddsdcofsup = (Button) dialog.findViewById(R.id.btnddsdcofsup);
		
		dialog.setTitle("DDS Setup");
		ddsfrqhzsel = true;
		tvfrequency.setText("Frequncy: " +  String.format("%.1f",((float)ddsfrqkhz * 1000 + ddsfrqhz)) + "Hz");
		sbfrequency.setProgress(ddsfrqhz);

        rgwave.setOnCheckedChangeListener(new  RadioGroup.OnCheckedChangeListener() {
	        public void onCheckedChanged(RadioGroup group,int checkedId) {
	        	if(checkedId == R.id.rbnsine) {
	        		ddsSineWave();
	        		ddswave=0;
	        		DrawDDSWave();
	        		SetSTM32_DDS(DDS_WAVESET);
	        	} else if (checkedId == R.id.rbntriangle) {
	        		ddsTriangleWave();
	        		ddswave=1;
	        		DrawDDSWave();
	        		SetSTM32_DDS(DDS_WAVESET);
	        	} else if (checkedId == R.id.rbnsquare) {
	        		ddsSquareWave();
	        		ddswave=2;
	        		DrawDDSWave();
	        		SetSTM32_DDS(DDS_WAVESET);
	        	}

	        }
       	});

        rgdds.setOnCheckedChangeListener(new  RadioGroup.OnCheckedChangeListener() {
	        public void onCheckedChanged(RadioGroup group,int checkedId) {
	        	if(checkedId == R.id.rbnhz) {
	        		ddsfrqhzsel = true;
	        		sbfrequency.setProgress(ddsfrqhz);
	        	} else {
	        		ddsfrqhzsel = false;
	        		sbfrequency.setProgress(ddsfrqkhz);
	        	}
	        }
       	});

        btnddsfrqdn.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (ddsfrqhzsel) {
					if (ddsfrqhz > 0) {
						ddsfrqhz--;
						sbfrequency.setProgress(ddsfrqhz);
					}
				} else {
					if (ddsfrqkhz > 0) {
						ddsfrqkhz--;
						sbfrequency.setProgress(ddsfrqkhz);
					}
				}
				tvfrequency.setText("Frequncy: " +  String.format("%.1f",((float)ddsfrqkhz * 1000 + ddsfrqhz)) + "Hz");
        		DrawDDSWave();
        		SetSTM32_DDS(DDS_PHASESET);
			}
		});
		
		sbfrequency.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
				if (ddsfrqhzsel) {
	        		ddsfrqhz = progress;
				} else {
	        		ddsfrqkhz = progress;
				}
				tvfrequency.setText("Frequncy: " +  String.format("%.1f",((float)ddsfrqkhz * 1000 + ddsfrqhz)) + "Hz");
        		DrawDDSWave();
        		SetSTM32_DDS(DDS_PHASESET);
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });

		btnddsfrqup.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (ddsfrqhzsel) {
					if (ddsfrqhz < 999) {
						ddsfrqhz++;
						sbfrequency.setProgress(ddsfrqhz);
					}
				} else {
					if (ddsfrqkhz < 999) {
						ddsfrqkhz++;
						sbfrequency.setProgress(ddsfrqkhz);
					}
				}
				tvfrequency.setText("Frequncy: " +  String.format("%.1f",((float)ddsfrqkhz * 1000 + ddsfrqhz)) + "Hz");
        		DrawDDSWave();
        		SetSTM32_DDS(DDS_PHASESET);
			}
		});

		tvamplitude.setText("Amplitude: " +  String.format("%.1f",((float)ddsamp * 10)) + "mV");
		sbamplitude.setProgress(ddsamp);

        btnddsampdn.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (ddsamp > 0) {
					ddsamp--;
					sbamplitude.setProgress(ddsamp);
					tvamplitude.setText("Amplitude: " +  String.format("%.1f",((float)ddsamp * 10)) + "mV");
	        		DrawDDSWave();
	        		SetSTM32_DDS(DDS_WAVESET);
				}
			}
		});
		
		sbamplitude.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		ddsamp = progress;
        		tvamplitude.setText("Amplitude: " +  String.format("%.1f",((float)ddsamp * 10)) + "mV");
        		DrawDDSWave();
        		SetSTM32_DDS(DDS_WAVESET);
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });

        btnddsampup.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (ddsamp < 300) {
					ddsamp++;
					sbamplitude.setProgress(ddsamp);
					tvamplitude.setText("Amplitude: " +  String.format("%.1f",((float)ddsamp * 10)) + "mV");
	        		DrawDDSWave();
	        		SetSTM32_DDS(DDS_WAVESET);
				}
			}
		});
		
		tvddsdcofs.setText("DC Offset: " +  String.format("%.1f",((float)(ddsdcofs - 299) * 10)) + "mV");
		sbdcoffset.setProgress(ddsdcofs);
		
        btnddsdcofsdn.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (ddsdcofs > 0) {
					ddsdcofs--;
					sbdcoffset.setProgress(ddsdcofs);
					tvddsdcofs.setText("DC Offset: " +  String.format("%.1f",((float)(ddsdcofs - 299) * 10)) + "mV");
	        		DrawDDSWave();
	        		SetSTM32_DDS(DDS_WAVESET);
				}
			}
		});
		
        sbdcoffset.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		ddsdcofs = progress;
				tvddsdcofs.setText("DC Offset: " +  String.format("%.1f",((float)(ddsdcofs - 299) * 10)) + "mV");
        		DrawDDSWave();
        		SetSTM32_DDS(DDS_WAVESET);
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });

        btnddsdcofsup.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (ddsamp < 600) {
					ddsdcofs++;
					sbdcoffset.setProgress(ddsdcofs);
					tvddsdcofs.setText("DC Offset: " +  String.format("%.1f",((float)(ddsdcofs - 299) * 10)) + "mV");
	        		DrawDDSWave();
	        		SetSTM32_DDS(DDS_WAVESET);
				}
			}
		});
		
		Button btnddsok = (Button) dialog.findViewById(R.id.btnddsok);
		// if button is clicked, close the custom dialog
		btnddsok.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				dialog.dismiss();
			}
		});

		dialog.show();
    }

	private void SetSTM32_SCP() {
		byte sr = scp.srset[scpsr];

		scp.Mag = 0;
		scp.SubSampling = 0;
		scp.Trigger = scptr;
		scp.TriggerLevel = (short)(13.65 * (double)scptl);
		scp.TimeDiv = scp.scptdint[scptd];
		scp.VPos = (short)(13.65 * (double)scpvp);
	}

	private String SampleRateTriple(int psr) {
		int clkdiv;
		int delay;
		int f;
		clkdiv = psr >> 4;
		clkdiv++;
		clkdiv *= 2;
		delay = psr & 0xF;
		delay += 5;
		f = STM32_CLOCK / 2 / clkdiv / delay;
		scp.SampleRateSet = (byte)psr;
		scp.Triple = 1;
		scp.SampleRate = f;
		String s = "" + f;
		return s + "Hz";
	}

	private String SampleRateSingle(int psr) {
		int clkdiv;
		int delay;
		int f;
		clkdiv = (psr >> 3) & 0x3;
		clkdiv++;
		clkdiv *= 2;
		delay = scp.stset[psr & 0x7] + 12;
		f = STM32_CLOCK / 2 / clkdiv / delay;
		scp.SampleRateSet = (byte)psr;
		scp.Triple = 0;
		scp.SampleRate = f;
		String s = "" + f;
		return s + "Hz";
	}

	private String SampleRate(int psr) {
		int sr = (int)scp.srset[psr];
		if (sr < 64) {
			return SampleRateTriple(sr);
		} else {
			return SampleRateSingle(sr);
		}
	}

	private void ShowSCPSetupDialog() {
    	final Context context = this;
		final Dialog dialog = new Dialog(context);
		dialog.setContentView(R.layout.dlgscp);
		dialog.getWindow().setGravity(Gravity.RIGHT | Gravity.TOP);
		LayoutParams params = dialog.getWindow().getAttributes();
		params.width = 512;
		params.y=0;
		dialog.getWindow().setAttributes(params);

		final TextView tvscpsr = (TextView) dialog.findViewById(R.id.tvscpsr);
		Button btnscpsrdn = (Button) dialog.findViewById(R.id.btnscpsrdn);
		final SeekBar sbscpsr = (SeekBar) dialog.findViewById(R.id.sbscpsr);
		Button btnscpsrup = (Button) dialog.findViewById(R.id.btnscpsrup);

		final TextView tvscptd = (TextView) dialog.findViewById(R.id.tvscptd);
		Button btnscptddn = (Button) dialog.findViewById(R.id.btnscptddn);
		final SeekBar sbscptd = (SeekBar) dialog.findViewById(R.id.sbscptd);
		Button btnscptdup = (Button) dialog.findViewById(R.id.btnscptdup);

		final TextView tvscpvd = (TextView) dialog.findViewById(R.id.tvscpvd);
		Button btnscpvddn = (Button) dialog.findViewById(R.id.btnscpvddn);
		final SeekBar sbscpvd = (SeekBar) dialog.findViewById(R.id.sbscpvd);
		Button btnscpvdup = (Button) dialog.findViewById(R.id.btnscpvdup);

		final TextView tvscpvp = (TextView) dialog.findViewById(R.id.tvscpvp);
		Button btnscpvpdn = (Button) dialog.findViewById(R.id.btnscpvpdn);
		final SeekBar sbscpvp = (SeekBar) dialog.findViewById(R.id.sbscpvp);
		Button btnscpvpup = (Button) dialog.findViewById(R.id.btnscpvpup);

		final TextView tvscptl = (TextView) dialog.findViewById(R.id.tvscptl);
		Button btnscptldn = (Button) dialog.findViewById(R.id.btnscptldn);
		final SeekBar sbscptl = (SeekBar) dialog.findViewById(R.id.sbscptl);
		Button btnscptlup = (Button) dialog.findViewById(R.id.btnscptlup);

		dialog.setTitle("SCOPE Setup");
		tvscpsr.setText("Sample rate: " + SampleRate(scpsr));
		sbscpsr.setProgress(scpsr);

		tvscptd.setText("Time / Div: " + scp.scptdstr[scptd]);
		sbscptd.setProgress(scptd);

		tvscpvd.setText("Volt / Div: " + scp.scpvdstr[scpvd]);
		sbscpvd.setProgress(scpvd);

		tvscpvp.setText("V-Pos: " + (scpvp - 150));
		sbscpvp.setProgress(scpvp);

		tvscptl.setText("Trigger level: " + (scptl - 150));
		sbscptl.setProgress(scptl);

		/* Trigger select */
		RadioButton rbn;
    	final RadioGroup rgtrg = (RadioGroup) dialog.findViewById(R.id.rgtrig);
		if (scptr == 0) {
			rbn=(RadioButton) dialog.findViewById(R.id.rbnscptrgn);
			rbn.setChecked(true);
		} else if (scptr == 1) {
			rbn=(RadioButton) dialog.findViewById(R.id.rbnscptrgr);
			rbn.setChecked(true);
		} else if (scptr == 2) {
			rbn=(RadioButton) dialog.findViewById(R.id.rbnscptrgf);
			rbn.setChecked(true);
		}
		/* Sample rate */
        btnscpsrdn.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (scpsr > 0) {
					scpsr--;
					sbscpsr.setProgress(scpsr);
					tvscpsr.setText("Sample rate: " + SampleRate(scpsr));
					SetSTM32_SCP();
				}
			}
		});
		sbscpsr.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		scpsr = progress;
				tvscpsr.setText("Sample rate: " + SampleRate(scpsr));
				SetSTM32_SCP();
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });
		btnscpsrup.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (scpsr < 67) {
					scpsr++;
					sbscpsr.setProgress(scpsr);
					tvscpsr.setText("Sample rate: " + SampleRate(scpsr));
					SetSTM32_SCP();
				}
			}
		});
		/* Time / Div */
        btnscptddn.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (scptd > 0) {
					scptd--;
					sbscptd.setProgress(scptd);
					tvscptd.setText("Time / Div: " + scp.scptdstr[scptd]);
					SetSTM32_SCP();
				}
			}
		});
		sbscptd.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		scptd = progress;
        		tvscptd.setText("Time / Div: " + scp.scptdstr[scptd]);
				SetSTM32_SCP();
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });
		btnscptdup.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (scptd < 20) {
					scptd++;
					sbscptd.setProgress(scptd);
					tvscptd.setText("Time / Div: " + scp.scptdstr[scptd]);
					SetSTM32_SCP();
				}
			}
		});
		/* Volt / Div */
        btnscpvddn.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (scpvd > 0) {
					scpvd--;
					tvscpvd.setText("Volt / Div: " + scp.scpvdstr[scpvd]);
					sbscpvd.setProgress(scpvd);
					SetSTM32_SCP();
				}
			}
		});
		sbscpvd.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		scpvd = progress;
				tvscpvd.setText("Volt / Div: " + scp.scpvdstr[scpvd]);
				SetSTM32_SCP();
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });
		btnscpvdup.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (scpvd < 8) {
					scpvd++;
					sbscpvd.setProgress(scpvd);
					tvscpvd.setText("Volt / Div: " + scp.scpvdstr[scpvd]);
					SetSTM32_SCP();
				}
			}
		});
		/* V-Position */
        btnscpvpdn.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (scpvp > 0) {
					scpvp--;
					tvscpvp.setText("V-Pos: " + (scpvp - 150));
					sbscpvp.setProgress(scpvp);
					SetSTM32_SCP();
				}
			}
		});
		sbscpvp.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		scpvp = progress;
				tvscpvp.setText("V-Pos: " + (scpvp - 150));
				SetSTM32_SCP();
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });
		btnscpvpup.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (scpvp < 300) {
					scpvp++;
					sbscpvp.setProgress(scpvp);
					tvscpvp.setText("V-Pos: " + (scpvp - 150));
					SetSTM32_SCP();
				}
			}
		});
		/* Trigger level */
        btnscptldn.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (scptl > 0) {
					scptl--;
					sbscptl.setProgress(scptl);
					tvscptl.setText("Trigger level: " + (scptl - 150));
					SetSTM32_SCP();
				}
			}
		});
		sbscptl.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		scptl = progress;
				tvscptl.setText("Trigger level: " + (scptl - 150));
				SetSTM32_SCP();
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });
		btnscptlup.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (scptl < 300) {
					scptl++;
					sbscptl.setProgress(scptl);
					tvscptl.setText("Trigger level: " + (scptl - 150));
					SetSTM32_SCP();
				}
			}
		});
		/* Trigger select */
        rgtrg.setOnCheckedChangeListener(new  RadioGroup.OnCheckedChangeListener() {
	        public void onCheckedChanged(RadioGroup group,int checkedId) {
	        	if(checkedId == R.id.rbnscptrgn) {
	        		scptr = 0;
	        	} else if (checkedId == R.id.rbnscptrgr) {
	        		scptr = 1;
	        	} else if (checkedId == R.id.rbnscptrgf) {
	        		scptr = 2;
	        	}
				SetSTM32_SCP();
	        }
       	});
        /* Auto */
        Button btnscpauto = (Button) dialog.findViewById(R.id.btnscpauto);
		// if button is clicked, auto configure
		btnscpauto.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
			}
		});
        /* Hold */
        Button btnscphold = (Button) dialog.findViewById(R.id.btnscphold);
		// if button is clicked, hold sampling
		btnscphold.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				scphold = !scphold;
			}
		});
        /* OK */
        Button btnscpok = (Button) dialog.findViewById(R.id.btnscpok);
		// if button is clicked, close the custom dialog
		btnscpok.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				dialog.dismiss();
			}
		});

		dialog.show();
    }

    private byte GetLGATrigger(Dialog dialog ,int id) {
    	byte val = 0, i;
		CheckBox chk;
		i = 1;
		while (i != 0) {
			chk=(CheckBox) dialog.findViewById(id);
			if (chk.isChecked()) {
				val |= i;
			}
			i <<= 1;
			id++;
		}
    	return val;
    }

    private void ShowLGASetupDialog() {
    	final Context context = this;
		final Dialog dialog = new Dialog(context);
		dialog.setContentView(R.layout.dlglga);
		dialog.getWindow().setGravity(Gravity.RIGHT | Gravity.TOP);
		LayoutParams params = dialog.getWindow().getAttributes();
		params.width = 512;
		params.y=0;
		dialog.getWindow().setAttributes(params);

		final TextView tvlgasr = (TextView) dialog.findViewById(R.id.tvlgasr);
		Button btnlgasrdn = (Button) dialog.findViewById(R.id.btnlgasrdn);
		final SeekBar sblgasr = (SeekBar) dialog.findViewById(R.id.sblgasr);
		Button btnlgasrup = (Button) dialog.findViewById(R.id.btnlgasrup);

		final TextView tvlgabuff = (TextView) dialog.findViewById(R.id.tvlgabuff);
		Button btnlgabuffdn = (Button) dialog.findViewById(R.id.btnlgabuffdn);
		final SeekBar sblgabuff = (SeekBar) dialog.findViewById(R.id.sblgabuff);
		Button btnlgabuffup = (Button) dialog.findViewById(R.id.btnlgabuffup);

		Button btnlgafinddn = (Button) dialog.findViewById(R.id.btnlgafinddn);
		Button btnlgafindup = (Button) dialog.findViewById(R.id.btnlgafindup);

		dialog.setTitle("LGA Setup");
		tvlgasr.setText("Sample rate: " +  lgasrstr[lgasr]);
		sblgasr.setProgress(lgasr);
		tvlgabuff.setText("Buffer size: " +  (lgabuff + 1) + "kb");
		sblgabuff.setProgress(lgabuff);

		/* Set trigger */
		CheckBox chk;
		byte i = 1;
		int id = R.id.chklgatrgd0;
		while (i != 0) {
			chk=(CheckBox) dialog.findViewById(id);
			chk.setChecked((lgatrg & i) != 0);
			i <<= 1;
			id++;
		}
		/* Set mask */
		i = 1;
		id = R.id.chklgamaskd0;
		while (i != 0) {
			chk=(CheckBox) dialog.findViewById(id);
			chk.setChecked((lgamask & i) != 0);
			i <<= 1;
			id++;
		}

		btnlgasrdn.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (lgasr > 0) {
					lgasr--;
					sblgasr.setProgress(lgasr);
					tvlgasr.setText("Sample rate: " +  lgasrstr[lgasr]);
				}
			}
		});
		
		sblgasr.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		lgasr = progress;
				tvlgasr.setText("Sample rate: " +  lgasrstr[lgasr]);
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });

		btnlgasrup.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (lgasr < 14) {
					lgasr++;
					sblgasr.setProgress(lgasr);
					tvlgasr.setText("Sample rate: " +  lgasrstr[lgasr]);
				}
			}
		});

        btnlgabuffdn.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (lgabuff > 0) {
					lgabuff--;
					sblgabuff.setProgress(lgabuff);
					tvlgabuff.setText("Buffer size: " +  (lgabuff + 1) + "kb");
				}
			}
		});
		
		sblgabuff.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		lgabuff = progress;
				tvlgabuff.setText("Buffer size: " +  (lgabuff + 1) + "kb");
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });

		btnlgabuffup.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (lgabuff < 31) {
					lgabuff++;
					sblgabuff.setProgress(lgabuff);
					tvlgabuff.setText("Buffer size: " +  (lgabuff + 1) + "kb");
				}
			}
		});

        btnlgafinddn.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (lgaxofs >= (WAVEGRID / LGAWIDTH)) {
					lgatrg = GetLGATrigger(dialog, R.id.chklgatrgd0);
					lgamask = GetLGATrigger(dialog, R.id.chklgamaskd0);
					byte val = (byte)((int)lgatrg & (int)lgamask);
					int inx = (int)(lgaxofs / (WAVEGRID / LGAWIDTH));
					inx--;
					while (inx >= 0) {
						if ((BlueTooth.btreadbuffer[inx] & lgamask) == val){
							lgaxofs = inx * (WAVEGRID / LGAWIDTH);
				    		DrawLGAWave();
							break;
						}
						inx--;
					}
		    		DrawLGAWave();
				}
			}
		});
		
        btnlgafindup.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (lgaxofs / (WAVEGRID / LGAWIDTH) < (lgabuff + 1) * 1024) {
					lgatrg = GetLGATrigger(dialog, R.id.chklgatrgd0);
					lgamask = GetLGATrigger(dialog, R.id.chklgamaskd0);
					byte val = (byte)((int)lgatrg & (int)lgamask);
					int inx = (int)(lgaxofs / (WAVEGRID / LGAWIDTH));
					inx++;
					while (inx < (lgabuff + 1) * 1024) {
						if ((BlueTooth.btreadbuffer[inx] & lgamask) == val){
							lgaxofs = inx * (WAVEGRID / LGAWIDTH);
				    		DrawLGAWave();
							break;
						}
						inx++;
					}
				}
			}
		});
		
		Button btnlgasample = (Button) dialog.findViewById(R.id.btnlgasample);
		// if button is clicked, close the custom dialog
		btnlgasample.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				int sr ;
				lgatrg = GetLGATrigger(dialog, R.id.chklgatrgd0);
				lgamask = GetLGATrigger(dialog, R.id.chklgamaskd0);
				lga.DataBlocks = (byte) (lgabuff + 1);
				lga.TriggerValue = lgatrg;
				lga.TriggerMask = lgamask;
				lga.TriggerWait = 0;
				sr=lgasrint[lgasr];
				if (sr == 199999) {
					lga.LGASampleRateDiv = 3;
					lga.LGASampleRate = (short)(sr >> 2);
				} else if (sr == 199999) {
					lga.LGASampleRateDiv = 1;
					lga.LGASampleRate = (short)(sr >> 1);
				} else {
					lga.LGASampleRateDiv = 0;
					lga.LGASampleRate = (short)sr;
				}
				lga.SendLGA();
				lgaxofs = 0;
				lgatrgpos = 0;
	    		DrawLGAWave();
				dialog.dismiss();
			}
		});

		dialog.show();
    }
    
    private int FrqToClk(int frq, int clkdiv) {
    	int c = 0;
    	int d = 1;
    	while (true) {
    		c = clkdiv / d / frq;
    		if (c < 65536) {
    			break;
    		}
    		
    	}
    	return c;
    }
    
    private int ClkToFrq(int cnt, int clk) {
    	int f = 0;
    	f = clk / cnt;
    	return f;
    }

    private int GetHscFrq(int frq) {
    	int c = 0;
    	if (frq < 3) {
    		hscclk = STM32_CLOCK / 2048;
    		hscarr = 1023;
    	} else if (frq < 6) {
    		hscclk = STM32_CLOCK / 1024;
    		hscarr = 511;
    	} else if (frq < 12) {
    		hscclk = STM32_CLOCK / 512;
    		hscarr = 255;
    	} else if (frq < 24) {
    		hscclk = STM32_CLOCK / 256;
    		hscarr = 127;
    	} else if (frq < 48) {
    		hscclk = STM32_CLOCK / 128;
    		hscarr = 63;
    	} else if (frq < 96) {
    		hscclk = STM32_CLOCK / 64;
    		hscarr = 31;
    	} else if (frq < 192) {
    		hscclk = STM32_CLOCK / 32;
    		hscarr = 15;
    	} else if (frq < 382) {
    		hscclk = STM32_CLOCK / 16;
    		hscarr = 7;
    	} else if (frq < 763) {
    		hscclk = STM32_CLOCK / 8;
    		hscarr = 3;
    	} else {
    		hscclk = STM32_CLOCK / 4;
    		hscarr = 1;
    	}
    	c = FrqToClk(frq, hscclk);
    	hscres = ClkToFrq(c, hscclk);
    	return c;
    }
    
    private void ShowHSCSetupDialog() {
    	final Context context = this;
		final Dialog dialog = new Dialog(context);
		dialog.setContentView(R.layout.dlghsc);
		dialog.getWindow().setGravity(Gravity.RIGHT | Gravity.TOP);
		LayoutParams params = dialog.getWindow().getAttributes();
		params.width = 512;
		params.y=0;
		dialog.getWindow().setAttributes(params);

    	final RadioGroup rghscfrq = (RadioGroup) dialog.findViewById(R.id.rghscfrq);
		RadioButton rbn;
		if (hscset == 0) {
			rbn=(RadioButton) dialog.findViewById(R.id.rbnhscmhz);
			rbn.setChecked(true);
		} else if (hscset == 1) {
			rbn=(RadioButton) dialog.findViewById(R.id.rbnhsckhz);
			rbn.setChecked(true);
		} else if (hscset == 2) {
			rbn=(RadioButton) dialog.findViewById(R.id.rbnhschz);
			rbn.setChecked(true);
		}

		Button btnhscfrqdn = (Button) dialog.findViewById(R.id.btnhscfrqdn);
		final EditText ethscfrqset = (EditText) dialog.findViewById(R.id.ethscfrqset);
		ethscfrqset.setText("" + hscfrq);
		Button btnhscfrqup = (Button) dialog.findViewById(R.id.btnhscfrqup);
		Button btnhscok = (Button) dialog.findViewById(R.id.btnhscok);

		dialog.setTitle("HSC Setup");

		rghscfrq.setOnCheckedChangeListener(new  RadioGroup.OnCheckedChangeListener() {
	        public void onCheckedChanged(RadioGroup group,int checkedId) {
	        	if(checkedId == R.id.rbnhscmhz) {
	        		hscset = 0;
	        	} else if (checkedId == R.id.rbnhsckhz) {
	        		hscset = 1;
	        	} else if (checkedId == R.id.rbnhschz) {
	        		hscset = 2;
	        	}

	        }
       	});

		btnhscfrqdn.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
		    	int t;
				if (hscfrq > 2) {
					switch (hscset) {
					case 0:
						hscfrq -=1000000;
						if (hscfrq < 2) {
							hscfrq = 2;
						}
						break;
					case 1:
						hscfrq -=1000;
						if (hscfrq < 2) {
							hscfrq = 2;
						}
						break;
					case 2:
						hscfrq--;
						break;
					}
					hscres = hscfrq - 1;
					t = GetHscFrq(hscfrq);
					while (hscfrq != hscres) {
						hscfrq--;
						t = GetHscFrq(hscfrq);
					}
					hscclk = t - 1;
					ethscfrqset.setText("" + hscfrq);
					DrawHSCWave();
					hscsend = true;
				}
			}
		});
		
		ethscfrqset.setOnEditorActionListener(new OnEditorActionListener() {
		    @Override
		    public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
		        boolean handled = false;
		    	int t;
		        if (actionId == EditorInfo.IME_ACTION_SEND) {
		            //sendMessage();
		        	hscfrq = Integer.parseInt(ethscfrqset.getText().toString());
		        	if (hscfrq < 2) {
		        		hscfrq = 2;
		        	} else if (hscfrq > 50000000) {
		        		hscfrq = 50000000;
		        	}
					t = GetHscFrq(hscfrq);
					hscfrq = hscres;
					hscclk = t - 1;
					ethscfrqset.setText("" + hscfrq);
					DrawHSCWave();
					hscsend = true;
					handled = true;
		        }
		        return handled;
		    }
		});

		btnhscfrqup.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
		    	int t;
				if (hscfrq < 50000000) {
					switch (hscset) {
					case 0:
						hscfrq += 1000000;
						if (hscfrq > 50000000) {
							hscfrq = 50000000;
						}
						break;
					case 1:
						hscfrq += 1000;
						if (hscfrq > 50000000) {
							hscfrq = 50000000;
						}
						break;
					case 2:
						hscfrq++;
						break;
					}
					t = GetHscFrq(hscfrq);
					hscfrq = hscres;
					hscclk = t - 1;
					ethscfrqset.setText("" + hscfrq);
					DrawHSCWave();
					hscsend = true;
				}
			}
		});

		btnhscok.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				dialog.dismiss();
			}
		});

		dialog.show();
    }

    @Override
	public boolean onTouchEvent(MotionEvent event) {
		switch (event.getAction()) {
		case MotionEvent.ACTION_UP:
			return (true);
		case MotionEvent.ACTION_POINTER_UP:
			return (true);
		case MotionEvent.ACTION_DOWN:
			xs = lgaxofs;
			if (mode == 2) {
				xd = event.getAxisValue(0);
				//Log.d("MYTAG", "ACTION_DOWN xd " + xd + " xs " + xs);
			}
			return (true);
		case MotionEvent.ACTION_POINTER_DOWN:
			return (true);
		case MotionEvent.ACTION_MOVE:
			if (mode == 2) {
				lgaxofs = xs + (xd - event.getAxisValue(0, event.getPointerCount() - 1));
				if (lgaxofs<0) lgaxofs=0;
				if (lgaxofs >= LGASIZE * LGAWIDTH - LGAWIDTH) lgaxofs = LGASIZE * LGAWIDTH - LGAWIDTH;
	    		DrawLGAWave();
				//Log.d("MYTAG", "ACTION_MOVE " + lgaxofs + " WAVEGRID " + WAVEGRID);
			}
			return (true);
		}
		return super.onTouchEvent(event);
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

	private boolean BTConnect() {
    	Boolean err = false;
    	btconnected = BTDisConnect();
        try {
        	if (mBluetoothAdapter == null) {
	        	err = true;
				Toast.makeText(getApplicationContext(), "Error occured no BT adapter found.", Toast.LENGTH_LONG).show();
				nobt = true;
        	} else {
    			Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
    			if (!mBluetoothAdapter.isEnabled()) {
    				startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
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
        				Toast.makeText(getApplicationContext(), "Attempting connect.", Toast.LENGTH_LONG).show();
                    	mBluetoothSocket.connect();
        	            // Create data streams so we can talk to server.
        	            try {
        	            	mOutputStream = mBluetoothSocket.getOutputStream();
        		            try {
        		            	mInputStream = mBluetoothSocket.getInputStream();
        		            	// Done, set the mode
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
