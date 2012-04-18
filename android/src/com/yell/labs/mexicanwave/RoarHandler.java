package com.yell.labs.mexicanwave;

import java.text.SimpleDateFormat;
import java.util.Date;

import android.content.Context;
import android.graphics.Color;
import android.media.AudioManager;
import android.media.SoundPool;
import android.media.SoundPool.OnLoadCompleteListener;
import android.os.Vibrator;
import android.util.Log;
import android.view.View;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

class RoarHandler {
	private Vibrator vibrator;
	private View theLayout;
	private PreviewSurface mSurface;
	private boolean cameraReady;	
	public boolean currentlyRoaring;	
	private float azimuth;
	private int waveDuration;
	private int waveColor;
	private boolean soundEnabled;
	private AudioManager audioManager;
	private SoundPool soundPool;
	private int soundId;
	private boolean soundLoaded;
	

	RoarHandler(Context c, View v, PreviewSurface previewSurface, int wD, int wC, boolean sE) {        
		vibrator = (Vibrator) c.getSystemService(Context.VIBRATOR_SERVICE);  
        theLayout = (View) v;
        mSurface = previewSurface;
        this.setWaveDuration(wD);
        this.setWaveColor(wC);
        this.setSound(sE);
        
        soundPool = new SoundPool(1, AudioManager.STREAM_MUSIC, 0);
        soundPool.setOnLoadCompleteListener(new OnLoadCompleteListener() {
			@Override
			public void onLoadComplete(SoundPool soundPool, int sampleId, int status) {
				soundLoaded = true;
			}
		});
        soundId = soundPool.load(c, R.raw.cheer, 1);
        audioManager = (AudioManager) c.getSystemService(c.AUDIO_SERVICE);
        
        
        currentlyRoaring = true;  // this is initialised as true, so when the app starts, the calmDown() gets called and sets everything to the non-roaring state
	}
	
	public void setSound(boolean s) {
		soundEnabled = s;
	}

	public boolean getCurrentlyRoaring() {
		return currentlyRoaring;
	}
	
	public void setWaveDuration(int w) {
		waveDuration = w;
	}
	public void setWaveColor(int c) {
		waveColor = c;
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
		
		SimpleDateFormat dateFormat = new SimpleDateFormat("ss.SSS");
		float seconds = Float.parseFloat(dateFormat.format(new Date()));
		
		float offset = seconds * 6 * (60/this.waveDuration);
		return (float) offset;
	}
	
    void update(float azimuth) {
		this.setAzimuth(azimuth);  // we do the maths for smoothing in here
		
		// float averageAzimuth = this.getAzimuthInDegrees();
    	//float waveOffset = this.getWaveOffestFromAzimuthInDegrees();
		//Log.i("info", "Current smoothed azimuth is " + String.valueOf(averageAzimuth));
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

	public void setReady(boolean ready) {
		cameraReady = ready;
	}
	
	public void goWild() {

		if (currentlyRoaring != true && cameraReady) {			
			mSurface.lightOn();
			vibrator.vibrate(1000);
			theLayout.setBackgroundColor(this.waveColor);
			currentlyRoaring = true;
			
			Log.i("info", "sound flags are " + String.valueOf(soundEnabled) + " : " + String.valueOf(soundLoaded));
			if(soundEnabled && soundLoaded) {
				Log.i("info", "playing");
				float actualVolume = (float) audioManager.getStreamVolume(AudioManager.STREAM_MUSIC);
				float maxVolume = (float) audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
				float volume = actualVolume / maxVolume;
				soundPool.play(soundId, volume, volume, 1, 0, 1f);
			}
			
		} else {
			// Log.i("info", "already roaring");
		}
		
		
	}	
	
	public void calmDown() {
		if(cameraReady) {
			mSurface.lightOff();
			theLayout.setBackgroundColor(Color.BLACK);
			currentlyRoaring = false;
		}
	
	}

}