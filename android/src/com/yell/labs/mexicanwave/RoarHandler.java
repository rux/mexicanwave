package com.yell.labs.mexicanwave;

import java.util.Timer;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
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
import android.widget.Toast;



class RoarHandler {
	private Context context;
	private Vibrator vibrator;
	private View screenFlash;
	private PreviewSurface mSurface;
	public boolean cameraReady;	
	public boolean currentlyRoaring;
	public boolean isFlat;
	public double azimuth;
	public int waveDuration;
	public int waveColor;
	public int waveFlashLength;
	public boolean vibrationEnabled;
	
	public boolean noGameMode;
	
	public boolean soundEnabled;
	private AudioManager audioManager;
	private SoundPool soundPool;
	private int soundId;
	private boolean soundLoaded;
	
	private Animation flashAnim;
	
	private SntpClient sntpClient;
	private final String timeServer;
	private long timeOffset;
	
	public boolean touched;
	private boolean missedTouchOpportunity; // this detects when the wave has passed the main point
	
	private  Toast myToast;

	public int score;
	public int highScore;

	RoarHandler(Context c, View v, PreviewSurface previewSurface, int wD, int wC, boolean sE, boolean vE, boolean nGM) {
		context = c;
		vibrator = (Vibrator) c.getSystemService(Context.VIBRATOR_SERVICE);  
        screenFlash = (View) v;
        mSurface = previewSurface;
        this.setWaveDuration(wD);
        waveColor = wC;
        soundEnabled = sE;
        vibrationEnabled = vE;
        noGameMode = nGM;
        isFlat = false;
        touched = false;
        score = 0;
        
        soundPool = new SoundPool(1, AudioManager.STREAM_MUSIC, 0);
        soundPool.setOnLoadCompleteListener(new OnLoadCompleteListener() {
			@Override
			public void onLoadComplete(SoundPool soundPool, int sampleId, int status) {
				soundLoaded = true;
			}
		});
        soundId = soundPool.load(context, R.raw.cheer, 1);
        audioManager = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
        
        
        flashAnim.setAnimationListener(new AnimationListener() {  // this is a workaround for a bug that means we can't define the last frame stay put after the animation's finished
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
        
        
        currentlyRoaring = false;  
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
	
	public void setWaveDuration(int w) {
		waveDuration = w;

		// There are two timings here.  The waveFlashLength is for the camera flash and the vibrator. Flashanim is
		// for the screen.  Different because the animation is a bit more complex, so is done in the XML files rather
		// than just assigning it a time.
		if (w < 20) {
			flashAnim = AnimationUtils.loadAnimation(context, R.anim.flash);
			waveFlashLength = 1700;
		} else {
			flashAnim = AnimationUtils.loadAnimation(context, R.anim.flash_long);
			waveFlashLength = 4000;
		}
	}

	
	public void setAzimuth(double a) {
		double oldAzimuth = (double) azimuth;
		double newAzimuth = (double) a;
		
		double oldx = Math.sin(oldAzimuth);
		double oldy = Math.cos(oldAzimuth);
		
		double newx = Math.sin(newAzimuth);
		double newy = Math.cos(newAzimuth);

		double x = 24.0*oldx + newx;
		double y = 24.0*oldy + newy;
		
		azimuth = (double) Math.atan2(x, y);  // upside down x and y.  do not be afraid.  Tom said it was OK
	}
	
	public int getAzimuthInDegrees() {
		return (int) (this.azimuth*180/Math.PI);
	}
	

	public long getWaveOffestFromAzimuthInDegrees() {
		long milliseconds = (long) ((System.currentTimeMillis() + timeOffset) % 60000);
		// milliseconds is a long that comes in the form of a number between 0 and 59999 that represents milliseconds from the last minute 'boundary'.
		
		// SimpleDateFormat dateFormatGmt = new SimpleDateFormat("HH:mm:ss");
		//Log.i("MexicanWave", " current corrected milliseconds " + (System.currentTimeMillis() + timeOffset) + " and date is " + String.valueOf(dateFormatGmt.format( new Date((System.currentTimeMillis() + timeOffset)))));
		
		float offsetDegrees =  ((milliseconds * 6 * (60/this.waveDuration) ) / 1000);

		// divide by 1000 to get milliseconds => seconds. multiply by 6 to get seconds => degrees. 
		 // Log.i("MexicanWave", "making offset with offset " + String.valueOf(timeOffset) + "ms, and offset degrees is " + String.valueOf(offsetDegrees));
		//return (int) 0;
		return (long) offsetDegrees;
	}
	
		
	public void check() {
		long angle = (-this.getAzimuthInDegrees() + this.getWaveOffestFromAzimuthInDegrees()) % 360;

		if (angle > 170 && angle < 200) {
			goWild(angle);
		} else {
			if (currentlyRoaring == false && noGameMode == false && missedTouchOpportunity == true) {
				myToast.makeText(context, "You missed!", Toast.LENGTH_SHORT).show();
				missedTouchOpportunity = false;
			}
			touched = false;
		}
		
		
		//Long correctedTime = System.currentTimeMillis() + timeOffset;
		//SimpleDateFormat dateFormatGmt = new SimpleDateFormat("HH:mm:ss");
		
		// Log.i("MexicanWave", String.valueOf(angle));
		// Log.i("MexicanWave", "** corrected time is " + String.valueOf(dateFormatGmt.format( new Date(correctedTime))));
	}


	public boolean getWhetherCameraIsReady() {
		return (mSurface.hasCamera && mSurface.hasSurface) ? true : false;
	}
	
	public void goWild(long angle) {
		if (currentlyRoaring != true && cameraReady && isFlat == false) {			
			if (touched == true || noGameMode==true) {
				mSurface.lightOn();
				
				lightSwitchTask lightSwitch = new lightSwitchTask();
				lightSwitch.execute(waveFlashLength); 

				if (vibrationEnabled) {
					vibrator.vibrate(waveFlashLength);
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
				
				if (currentlyRoaring == false) {
					score = this.score + score(angle);
					// myToast.makeText(context, String.valueOf(score), 500).show();
					missedTouchOpportunity = false;
				}
				
				currentlyRoaring = true;

			} else {
				Log.i("MexicanWaveTouch", "missed opportunity");
				missedTouchOpportunity = true;
			}

			touched = false;
		}
	}	
	
	public void calmDown() {
		if(cameraReady && (currentlyRoaring == true)) {
			mSurface.lightOff();
		}
		currentlyRoaring = false;
	}
	
	public int score(long angle ) {
		int points = 0;
		points = (int) (20 - (angle - 180));
		return points;
	}
	
	
	private class lightSwitchTask extends AsyncTask<Integer, Void, Boolean> {

		@Override
		protected Boolean doInBackground(Integer... params) {
			try {
				Thread.sleep((long) params[0]);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			
			calmDown();
			return true;
		}
	}
}

