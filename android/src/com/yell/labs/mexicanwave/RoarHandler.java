package com.yell.labs.mexicanwave;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;

import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.hardware.Camera;
import android.hardware.Camera.Parameters;
import android.os.Vibrator;
import android.util.Log;
import android.view.SurfaceView;
import android.view.View;

class RoarHandler {
	private Context context;
	private Vibrator vibrator;
	private Camera camera;
	private Parameters p;
	private View theLayout;
	private SurfaceView dummy;
	
	public boolean currentlyRoaring;
	
	private float azimuth;
	
	
	

	RoarHandler(Context c, View v) {
        PackageManager pm = c.getPackageManager();
        if (!pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)) {
        	Log.e("err", "This device has no flash");
        	return;
        }
        
		vibrator = (Vibrator) c.getSystemService(Context.VIBRATOR_SERVICE);  
        theLayout = (View) v;

		dummy=new SurfaceView(c);
		
        currentlyRoaring = true;  // this is initialised as true, so when the app starts, the calmDown() gets called and sets everything to the non-roaring state
	}
	
	
	public void grabCamera() {
		camera = Camera.open();
		p = camera.getParameters();
        try {
			camera.setPreviewDisplay(dummy.getHolder());
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} 
		Log.i("info", "The Camera is initialised!");
	}
	public void releaseCamera() {
		this.calmDown();
		camera.release();
	}
	
	
	public boolean getCurrentlyRoaring() {
		return currentlyRoaring;
	}
	
	private void setAzimuth(float a) {
		double oldAzimuth = (double) azimuth;
		double newAzimuth = (double) a;
		
		double oldx = Math.sin(oldAzimuth);
		double oldy = Math.cos(oldAzimuth);
		
		double newx = Math.sin(newAzimuth);
		double newy = Math.cos(newAzimuth);

		double x = 39*oldx + newx;
		double y = 39*oldy + newy;
		
		azimuth = (float) Math.atan2(x, y);  // upside down x and y.  do not be afraid.  Tom said it was OK
	}
	
	public float getAzimuth() {
		return azimuth;
	}
	public float getAzimuthInDegrees() {
		return (float) (this.getAzimuth()*180/Math.PI);
	}
	
	public float getWaveOffestFromAzimuthInDegrees() {
		int wavelength = 15;  // in seconds please
		
		SimpleDateFormat dateFormat = new SimpleDateFormat("ss.SSS");
		float seconds = Float.parseFloat(dateFormat.format(new Date()));
		
		float offset = seconds * 6 * (60/wavelength);
		return (float) offset;
	}


	
    void update(float azimuth) {
		this.setAzimuth(azimuth);  // we do the maths for smoothing in here
		
		float averageAzimuth = this.getAzimuthInDegrees();
    	float waveOffset = this.getWaveOffestFromAzimuthInDegrees();
		Log.i("info", "Current smoothed azimuth is " + String.valueOf(averageAzimuth));
		this.check();
    }	
	
	
	public void check() {
		float angle = (-this.getAzimuthInDegrees() + getWaveOffestFromAzimuthInDegrees()) % 360;
		if (angle > 160 && angle < 200) {
			goWild();
		} else {
			calmDown();
		}
	}


	public void goWild() {
		if (currentlyRoaring != true) {
			p.setFlashMode(Parameters.FLASH_MODE_TORCH);
			camera.setParameters(p);
			camera.startPreview();
			vibrator.vibrate(1000);
			theLayout.setBackgroundColor(Color.WHITE);
			Log.i("info", "camera info " + String.valueOf(camera) + "  :  " + String.valueOf(p.getFlashMode()));
		}
		currentlyRoaring = true;
	}	
	

	public void calmDown() {
		if (currentlyRoaring == true) {
			p.setFlashMode(Parameters.FLASH_MODE_OFF);
			camera.setParameters(p);
			camera.stopPreview();
			theLayout.setBackgroundColor(Color.BLACK);
		}
		currentlyRoaring = false;
	}
}