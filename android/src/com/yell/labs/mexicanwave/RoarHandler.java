package com.yell.labs.mexicanwave;

import android.content.Context;
import android.graphics.Color;
import android.media.AudioManager;
import android.media.SoundPool;
import android.media.SoundPool.OnLoadCompleteListener;
import android.os.AsyncTask;
import android.os.Vibrator;
import android.util.Log;
import android.view.View;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.animation.Animation;
import android.view.animation.Animation.AnimationListener;
import android.view.animation.AnimationUtils;



class RoarHandler {
	private Context context;
	private Vibrator vibrator;
	private View screenFlash;
	private PreviewSurface mSurface;
	public boolean cameraReady;	
	public boolean currentlyRoaring;
	public int waveCount;
	public float azimuth;
	private float waveDuration;
	private int waveColor;
	private boolean soundEnabled;
	private AudioManager audioManager;
	private SoundPool soundPool;
	private int soundId;
	private boolean soundLoaded;
	
	private Animation flashAnim;
	
	private SntpClient sntpClient;
	private final String timeServer;
	private long timeOffset;
	

	RoarHandler(Context c, View v, PreviewSurface previewSurface, int wD, int wC, boolean sE) {
		context = c;
		vibrator = (Vibrator) c.getSystemService(Context.VIBRATOR_SERVICE);  
        screenFlash = (View) v;
        mSurface = previewSurface;
        this.setWaveDuration(wD);
        this.setFlash(wD);
        this.setWaveColor(wC);
        this.setSound(sE);
        
        soundPool = new SoundPool(1, AudioManager.STREAM_MUSIC, 0);
        soundPool.setOnLoadCompleteListener(new OnLoadCompleteListener() {
			@Override
			public void onLoadComplete(SoundPool soundPool, int sampleId, int status) {
				soundLoaded = true;
			}
		});
        soundId = soundPool.load(context, R.raw.cheer, 1);
        audioManager = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
        
        
        flashAnim.setAnimationListener(new AnimationListener() {  // this is a workaround for a bug that means we can't define the last frame stay put afterh the animation's finished
			@Override
			public void onAnimationStart(Animation animation) {}
			@Override
			public void onAnimationRepeat(Animation animation) {}
			@Override
			public void onAnimationEnd(Animation animation) {
				screenFlash.setBackgroundColor(Color.TRANSPARENT);
			}
		});

        timeOffset = 0;
        timeServer = "0.pool.ntp.org";
        getNtpTime ntpTime = new getNtpTime();
        ntpTime.execute(timeServer);
        
        
        
        currentlyRoaring = true;  // this is initialised as true, so when the app starts, the calmDown() gets called and sets everything to the non-roaring state
	}
	

	private class getNtpTime extends AsyncTask<String, Void, Long> {
		@Override
		protected Long doInBackground(String... params) {
	        sntpClient = new SntpClient();
	        Long ntpTime = (long) 0;
	        Long timeDifference = (long) 0;
	        if (sntpClient.requestTime(timeServer, 5000) ) {
	        	ntpTime = sntpClient.getNtpTime();
	            // Log.i("MexicanWave", String.valueOf(System.currentTimeMillis()) + ".... System Time");
	            // Log.i("MexicanWave", String.valueOf(ntpTime) + ".... new Time");
	            timeDifference = ntpTime - System.currentTimeMillis();
	        } else {
	        	// Log.i("MexicanWave", "***** **** *** ** * no NTP time from " + timeServer);
	        }
			return timeDifference;
		}
		
		@Override
		protected void onPostExecute(Long result) {
			timeOffset = result;
			// Log.i("MexicanWave", "** now in postexecute " + String.valueOf(timeOffset));
		}
	}
	
	public void setSound(boolean s) {
		soundEnabled = s;
	}

	public boolean getCurrentlyRoaring() {
		return currentlyRoaring;
	}
	
	public void setWaveDuration(float w) {
		waveDuration = w;
		waveCount = (waveDuration == 15) ? 2 : 1;  // the gig speed, 15, has two waves going around
		this.setFlash(w);
	}
	public void setWaveColor(int c) {
		waveColor = c;
	}
	public void setFlash(float w) {
		if (w < 20) {
			flashAnim = AnimationUtils.loadAnimation(context, R.anim.flash);
		} else {
			flashAnim = AnimationUtils.loadAnimation(context, R.anim.flash_long);
		}
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
	public int getAzimuthInDegrees() {
		return (int) (this.azimuth*180/Math.PI);
	}
	

	public int getWaveOffestFromAzimuthInDegrees() {
		int milliseconds = (int) (System.currentTimeMillis() % 60000);
		// milliseconds is an int that comes in the form of a number between 0 and 59999 that represents milliseconds from the last minute 'boundary'.
		
		float offsetDegrees =  (((milliseconds + timeOffset) * 6 * (60/this.waveDuration) ) / 1000);
		// divide by 1000 to get milliseconds => seconds. multiply by 6 to get seconds => degrees. 
		Log.i("MexicanWave", "**()()** making with offset " + String.valueOf(timeOffset) + "ms, and offset degrees is " + String.valueOf(offsetDegrees));

		return (int) offsetDegrees;
	}
	
    void update(float azimuth) {
		this.setAzimuth(azimuth);  // we do the maths for smoothing in here
		
		// float averageAzimuth = this.getAzimuthInDegrees();
    	//float waveOffset = this.getWaveOffestFromAzimuthInDegrees();
		//Log.i("MexicanWave", "Current smoothed azimuth is " + String.valueOf(averageAzimuth));
		this.check();
    }	
		
	public void check() {
		int angle = (-this.getAzimuthInDegrees() + this.getWaveOffestFromAzimuthInDegrees()) % 360;
		Log.i("MexicanWave", "**()()** angle " + String.valueOf(angle));
		if (angle > 160 && angle < 200) {
			goWild();
		} else {
			calmDown();
		}
	}

	public void setReady(boolean ready) {
		cameraReady = ready;
	}
	public boolean getWhetherCameraIsReady() {
		return (mSurface.hasCamera && mSurface.hasSurface) ? true : false;
	}
	
	public void goWild() {
		
		if (currentlyRoaring != true && cameraReady) {			
			mSurface.lightOn();
			vibrator.vibrate(100 * (int) waveDuration);  // don't mind casting to int because the actual duration of the vibration isn't really all that important.
			screenFlash.setBackgroundColor(waveColor);
			screenFlash.startAnimation(flashAnim);
			
			
			if(soundEnabled && soundLoaded) {
				float actualVolume = (float) audioManager.getStreamVolume(AudioManager.STREAM_MUSIC);
				float maxVolume = (float) audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
				float volume = actualVolume / maxVolume;
				soundPool.play(soundId, volume, volume, 1, 0, 1f);
			}
			
			currentlyRoaring = true;
			
		}
	}	
	
	public void calmDown() {
		if(cameraReady && (currentlyRoaring == true)) {
			mSurface.lightOff();
		}
		currentlyRoaring = false;
	}
}

