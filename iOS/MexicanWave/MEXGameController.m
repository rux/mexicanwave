//
//  MEXGameController.m
//  MexicanWave
//
//  Created by Daniel Anderton on 15/05/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "MEXGameController.h"
#import "MEXAppDelegate.h"
#import "MEXWavingViewController.h"
#import "MEXWaveModel.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define kHighScoreKey @"kHighScoreKey"

@interface MEXGameController()
@property (nonatomic) SystemSoundID waveSoundID;
@property (nonatomic) SystemSoundID errorSoundID;
@property (nonatomic,getter = isShowingError) BOOL showingError; //Boolean for when error message is visiable
@property (nonatomic, getter = isAnimating) BOOL animating; //Boolean to show when the sprite is currently being animated.

@property (nonatomic) NSInteger currentScore;

-(void)playAudioClipForSound:(SystemSoundID)sound;
-(void)animateErrorBubbleWithMessage:(NSString*)message;
-(void)animateSprite;
-(void)enableGameMode;

-(void)resetUserScore;
-(void)updateUserScore;
@end

@implementation MEXGameController


@synthesize gameModeSprite,animating,canWave;
@synthesize showingError,errorView;
@synthesize errorMessage,waveSoundID,errorSoundID,currentScore;
@synthesize lblHighscore,lblCurrentScore;

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
     AudioServicesDisposeSystemSoundID(waveSoundID);
     AudioServicesDisposeSystemSoundID(errorSoundID);
    [errorMessage release];
    [errorView release];
    [gameModeSprite release];
    [super dealloc];
}

-(void)awakeFromNib{
    //Bug in latest x-Code a label size isnt auto adjusted 
    [errorMessage setAdjustsFontSizeToFitWidth:YES];

    // Load in the wave sounds.
    AudioServicesCreateSystemSoundID((CFURLRef)[[NSBundle mainBundle] URLForResource:@"spring" withExtension:@"mp3"], &waveSoundID);
    AudioServicesCreateSystemSoundID((CFURLRef)[[NSBundle mainBundle] URLForResource:@"boing" withExtension:@"mp3"], &errorSoundID);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableGameMode) name:kGameModeDidChange object:nil];
   
    double delayInSeconds = 7.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self enableGameMode];

    });
    [self enableUserPhotos];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableUserPhotos) name:kCustomCactusImagesDidChange object:nil];
}

-(void)enableUserPhotos{
                                        
    
    NSMutableArray* images = (NSMutableArray*)[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultKeyCustomCactusImages];
    if(images){    
        
        NSData* data = (NSData*)[images objectAtIndex:0];
            
        gameModeSprite.image = [self maskImage:[UIImage imageWithData:data]];
        
    }  
    
    else{
        
        self.gameModeSprite.image = [UIImage imageNamed:@"sprite_11"];
    
    }
    
    
    
}
-(void)enableGameMode{
    
    const NSInteger gameTextAlpha = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultKeyGameMode] ? 1 : 0;

    lblHighscore.text = [NSString stringWithFormat:@"High Score: %u",[[NSUserDefaults standardUserDefaults] integerForKey:kHighScoreKey]];
    lblCurrentScore.text = [NSString stringWithFormat:@"Score: %u",currentScore];
    
      
    lblCurrentScore.alpha = gameTextAlpha;
    lblHighscore.alpha = gameTextAlpha;

    
}

-(void)setCanWave:(BOOL)wave{
    canWave = wave;
      
    
    //if we cant wave and we are currently not animating we can assume you have missed the wave.
    if(!canWave && !self.animating){
        
        if(!self.showingError){
            
            [self animateErrorBubbleWithMessage:NSLocalizedString(@"Missed", @"Title shown when user hasnt tapped in game mode")];
        
        }
    }
}

-(void)playAudioClipForSound:(SystemSoundID)sound{
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultKeySound]){
        AudioServicesPlaySystemSound(sound);
    }
    
}

-(void)didTapDisplay{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultKeyGameMode]){
        return;
    }
      /*Check we are allowed to wave - this is to check the timings 
       Are we all ready animating? there is no need to animate twice
       If we are showing an error get rid of it we are about to wave */
    
    if(self.canWave){
        if(self.isAnimating){
            return;
        }
        
        if(self.isShowingError){
            self.errorView.hidden = YES;
        }
        
        [self animateSprite];
        return;
    }
           
    if(!self.showingError && !self.animating){
        [self animateErrorBubbleWithMessage:NSLocalizedString(@"Oops", @"Title shown when user has tapped to early")];         
    }
        
}

-(void)animateErrorBubbleWithMessage:(NSString*)message{
    /*
     Tell everyone we are showing an error and prepare it for animation
     Play the 'boing' error sound and animate the speech bubble into view. */
    [self resetUserScore];
    
    self.showingError = YES;
    self.errorView.alpha = 0;
    self.errorView.hidden = NO;
    self.errorMessage.text = message;

    [self playAudioClipForSound:errorSoundID];
    
    [UIView animateWithDuration:0.6 animations:^{
        self.errorView.alpha = 1;
        
    }completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.4 animations:^{
            self.errorView.alpha = 0;
            
        }completion:^(BOOL finished) {
            
            self.showingError = NO;
            self.errorView.hidden = YES;

        }];
    }];
    

}

-(void)animateSprite{
    
    /* Tell everyone are about to animate, get the center point of the gamemode sprite and animate
     its center point up. Once at peak play the spring sound
     flash the screen and the camera flash and vibrate if needed. 
     Then return to a hidden state. */
    
    self.animating = YES;
    MEXAppDelegate* appDel = (MEXAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    [self updateUserScore];
    
    const float speed = [[NSUserDefaults standardUserDefaults] integerForKey:MEXWaveSpeedSettingsKey] == kMEXVenueSizeSmall ? 0.6 : 1.0 ;
    
    [self playAudioClipForSound:waveSoundID];
    CATransform3D orginalScale = CATransform3DScale (gameModeSprite.layer.transform, 1.0, 1.0, 1);
    CATransform3D startingScale = CATransform3DScale (gameModeSprite.layer.transform, 0.7, 0.7, 1);
	CATransform3D overshootScale = CATransform3DScale (gameModeSprite.layer.transform, 1.2, 1.25, 1.0);
    self.gameModeSprite.layer.transform = startingScale;
    
    const CGPoint currentCenter = self.gameModeSprite.center;
    
    [UIView animateWithDuration:speed animations:^{
        self.gameModeSprite.center = CGPointMake(currentCenter.x, currentCenter.y - 100);
        self.gameModeSprite.layer.transform = overshootScale;
        
    }completion:^(BOOL finished) {
        
        [appDel.viewController startWave];
        
        [UIView animateWithDuration:speed animations:^{
            self.gameModeSprite.center = currentCenter;
            self.gameModeSprite.layer.transform = orginalScale;
            
        }completion:^(BOOL finished) {
            self.animating = NO;
        }];
    }];
}

-(void)updateUserScore{
    
    currentScore +=10;
    lblCurrentScore.text = [NSString stringWithFormat:@"Score: %u",currentScore];
    if(currentScore> [[NSUserDefaults standardUserDefaults] integerForKey:kHighScoreKey]){
        [[NSUserDefaults standardUserDefaults] setInteger:currentScore forKey:kHighScoreKey];
        lblHighscore.text = [NSString stringWithFormat:@"High Score: %u",currentScore];
        
    }
    
}

-(void)resetUserScore{
    currentScore = 0;
    lblCurrentScore.text = [NSString stringWithFormat:@"Score: %u",currentScore];

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

@end
