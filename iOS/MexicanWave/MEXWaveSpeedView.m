//
//  UserGuideView.m
//  MexicanWave
//
//  Created by Daniel Anderton on 24/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "MEXWaveSpeedView.h"
#import "QuartzCore/QuartzCore.h"
#import "MEXWaveModel.h"
#define kSelectionOffset 200
#define kUnselectedAlpha 0.4
#define kResetSelection 0.0

NSString* const kSpeedSegementDidChange = @"kSpeedSegementDidChange";

@interface MEXWaveSpeedView()

-(void)commonInitialisation;
@property(nonatomic) NSInteger currentSelection;
@end

@implementation MEXWaveSpeedView
@synthesize currentSelection;
@synthesize gigContainer,funContainer,stadiumContainer;
@synthesize btnFun,btnGig,btnStadium;
@synthesize lblStepOne,lblStepThree,lblStepTwo;
@synthesize lblFun,lblGig,lblStadium;
-(void)dealloc{
    [lblFun release];
    [lblGig release];
    [lblStadium release];
    [lblStepOne release];
    [lblStepThree release];
    [lblStepTwo release];
    [btnGig release];
    [btnFun release];
    [btnStadium release];
    [stadiumContainer release];
    [funContainer release];
    [gigContainer release];
    [super dealloc];
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInitialisation];
        
    }
    return self;
}

-(void)awakeFromNib{
        
    [self commonInitialisation];
}

-(void)commonInitialisation{
    
    //set the user guice subview to default alpha - these help the current selection to stand out
    
    funContainer.alpha = kUnselectedAlpha;
    gigContainer.alpha = kUnselectedAlpha;
    stadiumContainer.alpha = kUnselectedAlpha;
    
    lblGig.alpha = kUnselectedAlpha;
    lblFun.alpha = kUnselectedAlpha;
    lblStadium.alpha = kUnselectedAlpha;
    
}

-(void)startAnimatingCurrentSelection{
    //start animating the selected views wave from user defaults
    [self startWaveWithTag:kSelectionOffset + [[NSUserDefaults standardUserDefaults] integerForKey:MEXWaveSpeedSettingsKey]];
    
}
-(void)stopAnimating{
    //We are going off view so lets stop the current selection
    [self stopWaveWithTag:currentSelection];
    self.currentSelection = kResetSelection;
}

-(IBAction)didSelectWaveSpeed:(id)sender{
    //make sure this has come from a button.
    if(!sender){
        return;
    }
    
    UIButton *selected = (UIButton*)sender;
    [self startWaveWithTag:selected.tag];
               
} 

-(void)startWaveWithTag:(kWaveSelection)newSelection{

    //make sure we are a new selection
    if(self.currentSelection != newSelection){
        
        //stop the current wave and reset it to default values
        [self stopWaveWithTag:currentSelection];
        
        //find the correct selection using the kWaveSelection. If the current view is paused then resume it - else start a new wave form
        
        switch (newSelection) {
            case kWaveFunTag:
                (!funContainer.isPaused) ? [funContainer animateWithDuration:[MEXWaveModel wavePeriodInSecondsForCrowdType:kMEXCrowdTypeSmallGroup] startingPhase:0 numberOfPeaks:1] : [funContainer resumeAnimations];
                lblFun.alpha = 1.0f;
                funContainer.alpha = 1.0f;
                break;
            case kWaveGigTag:
                (!gigContainer.isPaused) ? [gigContainer animateWithDuration:[MEXWaveModel wavePeriodInSecondsForCrowdType:kMEXCrowdTypeStageBased] startingPhase:0 numberOfPeaks:1] :[gigContainer resumeAnimations];
                lblGig.alpha = 1.0f;
                gigContainer.alpha = 1.0f;
                break;
            case kWaveStaduimTag:
                (!stadiumContainer.isPaused) ? [stadiumContainer animateWithDuration:[MEXWaveModel wavePeriodInSecondsForCrowdType:kMEXCrowdTypeStadium] startingPhase:0 numberOfPeaks:1] : [stadiumContainer resumeAnimations];
                lblStadium.alpha = 1.0;
                stadiumContainer.alpha = 1.0f;
                break;
            default:
                NSLog(@"not recongised selection");
                break;
        }
        //save locally the new selection and broadcast to all listening that the user has changed the speed.
        self.currentSelection = newSelection; 

        [[NSNotificationCenter defaultCenter] postNotificationName:kSpeedSegementDidChange object:[NSNumber numberWithInteger:currentSelection-kSelectionOffset]];

    }

}

-(void)stopWaveWithTag:(kWaveSelection)selection{
    //find the current view that is animating and fade out the labels and wave view.
    switch (currentSelection) {
        case kWaveFunTag:
            [funContainer pauseAnimations];
            lblFun.alpha = kUnselectedAlpha;
            funContainer.alpha = kUnselectedAlpha;
            break;
        case kWaveGigTag:
            [gigContainer pauseAnimations];
            lblGig.alpha = kUnselectedAlpha;
            gigContainer.alpha = kUnselectedAlpha;
            break;
        case kWaveStaduimTag:
            [stadiumContainer pauseAnimations];
            lblStadium.alpha = kUnselectedAlpha;
            stadiumContainer.alpha = kUnselectedAlpha;
            break;
        default:
            break;
    }

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







