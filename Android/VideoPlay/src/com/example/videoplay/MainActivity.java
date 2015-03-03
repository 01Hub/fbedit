package com.example.videoplay;

import java.io.File;

import android.os.Bundle;
import android.os.Environment;
import android.app.Activity;
import android.content.Intent;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.view.View.OnClickListener;
import android.media.MediaPlayer;
import android.media.MediaPlayer.OnCompletionListener;
import android.net.Uri;
import android.widget.Button;
import android.widget.MediaController;
import android.widget.VideoView;

public class MainActivity extends Activity {

	private int rseed;
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		requestWindowFeature(Window.FEATURE_NO_TITLE);
		requestWindowFeature(Window.FEATURE_ACTION_BAR_OVERLAY);
		getWindow().setFlags(
		WindowManager.LayoutParams.FLAG_FULLSCREEN,  
		WindowManager.LayoutParams.FLAG_FULLSCREEN);
		setContentView(R.layout.main);

		final MediaController vidControl = new MediaController(this);
		Button btn0 = (Button) this.findViewById(R.id.btn0);
		Button btn1 = (Button) this.findViewById(R.id.btn1);
		Button btn2 = (Button) this.findViewById(R.id.btn2);
		Button btn3 = (Button) this.findViewById(R.id.btn3);
		rseed=1234;
		btn0.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				PlayVideo(vidControl, 0);
			 }
		});
		btn1.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				PlayVideo(vidControl, 1);
			 }
		});
		btn2.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				PlayVideo(vidControl, 2);
			 }
		});
		btn3.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				PlayVideo(vidControl, 3);
			 }
		});
	}

	private void PlayVideo(MediaController vidControl,int btn) {
		setContentView(R.layout.vidmain);
		final VideoView vidView = (VideoView)findViewById(R.id.myVideo);
		String path;
		String file = "";
		Uri vidUri = null;
		path = Environment.getExternalStorageDirectory() + File.separator + "Movies" + File.separator;
		switch (btn) {
		case 0:
			file = "video.mp4";
		case 1:
			file = "video.mp4";
		case 2:
			file = "video.mp4";
		case 3:
			file = "video.mp4";
		}
		vidUri = Uri.parse(path + file);

		vidView.setVideoURI(vidUri);
		vidControl.setAnchorView(vidView);
		vidView.setMediaController(vidControl);
	   vidView.setOnCompletionListener(new OnCompletionListener() {
	        @Override
	        public void onCompletion(MediaPlayer mp) {
				Intent i = getBaseContext().getPackageManager().getLaunchIntentForPackage( getBaseContext().getPackageName() );
				i.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
				startActivity(i);
			}
	    });
		vidView.start();
	}
	
	private int Random() {
		int lsb;
		int rnd = rseed * 23 + 7;
		lsb = (rnd & 1) << 31;
		rnd >>>= 1;
		rnd |= lsb;
		rnd ^= rseed;
		rseed = rnd;
		return rnd;
	}
}
