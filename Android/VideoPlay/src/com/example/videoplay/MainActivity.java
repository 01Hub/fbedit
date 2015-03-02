package com.example.videoplay;

import java.io.File;

import android.os.Bundle;
import android.os.Environment;
import android.app.Activity;
import android.view.Window;
import android.view.WindowManager;
import android.net.Uri;
import android.widget.MediaController;
import android.widget.VideoView;

public class MainActivity extends Activity {

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		requestWindowFeature(Window.FEATURE_NO_TITLE);
		requestWindowFeature(Window.FEATURE_ACTION_BAR_OVERLAY);
		getWindow().setFlags(
		WindowManager.LayoutParams.FLAG_FULLSCREEN,  
		WindowManager.LayoutParams.FLAG_FULLSCREEN);
		setContentView(R.layout.main);
		VideoView vidView = (VideoView)findViewById(R.id.myVideo);
		Uri vidUri = Uri.parse(Environment.getExternalStorageDirectory() + File.separator + "Movies" + File.separator + "video.mp4");

		vidView.setVideoURI(vidUri);
		MediaController vidControl = new MediaController(this);
		vidControl.setAnchorView(vidView);
		vidView.setMediaController(vidControl);
		vidView.start();
	}
}
