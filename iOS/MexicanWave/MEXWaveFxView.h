//
//  MEXWaveFxView.h
//  MexicanWave
//
//  Created by Tom York on 14/03/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MEXWaveFxView : UIView

@property (nonatomic,retain,readonly) NSArray* lampViews;
@property (nonatomic,getter = isPaused) BOOL paused;
- (void)animateWithDuration:(NSTimeInterval)duration startingPhase:(float)referenceAngle numberOfPeaks:(NSUInteger)peaksPerCycle;
- (void)pauseAnimations;
- (void)resumeAnimations;
- (void)cancelAnimations;

@end
