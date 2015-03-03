package app.DDSWave;

import android.app.Activity;
import android.app.Dialog;
import android.content.Context;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Canvas;
import android.graphics.drawable.BitmapDrawable;
import android.os.Bundle;
import android.util.Log;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.view.View.OnClickListener;
import android.view.WindowManager.LayoutParams;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.ImageView;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.SeekBar.OnSeekBarChangeListener;
import app.DDSWave.R;

public class DDSWave extends Activity {
	
	private static ImageView mIV;
	private static Bitmap bmpwave;
	private static Paint paint = new Paint(Paint.FAKE_BOLD_TEXT_FLAG);
	private static Canvas canvas;
	private int wt;
	private int ht;
	private static final int DDSSIZE = 2048;
	private static final int LGASIZE = 32 * 1024;
	private static final int LGAWIDTH = 8;
	private int mode = 0;
	private int WAVEGRID = 48;
	private int WAVEGRIDXOFS = 0;
	private int WAVEGRIDYOFS = 0;
	private short Wave[] = new short[DDSSIZE];
	private int ddsfrqhz = 100;
	private int ddsfrqkhz = 0;
	private boolean ddsfrqhzsel = true;
	private int ddsamp = 100;
	private int ddswave=0;
	private float xd,xs,xofs;

	private byte LGAData[] = new byte[LGASIZE];
	private int lgasr  = 0;
	private String lgasrstr[] = {"1KHz","2KHz","5KHz","10KHz","20KHz","50KHz","100KHz","200KHz","500KHz","1MHz","2MHz","5MHz","10MHz","20MHz","40MHz"};
	private int lgabuff  = 0;
	private byte lgatrg = (byte)0x00;
	private byte lgamask = (byte)0x00;

	private boolean StartUp = true;

