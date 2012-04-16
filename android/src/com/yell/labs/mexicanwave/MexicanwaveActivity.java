package com.yell.labs.mexicanwave;


import android.app.Activity;
import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.animation.Animation;
import android.view.animation.RotateAnimation;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.RelativeLayout;


public class MexicanwaveActivity extends Activity implements SensorEventListener {
    
	private Button button;
	private RoarHandler roarHandler;
	private Context context;
	private RelativeLayout view;
	private SensorManager mySensorManager;
	private Sensor accelerometer;
	private Sensor magnetometer;
	private float[] myGravities;
	private float[] myMagnetics;
	private float azimuth;
	
	ImageView waveCompass;
	
	private Animation rotateAnimation;
	

	

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        setContentView(R.layout.main);
        context = this;
        view = (RelativeLayout) findViewById(R.id.overallLayout);
        waveCompass = (ImageView) findViewById(R.id.spinningDisc);
  
        roarHandler = new RoarHandler(context, view);
        
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
    	mySensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_GAME );
    	mySensorManager.registerListener(this, magnetometer, SensorManager.SENSOR_DELAY_GAME );
    	roarHandler.grabCamera();
    }
 
	@Override
    protected void onPause() {
    	super.onPause();
    	roarHandler.calmDown();
    	mySensorManager.unregisterListener(this);

    	if (roarHandler.currentlyRoaring == false) {
    		roarHandler.releaseCamera();
    	}
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
}