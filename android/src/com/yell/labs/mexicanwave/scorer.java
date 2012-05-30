package com.yell.labs.mexicanwave;

import android.content.Context;
import android.widget.TextView;
import android.widget.Toast;

class Scorer {
	

	private Context context;
	
	public int score;
	public int highScore;

	public TextView scoreTextView;
	
	public boolean scoreHasBeenRegisteredForThisCycle;
	public boolean prefNoGame;
	
	
	
	Scorer(Context c, int highScore, TextView v) {
		context = c;
		this.highScore = highScore;
		this.scoreTextView = v;
		this.scoreHasBeenRegisteredForThisCycle = true;  // start with one lap's grace
	}
	
	
	public void registerScore(int s) {
		if (scoreHasBeenRegisteredForThisCycle == false) {
			score = score + s;
			if (score > highScore) {
				highScore = score;
			}
			displayScore();
		}
	}
	
	public void displayScore() {
		String scoreText = "Score: " + String.valueOf(score) + "\nHigh score: " + String.valueOf(highScore);
		scoreTextView.setText(scoreText);
	}
	
	public void registerScoreFromAngle(long angle ) {
		int points = 0;
		points = (int) (20 - (angle - 180));
		this.registerScore(points);
	}
	
	public void checkMiss() {
		if (scoreHasBeenRegisteredForThisCycle == false) {
			Toast.makeText(context, "You missed!", Toast.LENGTH_SHORT).show();
			registerScore(-5);
			scoreHasBeenRegisteredForThisCycle = true;
		}
	}
	
}