	@Override
	public void onCreate(Bundle icicle) {
		super.onCreate(icicle);
    	
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
		final Button btnSETUP = (Button) this.findViewById(R.id.btnSETUP);
		btnDDS.setBackgroundColor(Color.GRAY);
		GenSineWave();
		for (int i = 0;i<LGASIZE;i++) {
			LGAData[i] = (byte)(i & 255);
		}
		btnDDS.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				mode = 0;
				btnDDS.setBackgroundColor(Color.GRAY);
				btnSCOPE.setBackgroundColor(Color.DKGRAY);
				btnLGA.setBackgroundColor(Color.DKGRAY);
				DrawDDSWave();
				Log.d("MYTAG", "DrawDDSWave");
			}
		});
		btnSCOPE.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				mode = 1;
				btnDDS.setBackgroundColor(Color.DKGRAY);
				btnSCOPE.setBackgroundColor(Color.GRAY);
				btnLGA.setBackgroundColor(Color.DKGRAY);
				DrawScopeWave();
				Log.d("MYTAG", "DrawScopeWave");
			}
		});
		btnLGA.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				mode = 2;
				btnDDS.setBackgroundColor(Color.DKGRAY);
				btnSCOPE.setBackgroundColor(Color.DKGRAY);
				btnLGA.setBackgroundColor(Color.GRAY);
				DrawLGAWave();
				Log.d("MYTAG", "DrawLGAWave");
			}
		});
		btnSETUP.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				Log.d("MYTAG", "Setup");
				if (mode == 0) {
					ShowDDSSetupDialog();
				} else if (mode == 1) {
					ShowDDSSetupDialog();
				} else if (mode == 2) {
					ShowLGASetupDialog();
				}
			}
		});

	}
	
	private void GenSineWave() {
		double y;
		for (int x = 0;x < DDSSIZE;x++) {
			y=(float)Math.sin((float)(2*Math.PI) * (float)x / 2048.0D) * 2048.0;
			Wave[x] = (short)(2048 - (int)y);
		}
		
	}

	private void GenTriangleWave() {
		short y = 2048;
		short dir=4;
		for (int x = 0;x < DDSSIZE;x++) {
			Wave[x] = y;
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
	private void GenSquareWave() {
		short y = 4095;
		Wave[0] = 2048;
		Wave[2047] = 2048;
		for (int x = 1;x < DDSSIZE - 1;x++) {
			if (x == 1024) {
				y=0;
			}
			Wave[x] = y;
		}
		
	}

	private void DrawGrid() {
		int x=WAVEGRIDXOFS;
		int y=WAVEGRIDYOFS;
		int i=0;
		bmpwave.eraseColor(Color.BLUE);
		canvas = new Canvas(bmpwave);
		paint.setStrokeWidth(1);
        paint.setColor(Color.DKGRAY);
		while (i < 9) {
	        canvas.drawLine(WAVEGRIDXOFS, y, WAVEGRID*10+WAVEGRIDXOFS, y, paint);
	        y+=WAVEGRID;
	        i++;
		}
		i=0;
		while (i < 11) {
	        canvas.drawLine(x, WAVEGRIDYOFS, x, WAVEGRID*8+WAVEGRIDYOFS, paint);
	        x+=WAVEGRID;
	        i++;
		}
	}

	private void DrawScopeWave() {
		int xp, yp;
		int x=WAVEGRIDXOFS;
		int y=WAVEGRIDYOFS;
		int i=0;
		DrawGrid();
        paint.setColor(Color.YELLOW);
		xp = ((i / 8) * WAVEGRID * 10) / 256;
		yp = (((4095 + 2048- Wave[i]) / 16) * WAVEGRID * 8) / 512;
		i++;
		while (i < 2048) {
			x = ((i / 8) * WAVEGRID * 10) / 256;
			y = (((4095 + 2048 - Wave[i]) / 16) * WAVEGRID * 8) / 512;
	        canvas.drawLine(xp + WAVEGRIDXOFS, yp + WAVEGRIDYOFS, x + WAVEGRIDXOFS, y + WAVEGRIDYOFS, paint);
			xp = x;
			yp = y;
			i++;
		}
		mIV.setImageDrawable(new BitmapDrawable(getResources(), bmpwave));
	}

	private void DrawDDSWave() {
		int xp, yp;
		int x = WAVEGRIDXOFS;
		int y = WAVEGRIDYOFS;
		int i = 0;
		DrawGrid();
		paint.setStrokeWidth(2);
        paint.setColor(Color.YELLOW);
		xp = ((i / 8) * WAVEGRID * 10) / 256;
		yp = (((2048 - Wave[i]) / 16) * WAVEGRID * 6) / 256;
		yp = WAVEGRID * 4  + ((yp * ddsamp) / 300);
		i++;
		while (i < DDSSIZE) {
			x = ((i / 8) * WAVEGRID * 10) / 256;
			y = (((2048 - Wave[i]) / 16) * WAVEGRID * 6) / 256;
			y = WAVEGRID * 4 + ((y * ddsamp) / 300);
	        canvas.drawLine(xp + WAVEGRIDXOFS, yp + WAVEGRIDYOFS, x + WAVEGRIDXOFS, y + WAVEGRIDYOFS, paint);
			xp = x;
			yp = y;
			i++;
		}
		mIV.setImageDrawable(new BitmapDrawable(getResources(), bmpwave));
	}

	private void DrawLGAWave() {
		int x;
		int y = WAVEGRIDYOFS + WAVEGRID / 3;
		int i = 0;
		byte bit,prv;
		DrawGrid();
		paint.setTextSize(15);
		paint.setColor(Color.WHITE);
		while (i < 8) {
			canvas.drawText("D" + i, 5, y, paint);
			y += WAVEGRID;
			i++;
		}
		y = WAVEGRIDYOFS + WAVEGRID;
		bit = 1;
		while (bit != 0) {
			i = (int)xofs / 4;
			x = WAVEGRIDXOFS;
			prv = LGAData[i];
			while (i < LGASIZE) {
				/* Draw L or H */
				if ((LGAData[i] & bit) == 0) {
					/* Low */
			        canvas.drawLine(x, y, x + WAVEGRID / LGAWIDTH, y, paint);
				} else {
					/* High */
			        canvas.drawLine(x, y - WAVEGRID / 2, x + WAVEGRID / LGAWIDTH, y - WAVEGRID / 2, paint);
				}
				if ((prv & bit) != (LGAData[i] & bit)) {
					/* Draw transition */
			        canvas.drawLine(x, y, x, y - WAVEGRID / 2, paint);
				}
				x += WAVEGRID / LGAWIDTH;
				if (x - WAVEGRIDXOFS >= WAVEGRID * 10) {
					break;
				}
				prv = LGAData[i];
				i++;
			}
			bit <<=1;
			y += WAVEGRID;
		}
		mIV.setImageDrawable(new BitmapDrawable(getResources(), bmpwave));
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
//			if (wt > ht) {
//				WAVEGRID = ((ht - 10) / 10) & 254;
//			} else {
//				WAVEGRID = ((wt - 10) / 10) & 254;
//			}
			WAVEGRIDXOFS = (wt - WAVEGRID*10) / 2;
			WAVEGRIDYOFS = (ht - WAVEGRID*10) / 2;
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
		
		dialog.setTitle("DDS Setup");
		ddsfrqhzsel = true;
		tvfrequency.setText("Frequncy: " +  String.format("%.1f",((float)ddsfrqkhz * 1000 + ddsfrqhz)) + "Hz");
		sbfrequency.setProgress(ddsfrqhz);

        rgwave.setOnCheckedChangeListener(new  RadioGroup.OnCheckedChangeListener() {
	        public void onCheckedChanged(RadioGroup group,int checkedId) {
	        	if(checkedId == R.id.rbnsine) {
	        		GenSineWave();
	        		ddswave=0;
	        		DrawDDSWave();
	        	} else if (checkedId == R.id.rbntriangle) {
	        		GenTriangleWave();
	        		ddswave=1;
	        		DrawDDSWave();
	        	} else if (checkedId == R.id.rbnsquare) {
	        		GenSquareWave();
	        		ddswave=2;
	        		DrawDDSWave();
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
				}
			}
		});
		
		sbamplitude.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
        	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        		ddsamp = progress;
        		tvamplitude.setText("Amplitude: " +  String.format("%.1f",((float)ddsamp * 10)) + "mV");
        		DrawDDSWave();
        	}

        	public void onStartTrackingTouch(SeekBar seekBar) {
        	}

        	public void onStopTrackingTouch(SeekBar seekBar) {
        	}
        });

        btnddsampup.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				if (ddsamp < 299) {
					ddsamp++;
					sbamplitude.setProgress(ddsamp);
					tvamplitude.setText("Amplitude: " +  String.format("%.1f",((float)ddsamp * 10)) + "mV");
	        		DrawDDSWave();
				}
			}
		});
		
