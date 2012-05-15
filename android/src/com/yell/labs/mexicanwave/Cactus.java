package com.yell.labs.mexicanwave;

import android.content.Context;
import android.graphics.Bitmap;
import android.view.View;
import android.widget.ImageView;



public class Cactus extends View {
	
	private Bitmap bitmap;
	
	private int xPosition;
	private int yPosition;
	
	private int bounceHeight;
	private int bounceDuration;

	
	
	public Cactus(Context context, Bitmap bitmap, int xPosition, int yPosition, int bounceHeight, int bounceDuration) {
		super(context);
		this.xPosition = xPosition;
		this.yPosition = yPosition;
		this.bounceHeight = bounceHeight;
		this.bounceDuration = bounceDuration;
		this.bitmap = bitmap;
	}


	

	
	
}
