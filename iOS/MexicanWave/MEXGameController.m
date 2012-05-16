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
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface MEXGameController()
@property (nonatomic) SystemSoundID waveSoundID;
@property (nonatomic) SystemSoundID errorSoundID;

-(void)playAudioClipForSound:(SystemSoundID)sound;
-(void)animateErrorBubbleWithMessage:(NSString*)message;
-(void)animateSprite;
@end

@implementation MEXGameController


@synthesize gameModeSprite,canAnimate,animating,canWave;
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
    [errorMessage setAdjustsFontSizeToFitWidth:YES];
    // Load in the wave sound.
    AudioServicesCreateSystemSoundID((CFURLRef)[[NSBundle mainBundle] URLForResource:@"spring" withExtension:@"mp3"], &waveSoundID);
    AudioServicesCreateSystemSoundID((CFURLRef)[[NSBundle mainBundle] URLForResource:@"boing" withExtension:@"mp3"], &errorSoundID);

    
}

-(void)setCanWave:(BOOL)wave{
    canWave = wave;
    
    if(!canWave && !self.animating){
        
        if(!self.showingError){
            
            [self animateErrorBubbleWithMessage:@"Missed"];
            
        }
    }
}

-(void)playAudioClipForSound:(SystemSoundID)sound{
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultKeySound]){
        AudioServicesPlaySystemSound(sound);
    }
    
}

-(void)didTapDisplay{
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
        [self animateErrorBubbleWithMessage:@"Oops"];         
    }
        
}

-(void)animateErrorBubbleWithMessage:(NSString*)message{
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
    self.animating = YES;
    MEXAppDelegate* appDel = (MEXAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    [self playAudioClipForSound:waveSoundID];
    
    const CGPoint currentCenter = self.gameModeSprite.center;
    
    [UIView animateWithDuration:1.1 animations:^{
        self.gameModeSprite.center = CGPointMake(currentCenter.x, currentCenter.y - 100);
        
    }completion:^(BOOL finished) {
        [appDel.viewController startWave];
        
        [UIView animateWithDuration:0.8 animations:^{
            self.gameModeSprite.center = currentCenter;
            
        }completion:^(BOOL finished) {
            
            self.animating = NO;
        }];
    }];
}


  

@end
