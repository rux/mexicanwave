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
-(void)animateBounceWithCycleTime:(NSTimeInterval)cycleTime activeTime:(NSTimeInterval)activeTime phase:(float)phase imageViewIndex:(NSInteger)index;

@property(nonatomic,retain) NSArray* sprites;
@property(nonatomic,retain) NSArray* animationHeights;

@end


@implementation MEXWaveFxView

@synthesize paused;
@synthesize waveImageView,sprites;

@synthesize sprite_1,sprite_2,sprite_3,sprite_4,sprite_5,sprite_6,sprite_7,sprite_8,sprite_9,sprite_10,sprite_11,sprite_12,animationHeights;

#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame {
    if(!(self = [super initWithFrame:frame])) {
        return nil;
    }
    [self configureWave];
    return self;
}

-(void)awakeFromNib{
    [self configureWave];
}

- (void)dealloc {
    [sprites release];
    [waveImageView release];    
    [super dealloc];
}
#define SIGN(x) ((x) < 0.0f ? -1.0f : 1.0f)

- (CGPoint)positionOnProjectedCircleForAngle:(float)angle center:(CGPoint)center {
    const float y = 132.0f*2.0f*(fabsf(angle) - 0.5f);
    return CGPointMake(center.x + SIGN(angle)*sqrtf(132.0f*132.0f - y*y), center.y - y);
}

- (CGFloat)scaleFactorOnProjectedCircleForAngle:(float)fractionalAngle {
    return (76.0f/128.0f) * (1.0f - fabsf(fractionalAngle)*0.86);    
}

#pragma mark - Configuration
- (void)configureWave {
    self.sprites = [NSArray arrayWithObjects:
                    sprite_12,
                    sprite_11,
                    sprite_10,
                    sprite_9,
                    sprite_8,
                    sprite_7,
                    sprite_6,
                    sprite_5,
                    sprite_4,
                    sprite_3,
                    sprite_2,
                    sprite_1, nil];
       
    self.animationHeights = [NSArray arrayWithObjects:
                             [NSNumber numberWithFloat:30],
                             [NSNumber numberWithFloat:30],
                             [NSNumber numberWithFloat:30],
                             [NSNumber numberWithFloat:50],
                             [NSNumber numberWithFloat:76],
                             [NSNumber numberWithFloat:100],
                             [NSNumber numberWithFloat:72],
                             [NSNumber numberWithFloat:50],
                             [NSNumber numberWithFloat:30],
                             [NSNumber numberWithFloat:30],
                             [NSNumber numberWithFloat:30],
                             [NSNumber numberWithFloat:20], nil];

 
}

- (void)animateWithDuration:(NSTimeInterval)duration startingPhase:(float)startingPhase numberOfPeaks:(NSUInteger)peaksPerCycle {
   
    const NSUInteger numberOfLamps = self.sprites.count;
    [self.sprites enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        const float phase = (float)(idx * peaksPerCycle) / (float)numberOfLamps + startingPhase;   
        [self animateBounceWithCycleTime:duration activeTime:kActiveTime/(NSTimeInterval)peaksPerCycle phase:phase imageViewIndex:idx];
    }];
    

    
}
-(void)animateBounceWithCycleTime:(NSTimeInterval)cycleTime activeTime:(NSTimeInterval)activeTime phase:(float)phase imageViewIndex:(NSInteger)index {
    
    UIImageView* current = (UIImageView*)[self.sprites objectAtIndex:index];
    const NSNumber* offset = (NSNumber*)[self.animationHeights objectAtIndex:index];
    
    [current.layer removeAllAnimations];
   
    const NSInteger originalY = current.center.y;
    
    
    CAKeyframeAnimation* postionAnim = [CAKeyframeAnimation animationWithKeyPath:@"position.y"];
    postionAnim.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:originalY],
                          [NSNumber numberWithFloat:originalY-[offset integerValue]],
                          [NSNumber numberWithFloat:originalY],nil];
    postionAnim.keyTimes = [NSArray arrayWithObjects:
                            [NSNumber numberWithFloat:0.5*(1.0-activeTime)],
                            [NSNumber numberWithFloat:0.5],
                            [NSNumber numberWithFloat:0.5*(1.0+activeTime)],nil];
    
    postionAnim.speed = 1.0/cycleTime;
    postionAnim.duration = 1.0;
    postionAnim.timeOffset = phase;
    postionAnim.repeatCount = HUGE_VALF;  
    
    [current.layer addAnimation:postionAnim forKey:@"postionAnim"];
   
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