//		CheckBox chkShowTrail;
//		chkShowTrail = (CheckBox) dialog.findViewById(R.id.chkShowTrail);
//		chkShowTrail.setChecked(MyIV.showtrail);
//		chkShowTrail.setOnClickListener(new OnClickListener() {
//			
//			@Override
//			public void onClick(View v) {
//				MyIV.showtrail = ((CheckBox) v).isChecked();
//			}
//		});
//
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
		int id = 0x7f060019;
		while (i != 0) {
			chk=(CheckBox) dialog.findViewById(id);
			chk.setChecked((lgatrg & i) != 0);
			i <<= 1;
			id++;
		}
		/* Set mask */
		i = 1;
		id = 0x7f060022;
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
				if (xofs >= 4) {
					lgatrg = GetLGATrigger(dialog, 0x7f060019);
					lgamask = GetLGATrigger(dialog, 0x7f060022);
					byte val = (byte)((int)lgatrg & (int)lgamask);
					int inx = (int)(xofs / 4);
					inx--;
					while (inx >= 0) {
						if ((LGAData[inx] & lgamask) == val){
							xofs = inx * 4;
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
				if (xofs / 4 < (lgabuff + 1) * 1024) {
					lgatrg = GetLGATrigger(dialog, 0x7f060019);
					lgamask = GetLGATrigger(dialog, 0x7f060022);
					byte val = (byte)((int)lgatrg & (int)lgamask);
					int inx = (int)(xofs / 4);
					inx++;
					while (inx < (lgabuff + 1) * 1024) {
						if ((LGAData[inx] & lgamask) == val){
							xofs = inx * 4;
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
				lgatrg = GetLGATrigger(dialog, 0x7f060019);
				lgamask = GetLGATrigger(dialog, 0x7f060022);
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
			xs = xofs;
			if (mode == 2) {
				xd = event.getAxisValue(0);
				Log.d("MYTAG", "ACTION_DOWN xd " + xd + " xs " + xs);
			}
			return (true);
		case MotionEvent.ACTION_POINTER_DOWN:
			return (true);
		case MotionEvent.ACTION_MOVE:
			if (mode == 2) {
				xofs = xs + (xd - event.getAxisValue(0, event.getPointerCount() - 1));// / 2;//LGAWIDTH;
				if (xofs<0) xofs=0;
				if (xofs >= LGASIZE * LGAWIDTH - LGAWIDTH) xofs = LGASIZE * LGAWIDTH - LGAWIDTH;
	    		DrawLGAWave();
				Log.d("MYTAG", "ACTION_MOVE " + xofs + " WAVEGRID " + WAVEGRID);
			}
			return (true);
		}
		return super.onTouchEvent(event);
	}
}
