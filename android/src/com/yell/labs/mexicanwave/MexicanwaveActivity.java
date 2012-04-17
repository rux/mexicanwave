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
import android.preference.PreferenceManager;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.animation.Animation;
import android.view.animation.RotateAnimation;
import android.widget.ImageView;
import android.widget.RelativeLayout;


public class MexicanwaveActivity extends Activity implements SensorEventListener, PreviewSurface.Callback, OnSharedPreferenceChangeListener {
    
	private RoarHandler roarHandler;
	private Context context;
	private RelativeLayout view;
	private SensorManager mySensorManager;
	private Sensor accelerometer;
	private Sensor magnetometer;
	private float[] myGravities;
	private float[] myMagnetics;
	private float azimuth;
	private PreviewSurface mSurface;
		
	ImageView waveCompass;
	private Animation rotateAnimation;
	
	private SharedPreferences prefs;
	private int waveDuration;
	private int waveColor;

	

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(this);
       
        prefs.registerOnSharedPreferenceChangeListener(this);
        
        waveDuration = Integer.parseInt(prefs.getString("pref_wave_duration", "15"));
        Log.i("info", "************** " + prefs.getString("pref_coloring", "#FFFFFFFF"));
        waveColor = Color.parseColor(prefs.getString("pref_coloring", "#FFFFFFFF"));
        
        setContentView(R.layout.main);
        context = this;
        view = (RelativeLayout) findViewById(R.id.overallLayout);
        waveCompass = (ImageView) findViewById(R.id.spinningDisc);
        
  
        mSurface = (PreviewSurface) findViewById(R.id.surface);
        mSurface.setCallback(this);

        roarHandler = new RoarHandler(context, view, mSurface, waveDuration, waveColor);
        
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
    	mySensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_UI );
    	mySensorManager.registerListener(this, magnetometer, SensorManager.SENSOR_DELAY_UI );
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
																// held up to do a mexican wave, we don't really care about this state.
				
				float oldAzimuth = roarHandler.getAzimuthInDegrees();  // the old azimuth is used to feed into the animation that smooths the rotation animation
				
				roarHandler.update(azimuth);  // this sends new raw (and usually very, very noisy) data to the roarHandler, where it is smoothed out and set.
				
				float newAzimuth = roarHandler.getAzimuthInDegrees();
				float offset = roarHandler.getWaveOffestFromAzimuthInDegrees();
				
				rotateAnimation = new RotateAnimation(-oldAzimuth + offset, -newAzimuth + offset, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF , 0.5f);
				waveCompass.startAnimation(rotateAnimation);
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
	public void onSharedPreferenceChanged(SharedPreferences sharedPreferences, String key) {
		if (key.equals("pref_group_size_values")) {
			waveDuration = Integer.parseInt(prefs.getString("pref_group_size", "15"));
		}
		if (key.equals("pref_color_values")) {
			waveColor = Color.parseColor(prefs.getString("pref_color", "Color.WHITE"));
		}
	}
}