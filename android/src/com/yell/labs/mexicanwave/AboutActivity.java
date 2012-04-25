package com.yell.labs.mexicanwave;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;


public class AboutActivity extends Activity  {
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.about);
	}
	

	public void installYellApp(View view) {
		Intent goToMarket = null;
		goToMarket = new Intent(Intent.ACTION_VIEW,Uri.parse("market://details?id=com.yell.launcher2"));
		startActivity(goToMarket);
	}
}