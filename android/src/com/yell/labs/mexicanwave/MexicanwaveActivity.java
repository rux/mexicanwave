package com.yell.labs.mexicanwave;


import java.util.Random;

import android.R.integer;
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
import android.view.MotionEvent;
import android.view.View;
import android.view.animation.Animation;
import android.view.animation.CycleInterpolator;
import android.view.animation.RotateAnimation;
import android.view.animation.TranslateAnimation;
import android.view.animation.Animation.AnimationListener;
import android.widget.ImageView;
import android.widget.RelativeLayout;
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
	private double azimuth;
	private PreviewSurface mSurface;
	private PowerManager powerManager;
	private WakeLock wakeLock;
	private SharedPreferences prefs;
	private boolean cameraIsInitialised;
	private AppMeasurement s;
	private static boolean PRODUCTION_VERSION;
	private ImageView[] cacti;
	private boolean[] cactiBouncing;
	private int[] frontCactusOptions;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        
        PRODUCTION_VERSION = false;

        prefs = PreferenceManager.getDefaultSharedPreferences(this);
        prefs.registerOnSharedPreferenceChangeListener(this);
        boolean stadiumMode = prefs.getBoolean("pref_stadium", false);
        int waveDuration = stadiumMode ? 10 : 5;
        
        int waveColor = Color.parseColor(prefs.getString("pref_coloring", "#EEFFFFFF"));
        boolean soundEnabled = prefs.getBoolean("pref_sound", false);
        boolean vibrationEnabled = prefs.getBoolean("pref_vibration", true);
        boolean noGameMode = prefs.getBoolean("pref_no_game", false);
        
        setContentView(R.layout.main);
        context = this;
        view = (View) findViewById(R.id.screenFlash);
        warning = (View) findViewById(R.id.holdThePhone);
        
        mSurface = (PreviewSurface) findViewById(R.id.surface);
        mSurface.setCallback(this);

        roarHandler = new RoarHandler(context, view, mSurface, waveDuration, waveColor, soundEnabled, vibrationEnabled, noGameMode);
        
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
        
        cacti = new ImageView[12];
        cactiBouncing = new boolean[12];
        
        cacti[0] = (ImageView) findViewById(R.id.cactus_0);
        cacti[1] = (ImageView) findViewById(R.id.cactus_1);
        cacti[2] = (ImageView) findViewById(R.id.cactus_2);
        cacti[3] = (ImageView) findViewById(R.id.cactus_3);
        cacti[4] = (ImageView) findViewById(R.id.cactus_4);
        cacti[5] = (ImageView) findViewById(R.id.cactus_5);
        cacti[6] = (ImageView) findViewById(R.id.cactus_6);
        cacti[7] = (ImageView) findViewById(R.id.cactus_7);
        cacti[8] = (ImageView) findViewById(R.id.cactus_8);
        cacti[9] = (ImageView) findViewById(R.id.cactus_9);
        cacti[10] = (ImageView) findViewById(R.id.cactus_10);
        cacti[11] = (ImageView) findViewById(R.id.cactus_11);
        
		
        // TODO maybe move these to the XML, but for now it's easier to move them around when all these values are in the same place
        cacti[5].setMaxHeight(40);
        cacti[4].setMaxHeight(50);
        cacti[6].setMaxHeight(50);
        cacti[3].setMaxHeight(60);
        cacti[7].setMaxHeight(60);
        cacti[2].setMaxHeight(80);
        cacti[8].setMaxHeight(80);
        cacti[1].setMaxHeight(100);
        cacti[9].setMaxHeight(100);
        cacti[0].setMaxHeight(150);
        cacti[10].setMaxHeight(150);
        cacti[11].setMaxHeight(225);  // this should be the biggest one
        

        frontCactusOptions = new int[4];

        frontCactusOptions[0] = R.drawable.sprite_1;
		frontCactusOptions[1] = R.drawable.sprite_4;
		frontCactusOptions[2] = R.drawable.sprite_8;
		frontCactusOptions[3] = R.drawable.sprite_9;
		
		Log.i("Mex Init", String.valueOf(frontCactusOptions[1]));
       
    }
    
	@Override
    protected void onStop() {
		super.onStop();
	}
	
	@Override
    protected void onResume() {
    	super.onResume();
    	mySensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_UI  );
    	mySensorManager.registerListener(this, magnetometer, SensorManager.SENSOR_DELAY_UI );
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
		roarHandler.cameraReady = true;
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
		int sensorType = event.sensor.getType();
		
		if (sensorType == Sensor.TYPE_ACCELEROMETER) {
			myGravities = event.values;
		}
		if (sensorType == Sensor.TYPE_MAGNETIC_FIELD) {
			myMagnetics = event.values;
		}
		
		if ((sensorType == Sensor.TYPE_MAGNETIC_FIELD || sensorType == Sensor.TYPE_ACCELEROMETER) && myGravities != null && myMagnetics != null) {
			
			
			// check the magnitude of magnetometers - to handle dodgy readings
			double magneticFieldStrength = (Math.sqrt(myMagnetics[0]*myMagnetics[0] + myMagnetics[1]*myMagnetics[1] + myMagnetics[2]*myMagnetics[2]));
			
			// check the magnitude of gravity sensors
			double gravityFieldStrength = (Math.sqrt(myGravities[0]*myGravities[0] + myGravities[1]*myGravities[1] + myGravities[2]*myGravities[2]));
			
			if ( magneticFieldStrength < 18 || magneticFieldStrength > 65 ) {  // values take because the are the working ranges in the
				// UK.  Or here http://en.wikipedia.org/wiki/Orders_of_magnitude_(magnetic_field).
				// it is possible to end up here thanks to bad sensor systems in the device, notably Samsung devices.
				// Occasionally, the myMagnetics array gets filled with sensor readings from the accelerometer ( eg [0,0,9.81] ).
				// This is clearly wrong, so if we get readings in that ballpark, ie magnitude of about 10, we can clearly
				// just drop it.
				
				// Log.e("MexicanWaveMagnets", " magneticFieldStrength is outside expected tolerances, dropping measurement.  We may have interference. " + String.valueOf(magneticFieldStrength)  );
			} else if (gravityFieldStrength < 5 || gravityFieldStrength > 15) {
				// this will happen when the crazy Samsung sensors give the magnetic sensors to the gravity array.
				// Also, this will happen if there's too much movement or if the person is in freefall, both of which mean
				// that we shouldn't be using the values.
				// Log.e("MexicanWaveGravity", " gravityFieldStrength is outside expected tolerances, dropping measurement. " + String.valueOf(gravityFieldStrength));
			} else {
				float Ro[] = new float[9];
				float I[] = new float[9];
				boolean success = SensorManager.getRotationMatrix(Ro, I, myGravities, myMagnetics);
				if (success) {
					azimuth = Math.atan2(-Ro[2], -Ro[5]);   // This is a matrix transform that means that we have expected behaviour when the phone is
																	// held up with the screen vertical.  The unpredictable zone for behaviour becomes the state
																	// when the phone is flat, screen parallel to the ground, but as we want the phones to be 
																	// held up to do a Mexican wave, we don't really care about this state.
					
					int oldAzimuth = roarHandler.getAzimuthInDegrees();  // the old azimuth is used to feed into the animation that smoothes the rotation animation
					
					roarHandler.setAzimuth(azimuth);  // this sends new raw (and usually very, very noisy) data to the roarHandler, where it is smoothed out and set.
					roarHandler.check();  // this checks to see if we should be roaring or not.
					
					int newAzimuth = roarHandler.getAzimuthInDegrees();
					long offset = roarHandler.getWaveOffestFromAzimuthInDegrees();
					
					int oldAngle = (int) ((-oldAzimuth + offset) % 360);
					int newAngle = (int) ((-newAzimuth + offset) % 360);
					

					
					if (cameraIsInitialised != true ) {
						if (roarHandler.getWhetherCameraIsReady() == true) {
							view.setBackgroundColor(Color.TRANSPARENT);
							cameraIsInitialised = true;
						}
					}
					
					for (ImageView cactus : cacti) {
						if (cactus != null) {
								Object tag = cactus.getTag();  
								//TODO is there a better way to do this?  Seems a little wrong to have to do so much conversion...
								String stringAngle = String.valueOf(tag);
								Integer angle = Integer.valueOf(stringAngle);
								if (Math.abs(newAngle - angle) < 15) {
									bounce(cactus, angle);
								}
						}
					}

					
					
					
					// The way we calculate the vector for direction does not work well when the phone is flat,
					// so we first check to make sure that we've not got the z-axis of the device aligned 
					// to the gravity of Earth.  I have made the assumption, as is evidenced by my choice
					// of 9.80665m/s^2, that we won't be using this app on any other planets.
					// TODO - make this work on other planets.
					
					averageZGravity = (averageZGravity*9 + Math.min(Math.abs(myGravities[2]), 9.80665f) )/10;  // abs and min are to hard-filter any rogue readings (samsung nexus loves to give a -32.75 reading every few seconds for no reason whilst flat on a table.)

					if (Math.abs(averageZGravity) > 9 ) {
						// device is too flat
						roarHandler.isFlat = true;
						warning.setVisibility(View.VISIBLE);
					}
					if (Math.abs(averageZGravity) < 8 ) {
						// device is now OK
						roarHandler.isFlat = false;
						warning.setVisibility(View.INVISIBLE);
					}
				}
			}
			
		}
		
	}
	
	
	
	private void bounce(final ImageView cactus, final Integer angle) {
		boolean isCurrentlyAnimating = false;
		
		Animation ani = cactus.getAnimation();
		if (ani != null) {
		    isCurrentlyAnimating = !ani.hasEnded();
		}

        if (isCurrentlyAnimating == false) {
        	
        	// change the front sprite image
        	if (angle == 180 ) {
        		Random rand = new Random();
        		
        		int r = rand.nextInt(4);
        		cactus.setImageResource(frontCactusOptions[r]);
        		
        	}
        	
			int bounceHeight = -20 -cactus.getTop()/5;
			
	        TranslateAnimation bounceAnimation = new TranslateAnimation(0, 0, 0, bounceHeight );
	        bounceAnimation.setDuration(2000);
	        bounceAnimation.setInterpolator(new CycleInterpolator(1));
        
        	cactus.startAnimation(bounceAnimation);
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
		if (key.equals("pref_stadium")) {
			boolean stadiumMode = prefs.getBoolean("pref_stadium", false);
		    int waveDuration = stadiumMode ? 10 : 5;
			roarHandler.setWaveDuration(waveDuration);
		}
		
		if (key.equals("pref_color_values")) {
			roarHandler.waveColor = Color.parseColor(prefs.getString("pref_coloring", "Color.WHITE"));
		}

		if (key.equals("pref_sound")) {
			roarHandler.soundEnabled = prefs.getBoolean(key, false);
		}

		if (key.equals("pref_vibration")) {
			roarHandler.vibrationEnabled = prefs.getBoolean(key, true);
		}

		if (key.equals("pref_no_game")) {
			roarHandler.noGameMode = prefs.getBoolean(key, false);
		}
	}

	
	@Override
	public boolean dispatchTouchEvent(MotionEvent ev) {
		super.dispatchTouchEvent(ev);
		
		if (ev.getAction() == MotionEvent.ACTION_DOWN ) {
			Log.i("MexicanWaveTouch", "touch down");  // + ev.toString());
			roarHandler.touched = true;
		}
		
		return false;
	}
}