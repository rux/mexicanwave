package com.yell.labs.mexicanwave;

import android.content.Context;
import android.graphics.Bitmap;
import android.util.Log;
import android.view.View;
import android.view.animation.BounceInterpolator;
import android.view.animation.CycleInterpolator;
import android.view.animation.Interpolator;
import android.view.animation.TranslateAnimation;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.RelativeLayout.LayoutParams;



public class Cactus extends ImageView {
	
	public LayoutParams layoutParams;
	
	public int xPosition;
	public int yPosition;
	
	public int angle;
	
	private int bounceHeight;
	private int bounceDuration;

	private TranslateAnimation bounceAnimation;
	private boolean isBouncing;
	
	
	
	public Cactus(Context context, int drawable, int xPosition, int yPosition, int bounceHeight, int bounceDuration, int angle) {
		super(context);
		this.xPosition = xPosition;
		this.yPosition = yPosition;
		this.angle = angle;
		
		this.setImageResource(drawable);
		
		
		this.bounceHeight = bounceHeight;
		this.bounceDuration = bounceDuration;
		
		layoutParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT );
		layoutParams.topMargin = yPosition;
        layoutParams.leftMargin = xPosition;
		
        bounceAnimation = new TranslateAnimation(0, 0, 0, -bounceHeight);
        bounceAnimation.setDuration(bounceDuration);
        bounceAnimation.setInterpolator(new CycleInterpolator(1));
        
	}


	public void bounce() {
		if (isBouncing == false) {
			Log.i("MexBounce", "bounce started for " + String.valueOf(angle));
			this.startAnimation(bounceAnimation);
			isBouncing = true;
		}
	}
	
	@Override
	protected void onAnimationEnd() {
		super.onAnimationEnd();
		invalidate();
		isBouncing = false;
	}
	
}
