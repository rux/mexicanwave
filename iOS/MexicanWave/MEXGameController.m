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

@implementation MEXGameController
@synthesize gameModeSprite,canAnimate,animating,canWave;
@synthesize showingError,errorView;
@synthesize errorMessage;
-(void)dealloc{
    [errorMessage release];
    [errorView release];
    [gameModeSprite release];
    [super dealloc];
}

-(void)awakeFromNib{
    [errorMessage setAdjustsFontSizeToFitWidth:YES];
}

-(void)didTapDisplay{
    if(self.canWave){
        if(self.isAnimating){
            return;
        }
        
        if(self.isShowingError){
            self.errorView.hidden = YES;
        }
        
        self.animating = YES;
        MEXAppDelegate* appDel = (MEXAppDelegate*)[[UIApplication sharedApplication] delegate];
        
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
    else {
        if(!self.showingError && !self.animating){
                
            self.errorView.alpha = 0;
            self.errorView.hidden = NO;

            [UIView animateWithDuration:0.6 animations:^{
                self.errorView.alpha = 1;
                
            }completion:^(BOOL finished) {
                
                [UIView animateWithDuration:0.4 animations:^{
                    self.errorView.alpha = 0;
                    
                }completion:^(BOOL finished) {
                    
                    self.showingError = NO;
                }];
            }];
            
            
        }
        
    }
}

-(void)setCanWave:(BOOL)wave{
    canWave = wave;
    
    if(!canWave && !self.animating){
        
        if(!self.showingError){
            self.showingError = YES;
            self.errorMessage.text = @"Missed";
            self.errorView.alpha = 0;
            self.errorView.hidden = NO;
            
            [UIView animateWithDuration:1.0 animations:^{
                self.errorView.alpha = 1;
                
            }completion:^(BOOL finished) {
                
                [UIView animateWithDuration:0.6 animations:^{
                    self.errorView.alpha = 0;
                    
                }completion:^(BOOL finished) {
                    self.showingError = NO;
                    self.errorView.hidden = YES;
                    self.errorMessage.text = @"Oops";
                }];
            }];
        }
    }
}

@end
