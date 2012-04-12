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
import android.view.animation.AnimationSet;
import android.view.animation.AnimationUtils;
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
    protected void onStop() {
		super.onStop();
		roarHandler.calmDown();
	}
	

    
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        
        
        //waveCompass = new WaveCompass(this);
        //setContentView(waveCompass);
        
        setContentView(R.layout.main);
        context = this;
        view = (RelativeLayout) findViewById(R.id.overallLayout);
        button = (Button) findViewById(R.id.buttonForWave);
        waveCompass = (ImageView) findViewById(R.id.spinningDisc);
        
        
                
        roarHandler = new RoarHandler(context, view);
        
        mySensorManager = (SensorManager) getSystemService(SENSOR_SERVICE);
        accelerometer = mySensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
        magnetometer = mySensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD);

        
//        button.setOnClickListener(new OnClickListener() {
 //       	@Override
   //     	public void onClick(View arg0) {

     //   	}
        	
       // });
               
    }
    
    
    
    protected void onResume() {
    	super.onResume();
    	mySensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_FASTEST );
    	mySensorManager.registerListener(this, magnetometer, SensorManager.SENSOR_DELAY_FASTEST );
    }
 
    protected void onPause() {
    	super.onPause();
    	mySensorManager.unregisterListener(this);
    	roarHandler.calmDown();
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
			// float augmentedR[] = new float[9];
			float I[] = new float[9];
			boolean success = SensorManager.getRotationMatrix(Ro, I, myGravities, myMagnetics);
			if (success) {
				// transpose to a coordinate system where the x axis goes front-to-back through the screen rather than bottom to top parallel with it
				
				// SensorManager.remapCoordinateSystem(R, SensorManager.AXIS_X, SensorManager.AXIS_Z, augmentedR);
				
				//float orientation[] = new float[3];
				//SensorManager.getOrientation(augmentedR, orientation);
				//azimuth = orientation[0];
				
				// retired code, but a reminder that we could do the coordinate mapping this way later on...
				azimuth = (float) Math.atan2(-Ro[2], -Ro[5]);
				
				float oldAzimuth = roarHandler.getAzimuthInDegrees();
				
				roarHandler.check(azimuth);
				
				// TODO: animation here?
				// waveCompass.setDirection((float) (-roarHandler.getAzimuthInDegrees()) + roarHandler.getWaveOffestFromAzimuthInDegrees());
				// rotateAnimation = (Animation) AnimationUtils.loadAnimation(this, R.anim.rotation);
				
				rotateAnimation = new RotateAnimation(oldAzimuth + roarHandler.getWaveOffestFromAzimuthInDegrees(), roarHandler.getAzimuthInDegrees() + roarHandler.getWaveOffestFromAzimuthInDegrees(), Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF , 0.5f);
				
				
				
				waveCompass.startAnimation(rotateAnimation);
			}
			
		}
		
	}
}