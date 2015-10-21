package com.app.jmrest;

import com.app.jmrest.MyAppWebViewClient;
import com.app.jmrest.R;

import android.app.Activity;
import android.os.Bundle;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;

public class JMRestActivity extends Activity {
	private WebView mWebView;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		requestWindowFeature(Window.FEATURE_NO_TITLE);
		requestWindowFeature(Window.FEATURE_ACTION_BAR_OVERLAY);
		getWindow().setFlags(
		WindowManager.LayoutParams.FLAG_FULLSCREEN,  
		WindowManager.LayoutParams.FLAG_FULLSCREEN);
		setContentView(R.layout.activity_jmrest);

		//final View contentView = findViewById(R.id.activity_main_webview);

        mWebView = (WebView) findViewById(R.id.jmrest_webview);
        // Stop local links and redirects from opening in browser instead of WebView
        mWebView.setWebChromeClient(new WebChromeClient());
        mWebView.setWebViewClient(new MyAppWebViewClient());
        // Enable Javascript
        WebSettings webSettings = mWebView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setUserAgentString("JMAndroidRest");
        mWebView.loadUrl("http://www.jm-data.no/");
	}
}
