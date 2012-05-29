//
//  MEXWaveFxView.m
//  MexicanWave
//
//  Created by Tom York on 14/03/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "MEXWaveFxView.h"
#import <QuartzCore/QuartzCore.h>
#import "SettingsView.h"
#define kDefaultWidth 320.0f

#define kActiveTime 0.5

@interface MEXWaveFxView ()
-(void)configureWave;
-(void)animateBounceWithCycleTime:(NSTimeInterval)cycleTime activeTime:(NSTimeInterval)activeTime phase:(float)phase imageViewIndex:(NSInteger)index;
-(void)enableGameMode;
- (UIImage*) maskImage:(UIImage *)image;
@property(nonatomic,retain) NSArray* sprites;
@property(nonatomic,retain) NSArray* animationHeights;

@end


@implementation MEXWaveFxView

@synthesize paused;
@synthesize sprites;

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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [sprites release];
    [animationHeights release];
    [sprite_1 release];
    [sprite_2 release];
    [sprite_3 release];
    [sprite_4 release];
    [sprite_5 release];
    [sprite_6 release];
    [sprite_7 release];
    [sprite_8 release];
    [sprite_9 release];
    [sprite_10 release];
    [sprite_11 release];
    [sprite_12 release];
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
    
    //set up the image sprites.
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
    
    //set up and array of the hieghts that each sprite changes its y center point   
    self.animationHeights = [NSArray arrayWithObjects:
                             [NSNumber numberWithFloat:35],
                             [NSNumber numberWithFloat:35],
                             [NSNumber numberWithFloat:40],
                             [NSNumber numberWithFloat:50],
                             [NSNumber numberWithFloat:80],
                             [NSNumber numberWithFloat:100],
                             [NSNumber numberWithFloat:80],
                             [NSNumber numberWithFloat:50],
                             [NSNumber numberWithFloat:40],
                             [NSNumber numberWithFloat:35],
                             [NSNumber numberWithFloat:35],
                             [NSNumber numberWithFloat:30], nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableUserPhotos) name:kCustomCactusImagesDidChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableGameMode) name:kGameModeDidChange object:nil];
    [self enableGameMode];
}

