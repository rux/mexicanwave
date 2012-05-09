//
//  MEXWaveFxView.m
//  MexicanWave
//
//  Created by Tom York on 14/03/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "MEXWaveFxView.h"
#import <QuartzCore/QuartzCore.h>

#define kDefaultWidth 320.0f

#define kActiveTime 0.5

@interface MEXWaveFxView ()
- (void)configureWave;
@end


@implementation MEXWaveFxView

@synthesize paused;
@synthesize waveImageView;
#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame {
    if(!(self = [super initWithFrame:frame])) {
        return nil;
    }
    [self configureWave];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if(!(self = [super initWithCoder:aDecoder])) {
        return nil;
    }
    [self configureWave];
    return self;
}

- (void)dealloc {
    [waveImageView release];    
    [super dealloc];
}

#pragma mark - Configuration

- (void)configureWave {
    // TEST
    const CGSize viewSize = self.waveImageView.bounds.size;
    
    const CGFloat nearPlaneDistance = viewSize.width / (2.0f * tanf(0.5f*120.0f));
    // 120 degrees Field Of View angle
    CATransform3D perspectiveTransform = CATransform3DIdentity;
    perspectiveTransform.m11 = nearPlaneDistance / viewSize.width;
    perspectiveTransform.m22 = nearPlaneDistance / viewSize.height;
    perspectiveTransform.m33 = -1.0f;
    perspectiveTransform.m43 = -1.0f;
    perspectiveTransform.m34 = -2.0f*nearPlaneDistance;
    
    
    CATransform3D discOrientTransform = CATransform3DMakeRotation(0.0f * M_PI/180.0f, 0.0f, 0.0f, 1.0f);
    // Spin the image around the plane over time
    discOrientTransform = CATransform3DRotate(discOrientTransform, 40.0f * M_PI/180.0f, 1.0f, 0.0f, 0.0f);
    // 40 degree rotation away from face-on
    discOrientTransform = CATransform3DConcat(perspectiveTransform, discOrientTransform);
    
    self.waveImageView.layer.transform = discOrientTransform;   
    
}

- (void)animateWithDuration:(NSTimeInterval)duration startingPhase:(float)startingPhase numberOfPeaks:(NSUInteger)peaksPerCycle {
   
    [self cancelAnimations];
    
    CABasicAnimation* animation;
    animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    
    animation.fromValue = [NSNumber numberWithFloat:0];
    animation.toValue = [NSNumber numberWithFloat:2.0 * M_PI];
    animation.duration = 1.0;
    animation.removedOnCompletion = NO;
    animation.repeatCount = HUGE_VALF;    // Repeat forever           
    animation.speed = 1.0/duration;
    animation.timeOffset = startingPhase;
    [self.waveImageView.layer addAnimation:animation forKey:@"transform.rotation.z"];
}

-(void)pauseAnimations{
    const CFTimeInterval timeAtPause = CACurrentMediaTime();
    self.waveImageView.layer.speed = 0;
    self.waveImageView.layer.timeOffset = timeAtPause;
    self.paused = YES;

}
- (void)resumeAnimations{
    if(!self.isPaused){
        return;
    }
    CFTimeInterval pausedTime = [self.waveImageView.layer timeOffset];
    self.waveImageView.layer.speed = 1.0;
    self.waveImageView.layer.timeOffset = 0.0;
    self.waveImageView.layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [self.waveImageView.layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    self.waveImageView.layer.beginTime = timeSincePause;
    self.paused = NO;
}
- (void)cancelAnimations{
    [self.waveImageView.layer removeAllAnimations];
    self.paused = NO;

}
@end
