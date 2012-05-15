//
//  MEXWaveFxView.h
//  MexicanWave
//
//  Created by Tom York on 14/03/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface MEXWaveFxView : UIView

@property (nonatomic,getter = isPaused) BOOL paused;
@property (nonatomic,retain) IBOutlet UIImageView* waveImageView;
- (void)animateWithDuration:(NSTimeInterval)duration startingPhase:(float)referenceAngle numberOfPeaks:(NSUInteger)peaksPerCycle;
- (void)pauseAnimations;
- (void)resumeAnimations;
- (void)cancelAnimations;


@property(nonatomic,retain) IBOutlet UIImageView* sprite_1;
@property(nonatomic,retain) IBOutlet UIImageView* sprite_2;
@property(nonatomic,retain) IBOutlet UIImageView* sprite_3;
@property(nonatomic,retain) IBOutlet UIImageView* sprite_4;
@property(nonatomic,retain) IBOutlet UIImageView* sprite_5;
@property(nonatomic,retain) IBOutlet UIImageView* sprite_6;
@property(nonatomic,retain) IBOutlet UIImageView* sprite_7;
@property(nonatomic,retain) IBOutlet UIImageView* sprite_8;
@property(nonatomic,retain) IBOutlet UIImageView* sprite_9;
@property(nonatomic,retain) IBOutlet UIImageView* sprite_10;
@property(nonatomic,retain) IBOutlet UIImageView* sprite_11;
@property(nonatomic,retain) IBOutlet UIImageView* sprite_12;
@end
