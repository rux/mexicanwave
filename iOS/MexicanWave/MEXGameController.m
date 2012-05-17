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

@interface MEXGameController()
@property (nonatomic) SystemSoundID waveSoundID;
@property (nonatomic) SystemSoundID errorSoundID;
@property (nonatomic,getter = isShowingError) BOOL showingError; //Boolean for when error message is visiable
@property (nonatomic, getter = isAnimating) BOOL animating; //Boolean to show when the sprite is currently being animated.


-(void)playAudioClipForSound:(SystemSoundID)sound;
-(void)animateErrorBubbleWithMessage:(NSString*)message;
-(void)animateSprite;
@end

@implementation MEXGameController


@synthesize gameModeSprite,animating,canWave;
@synthesize showingError,errorView;
@synthesize errorMessage,waveSoundID,errorSoundID;


-(void)dealloc{
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
    
    const float speed = [[NSUserDefaults standardUserDefaults] integerForKey:MEXWaveSpeedSettingsKey] == kMEXVenueSizeSmall ? 0.6 : 1.0 ;
    
    [self playAudioClipForSound:waveSoundID];
    
    const CGPoint currentCenter = self.gameModeSprite.center;
    
    [UIView animateWithDuration:speed animations:^{
        self.gameModeSprite.center = CGPointMake(currentCenter.x, currentCenter.y - 100);
        
    }completion:^(BOOL finished) {
        
        [appDel.viewController startWave];
        
        [UIView animateWithDuration:speed animations:^{
            self.gameModeSprite.center = currentCenter;
            
        }completion:^(BOOL finished) {
            
            self.animating = NO;
        }];
    }];
}


  

@end
