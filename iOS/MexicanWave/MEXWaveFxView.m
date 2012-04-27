//
//  MEXWaveFxView.m
//  MexicanWave
//
//  Created by Tom York on 14/03/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "MEXWaveFxView.h"
#import "MEXLampView.h"
#import <QuartzCore/QuartzCore.h>

#define kDefaultWidth 320.0f

#define kActiveTime 0.5

@interface MEXWaveFxView ()
@property (nonatomic,retain,readwrite) NSArray* lampViews;

- (void)configureLamps;
@end


@implementation MEXWaveFxView

@synthesize lampViews,paused;

#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame {
    if(!(self = [super initWithFrame:frame])) {
        return nil;
    }
    [self configureLamps];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if(!(self = [super initWithCoder:aDecoder])) {
        return nil;
    }
    [self configureLamps];
    return self;
}

- (void)dealloc {
    [lampViews release];
    [super dealloc];
}

#pragma mark - Configuration

#define SIGN(x) ((x) < 0.0f ? -1.0f : 1.0f)

- (CGPoint)positionOnProjectedCircleForAngle:(float)angle center:(CGPoint)center {
    const float y = 132.0f*2.0f*(fabsf(angle) - 0.5f);
    return CGPointMake(center.x + SIGN(angle)*sqrtf(132.0f*132.0f - y*y), center.y - y);
}

- (CGFloat)scaleFactorOnProjectedCircleForAngle:(float)fractionalAngle {
    return (76.0f/128.0f) * (1.0f - fabsf(fractionalAngle)*0.86);    
}

- (void)configureLamps {
    NSArray* angles = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0f],[NSNumber numberWithFloat:0.24f],[NSNumber numberWithFloat:0.48f],[NSNumber numberWithFloat:0.68f],[NSNumber numberWithFloat:0.815f],[NSNumber numberWithFloat:0.896f],[NSNumber numberWithFloat:0.945f],[NSNumber numberWithFloat:0.98f],[NSNumber numberWithFloat:0.995f],[NSNumber numberWithFloat:1.0f],[NSNumber numberWithFloat:-0.995f],[NSNumber numberWithFloat:-0.98f],[NSNumber numberWithFloat:-0.945f],[NSNumber numberWithFloat:-0.896f],[NSNumber numberWithFloat:-0.815f],[NSNumber numberWithFloat:-0.68f],[NSNumber numberWithFloat:-0.48f],[NSNumber numberWithFloat:-0.24f],nil];

    NSMutableArray* newLamps = [[NSMutableArray alloc] initWithCapacity:angles.count];
    
    [angles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        MEXLampView* oneNewLamp = [[MEXLampView alloc] initWithFrame:CGRectZero];
        [self addSubview:oneNewLamp];
        [newLamps addObject:oneNewLamp];
        [oneNewLamp release];        

        const float oneAngle = [obj floatValue];
        
        const CGFloat scaleFactor = self.bounds.size.width / kDefaultWidth;
        const CGAffineTransform scaleTx = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
        oneNewLamp.center = CGPointApplyAffineTransform([self positionOnProjectedCircleForAngle:oneAngle center:CGPointMake(158.0f, 155.0f)], scaleTx);
        oneNewLamp.transform = scaleTx;
        oneNewLamp.bulbScale = [self scaleFactorOnProjectedCircleForAngle:oneAngle];
        
        
    }];
    
    self.lampViews = newLamps;
    [newLamps release];

}

- (void)animateWithDuration:(NSTimeInterval)duration startingPhase:(float)startingPhase numberOfPeaks:(NSUInteger)peaksPerCycle {

    const NSUInteger numberOfLamps = self.lampViews.count;
    [self.lampViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        MEXLampView* oneLamp = (MEXLampView*)obj;
        const float phase = (float)(idx * peaksPerCycle) / (float)numberOfLamps + startingPhase;   
        [oneLamp animateGlowWithCycleTime:duration activeTime:kActiveTime/(NSTimeInterval)peaksPerCycle phase:phase];
    }];

}

-(void)pauseAnimations{
    [self.lampViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        MEXLampView* oneLamp = (MEXLampView*)obj;
        [oneLamp pauseAnimation];
    }];
    self.paused = YES;

}
- (void)resumeAnimations{
    if(!self.isPaused){
        return;
    }
    [self.lampViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        MEXLampView* oneLamp = (MEXLampView*)obj;
        [oneLamp resumeAnimation];
    }];
    
    self.paused = NO;
}
- (void)cancelAnimations{
    [self.lampViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        MEXLampView* oneLamp = (MEXLampView*)obj;
        [oneLamp.layer removeAllAnimations];
    }];
    self.paused = NO;

}
@end
