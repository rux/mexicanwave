package com.yell.labs.mexicanwave;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

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
	public boolean isFlat;
	public int waveCount;
	public float azimuth;
	private float waveDuration;
	private int waveColor;
	public boolean vibrationEnabled;
	public boolean soundEnabled;
	private AudioManager audioManager;
	private SoundPool soundPool;
	private int soundId;
	private boolean soundLoaded;
	
	private Animation flashAnim;
	
	private SntpClient sntpClient;
	private final String timeServer;
	private long timeOffset;
	

	RoarHandler(Context c, View v, PreviewSurface previewSurface, float wD, int wC, boolean sE, boolean vE) {
		context = c;
		vibrator = (Vibrator) c.getSystemService(Context.VIBRATOR_SERVICE);  
        screenFlash = (View) v;
        mSurface = previewSurface;
        this.setWaveDuration(wD);
        this.setFlash(wD);
        this.setWaveColor(wC);
        soundEnabled = sE;
        vibrationEnabled =vE;
        isFlat = false;
        
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
	             //Log.i("MexicanWaveNtp", String.valueOf(System.currentTimeMillis()) + ".... System Time");
	             //Log.i("MexicanWaveNtp", String.valueOf(ntpTime) + ".... new Time");
	            timeDifference = ntpTime - System.currentTimeMillis();
	        } else {
	        	Log.e("MexicanWaveNtp", "no NTP time from " + timeServer);
	        }
			return timeDifference;
		}
		
		@Override
		protected void onPostExecute(Long result) {
			timeOffset = result;
			// Log.i("MexicanWaveNtp", String.valueOf(timeOffset) + ".... offset");
		}
	}
	
	public void setSound(boolean s) {
		soundEnabled = s;
	}

	public void setWaveDuration(float w) {
		waveDuration = w;
		// waveCount = (waveDuration == 15) ? 2 : 1;  // the gig speed, 15, has two waves going around
		waveCount =1;
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

		double x = 69.0*oldx + newx;
		double y = 69.0*oldy + newy;
		
		azimuth = (float) Math.atan2(x, y);  // upside down x and y.  do not be afraid.  Tom said it was OK
	}
	
	public float getAzimuth() {
		return azimuth;
	}
	public int getAzimuthInDegrees() {
		return (int) (this.azimuth*180/Math.PI);
	}
	

	public long getWaveOffestFromAzimuthInDegrees() {
		long milliseconds = (long) ((System.currentTimeMillis() + timeOffset) % 60000);
		// milliseconds is an int that comes in the form of a number between 0 and 59999 that represents milliseconds from the last minute 'boundary'.
		
		SimpleDateFormat dateFormatGmt = new SimpleDateFormat("HH:mm:ss");
		//Log.i("MexicanWave", " current corrected milliseconds " + (System.currentTimeMillis() + timeOffset) + " and date is " + String.valueOf(dateFormatGmt.format( new Date((System.currentTimeMillis() + timeOffset)))));
		
		
		float offsetDegrees =  ((milliseconds * 6 * (60/this.waveDuration) ) / 1000);

		// divide by 1000 to get milliseconds => seconds. multiply by 6 to get seconds => degrees. 
		 // Log.i("MexicanWave", "**()()** making with offset " + String.valueOf(timeOffset) + "ms, and offset degrees is " + String.valueOf(offsetDegrees));
		//return (int) 0;
		return (long) offsetDegrees;
	}
	
    void update(float azimuth) {
		this.setAzimuth(azimuth);  // we do the maths for smoothing in here
		
		// float averageAzimuth = this.getAzimuthInDegrees();
    	//float waveOffset = this.getWaveOffestFromAzimuthInDegrees();
		//Log.i("MexicanWave", "Current smoothed azimuth is " + String.valueOf(averageAzimuth));
		this.check();
    }	
		
	public void check() {
		long angle = (-this.getAzimuthInDegrees() + this.getWaveOffestFromAzimuthInDegrees()) % 360;
		if (angle > 175 && angle < 185) {

			goWild();
		} else {
			calmDown();
		}
		
		
		//Long correctedTime = System.currentTimeMillis() + timeOffset;
		//SimpleDateFormat dateFormatGmt = new SimpleDateFormat("HH:mm:ss");
		
		// Log.i("MexicanWave", String.valueOf(angle));
		// Log.i("MexicanWave", "** corrected time is " + String.valueOf(dateFormatGmt.format( new Date(correctedTime))));
	}

	public void setReady(boolean ready) {
		cameraReady = ready;
	}
	public boolean getWhetherCameraIsReady() {
		return (mSurface.hasCamera && mSurface.hasSurface) ? true : false;
	}
	
	public void goWild() {
		
		if (currentlyRoaring != true && cameraReady && isFlat == false) {			
			
			
			mSurface.lightOn();
			if (vibrationEnabled) {
				vibrator.vibrate(100 * (int) waveDuration);  // don't mind casting to int because the actual duration of the vibration isn't really all that important.
			}
			screenFlash.setBackgroundColor(waveColor);
			screenFlash.startAnimation(flashAnim);
			
			
			if(soundEnabled && soundLoaded) {
				float actualVolume = (float) audioManager.getStreamVolume(AudioManager.STREAM_MUSIC);
				float maxVolume = (float) audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
				float volume = actualVolume / maxVolume;
				soundPool.play(soundId, volume, volume, 1, 0, 1f);
			}
			
			getNtpTime ntpTime = new getNtpTime();
			ntpTime.execute(timeServer);
			
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

