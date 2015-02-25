package com.audio.processing;
import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.ImageView;

import ca.uol.aig.fftpack.RealDoubleFFT;

public class AudioProcessing extends Activity implements OnClickListener{
	int frequency = 8000;
    private RealDoubleFFT transformer;
    int blockSize = 256;
    Button startStopButton;
    Button downButton;
    Button upButton;
    boolean started = false;
    ImageView imageView;
    ImageView imageView2;
    Bitmap bitmap;
    Bitmap bitmap2;
    Canvas canvas;
    Canvas canvas2;
    Paint paint;
    CreateWave waveTask;
    int frq=100;
    boolean fft=false;
    boolean processdone;
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        startStopButton = (Button) this.findViewById(R.id.StartStopButton);
        startStopButton.setOnClickListener(this);

        downButton = (Button) this.findViewById(R.id.button2);
        downButton.setOnClickListener(this);
        downButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
            	frq -= 5;
            	Log.e("AudioRecord", "downButton " + frq);
			}
		});

        upButton = (Button) this.findViewById(R.id.button1);
        upButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
            	frq += 5;
            	Log.e("AudioRecord", "upButton " + frq);
			}
		});


        transformer = new RealDoubleFFT(blockSize);
        imageView = (ImageView) this.findViewById(R.id.ImageView01);
        imageView2 = (ImageView) this.findViewById(R.id.ImageView02);
        bitmap = Bitmap.createBitmap((int)256,(int)120,Bitmap.Config.ARGB_8888);
        bitmap2 = Bitmap.createBitmap((int)256,(int)120,Bitmap.Config.ARGB_8888);
        canvas = new Canvas(bitmap);
        canvas2 = new Canvas(bitmap2);
        paint = new Paint();
        imageView.setImageBitmap(bitmap);
        imageView2.setImageBitmap(bitmap2);
//    	started = true;
//    	startStopButton.setText("Stop");
//    	recordTask = new RecordAudio();
//    	recordTask.execute();
    }

    private class CreateWave extends AsyncTask<Void, double[], Void> {
        @Override
        protected Void doInBackground(Void... params) {
        	try {
                double[] toTransform = new double[blockSize];
                while (started) {
                	/* Create a sine wave with 2nd and 3rd harmonics */
                	for (int i = 0; i < blockSize; i++) {
                		toTransform[i] = ((float) Math.sin( (float)i * ((float)(2*Math.PI) * frq / 8000)))/15.0 + ((float) Math.sin( (float)i * ((float)(2*Math.PI) * frq*2 / 8000)))/30.0 + ((float) Math.sin( (float)i * ((float)(2*Math.PI) * frq*3 / 8000)))/30.0;
                	}
                	fft = false;
        		    processdone = false;
                	publishProgress(toTransform);
                	while (processdone == false);
                	fft = true;
        		    processdone = false;
                	transformer.ft(toTransform);
                	publishProgress(toTransform);
                	while (processdone == false);
//                	Log.e("AudioRecord", "Recording: ");
                }
            } catch (Throwable t) {
                Log.e("AudioRecord", "Recording Failed");
            }
            return null;
        }

	    @Override
	    protected void onProgressUpdate(double[]... toTransform) {
	    	int x,y1 = 60, y2;
	        canvas.drawColor(Color.BLACK);
	        canvas2.drawColor(Color.BLACK);
	        if (fft) {
	        	/* Draw fft */
	            paint.setColor(Color.GREEN);
	        	paint.setStrokeWidth(1.0F);
	        	y2 = 110;
		        for (x = 0; x < toTransform[0].length; x++) {
		        	y1 = (int) (110 - (Math.abs(toTransform[0][x]*10)));
		        	canvas.drawLine(x, y1, x, y2, paint);
		        }
		        imageView.invalidate();
	        } else {
	        	/* Draw wave */
	            paint.setColor(Color.YELLOW);
	        	paint.setStrokeWidth(1.0F);
		        for (x = 0; x < toTransform[0].length; x++) {
		        	y2 = (int) (60 - (toTransform[0][x]*400));
		        	canvas2.drawLine(x, y1, x, y2, paint);
		        	canvas2.drawPoint(x, y2, paint);
		        	y1=y2;
		        }
		        imageView2.invalidate();
	        }

		    processdone = true;
	    }
    }

    public void onClick(View v) {
        if (started) {
        	started = false;
        	startStopButton.setText("Start");
        	waveTask.cancel(true);
        } else {
        	started = true;
        	startStopButton.setText("Stop");
        	waveTask = new CreateWave();
        	waveTask.execute();
        }
    }
}
