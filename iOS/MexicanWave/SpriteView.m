//
//  SpriteView.m
//  MexicanWave
//
//  Created by Daniel Anderton on 14/05/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "SpriteView.h"
#import <QuartzCore/QuartzCore.h>
@implementation SpriteView
@synthesize sprite,spriteImage;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInitalistion];
    }
    return self;
}


-(void)commonInitalistion{
    sprite = [[UIImageView alloc]initWithFrame:CGRectZero];
    [self addSubview:sprite];
}

-(void)animateBounceWithCycleTime:(NSTimeInterval)cycleTime activeTime:(NSTimeInterval)activeTime phase:(float)phase {

    [CATransaction begin];
    [self.sprite.layer removeAllAnimations];

    CAKeyframeAnimation * animation = [CAKeyframeAnimation animationWithKeyPath:@"position.y"];
	
	NSMutableArray * positionYValues = [NSMutableArray array];
	
    const CGFloat originalY = self.sprite.frame.origin.y;
    
	[positionYValues addObject:[NSNumber numberWithFloat:originalY]];
	
	[positionYValues addObject:[NSNumber numberWithFloat:originalY+50]];
	
	[positionYValues addObject:[NSNumber numberWithFloat:originalY-50]];
	
	[positionYValues addObject:[NSNumber numberWithFloat:originalY]];
	
	animation.values = positionYValues;
    animation.keyTimes = [NSArray arrayWithObjects:
                                      [NSNumber numberWithFloat:0],
                                      [NSNumber numberWithFloat:0.25],
                                      [NSNumber numberWithFloat:0.5],
                                      [NSNumber numberWithFloat:0.75],
                                      nil];

   
    animation.removedOnCompletion = NO;
    animation.speed = 1.0/cycleTime;
    animation.duration = 1;
    animation.timeOffset = phase - 0.5;
    animation.repeatCount = HUGE_VAL;    // Repeat forever
  

    [self.sprite.layer addAnimation:animation forKey:@"position.y"];

}

-(void)setSpriteImage:(UIImage *)newImage{
    [spriteImage release];
    spriteImage = [newImage retain];
    self.sprite.image = newImage;
    self.sprite.frame = CGRectMake(0, 20, 35, 50);
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
