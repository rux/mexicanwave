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
import android.os.Bundle;
import android.os.Debug;
import android.os.PowerManager;
import android.os.PowerManager.WakeLock;
import android.preference.PreferenceManager;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.animation.Animation;
import android.view.animation.RotateAnimation;
import android.widget.ImageView;
import android.widget.TextView;

import com.omniture.*;


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
	
	private PowerManager powerManager;
	private WakeLock wakeLock;
	
	private SharedPreferences prefs;
	private float waveDuration;
	private int waveColor;
	private boolean soundEnabled;
	private boolean vibrationEnabled;

	private boolean cameraIsInitialised;
	
	private AppMeasurement s;
	
	private TextView debugText;
	

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        prefs = PreferenceManager.getDefaultSharedPreferences(this);
        prefs.registerOnSharedPreferenceChangeListener(this);
        waveDuration = Float.parseFloat(prefs.getString("pref_wave_duration", "15"));
        waveColor = Color.parseColor(prefs.getString("pref_coloring", "#EEFFFFFF"));
        soundEnabled = prefs.getBoolean("pref_sound", false);
        vibrationEnabled = prefs.getBoolean("pref_vibration", true);
        
        setContentView(R.layout.main);
        context = this;
        view = (View) findViewById(R.id.screenFlash);
        warning = (View) findViewById(R.id.holdThePhone);
        waveCompass = (ImageView) findViewById(R.id.spinningDisc);
        
        debugText = (TextView) findViewById(R.id.debugText1);
  
        mSurface = (PreviewSurface) findViewById(R.id.surface);
        mSurface.setCallback(this);

        roarHandler = new RoarHandler(context, view, mSurface, waveDuration, waveColor, soundEnabled, vibrationEnabled);
        
        mySensorManager = (SensorManager) getSystemService(SENSOR_SERVICE);
        accelerometer = mySensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
        magnetometer = mySensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD);
        
        // don't let it dim whilst being used
        powerManager = (PowerManager) getSystemService(Context.POWER_SERVICE);
        wakeLock = powerManager.newWakeLock(PowerManager.FULL_WAKE_LOCK, "WakeLockTag");
        
        // Omniture
        s = new AppMeasurement(getApplication());
        s.account = "yelllabsdev";
        s.ssl = true;
        s.currencyCode = "GBP";
        /* Turn on and configure debugging */
        s.debugTracking = true;
        /* WARNING: Changing any of the below variables will cause drastic changes
        to how your visitor data is collected.  Changes should only be made
        when instructed to do so by your account manager.*/
        s.trackingServer = "yellgroup.122.2o7.net";
        
    }
    
	@Override
    protected void onStop() {
		super.onStop();
	}
	
	@Override
    protected void onResume() {
    	super.onResume();
    	mySensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_GAME  );
    	mySensorManager.registerListener(this, magnetometer, SensorManager.SENSOR_DELAY_GAME );
    	// Debug.startMethodTracing("mexicanwave");

        s.pageName = "android/MexicanWave";
        s.channel = "android/MexicanWave";
        s.track();
        

    	wakeLock.acquire();
    }
 
	@Override
    protected void onPause() {

    	// Debug.stopMethodTracing();
    	super.onPause();
    	mySensorManager.unregisterListener(this);
    	roarHandler.calmDown();
        mSurface.releaseCamera();
        
        wakeLock.release();
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
				
				int oldAzimuth = roarHandler.getAzimuthInDegrees();  // the old azimuth is used to feed into the animation that smoothes the rotation animation
				
//				roarHandler.update((float) Math.PI);  // this sends new raw (and usually very, very noisy) data to the roarHandler, where it is smoothed out and set.
				roarHandler.update(azimuth);  // this sends new raw (and usually very, very noisy) data to the roarHandler, where it is smoothed out and set.
				
				int newAzimuth = roarHandler.getAzimuthInDegrees();
				long offset = roarHandler.getWaveOffestFromAzimuthInDegrees();
				
				debugText.setText( "Smoothed " + String.valueOf(newAzimuth));
			
				
				rotateAnimation = new RotateAnimation(-oldAzimuth + offset, -newAzimuth + offset, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF , 0.5f);
				rotateAnimation.setDuration( 20 ); // this is a bit of a guess because I *think* the game sensor delay rate is about 50Hz.
				waveCompass.startAnimation(rotateAnimation);
				
				if (cameraIsInitialised != true ) {
					if (roarHandler.getWhetherCameraIsReady() == true) {
						view.setBackgroundColor(Color.TRANSPARENT);
						cameraIsInitialised = true;
					}
				}
				


				
				
				
				// The way we calculate the vector for direction does not work well when the phone is flat,
				// so we first check to make sure that we've not got the z-axis of the device aligned 
				// to the gravity of Earth.  I have made the assumption, as is evidenced by my choice
				// of 9.80665m/s^2, that we won't be using this app on any other planets.
				// TODO - make this work on other planets.
				
				averageZGravity = (averageZGravity*9 + Math.min(Math.abs(myGravities[2]), 9.80665f) )/10;  // abs and min are to hard-filter any rogue readings (samsung nexus loved to give a -32.75 reading every few seconds for no reason whilst flat on a table.)

				// Log.i("MexicanWave", " ##### Z Gravity is " + String.valueOf(averageZGravity) + " raw is " + String.valueOf( Math.min(Math.abs(myGravities[2]), 9.80665f)));
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
		roarHandler.calmDown();
		if (key.equals("pref_group_size_values")) {
			waveDuration = Integer.parseInt(prefs.getString("pref_wave_duration", "15"));
			roarHandler.setWaveDuration(waveDuration);
		}
		if (key.equals("pref_color_values")) {
			waveColor = Color.parseColor(prefs.getString("pref_coloring", "Color.WHITE"));
			roarHandler.setWaveColor(waveColor);
		}


		if (key.equals("pref_sound")) {
			soundEnabled = prefs.getBoolean(key, false);
			roarHandler.soundEnabled = soundEnabled;
		}

		if (key.equals("pref_vibration")) {
			vibrationEnabled = prefs.getBoolean(key, true);
			Log.i("Mex", String.valueOf(vibrationEnabled));
			roarHandler.vibrationEnabled = vibrationEnabled;
		}
	}

}