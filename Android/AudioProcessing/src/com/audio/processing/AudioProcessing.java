package com.audio.processing;
import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
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
    int channelConfiguration = AudioFormat.CHANNEL_IN_MONO;
    int audioEncoding = AudioFormat.ENCODING_PCM_16BIT;
    private RealDoubleFFT transformer;
    int blockSize = 256;
    Button startStopButton;
    Button downButton;
    Button upButton;
    boolean started = false;
    RecordAudio recordTask;
    ImageView imageView;
    Bitmap bitmap;
    Canvas canvas;
    Paint paint;
    int frq=100;
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
            	frq += 1;
            	Log.e("AudioRecord", "downButton " + frq);
			}
		});

        upButton = (Button) this.findViewById(R.id.button1);
        upButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
            	frq -= 1;
            	Log.e("AudioRecord", "upButton " + frq);
			}
		});


        transformer = new RealDoubleFFT(blockSize);
        imageView = (ImageView) this.findViewById(R.id.ImageView01);
        bitmap = Bitmap.createBitmap((int)256,(int)200,Bitmap.Config.ARGB_8888);
        canvas = new Canvas(bitmap);
        paint = new Paint();
        paint.setColor(Color.GREEN);
        imageView.setImageBitmap(bitmap);
    }

    private class RecordAudio extends AsyncTask<Void, double[], Void> {
        @Override
        protected Void doInBackground(Void... params) {
        	try {
//        		int bufferSize = AudioRecord.getMinBufferSize(frequency, channelConfiguration, audioEncoding);
//                AudioRecord audioRecord = new AudioRecord(MediaRecorder.AudioSource.DEFAULT, frequency, channelConfiguration, audioEncoding, bufferSize);
                short[] buffer = new short[blockSize];
                double[] toTransform = new double[blockSize];
//                audioRecord.startRecording();
                while (started) {
//                	int bufferReadResult = audioRecord.read(buffer, 0, blockSize);
 //                   Log.e("AudioRecord", "Recording: " + bufferReadResult);
//                	for (int i = 0; i < blockSize && i < bufferReadResult; i++) {
//                		toTransform[i] = (double) buffer[i] / 32768.0; // signed 16 bit
//                	}
                	for (int i = 0; i < blockSize; i++) {
                		toTransform[i] = ((float) Math.sin( (float)i * ((float)(2*Math.PI) * frq / 8000)))/15.0 + ((float) Math.sin( (float)i * ((float)(2*Math.PI) * frq*2 / 8000)))/30.0 + ((float) Math.sin( (float)i * ((float)(2*Math.PI) * frq*3 / 8000)))/30.0;    //the part that makes this a sine wave.... 
                				//0.001D*(i & 7);//(double) buffer[i] / 32768.0; // signed 16 bit
                	}
                	transformer.ft(toTransform);
                	publishProgress(toTransform);

                	for (int i = 0; i < 1000000; i++) {
                	}
                	
//                	Log.e("AudioRecord", "Recording: ");
                }
//                audioRecord.stop();
            } catch (Throwable t) {
                Log.e("AudioRecord", "Recording Failed");
            }
            return null;
        }

	    @Override
	    protected void onProgressUpdate(double[]... toTransform) {
	    	int x = 0;
	    	int downy = 0;
	        canvas.drawColor(Color.BLACK);
	        for (int i = 0; i < toTransform[0].length; i++) {
	        	x = i;
	        	downy = (int) (100 - (Math.abs(toTransform[0][i]*10D)));
	        	int upy = 100;
	        	canvas.drawLine(x, downy, x, upy, paint);
	        }
	        imageView.invalidate();
	    }
    }

    public void onClick(View v) {
        if (started) {
        	started = false;
        	startStopButton.setText("Start");
        	recordTask.cancel(true);
        } else {
        	started = true;
        	startStopButton.setText("Stop");
        	recordTask = new RecordAudio();
        	recordTask.execute();
        }
    }
}
