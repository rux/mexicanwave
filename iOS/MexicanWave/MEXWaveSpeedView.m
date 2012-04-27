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
-(void)cancelWaveWithTag:(MEXWaveSelection)selection;
-(void)pauseWaveWithTag:(MEXWaveSelection)selection;
-(void)startWaveWithTag:(MEXWaveSelection)newSelection;


@property(nonatomic) NSInteger currentSelection;
@end

@implementation MEXWaveSpeedView
@synthesize currentSelection;
@synthesize mediumVenueWave,smallVenueWave,largeVenueWave;
@synthesize btnFun,btnGig,btnStadium,visible;
@synthesize lblStepOne,lblStepThree,lblStepTwo;
@synthesize lblFun,lblGig,lblStadium;
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [lblFun release];
    [lblGig release];
    [lblStadium release];
    [lblStepOne release];
    [lblStepThree release];
    [lblStepTwo release];
    [btnGig release];
    [btnFun release];
    [btnStadium release];
    [largeVenueWave release];
    [smallVenueWave release];
    [mediumVenueWave release];
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
    
    smallVenueWave.alpha = kUnselectedAlpha;
    mediumVenueWave.alpha = kUnselectedAlpha;
    largeVenueWave.alpha = kUnselectedAlpha;
    
    lblGig.alpha = kUnselectedAlpha;
    lblFun.alpha = kUnselectedAlpha;
    lblStadium.alpha = kUnselectedAlpha;
    

}

-(void)didEnterBackground{
    [self cancelWaveWithTag:currentSelection];
}


-(void)didBecomeActive{
    //if we are currently in view restart the animation
    if(self.isVisible){
        [self startWaveWithTag:kSelectionOffset + [[NSUserDefaults standardUserDefaults] integerForKey:MEXWaveSpeedSettingsKey]];
    }
}

-(void)startAnimatingCurrentSelection{
    //start animating the selected views wave from user defaults
    [self startWaveWithTag:kSelectionOffset + [[NSUserDefaults standardUserDefaults] integerForKey:MEXWaveSpeedSettingsKey]];
    self.visible = YES;    
}
-(void)stopAnimating{
    //We are going off view so lets stop the current selection
    [self cancelWaveWithTag:currentSelection];
    self.visible = NO;
}

-(IBAction)didSelectWaveSpeed:(id)sender{
    //make sure this has come from a button.
    if(!sender){
        return;
    }
    
    UIButton *selected = (UIButton*)sender;
    [self startWaveWithTag:selected.tag];
               
} 

-(void)startWaveWithTag:(MEXWaveSelection)newSelection{

    //make sure we are a new selection
    if(self.currentSelection != newSelection){
        
        //stop the current wave and reset it to default values
        [self pauseWaveWithTag:currentSelection];
        
        //find the correct selection using the kWaveSelection. If the current view is paused then resume it - else start a new wave form
        switch (newSelection) {
            case kWaveFunTag:
                (!smallVenueWave.isPaused) ? [smallVenueWave animateWithDuration:[MEXWaveModel wavePeriodInSecondsForCrowdType:kMEXCrowdTypeSmallGroup] startingPhase:0 numberOfPeaks:1] :[smallVenueWave resumeAnimations];
                lblFun.alpha = 1.0f;
                smallVenueWave.alpha = 1.0f;
                break;
            case kWaveGigTag:
                (!mediumVenueWave.isPaused) ? [mediumVenueWave animateWithDuration:[MEXWaveModel wavePeriodInSecondsForCrowdType:kMEXCrowdTypeStageBased] startingPhase:0 numberOfPeaks:1] :[mediumVenueWave resumeAnimations];
                lblGig.alpha = 1.0f;
                mediumVenueWave.alpha = 1.0f;
                break;
            case kWaveStaduimTag:
                (!largeVenueWave.isPaused) ? [largeVenueWave animateWithDuration:[MEXWaveModel wavePeriodInSecondsForCrowdType:kMEXCrowdTypeStadium] startingPhase:0 numberOfPeaks:1] : [largeVenueWave resumeAnimations];
                lblStadium.alpha = 1.0;
                largeVenueWave.alpha = 1.0f;
                break;
            default:
                DLog(@"Not a selection we know about %u",newSelection);
                return;
                break;
        }
        self.currentSelection = newSelection;
        //save locally the new selection and broadcast to all listening that the user has changed the speed.
        DLog(@"started");
        [[NSNotificationCenter defaultCenter] postNotificationName:kSpeedSegementDidChange object:[NSNumber numberWithInteger:currentSelection-kSelectionOffset]];

    }

}

-(void)pauseWaveWithTag:(MEXWaveSelection)selection{
    //find the current view that is animating and fade out the labels and wave view.
    switch (currentSelection) {
        case kWaveFunTag:
            [smallVenueWave pauseAnimations];
            lblFun.alpha = kUnselectedAlpha;
            smallVenueWave.alpha = kUnselectedAlpha;
            break;
        case kWaveGigTag:
            [mediumVenueWave pauseAnimations];
            lblGig.alpha = kUnselectedAlpha;
            mediumVenueWave.alpha = kUnselectedAlpha;
            break;
        case kWaveStaduimTag:
            [largeVenueWave pauseAnimations];
            lblStadium.alpha = kUnselectedAlpha;
            largeVenueWave.alpha = kUnselectedAlpha;
            break;
        default:
            break;
    }
    DLog(@"paused");
}
-(void)cancelWaveWithTag:(MEXWaveSelection)selection{
    //find the current view that is animating and cancel the current animations
  
    [smallVenueWave cancelAnimations];
    lblFun.alpha = kUnselectedAlpha;
    smallVenueWave.alpha = kUnselectedAlpha;
    
    [mediumVenueWave cancelAnimations];
    lblGig.alpha = kUnselectedAlpha;
    mediumVenueWave.alpha = kUnselectedAlpha;
    
    [largeVenueWave cancelAnimations];
    lblStadium.alpha = kUnselectedAlpha;
    largeVenueWave.alpha = kUnselectedAlpha;
          
    currentSelection =kResetSelection;
    DLog(@"cancelled");
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