-(void)enableGameMode{
    if([[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultKeyGameMode]){
        self.sprite_7.image = nil;
        return;
    }
    
    self.sprite_7.image = [UIImage imageNamed:@"sprite_8.png"];
    
}
-(void)enableUserPhotos{

    
    NSArray* frontOrderedSprites = [NSArray arrayWithObjects:
                                   sprite_7,
                                   sprite_6,
                                   sprite_8,
                                   sprite_5,
                                   sprite_9,
                                   sprite_4,
                                   sprite_10,
                                   sprite_3,
                                   sprite_11,
                                   sprite_2,
                                   sprite_12,
                                   sprite_1, nil];

    
    NSMutableArray* images = (NSMutableArray*)[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultKeyCustomCactusImages];
    if(images){    
        
        for (NSInteger i = 0; i<[images count]; i++) {
            NSData* data = (NSData*)[images objectAtIndex:i];
            UIImageView *sprite = (UIImageView*)[frontOrderedSprites objectAtIndex:i];
            
            sprite.image = [self maskImage:[UIImage imageWithData:data]];
            
        }
   
    }  else{
        
        self.sprite_5.image = [UIImage imageNamed:@"sprite_5"];
        self.sprite_9.image = [UIImage imageNamed:@"sprite_5"];
        self.sprite_6.image = [UIImage imageNamed:@"sprite_6"];
        self.sprite_8.image = [UIImage imageNamed:@"sprite_6"];
        self.sprite_7.image = [UIImage imageNamed:@"sprite_8"];
    }
    
    
    
}

- (UIImage*) maskImage:(UIImage *)image {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    UIImage *maskImage = [UIImage imageNamed:@"mask.png"];
    CGImageRef maskImageRef = [maskImage CGImage];
    
    // create a bitmap graphics context the size of the image
    CGContextRef mainViewContentContext = CGBitmapContextCreate (NULL, maskImage.size.width, maskImage.size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    
    
    if (mainViewContentContext==NULL)
        return NULL;
    
    CGFloat ratio = 0;
    
    ratio = maskImage.size.width/ image.size.width;
    
    if(ratio * image.size.height < maskImage.size.height) {
        ratio = maskImage.size.height/ image.size.height;
    } 
    
    CGRect rect1  = {{0, 0}, {maskImage.size.width, maskImage.size.height}};
    CGRect rect2  = {{-((image.size.width*ratio)-maskImage.size.width)/2 , -((image.size.height*ratio)-maskImage.size.height)/2}, {image.size.width*ratio, image.size.height*ratio}};
    
    
    CGContextClipToMask(mainViewContentContext, rect1, maskImageRef);
    CGContextDrawImage(mainViewContentContext, rect2, image.CGImage);
    
    
    // Create CGImageRef of the main view bitmap content, and then
    // release that bitmap context
    CGImageRef newImage = CGBitmapContextCreateImage(mainViewContentContext);
    CGContextRelease(mainViewContentContext);
    
    UIImage *theImage = [UIImage imageWithCGImage:newImage];
    
    CGImageRelease(newImage);
    
    // return the image
    return theImage;
}
- (void)animateWithDuration:(NSTimeInterval)duration startingPhase:(float)startingPhase numberOfPeaks:(NSUInteger)peaksPerCycle {
   
    const NSUInteger numberOfLamps = self.sprites.count;
    [self.sprites enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        const float phase = (float)(idx * peaksPerCycle) / (float)numberOfLamps + startingPhase;   
        [self animateBounceWithCycleTime:duration activeTime:kActiveTime/(NSTimeInterval)peaksPerCycle phase:phase imageViewIndex:idx];
    }];
    

    
}
-(void)animateBounceWithCycleTime:(NSTimeInterval)cycleTime activeTime:(NSTimeInterval)activeTime phase:(float)phase imageViewIndex:(NSInteger)index {
      
    
    UIImageView* currentSprite = (UIImageView*)[self.sprites objectAtIndex:index];

    //remove the old animations
    [currentSprite.layer removeAnimationForKey:@"postion"];
    [currentSprite.layer removeAnimationForKey:@"bobbleAnimation"];
   
    //move the center y point up to animate up
    const NSNumber* offset = (NSNumber*)[self.animationHeights objectAtIndex:index];
    const NSInteger originalY = currentSprite.center.y;
    
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
    postionAnim.removedOnCompletion = NO;
    postionAnim.fillMode = kCAFillModeBackwards;
   
    [currentSprite.layer addAnimation:postionAnim forKey:@"postion"];
    
    //Animate a growing effect to make it look like the sprites are enlarging
    CAKeyframeAnimation *bobbleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
	
	CATransform3D startingScale = CATransform3DScale (currentSprite.layer.transform, 0.6, 0.6, 0.6);
	CATransform3D overshootScale = CATransform3DScale (currentSprite.layer.transform, 1.2, 1.25, 1.0);
	CATransform3D endingScale = currentSprite.layer.transform;
	
	NSArray *boundsValues = [NSArray arrayWithObjects:[NSValue valueWithCATransform3D:startingScale],
							 [NSValue valueWithCATransform3D:overshootScale],
							 [NSValue valueWithCATransform3D:endingScale], nil];
	[bobbleAnimation setValues:boundsValues];
	
    bobbleAnimation.keyTimes = [NSArray arrayWithObjects:
                            [NSNumber numberWithFloat:0.5*(1.0-activeTime)],
                            [NSNumber numberWithFloat:0.5],
                            [NSNumber numberWithFloat:0.5*(1.0+activeTime)],nil];

	
	NSArray *timingFunctions = [NSArray arrayWithObjects:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut], 
								[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
								[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
								nil];
	[bobbleAnimation setTimingFunctions:timingFunctions];
	bobbleAnimation.fillMode = kCAFillModeBackwards;
	bobbleAnimation.removedOnCompletion = YES;
    bobbleAnimation.speed = 1.0/cycleTime;
    bobbleAnimation.duration = 1.0;
    bobbleAnimation.timeOffset = phase;
    bobbleAnimation.repeatCount = HUGE_VAL;
	
    [currentSprite.layer addAnimation:bobbleAnimation forKey:@"bobbleAnimation"];

    
    
}
-(void)pauseAnimations{
        
    [self.sprites enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
     
        UIImageView* currentSprite =(UIImageView*)obj;
        const CFTimeInterval timeAtPause = CACurrentMediaTime();
        currentSprite.layer.speed = 0;
        currentSprite.layer.timeOffset = timeAtPause;
        
    }];
    
    
    self.paused = YES;
    
}
- (void)resumeAnimations{
    if(!self.isPaused){
        return;
    }   
    [self.sprites enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        UIImageView* currentSprite =(UIImageView*)obj;
        CFTimeInterval pausedTime = [currentSprite.layer timeOffset];
        currentSprite.layer.speed = 1.0;
        currentSprite.layer.timeOffset = 0.0;
        currentSprite.layer.beginTime = 0.0;
        CFTimeInterval timeSincePause = [currentSprite.layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
        currentSprite.layer.beginTime = timeSincePause;
        
        
    }];
    self.paused = NO;
}
- (void)cancelAnimations{
    
    [self.sprites enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIImageView* currentSprite =(UIImageView*)obj;

        [currentSprite.layer removeAllAnimations];
        
    }];
    
    self.paused = NO;

}
@end
