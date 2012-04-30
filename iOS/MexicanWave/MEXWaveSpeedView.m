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
-(void)resetAllWaves;
-(void)startWaveWithTag:(MEXWaveSelection)newSelection;


@property(nonatomic) NSInteger currentSelection;
@end

@implementation MEXWaveSpeedView
@synthesize currentSelection;
@synthesize mediumVenueWave,smallVenueWave,largeVenueWave;
@synthesize btnFun,btnGig,btnStadium,visible;
@synthesize lblStepOne,lblStepThree,lblStepTwo;
@synthesize lblSmall,lblMedium,lblLarge;
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [lblSmall release];
    [lblMedium release];
    [lblLarge release];
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
    
    //Reset all the speed settings to default blank values 
    [self resetAllWaves];
}

-(void)didEnterBackground{
    [self resetAllWaves];
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
    [self resetAllWaves];
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
        [self resetAllWaves];
        
        //find the correct selection using the kWaveSelection. If the current view is paused then resume it - else start a new wave form
        switch (newSelection) {
            case kWaveFunTag:
                [smallVenueWave animateWithDuration:[MEXWaveModel wavePeriodInSecondsForCrowdType:kMEXCrowdTypeSmallGroup] startingPhase:0 numberOfPeaks:1];
                lblSmall.alpha = 1.0f;
                smallVenueWave.alpha = 1.0f;
                break;
            case kWaveGigTag:
                [mediumVenueWave animateWithDuration:[MEXWaveModel wavePeriodInSecondsForCrowdType:kMEXCrowdTypeStageBased] startingPhase:0 numberOfPeaks:1];
                lblMedium.alpha = 1.0f;
                mediumVenueWave.alpha = 1.0f;
                break;
            case kWaveStaduimTag:
                [largeVenueWave animateWithDuration:[MEXWaveModel wavePeriodInSecondsForCrowdType:kMEXCrowdTypeStadium] startingPhase:0 numberOfPeaks:1];
                lblLarge.alpha = 1.0;
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

-(void)resetAllWaves{
    //Reset all the vies to thier default values.
  
    [smallVenueWave cancelAnimations];
    lblSmall.alpha = kUnselectedAlpha;
    smallVenueWave.alpha = kUnselectedAlpha;
    
    [mediumVenueWave cancelAnimations];
    lblMedium.alpha = kUnselectedAlpha;
    mediumVenueWave.alpha = kUnselectedAlpha;
    
    [largeVenueWave cancelAnimations];
    lblLarge.alpha = kUnselectedAlpha;
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







