package com.yell.labs.mexicanwave;


import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.SharedPreferences.OnSharedPreferenceChangeListener;
import android.graphics.Color;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.opengl.Visibility;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.animation.Animation;
import android.view.animation.RotateAnimation;
import android.widget.ImageView;


public class MexicanwaveActivity extends Activity implements SensorEventListener, PreviewSurface.Callback, OnSharedPreferenceChangeListener {
    
	private RoarHandler roarHandler;
	private Context context;
	private View view;
	private View warning;
	private SensorManager mySensorManager;
	private Sensor accelerometer;
	private Sensor magnetometer;
	private float[] myGravities;
	private float[] myMagnetics;
	private float averageZGravity;
	private float azimuth;
	private PreviewSurface mSurface;
		
	ImageView waveCompass;
	private Animation rotateAnimation;
	
	private SharedPreferences prefs;
	private int waveDuration;
	private int waveColor;
	private boolean soundEnabled;

	

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        prefs = PreferenceManager.getDefaultSharedPreferences(this);
        prefs.registerOnSharedPreferenceChangeListener(this);
        waveDuration = Integer.parseInt(prefs.getString("pref_wave_duration", "15"));
        waveColor = Color.parseColor(prefs.getString("pref_coloring", "#EEFFFFFF"));
        soundEnabled = prefs.getBoolean("pref_sound", false);
        
        setContentView(R.layout.main);
        context = this;
        view = (View) findViewById(R.id.screenFlash);
        warning = (View) findViewById(R.id.holdThePhone);
        waveCompass = (ImageView) findViewById(R.id.spinningDisc);
        
  
        mSurface = (PreviewSurface) findViewById(R.id.surface);
        mSurface.setCallback(this);

        roarHandler = new RoarHandler(context, view, mSurface, waveDuration, waveColor, soundEnabled);
        
        mySensorManager = (SensorManager) getSystemService(SENSOR_SERVICE);
        accelerometer = mySensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
        magnetometer = mySensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD);
        
    }
    
	@Override
    protected void onStop() {
		super.onStop();
	}
	
	@Override
    protected void onResume() {
    	super.onResume();
    	mySensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_FASTEST );
    	mySensorManager.registerListener(this, magnetometer, SensorManager.SENSOR_DELAY_FASTEST );
    }
 
	@Override
    protected void onPause() {
    	super.onPause();
    	mySensorManager.unregisterListener(this);
    	roarHandler.calmDown();
        mSurface.releaseCamera();
    }

	@Override
	public void cameraReady() {
		roarHandler.setReady(true);
	}

	@Override
	public void cameraNotAvailable() {
		// TODO Auto-generated method stub
	}

	@Override
	public void onAccuracyChanged(Sensor sensor, int accuracy) {
		// TODO Auto-generated method stub
	}

	@Override
	public void onSensorChanged(SensorEvent event) {
		if (event.sensor.getType() == Sensor.TYPE_ACCELEROMETER) {
			myGravities = event.values;
		}
		if (event.sensor.getType() == Sensor.TYPE_MAGNETIC_FIELD) {
			myMagnetics = event.values;
		}
		
		if (myGravities != null && myMagnetics != null) {
			float Ro[] = new float[9];
			float I[] = new float[9];
			boolean success = SensorManager.getRotationMatrix(Ro, I, myGravities, myMagnetics);
			if (success) {

											// 
				azimuth = (float) Math.atan2(-Ro[2], -Ro[5]);   // This is a matrix transform that means that we have expected behaviour when the phone is
																// held up with the screen vertical.  The unpredictable zone for behaviour becomes the state
																// when the phone is flat, screen parallel to the ground, but as we want the phones to be 
																// held up to do a Mexican wave, we don't really care about this state.
				
				float oldAzimuth = roarHandler.getAzimuthInDegrees();  // the old azimuth is used to feed into the animation that smoothes the rotation animation
				
				roarHandler.update(azimuth);  // this sends new raw (and usually very, very noisy) data to the roarHandler, where it is smoothed out and set.
				
				float newAzimuth = roarHandler.getAzimuthInDegrees();
				float offset = roarHandler.getWaveOffestFromAzimuthInDegrees();
				
				rotateAnimation = new RotateAnimation(-oldAzimuth + offset, -newAzimuth + offset, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF , 0.5f);
				waveCompass.startAnimation(rotateAnimation);
				


				
				
				
				// The way we calculate the vector for direction does not work well when the phone is flat,
				// so we first check to make sure that we've not got the z-axis of the device aligned 
				// to the gravity of Earth.  I have made the assumption, as is evidenced by my choice
				// of 9.80665m/s^2, that we won't be using this app on any other planets.
				// TODO - make this work on other planets.
				
				averageZGravity = (averageZGravity*9 + Math.min(Math.abs(myGravities[2]), 9.80665f) )/10;  // abs and min are to hard-filter any rogue readings (samsung nexus loved to give a -32.75 reading every few seconds for no reason whilst flat on a table.)

				// Log.i("info", " ##### Z Gravity is " + String.valueOf(averageZGravity) + " raw is " + String.valueOf( Math.min(Math.abs(myGravities[2]), 9.80665f)));
				if (Math.abs(averageZGravity) > 9 ) {
					// device is too flat
					warning.setVisibility(View.VISIBLE);
				}
				if (Math.abs(averageZGravity) < 8 ) {
					// device is now OK
					warning.setVisibility(View.INVISIBLE);
				}

			}
			
		}
		
	}

	// make the menu, and respond to clicks
	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.menu, menu);
		return true;
	}
	public boolean onOptionsItemSelected(MenuItem item) {
		switch(item.getItemId()) {
		case R.id.settings:
			startActivity(new Intent(this, SettingsActivity.class));
			return true;
		case R.id.about:
			startActivity(new Intent(this, AboutActivity.class));
			return true;
			
			
			default:
				return super.onOptionsItemSelected(item);
		}
		
	}
	
	
	@Override
	public void onSharedPreferenceChanged(SharedPreferences prefs, String key) {
		if (key.equals("pref_group_size_values")) {
			waveDuration = Integer.parseInt(prefs.getString("pref_group_size", "15"));
			roarHandler.setWaveDuration(waveDuration);
		}
		if (key.equals("pref_color_values")) {
			waveColor = Color.parseColor(prefs.getString("pref_coloring", "Color.WHITE"));
			roarHandler.setWaveColor(waveColor);
		}
		

		if (key.equals("pref_sound")) {
			Log.i("info", "innit  " + key);
			soundEnabled = prefs.getBoolean(key, false);
			roarHandler.setSound(soundEnabled);
		}
	}
}