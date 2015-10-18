package app.DDSWave;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.Method;
import java.math.BigDecimal;
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
	public static final int WAVEXSIZE = (WAVEGRID * WAVEGRIDX);
	public static final int WAVEYSIZE = (WAVEGRID * WAVEGRIDY);
	private int WAVEGRIDXOFS = 0;
	private int WAVEGRIDYOFS = 0;
	private String wavestr[] = new String[9];

	// DDS
	private static final short DDS_PHASESET = 1;
	private static final short DDS_WAVESET = 2;
	private static final short DDS_SWEEPSET = 3;
    private static boolean ddssend = false;
	private static final int DDSSIZE = 2048;
	private short ddsWave[] = new short[DDSSIZE];
	private int ddswave=0;
	private int ddsfrqhz = 0;
	private int ddsfrqkhz = 5;
	private boolean ddsfrqhzsel = false;
	private int ddsamp = 100;
	private int ddsdcofs = 299;
    private static STM32_DDS dds = new STM32_DDS();

	// Scope
    public static short scpWave[] = new short[WAVEXSIZE];
	private int scpsr = 67;
	private int scptd = 8;
	private int scpvd = 8;
	private int scpvp = (150 + 13);
	private int scptl = 150;
	private byte scptr = 1;
	private String scpfrq = "";
	private boolean scpsample = false;
	private boolean scpsampledone = false;
	private boolean scphold = false;
    private static STM32_SCP scp = new STM32_SCP();

	// LGA
	public static final int LGASIZE = 32 * 1024;
	private static final int LGAWIDTH = 10;
	private int lgasr  = 0;
	private int lgabuff  = 0;
	private byte lgatrg = (byte)0x00;
	private byte lgamask = (byte)0x00;
	private float xd, yd, xs, lgaxofs;
	private int lgatrgpos = 0;
	private int lgatstpos = 0;
    private static STM32_LGA lga = new STM32_LGA();

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
		for (i = 0;i<9;i++) {
			wavestr[i] = "";
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
				if (BlueTooth.btconnected || nobt) {
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
				if ((BlueTooth.btconnected == true || nobt == true) && BlueTooth.btmode == BlueTooth.CMD_DONE && (tmrcnt & 31) == 0 && BlueTooth.btbusy == false) {
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

    public static String FormatFrequency(int frq) {
    	String s;
    	if (frq >= 1000000) {
    		/* MHz */
			s = (new BigDecimal(Double.toString(((double)(frq / 1000000.0)))).stripTrailingZeros().toPlainString()) + "MHz";
    	} else if (frq >= 1000) {
    		/* KHz */
			s = (new BigDecimal(Double.toString(((double)(frq / 1000.0)))).stripTrailingZeros().toPlainString()) + "KHz";
    	} else {
    		/* Hz */
			s = (new BigDecimal(Double.toString(((double)(frq)))).stripTrailingZeros().toPlainString()) + "Hz";
    	}
    	return s;
    }

    private String FormatTime(double time) {
    	String s;
    	if (time >= 1000000000) {
    		/* s */
			s = (new BigDecimal(Double.toString(((double)(time / 1000000000.0)))).stripTrailingZeros().toPlainString()) + "s";
    	} else if (time >= 1000000) {
    		/* ms */
			s = (new BigDecimal(Double.toString(((double)(time / 1000000.0)))).stripTrailingZeros().toPlainString()) + "ms";
    	} else if (time >= 1000) {
    		/* us */
			s = (new BigDecimal(Double.toString(((double)(time / 1000.0)))).stripTrailingZeros().toPlainString()) + "us";
    	} else {
    		/* ns */
        	s = (new BigDecimal(Double.toString(((double)(time)))).stripTrailingZeros().toPlainString()) + "ns";
    	}
    	return s;
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
		for (int x = 0;x < WAVEXSIZE;x++) {
			y=(float)Math.sin((float)(2*Math.PI) * (float)x / (float)WAVEYSIZE) * 2047.0;
			scpWave[x] = (short)(2048 - (int)y);
		}
	}

	private void DrawBTStatus() {
		if (BlueTooth.btconnected == true) {
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
		int i = 0, xm;
		bmpwave.eraseColor(Color.BLUE);
        paint.setColor(Color.DKGRAY);
        /* Draw horizontal lines */
		while (i <= WAVEGRIDY) {
			if (i == 4 && mode != 2) {
				paint.setStrokeWidth(2);
			} else {
				paint.setStrokeWidth(1);
			}
	        canvas.drawLine(WAVEGRIDXOFS, y, WAVEGRID*10+WAVEGRIDXOFS, y, paint);
	        y += WAVEGRID;
	        i++;
		}
		i=0;
        /* Draw vertical lines */
		while (i <= WAVEGRIDX) {
			if (i == 5 && mode != 2) {
				paint.setStrokeWidth(2);
			} else {
				paint.setStrokeWidth(1);
			}
	        canvas.drawLine(x, WAVEGRIDYOFS, x, WAVEGRID*WAVEGRIDY+WAVEGRIDYOFS, paint);
	        x+=WAVEGRID;
	        i++;
		}
        y -= WAVEGRID / 3;
        xm = WAVEXSIZE / 3;
		paint.setTextSize(18);
        paint.setColor(Color.WHITE);
		canvas.drawText(wavestr[0], WAVEGRIDXOFS, y, paint);
		canvas.drawText(wavestr[1], WAVEGRIDXOFS + xm, y, paint);
		canvas.drawText(wavestr[2], WAVEGRIDXOFS + xm * 2, y, paint);
        y += WAVEGRID / 2;
		canvas.drawText(wavestr[3], WAVEGRIDXOFS, y, paint);
		canvas.drawText(wavestr[4], WAVEGRIDXOFS + xm, y, paint);
		canvas.drawText(wavestr[5], WAVEGRIDXOFS + 332, y, paint);
        y += WAVEGRID / 2;
		canvas.drawText(wavestr[6], WAVEGRIDXOFS, y, paint);
		canvas.drawText(wavestr[7], WAVEGRIDXOFS + xm, y, paint);
		canvas.drawText(wavestr[8], WAVEGRIDXOFS + xm * 2, y, paint);
		DrawBTStatus();
	}

	private void DrawDDSWave() {
		int frq, xp, yp;
		int x = WAVEGRIDXOFS;
		int y = WAVEGRIDYOFS;
		int i;
		double per = 0;
		
		for (i = 0;i<9;i++) {
			wavestr[i] = "";
		}
		frq = ddsfrqkhz * 1000 + ddsfrqhz;
		wavestr[0] = "Frq: " + FormatFrequency(frq);
		if (frq > 0) {
			per = 1000000000.0 / (double)frq;
		}
		wavestr[1] = "Per: " + FormatTime(per);
		wavestr[3] = "Vpp: " + ddsamp * 10 + "mV";
		wavestr[4] = "Vmin: " + (((ddsdcofs - 299) * 10) - ddsamp * 10) + "mV";
		wavestr[5] = "Vmax: " + (((ddsdcofs - 299) * 10) + ddsamp * 10) + "mV";
		DrawGrid();
		canvas.clipRect(WAVEGRIDXOFS,WAVEGRIDYOFS,WAVEXSIZE + WAVEGRIDXOFS + 1,WAVEYSIZE + WAVEGRIDYOFS + 1, Op.REPLACE);
		paint.setStrokeWidth(2);
        paint.setColor(Color.RED);
        y = (WAVEYSIZE / 2) + (((ddsdcofs - 299) * (WAVEYSIZE - 2 * WAVEGRID)) / 600);
        canvas.drawLine(WAVEGRIDXOFS, y + WAVEGRIDYOFS, WAVEGRIDXOFS + WAVEXSIZE, y + WAVEGRIDYOFS, paint);
        paint.setColor(Color.YELLOW);
        i = 0;
		xp = ((i / 8) * WAVEXSIZE) / 256;
		yp = (((2048 - ddsWave[i]) / 16) * WAVEGRID * 6) / 256;
		yp = WAVEGRID * 4  + ((yp * ddsamp) / 300);
		i++;
		while (i < DDSSIZE) {
			x = ((i / 8) * WAVEXSIZE) / 256;
			y = (((2048 - ddsWave[i]) / 16) * WAVEGRID * 6) / 256;
			y = WAVEGRID * 4 + ((y * ddsamp) / 300);
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
		double per = 0;
		for (i = 0;i<9;i++) {
			wavestr[i] = "";
		}
		wavestr[0] = "Frq: " + FormatFrequency(scp.scpfrq);
		if (scp.scpfrq > 0) {
			per = 1000000000.0 / (double)scp.scpfrq;
		}
		wavestr[1] = "Per: " + FormatTime(per);
		wavestr[3] = scp.scptdstr[scptd] + " / Div";
		wavestr[6] = scp.scpvdstr[scpvd] + " / Div";
		DrawGrid();
		canvas.clipRect(WAVEGRIDXOFS,WAVEGRIDYOFS,WAVEXSIZE + WAVEGRIDXOFS + 1,WAVEYSIZE + WAVEGRIDYOFS + 1, Op.REPLACE);
		paint.setStrokeWidth(2);
		if (scptr != 0) {
			/* Draw trigger level */
	        paint.setColor(Color.RED);
	        yp = 150 - scptl;
	        yp = (int)((double)yp * 4.0 / 3.0);
	        yp += WAVEYSIZE / 2;
	        canvas.drawLine(WAVEGRIDXOFS, WAVEGRIDYOFS + yp, WAVEGRIDXOFS + WAVEXSIZE, WAVEGRIDYOFS + yp, paint);
		}
        paint.setColor(Color.YELLOW);
		xp = 0;
		i = 0;
		// Invert
		yp = 4095 - scpWave[i];
		// Scale to grid
		yp = (yp * WAVEYSIZE) / 4095;
		i++;
		while (i < WAVEXSIZE) {
			x = i;
			// Invert
			y = 4095 - scpWave[i];
			// Scale to grid
			y = (y * WAVEYSIZE) / 4095;
	        canvas.drawLine(xp + WAVEGRIDXOFS, yp + WAVEGRIDYOFS, x + WAVEGRIDXOFS, y + WAVEGRIDYOFS, paint);
			xp = x;
			yp = y;
			i++;
		}
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
		wavestr[0] = FormatTime((double)lga.lgatimediv[lgasr]) + " / Div";
		wavestr[3] = "Byte: " + lgatrgpos + "/" + lgatstpos;
		wavestr[4] = "Count: " + Math.abs(lgatstpos - lgatrgpos);
		wavestr[5] = "Time: " + FormatTime((double)(lga.lgatimediv[lgasr] / 10) * Math.abs(lgatstpos - lgatrgpos));
		wavestr[6] = "Byte Dec: " + BlueTooth.btreadbuffer[lgatrgpos];
		wavestr[7] = "Hex: " + String.format("%02x", BlueTooth.btreadbuffer[lgatrgpos] & 0xff).toUpperCase();
		wavestr[8] = "Bin: " + String.format("%8s", Integer.toBinaryString(BlueTooth.btreadbuffer[lgatrgpos] & 0xFF)).replace(' ', '0');
		DrawGrid();
		canvas.clipRect(WAVEGRIDXOFS,WAVEGRIDYOFS,WAVEXSIZE + WAVEGRIDXOFS + 1,WAVEYSIZE + WAVEGRIDYOFS + 1, Op.REPLACE);
		paint.setStrokeWidth(2);
		ofs = (int)lgaxofs / (WAVEGRID / LGAWIDTH);
		//Log.d("MYTAG", "ofs " + ofs + " lgatrgpos " + lgatrgpos);
		if (lgatstpos >= ofs && lgatstpos <= (ofs + WAVEXSIZE / (WAVEGRID / LGAWIDTH))) {
			paint.setColor(Color.GREEN);
	        canvas.drawLine(WAVEGRIDXOFS - ofs * (WAVEGRID / LGAWIDTH) + lgatstpos * 5 + 1, WAVEGRIDYOFS, WAVEGRIDXOFS - ofs * (WAVEGRID / LGAWIDTH) + lgatstpos * 5 + 1, WAVEGRIDYOFS + WAVEXSIZE, paint);
		}
		if (lgatrgpos >= ofs && lgatrgpos <= (ofs + WAVEXSIZE / (WAVEGRID / LGAWIDTH))) {
			paint.setColor(Color.RED);
	        canvas.drawLine(WAVEGRIDXOFS - ofs * (WAVEGRID / LGAWIDTH) + lgatrgpos * 5, WAVEGRIDYOFS, WAVEGRIDXOFS - ofs * (WAVEGRID / LGAWIDTH) + lgatrgpos * 5, WAVEGRIDYOFS + WAVEXSIZE, paint);
		}
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
				if (x - WAVEGRIDXOFS >= WAVEXSIZE) {
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
		double dut, per = 0;
		for (i = 0;i<9;i++) {
			wavestr[i] = "";
		}
		wavestr[0] = "Frq: " + FormatFrequency(hscfrq);
		if (hscfrq > 0) {
			per = 1000000000.0 / (double)hscfrq;
		}
		wavestr[1] = "Per: " + FormatTime(per);
		dut = ((double)((hscarr + 1) >> 1) / ((double)hscarr + 1.0));
		wavestr[3] = "Dut: " + String.format("%.1f",100.0 * dut) + "%";
		DrawGrid();
		canvas.clipRect(WAVEGRIDXOFS,WAVEGRIDYOFS,WAVEXSIZE + WAVEGRIDXOFS + 1,WAVEYSIZE + WAVEGRIDYOFS + 1, Op.REPLACE);
		paint.setStrokeWidth(2);
        paint.setColor(Color.YELLOW);
        // Draw l to h
        x = 1;
        xp = 1;
        y = WAVEGRID * 7;
        yp = WAVEGRID * 1;
        canvas.drawLine(xp + WAVEGRIDXOFS, yp + WAVEGRIDYOFS, x + WAVEGRIDXOFS, y + WAVEGRIDYOFS, paint);
        // Draw h
        xp = (int)(WAVEXSIZE * dut);
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
			WAVEGRIDXOFS = (wt - WAVEXSIZE) / 2;
			WAVEGRIDYOFS = 50;
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
		tvfrequency.setText("Frequncy: " +  FormatFrequency(ddsfrqkhz * 1000 + ddsfrqhz));
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
				tvfrequency.setText("Frequncy: " +  FormatFrequency(ddsfrqkhz * 1000 + ddsfrqhz));
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
				tvfrequency.setText("Frequncy: " +  FormatFrequency(ddsfrqkhz * 1000 + ddsfrqhz));
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
				tvfrequency.setText("Frequncy: " +  FormatFrequency(ddsfrqkhz * 1000 + ddsfrqhz));
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
				if (ddsdcofs < 599) {
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
		String s = FormatFrequency(f);
		return s;
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
		String s = FormatFrequency(f);
		return s;
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

		Button btnlgamovetrgdn = (Button) dialog.findViewById(R.id.btnlgamovetrgdn);
		Button btnlgamovetrgup = (Button) dialog.findViewById(R.id.btnlgamovetrgup);

		Button btnlgamovetstdn = (Button) dialog.findViewById(R.id.btnlgamovetstdn);
		Button btnlgamovetstup = (Button) dialog.findViewById(R.id.btnlgamovetstup);

		dialog.setTitle("LGA Setup");
		tvlgasr.setText("Sample rate: " +  lga.lgasrstr[lgasr]);
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
					tvlgasr.setText("Sample rate: " +  lga.lgasrstr[lgasr]);
				}
			}
		});
		
		sblgasr.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		lgasr = progress;
				tvlgasr.setText("Sample rate: " +  lga.lgasrstr[lgasr]);
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
					tvlgasr.setText("Sample rate: " +  lga.lgasrstr[lgasr]);
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
				if (lgatrgpos > 0) {
					lgatrg = GetLGATrigger(dialog, R.id.chklgatrgd0);
					lgamask = GetLGATrigger(dialog, R.id.chklgamaskd0);
					byte val = (byte)((int)lgatrg & (int)lgamask);
					int inx = lgatrgpos;
					inx--;
					while (inx >= 0) {
						if ((BlueTooth.btreadbuffer[inx] & lgamask) == val){
							lgatrgpos = inx;
							if (lgatrgpos < (int)lgaxofs / (WAVEGRID / LGAWIDTH)) {
								lgaxofs = lgatrgpos * (WAVEGRID / LGAWIDTH) - WAVEXSIZE / 2;
								if (lgaxofs < 0) {
									lgaxofs = 0;
								}
							}
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
				if (lgatrgpos < (lgabuff + 1) * 1024) {
					lgatrg = GetLGATrigger(dialog, R.id.chklgatrgd0);
					lgamask = GetLGATrigger(dialog, R.id.chklgamaskd0);
					byte val = (byte)((int)lgatrg & (int)lgamask);
					int inx = lgatrgpos;
					inx++;
					while (inx < (lgabuff + 1) * 1024) {
						if ((BlueTooth.btreadbuffer[inx] & lgamask) == val){
							lgatrgpos = inx;
							if (lgatrgpos > (int)lgaxofs / (WAVEGRID / LGAWIDTH) + WAVEXSIZE / (WAVEGRID / LGAWIDTH)) {
								lgaxofs = (lgatrgpos * (WAVEGRID / LGAWIDTH)) - (WAVEXSIZE / 2);
								if (lgaxofs < 0) {
									lgaxofs = 0;
								}
							}
							break;
						}
						inx++;
					}
		    		DrawLGAWave();
				}
			}
		});
		
        btnlgamovetrgdn.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (lgatrgpos > 0) {
					lgatrgpos--;
					DrawLGAWave();
				}
			}
		});
		
        btnlgamovetrgup.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (lgatrgpos < (lgabuff + 1) * 1024) {
					lgatrgpos++;
					DrawLGAWave();
				}
			}
		});
		
        btnlgamovetstdn.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (lgatstpos > 0) {
					lgatstpos--;
					DrawLGAWave();
				}
			}
		});
		
        btnlgamovetstup.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (lgatstpos < (lgabuff + 1) * 1024) {
					lgatstpos++;
					DrawLGAWave();
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
				sr=lga.lgasrint[lgasr];
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
				//dialog.dismiss();
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
					if (hscfrq > 25000000) {
						hscfrq = 25000000;
						t = GetHscFrq(hscfrq);
					} else if (hscfrq > 16666666){
						hscfrq = 16666666;
						t = GetHscFrq(hscfrq);
					} else if (hscfrq > 12500000){
						hscfrq = 12500000;
						t = GetHscFrq(hscfrq);
					} else if (hscfrq > 10000000){
						hscfrq = 10000000;
						t = GetHscFrq(hscfrq);
					} else {
						t = GetHscFrq(hscfrq);
						while (hscfrq != hscres) {
							hscfrq--;
							t = GetHscFrq(hscfrq);
						}
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
			if (mode == 2 && xd < 512) {
				//Log.d("MYTAG", "ACTION_UP xd " + (int)xd + " yd " + (int)yd + " ofs " + lgaxofs);
				if (Math.abs(xd - event.getX()) < 5 && Math.abs(yd - event.getY()) < 5 && yd < WAVEGRIDYOFS * 2) {
					if (yd > WAVEGRIDYOFS) {
						lgatstpos = (int)lgaxofs / 5 + ((int)(xd - 2.5)) / 5;
					} else {
						lgatrgpos = (int)lgaxofs / 5 + ((int)(xd - 2.5)) / 5;
					}
		    		DrawLGAWave();
				}
			}
			return (true);
		case MotionEvent.ACTION_POINTER_UP:
			Log.d("MYTAG", "ACTION_POINTER_UP");
			return (true);
		case MotionEvent.ACTION_DOWN:
			xs = lgaxofs;
			xd = event.getX();
			yd = event.getY();
			//Log.d("MYTAG", "ACTION_DOWN xd " + xd + " xs " + xs);
			return (true);
		case MotionEvent.ACTION_POINTER_DOWN:
			Log.d("MYTAG", "ACTION_POINTER_DOWN");
			return (true);
		case MotionEvent.ACTION_MOVE:
			if (mode == 2 && xd < 512) {
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
    	BlueTooth.btconnected = BTDisConnect();
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
        		            	BlueTooth.btconnected = true;
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
        	BlueTooth.btconnected = BTDisConnect();
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
